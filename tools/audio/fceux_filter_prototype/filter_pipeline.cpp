// Diagnostic port of FCEUX 2.7.0 soundq=2 filtering.
//
// The convolution, fixed-point interpolation, overlap, and SexyFilter state
// follow FCEUX src/filter.cpp at pinned commit a6d03e7968bd77a8156a7c9b628a673753f2f4c6.
// This tool deliberately does not synthesize WaveHi. Its input is a ROM-derived
// libgme 44.1-kHz mono signal, held at mapped CPU-cycle positions as a named
// surrogate input, so output is diagnostic and cannot be mistaken for FCEUX
// WaveHi or a runtime asset.

#include "fceux_fir_coefficients.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
constexpr int kSampleRate = 44100;
constexpr double kNtscCpuHz = 1789772.7272727272727272;
constexpr std::uint32_t kFirLength = 1024;

struct FrameCycles {
	std::uint64_t source_frame;
	std::uint64_t cycle_start;
	std::uint64_t cycle_end;
};

std::uint16_t read_u16(std::istream& input) {
	std::uint16_t value;
	input.read(reinterpret_cast<char*>(&value), sizeof(value));
	if (!input) throw std::runtime_error("truncated WAV header");
	return value;
}

std::uint32_t read_u32(std::istream& input) {
	std::uint32_t value;
	input.read(reinterpret_cast<char*>(&value), sizeof(value));
	if (!input) throw std::runtime_error("truncated WAV header");
	return value;
}

std::vector<std::int16_t> load_pcm_wav(const std::string& path) {
	std::ifstream file(path, std::ios::binary);
	if (!file) throw std::runtime_error("unable to open source WAV: " + path);
	char riff[4], wave[4];
	file.read(riff, 4);
	(void)read_u32(file);
	file.read(wave, 4);
	if (!file || std::string(riff, 4) != "RIFF" || std::string(wave, 4) != "WAVE")
		throw std::runtime_error("input is not a RIFF/WAVE file");

	bool have_fmt = false, have_data = false;
	std::uint16_t channels = 0, bits = 0, format = 0;
	std::uint32_t sample_rate = 0, data_size = 0;
	std::streampos data_pos = 0;
	while (file && !(have_fmt && have_data)) {
		char chunk[4];
		file.read(chunk, 4);
		if (!file) break;
		const std::uint32_t size = read_u32(file);
		const std::string id(chunk, 4);
		if (id == "fmt ") {
			format = read_u16(file);
			channels = read_u16(file);
			sample_rate = read_u32(file);
			(void)read_u32(file);
			(void)read_u16(file);
			bits = read_u16(file);
			if (size > 16) file.seekg(size - 16, std::ios::cur);
			have_fmt = true;
		} else if (id == "data") {
			data_pos = file.tellg();
			data_size = size;
			file.seekg(size, std::ios::cur);
			have_data = true;
		} else {
			file.seekg(size, std::ios::cur);
		}
		if (size & 1) file.seekg(1, std::ios::cur);
	}
	if (!have_fmt || !have_data || format != 1 || channels != 1 || bits != 16 || sample_rate != kSampleRate)
		throw std::runtime_error("source WAV must be mono 16-bit PCM at 44.1 kHz");
	if (data_size % 2) throw std::runtime_error("invalid 16-bit PCM data size");
	file.clear();
	file.seekg(data_pos);
	std::vector<std::int16_t> samples(data_size / 2);
	file.read(reinterpret_cast<char*>(samples.data()), data_size);
	if (!file) throw std::runtime_error("truncated WAV data");
	return samples;
}

std::vector<FrameCycles> load_frame_cycles(const std::string& path) {
	std::ifstream file(path);
	if (!file) throw std::runtime_error("unable to open frame-cycle CSV: " + path);
	std::string line;
	std::getline(file, line); // header
	std::vector<FrameCycles> rows;
	while (std::getline(file, line)) {
		std::stringstream stream(line);
		std::string field;
		std::vector<std::string> columns;
		while (std::getline(stream, field, ',')) columns.push_back(field);
		if (columns.size() < 5) continue;
		const auto cycle_start = std::stoull(columns[2]);
		const auto cycle_end = std::stoull(columns[3]);
		const auto cycle_delta = std::stoull(columns[4]);
		if (cycle_end < cycle_start || cycle_end - cycle_start != cycle_delta)
			throw std::runtime_error("inconsistent frame-cycle row: " + line);
		rows.push_back({std::stoull(columns[0]), cycle_start, cycle_end});
	}
	if (rows.empty()) throw std::runtime_error("frame-cycle CSV contains no rows");
	return rows;
}

std::int32_t wrap_i32(std::int64_t value) {
	return static_cast<std::int32_t>(static_cast<std::uint32_t>(value));
}

void write_u16(std::ostream& out, std::uint16_t value) {
	out.put(static_cast<char>(value & 0xFF));
	out.put(static_cast<char>((value >> 8) & 0xFF));
}

void write_u32(std::ostream& out, std::uint32_t value) {
	for (int shift = 0; shift < 32; shift += 8) out.put(static_cast<char>((value >> shift) & 0xFF));
}

void write_wav_header(std::ostream& out, std::uint32_t sample_count) {
	const std::uint32_t data_bytes = sample_count * 2;
	out.write("RIFF", 4);
	write_u32(out, 36 + data_bytes);
	out.write("WAVEfmt ", 8);
	write_u32(out, 16);
	write_u16(out, 1);
	write_u16(out, 1);
	write_u32(out, kSampleRate);
	write_u32(out, kSampleRate * 2);
	write_u16(out, 2);
	write_u16(out, 16);
	out.write("data", 4);
	write_u32(out, data_bytes);
}

class FceuxSoundq2Port {
public:
	FceuxSoundq2Port()
		: mrindex_((kFirLength + 1) << 16),
		  mrratio_(static_cast<std::uint32_t>(static_cast<std::uint64_t>(kNtscCpuHz * 65536.0) / kSampleRate)) {}

	std::vector<std::int16_t> process_frame(
		const FrameCycles& frame,
		const std::vector<std::int16_t>& source,
		double cycle_scale,
		double phase_offset
	) {
		const std::uint64_t cycles = frame.cycle_end - frame.cycle_start;
		if (cycles == 0) return {};
		if (cycles > 40000) throw std::runtime_error("unexpected per-frame cycle count");

		std::vector<std::int32_t> input;
		input.reserve(history_.size() + cycles);
		input.insert(input.end(), history_.begin(), history_.end());
		const double source_cycle_ratio = 1.0 / cycle_scale;
		const double sample_step = source_cycle_ratio * kSampleRate / kNtscCpuHz;
		double source_sample_position = ((static_cast<double>(frame.cycle_start) - phase_offset) * source_cycle_ratio) * kSampleRate / kNtscCpuHz;
		for (std::uint64_t offset = 0; offset < cycles; ++offset) {
			const long long sample_index = static_cast<long long>(std::floor(source_sample_position));
			std::int32_t sample = 0;
			if (sample_index >= 0 && static_cast<std::size_t>(sample_index) < source.size()) sample = source[static_cast<std::size_t>(sample_index)];
			input.push_back(sample);
			source_sample_position += sample_step;
		}
		return run_filter(input);
	}

	std::vector<std::int16_t> process_wavehi_frame(const std::vector<std::int32_t>& wavehi) {
		std::vector<std::int32_t> input;
		input.reserve(history_.size() + wavehi.size());
		input.insert(input.end(), history_.begin(), history_.end());
		input.insert(input.end(), wavehi.begin(), wavehi.end());
		return run_filter(input);
	}

private:
	std::vector<std::int16_t> run_filter(const std::vector<std::int32_t>& input) {
		const std::uint32_t inlen = static_cast<std::uint32_t>(input.size());
		if (inlen < kFirLength + 1) throw std::runtime_error("input block shorter than FIR history");
		const std::uint32_t max = (inlen - 1) << 16;
		std::uint32_t x = mrindex_;
		std::vector<std::int32_t> filtered;
		filtered.reserve(static_cast<std::size_t>(inlen * kSampleRate / kNtscCpuHz + 8));

		// Port of FCEUX NeoFilterSound() for soundq=2. The coefficient table is
		// mirrored in the generated pinned-source header, as MakeFilters() does.
		for (; x < max; x += mrratio_) {
			std::int32_t acc = 0, acc2 = 0;
			const std::int32_t position = static_cast<std::int32_t>(x >> 16);
			const std::uint32_t fraction = x & 65535;
			for (std::uint32_t tap = 0; tap < kFirLength; ++tap) {
				const std::int32_t coefficient = kFceuxSq2Coefficients[tap];
				const std::int32_t first = input[static_cast<std::size_t>(position - static_cast<std::int32_t>(tap))];
				const std::int32_t second = input[static_cast<std::size_t>(position - static_cast<std::int32_t>(tap) + 1)];
				acc = wrap_i32(static_cast<std::int64_t>(acc) + ((static_cast<std::int64_t>(first) * coefficient) >> 6));
				acc2 = wrap_i32(static_cast<std::int64_t>(acc2) + ((static_cast<std::int64_t>(second) * coefficient) >> 6));
			}
			const std::int64_t interpolated = static_cast<std::int64_t>(acc) * (65536 - fraction) + static_cast<std::int64_t>(acc2) * fraction;
			filtered.push_back(static_cast<std::int32_t>(interpolated >> 27));
		}

		mrindex_ = x - max + (kFirLength << 16);
		history_.assign(input.end() - (kFirLength + 1), input.end());
		return run_sexy_filter(filtered);
	}

	std::vector<std::int16_t> run_sexy_filter(const std::vector<std::int32_t>& input) {
		const std::int32_t mul1 = (94 << 16) / kSampleRate;
		const std::int32_t mul2 = (24 << 16) / kSampleRate;
		std::int32_t vmul = (256 << 16) * 3 / 4 / 100;
		vmul /= 4; // FCEUX soundq >= 1
		std::vector<std::int16_t> output;
		output.reserve(input.size());
		for (std::int32_t sample : input) {
			const std::int64_t ino = static_cast<std::int64_t>(sample) * vmul;
			acc1_ += ((ino - acc1_) * mul1) >> 16;
			acc2_ += ((ino - acc1_ - acc2_) * mul2) >> 16;
			std::int64_t value = (acc1_ - ino + acc2_) >> 16;
			value = std::clamp<std::int64_t>(value, -32768, 32767);
			output.push_back(static_cast<std::int16_t>(value));
		}
		return output;
	}

	std::uint32_t mrindex_;
	std::uint32_t mrratio_;
	std::vector<std::int32_t> history_;
	std::int64_t acc1_ = 0;
	std::int64_t acc2_ = 0;
};
} // namespace

#ifndef FCEUX_FILTER_PIPELINE_NO_MAIN
int main(int argc, char** argv) {
	if (argc != 7) {
		std::fprintf(stderr, "usage: %s source.wav frame_cycles.csv output.wav scale_num scale_den phase_cycles\n", argv[0]);
		return 2;
	}
	try {
		const std::string source_path = argv[1];
		const std::string frame_path = argv[2];
		const std::string output_path = argv[3];
		const std::uint64_t scale_num = std::stoull(argv[4]);
		const std::uint64_t scale_den = std::stoull(argv[5]);
		const double phase_cycles = std::stod(argv[6]);
		if (!scale_num || !scale_den) throw std::runtime_error("invalid cycle scale ratio");
		const double scale = static_cast<double>(scale_num) / scale_den;
		const std::vector<std::int16_t> source = load_pcm_wav(source_path);
		const std::vector<FrameCycles> frames = load_frame_cycles(frame_path);
		FceuxSoundq2Port renderer;
		std::vector<std::int16_t> all_output;
		for (const FrameCycles& frame : frames) {
			auto segment = renderer.process_frame(frame, source, scale, phase_cycles);
			all_output.insert(all_output.end(), segment.begin(), segment.end());
		}
		if (all_output.size() > UINT32_MAX / 2) throw std::runtime_error("WAV output exceeds RIFF size limit");
		std::ofstream out(output_path, std::ios::binary);
		if (!out) throw std::runtime_error("unable to create output WAV");
		write_wav_header(out, static_cast<std::uint32_t>(all_output.size()));
		out.write(reinterpret_cast<const char*>(all_output.data()), all_output.size() * sizeof(std::int16_t));
		if (!out) throw std::runtime_error("failed to write output WAV");
		std::printf("output_samples=%zu\n", all_output.size());
		return 0;
	} catch (const std::exception& error) {
		std::fprintf(stderr, "fceux filter prototype: %s\n", error.what());
		return 1;
	}
}
#endif
