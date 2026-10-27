// Build-only diagnostic reconstruction of the FCEUX 2.7.0 soundq>=1 APU
// WaveHi source from cycle-stamped CPU-bus writes plus measured FCEUX
// instruction-hook frame/DMC events. This is diagnostic output, not a runtime
// asset or a complete emulator core.

#define FCEUX_FILTER_PIPELINE_NO_MAIN
#include "../fceux_filter_prototype/filter_pipeline.cpp"

#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>

namespace {
struct ApuWrite {
	std::uint64_t cycle;
	std::uint16_t address;
	std::uint8_t value;
};

struct DmcFetchEvent {
	std::uint64_t cycle;
	std::uint32_t cpu_address;
	std::uint8_t value;
};

struct DmcStateEvent {
	std::uint64_t cycle;
	std::int32_t accumulator;
	std::int32_t period;
	std::uint8_t bit_count;
	std::uint32_t address;
	std::uint32_t size;
	std::uint8_t shift;
	bool have_dma;
	bool have_sample;
	std::uint8_t dma_buffer;
	std::uint8_t raw_dac;
};

struct DmcDacTransition {
	std::uint64_t cycle;
	std::uint8_t raw_dac;
};

struct DmcTrace {
	std::vector<std::uint64_t> frame_update_cycles;
	std::vector<DmcFetchEvent> fetches;
	std::vector<DmcStateEvent> bit_states;
	std::vector<DmcDacTransition> dac_transitions;
	std::vector<std::uint8_t> source_dac_before;
};

struct ChannelWaveHiTraceRecord {
	std::uint64_t cycle;
	std::int32_t channel[5]; // pulse 1, pulse 2, triangle, noise, DMC
	std::uint32_t raw_wavehi;
};
static_assert(sizeof(ChannelWaveHiTraceRecord) == 32, "unexpected channel WaveHi trace record layout");

DmcTrace load_dmc_trace(const std::string& path, bool include_frame_updates, bool require_dmc_events = true) {
	std::ifstream file(path);
	if (!file) throw std::runtime_error("unable to open FCEUX DMC event trace: " + path);
	std::string line;
	std::getline(file, line); // header
	DmcTrace trace;
	bool pending_pcm_sync = false;
	std::uint64_t pending_hook = 0;
	std::uint64_t pending_cycle = 0;
	std::uint32_t pending_fudge = 0;
	while (std::getline(file, line)) {
		std::stringstream stream(line);
		std::vector<std::string> fields;
		std::string field;
		while (std::getline(stream, field, ',')) fields.push_back(field);
		if (fields.size() < 27) throw std::runtime_error("malformed DMC event trace row: " + line);
		if (fields[1] == "FRAME_UPDATE_IN" && include_frame_updates) {
			trace.frame_update_cycles.push_back(std::stoull(fields[5]));
		} else if (fields[1] == "DMC_DMA_OUT") {
			trace.fetches.push_back({
				std::stoull(fields[5]),
				static_cast<std::uint32_t>(std::stoul(fields[24], nullptr, 16)),
				static_cast<std::uint8_t>(std::stoul(fields[25]))});
		} else if (fields[1] == "DMC_BIT_OUT") {
			const std::uint64_t cycle = std::stoull(fields[5]);
			trace.bit_states.push_back({
				cycle,
				std::stoi(fields[10]),
				std::stoi(fields[11]),
				static_cast<std::uint8_t>(std::stoul(fields[12])),
				static_cast<std::uint32_t>(std::stoul(fields[13], nullptr, 16)),
				static_cast<std::uint32_t>(std::stoul(fields[14])),
				static_cast<std::uint8_t>(std::stoul(fields[15], nullptr, 16)),
				std::stoul(fields[16]) != 0,
				std::stoul(fields[17]) != 0,
				static_cast<std::uint8_t>(std::stoul(fields[18], nullptr, 16)),
				static_cast<std::uint8_t>(std::stoul(fields[19], nullptr, 16))});
			if (pending_pcm_sync) {
				if (std::stoull(fields[2]) != pending_hook || cycle != pending_cycle)
					throw std::runtime_error("PCM_SYNC_IN is not paired with its DMC bit edge in the same FCEUX hook");
				if (pending_cycle < pending_fudge)
					throw std::runtime_error("PCM_SYNC_IN phase correction precedes trace cycle zero");
				trace.dac_transitions.push_back({
					pending_cycle - pending_fudge,
					static_cast<std::uint8_t>(std::stoul(fields[19], nullptr, 16))});
				pending_pcm_sync = false;
			}
		} else if (fields[1] == "PCM_SYNC_IN") {
			if (pending_pcm_sync) throw std::runtime_error("unpaired preceding PCM_SYNC_IN event");
			pending_pcm_sync = true;
			pending_hook = std::stoull(fields[2]);
			pending_cycle = std::stoull(fields[5]);
			pending_fudge = static_cast<std::uint32_t>(std::stoul(fields[26]));
		}
	}
	if (pending_pcm_sync) throw std::runtime_error("trace ends with an unpaired PCM_SYNC_IN event");
	for (std::size_t i = 1; i < trace.fetches.size(); ++i) {
		if (trace.fetches[i].cycle < trace.fetches[i - 1].cycle) throw std::runtime_error("DMC fetch trace is not cycle sorted");
	}
	for (std::size_t i = 1; i < trace.frame_update_cycles.size(); ++i) {
		if (trace.frame_update_cycles[i] < trace.frame_update_cycles[i - 1]) throw std::runtime_error("frame-sequencer trace is not cycle sorted");
	}
	for (std::size_t i = 1; i < trace.bit_states.size(); ++i) {
		if (trace.bit_states[i].cycle < trace.bit_states[i - 1].cycle) throw std::runtime_error("DMC bit-state trace is not cycle sorted");
	}
	for (std::size_t i = 1; i < trace.dac_transitions.size(); ++i) {
		if (trace.dac_transitions[i].cycle < trace.dac_transitions[i - 1].cycle) throw std::runtime_error("PCM-corrected DMC DAC transitions are not cycle sorted");
	}
	if ((include_frame_updates && trace.frame_update_cycles.empty()) || (require_dmc_events
			&& (trace.fetches.empty() || trace.bit_states.empty() || trace.dac_transitions.empty())))
		throw std::runtime_error("trace needs DMC fetch, bit-state, and PCM_SYNC_IN events, plus frame events unless source-clocked");
	return trace;
}

std::uint16_t parse_hex16(const std::string& text) {
	if (text.size() < 2 || text[0] != '$') throw std::runtime_error("expected $hex APU address: " + text);
	return static_cast<std::uint16_t>(std::stoul(text.substr(1), nullptr, 16));
}

std::uint8_t parse_hex8(const std::string& text) {
	if (text.size() < 2 || text[0] != '$') throw std::runtime_error("expected $hex APU value: " + text);
	return static_cast<std::uint8_t>(std::stoul(text.substr(1), nullptr, 16));
}

std::vector<std::uint64_t> load_source_frame_update_events(const std::string& path) {
	std::ifstream file(path);
	if (!file) throw std::runtime_error("unable to open ROM-stepper frame-update events: " + path);
	std::string line;
	if (!std::getline(file, line)) throw std::runtime_error("ROM-stepper frame-update event file is empty");
	if (!line.empty() && line.back() == '\r') line.pop_back();
	std::vector<std::string> header;
	{
		std::stringstream stream(line);
		std::string field;
		while (std::getline(stream, field, ',')) header.push_back(field);
	}
	std::size_t source_frame_column = header.size();
	std::size_t cycle_column = header.size();
	for (std::size_t i = 0; i < header.size(); ++i) {
		if (header[i] == "source_frame") source_frame_column = i;
		if (header[i] == "cycle") cycle_column = i;
	}
	if (source_frame_column == header.size() || cycle_column == header.size())
		throw std::runtime_error("ROM-stepper frame-update CSV needs source_frame and cycle columns");
	std::vector<std::uint64_t> events;
	std::uint64_t previous_cycle = 0;
	std::uint64_t previous_frame = 0;
	while (std::getline(file, line)) {
		if (!line.empty() && line.back() == '\r') line.pop_back();
		std::stringstream stream(line);
		std::vector<std::string> fields;
		std::string field;
		while (std::getline(stream, field, ',')) fields.push_back(field);
		if (fields.size() < header.size()) throw std::runtime_error("malformed ROM-stepper frame-update row: " + line);
		const std::uint64_t frame = std::stoull(fields[source_frame_column]);
		const std::uint64_t cycle = std::stoull(fields[cycle_column]);
		if (!events.empty() && (cycle <= previous_cycle || frame < previous_frame))
			throw std::runtime_error("ROM-stepper frame-update events are not strictly ordered");
		events.push_back(cycle);
		previous_cycle = cycle;
		previous_frame = frame;
	}
	if (events.empty()) throw std::runtime_error("ROM-stepper frame-update event file contains no events");
	return events;
}

DmcTrace load_source_nsf_dmc_callbacks(const std::string& path) {
	std::ifstream file(path);
	if (!file) throw std::runtime_error("unable to open source NSF DMC callback trace: " + path);
	std::string line;
	std::getline(file, line);
	DmcTrace trace;
	while (std::getline(file, line)) {
		std::stringstream stream(line);
		std::array<std::string, 5> fields;
		for (std::string& field : fields) {
			if (!std::getline(stream, field, ',')) throw std::runtime_error("malformed source NSF DMC callback row: " + line);
		}
		trace.fetches.push_back({std::stoull(fields[1]), parse_hex16(fields[3]), parse_hex8(fields[4])});
	}
	for (std::size_t i = 1; i < trace.fetches.size(); ++i) {
		if (trace.fetches[i].cycle < trace.fetches[i - 1].cycle)
			throw std::runtime_error("source NSF DMC callbacks are not cycle sorted");
	}
	if (trace.fetches.empty()) throw std::runtime_error("source NSF DMC callback trace is empty");
	return trace;
}

DmcTrace load_source_stepper_dmc_reads(const std::string& path) {
	std::ifstream file(path);
	if (!file) throw std::runtime_error("unable to open ROM-stepper DMC read stream: " + path);
	std::string line;
	if (!std::getline(file, line)) throw std::runtime_error("ROM-stepper DMC read stream is empty");
	if (!line.empty() && line.back() == '\r') line.pop_back();
	if (line != "source_frame,cycle,address,value,index")
		throw std::runtime_error("unexpected ROM-stepper DMC read header");
	DmcTrace trace;
	std::uint64_t group_frame = 0;
	std::uint64_t group_cycle = 0;
	std::uint32_t group_address = 0;
	std::uint8_t group_value = 0;
	std::uint64_t expected_index = 0;
	while (std::getline(file, line)) {
		if (!line.empty() && line.back() == '\r') line.pop_back();
		if (line.empty()) continue;
		std::stringstream stream(line);
		std::array<std::string, 5> fields;
		for (std::string& field : fields) {
			if (!std::getline(stream, field, ',')) throw std::runtime_error("malformed ROM-stepper DMC read row: " + line);
		}
		if (stream.rdbuf()->in_avail() != 0) throw std::runtime_error("extra fields in ROM-stepper DMC read row: " + line);
		const std::uint64_t frame = std::stoull(fields[0]);
		const std::uint64_t cycle = std::stoull(fields[1]);
		const std::uint32_t address = parse_hex16(fields[2]);
		const std::uint8_t value = parse_hex8(fields[3]);
		const std::uint64_t index = std::stoull(fields[4]);
		if (index != expected_index) throw std::runtime_error("ROM-stepper DMC read indices are not contiguous from zero");
		const unsigned phase = static_cast<unsigned>(index & 3);
		if (phase == 0) {
			group_frame = frame;
			group_cycle = cycle;
			group_address = address;
			group_value = value;
		} else if (frame != group_frame || cycle != group_cycle + phase || address != group_address || value != group_value) {
			throw std::runtime_error("ROM-stepper DMC four-cycle read group is internally inconsistent at row " + std::to_string(index));
		}
		if (phase == 3) {
			if (address < 0xc000 || address >= 0xe000)
				throw std::runtime_error("ROM-stepper DMC read left mapped bank-$1E window");
			trace.fetches.push_back({cycle, address, value});
		}
		++expected_index;
	}
	if ((expected_index & 3) != 0) throw std::runtime_error("ROM-stepper DMC input ends inside a four-cycle read group");
	for (std::size_t i = 1; i < trace.fetches.size(); ++i) {
		if (trace.fetches[i].cycle <= trace.fetches[i - 1].cycle)
			throw std::runtime_error("ROM-stepper accepted DMC byte reads are not strictly cycle sorted");
	}
	if (trace.fetches.empty()) throw std::runtime_error("ROM-stepper DMC read stream has no completed output-byte reads");
	return trace;
}

DmcTrace load_source_dmc_dac_edges(const std::string& path) {
	std::ifstream file(path);
	if (!file) throw std::runtime_error("unable to open source DMC DAC-edge schedule: " + path);
	std::string line;
	if (!std::getline(file, line)) throw std::runtime_error("source DMC DAC-edge schedule is empty");
	if (!line.empty() && line.back() == '\r') line.pop_back();
	if (line != "source_frame,cycle,raw_dac_before,raw_dac")
		throw std::runtime_error("unexpected source DMC DAC-edge header");
	DmcTrace trace;
	while (std::getline(file, line)) {
		if (!line.empty() && line.back() == '\r') line.pop_back();
		if (line.empty()) continue;
		std::stringstream stream(line);
		std::array<std::string, 4> fields;
		for (std::string& field : fields) {
			if (!std::getline(stream, field, ',')) throw std::runtime_error("malformed source DMC DAC-edge row: " + line);
		}
		if (stream.rdbuf()->in_avail() != 0) throw std::runtime_error("extra fields in source DMC DAC-edge row: " + line);
		const std::uint64_t cycle = std::stoull(fields[1]);
		const std::uint8_t before = static_cast<std::uint8_t>(std::stoul(fields[2]));
		const std::uint8_t after = static_cast<std::uint8_t>(std::stoul(fields[3]));
		if (before > 127 || after > 127 || before == after)
			throw std::runtime_error("invalid source DMC DAC transition at cycle " + std::to_string(cycle));
		trace.dac_transitions.push_back({cycle, after});
		trace.source_dac_before.push_back(before);
	}
	for (std::size_t i = 1; i < trace.dac_transitions.size(); ++i) {
		if (trace.dac_transitions[i].cycle <= trace.dac_transitions[i - 1].cycle)
			throw std::runtime_error("source DMC DAC edges are not strictly cycle sorted");
	}
	if (trace.dac_transitions.empty()) throw std::runtime_error("source DMC DAC-edge schedule contains no transitions");
	return trace;
}

DmcTrace load_source_dmc_state_events(const std::string& path) {
	std::ifstream file(path);
	if (!file) throw std::runtime_error("unable to open source DMC state-event schedule: " + path);
	std::string line;
	if (!std::getline(file, line)) throw std::runtime_error("source DMC state-event schedule is empty");
	if (!line.empty() && line.back() == '\r') line.pop_back();
	if (line != "sequence,source_frame,cycle,accumulator,period,bit_count,address,size,shift,have_dma,have_sample,dma_buffer,raw_dac")
		throw std::runtime_error("unexpected source DMC state-event header");
	DmcTrace trace;
	while (std::getline(file, line)) {
		if (!line.empty() && line.back() == '\r') line.pop_back();
		if (line.empty()) continue;
		std::stringstream stream(line);
		std::array<std::string, 13> fields;
		for (std::string& field : fields) {
			if (!std::getline(stream, field, ',')) throw std::runtime_error("malformed source DMC state-event row: " + line);
		}
		if (stream.rdbuf()->in_avail() != 0) throw std::runtime_error("extra fields in source DMC state-event row: " + line);
		trace.bit_states.push_back({
			std::stoull(fields[2]), std::stoi(fields[3]), std::stoi(fields[4]),
			static_cast<std::uint8_t>(std::stoul(fields[5])),
			static_cast<std::uint32_t>(std::stoul(fields[6])),
			static_cast<std::uint32_t>(std::stoul(fields[7])),
			static_cast<std::uint8_t>(std::stoul(fields[8])),
			std::stoul(fields[9]) != 0, std::stoul(fields[10]) != 0,
			static_cast<std::uint8_t>(std::stoul(fields[11])),
			static_cast<std::uint8_t>(std::stoul(fields[12]))});
	}
	for (std::size_t i = 1; i < trace.bit_states.size(); ++i) {
		if (trace.bit_states[i].cycle < trace.bit_states[i - 1].cycle)
			throw std::runtime_error("source DMC state events are not cycle sorted");
	}
	if (trace.bit_states.empty()) throw std::runtime_error("source DMC state-event schedule contains no state changes");
	return trace;
}

std::vector<ApuWrite> load_apu_writes(const std::string& path) {
	std::ifstream file(path);
	if (!file) throw std::runtime_error("unable to open APU write trace: " + path);
	std::string line;
	std::getline(file, line);
	std::vector<ApuWrite> writes;
	while (std::getline(file, line)) {
		std::stringstream stream(line);
		std::array<std::string, 7> fields;
		for (std::string& field : fields) {
			if (!std::getline(stream, field, ',')) throw std::runtime_error("malformed APU trace row: " + line);
		}
		const std::uint16_t address = parse_hex16(fields[5]);
		if (!((address >= 0x4000 && address <= 0x4013) || address == 0x4015 || address == 0x4017)) continue;
		writes.push_back({std::stoull(fields[3]), address, parse_hex8(fields[6])});
	}
	for (std::size_t i = 1; i < writes.size(); ++i) {
		if (writes[i].cycle < writes[i - 1].cycle) throw std::runtime_error("APU write trace is not cycle sorted");
	}
	return writes;
}

std::vector<std::uint8_t> load_prg_bank_1e(const std::string& path) {
	std::ifstream file(path, std::ios::binary);
	if (!file) throw std::runtime_error("unable to open supplied ROM for read-only DMC lookup: " + path);
	std::vector<std::uint8_t> rom((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
	if (rom.size() < 16 || rom[0] != 'N' || rom[1] != 'E' || rom[2] != 'S' || rom[3] != 0x1a)
		throw std::runtime_error("supplied source is not an iNES ROM");
	const std::size_t trainer_bytes = (rom[6] & 0x04) ? 512 : 0;
	const std::size_t prg_start = 16 + trainer_bytes;
	const std::size_t bank_start = prg_start + 0x1e * 0x2000;
	if (bank_start + 0x2000 > rom.size()) throw std::runtime_error("ROM does not contain complete physical PRG bank $1E");
	return std::vector<std::uint8_t>(rom.begin() + bank_start, rom.begin() + bank_start + 0x2000);
}

class FceuxApuWaveHi {
public:
	FceuxApuWaveHi(std::vector<std::uint8_t> dmc_prg_bank, DmcTrace dmc_trace,
			bool source_frame_sequencer, bool source_dmc_engine = false,
			const std::string& source_dmc_fetch_output = "", bool source_dmc_callback_mode = false,
			bool source_dmc_read_replay_mode = false, bool source_dmc_dac_edge_mode = false,
			bool source_dmc_state_replay_mode = false, const std::string& channel_trace_output = "",
			std::uint64_t channel_trace_start = 0, std::uint64_t channel_trace_end = 0,
			const std::string& triangle_trace_output = "", std::uint64_t triangle_trace_start = 0,
			std::uint64_t triangle_trace_end = 0)
		: dmc_prg_bank_(std::move(dmc_prg_bank)), frame_update_cycles_(std::move(dmc_trace.frame_update_cycles)),
		  dmc_fetches_(std::move(dmc_trace.fetches)),
		  dmc_bit_states_(std::move(dmc_trace.bit_states)),
		  dac_transitions_(std::move(dmc_trace.dac_transitions)),
		  source_dac_before_(std::move(dmc_trace.source_dac_before)),
	  source_frame_sequencer_(source_frame_sequencer), source_dmc_engine_(source_dmc_engine),
		  source_dmc_callback_mode_(source_dmc_callback_mode), source_dmc_read_replay_mode_(source_dmc_read_replay_mode),
		  source_dmc_dac_edge_mode_(source_dmc_dac_edge_mode), source_dmc_state_replay_mode_(source_dmc_state_replay_mode) {
		if (dmc_prg_bank_.size() != 0x2000) throw std::runtime_error("DMC source bank must be exactly 8 KiB");
		for (int x = 1; x < 32; ++x) {
			wlookup1_[x] = static_cast<std::uint32_t>(16.0 * 16 * 16 * 4 * 95.52 / (8128.0 / x + 100));
		}
		for (int x = 1; x < 203; ++x) {
			wlookup2_[x] = static_cast<std::uint32_t>(16.0 * 16 * 16 * 4 * 163.67 / (24329.0 / x + 100));
		}
		fhinc_ = 14915 * 24;
		fhcnt_ = fhinc_;
		for (int channel = 0; channel < 2; ++channel) square_period_count_[channel] = 2048;
		triangle_period_count_ = 1;
		noise_period_count_ = 2048;
		noise_lfsr_ = 1;
		if (!source_dmc_fetch_output.empty()) {
			source_dmc_fetch_stream_.open(source_dmc_fetch_output);
			if (!source_dmc_fetch_stream_) throw std::runtime_error("unable to open source-mode DMC fetch output");
			source_dmc_fetch_stream_ << "sequence,source_cpu_cycle,cpu_address,value,rom_bank,rom_offset\n";
		}
		if (!channel_trace_output.empty()) {
			if (channel_trace_end <= channel_trace_start)
				throw std::runtime_error("source channel WaveHi trace needs a valid half-open cycle window");
			channel_trace_stream_.open(channel_trace_output, std::ios::binary);
			if (!channel_trace_stream_) throw std::runtime_error("unable to open source channel WaveHi trace output");
			channel_trace_start_ = channel_trace_start;
			channel_trace_end_ = channel_trace_end;
		}
		if (!triangle_trace_output.empty()) {
			if (triangle_trace_end <= triangle_trace_start)
				throw std::runtime_error("source triangle state trace needs a valid half-open cycle window");
			triangle_trace_stream_.open(triangle_trace_output);
			if (!triangle_trace_stream_) throw std::runtime_error("unable to open source triangle state trace output");
			triangle_trace_start_ = triangle_trace_start;
			triangle_trace_end_ = triangle_trace_end;
			triangle_trace_stream_ << "sequence,cycle,event,step_before,step_after,timer_before,timer_after,length_count,linear_count,active,control,period_low,period_high\n";
		}
	}

	void begin_frame(std::uint64_t cycle_start, std::uint64_t cycle_end) {
		if (cycle_end < cycle_start) throw std::runtime_error("reversed FCEUX frame-cycle range");
		frame_cycle_start_ = cycle_start;
		const std::uint64_t length = cycle_end - cycle_start;
		if (length > 40000) throw std::runtime_error("unexpected per-frame WaveHi source length");
		packed_wavehi_.assign(static_cast<std::size_t>(length), 0);
		for (auto& channel : raw_channel_wavehi_) channel.assign(static_cast<std::size_t>(length), 0);
		channel_bc_.fill(0);
	}

	void write(std::uint16_t address, std::uint8_t value, std::uint64_t cpu_cycle) {
		const std::uint32_t source_position = source_position_for(cpu_cycle);
		if (address >= 0x4000 && address <= 0x400f) {
			const std::uint8_t reg = address & 0x1f;
			flush_channel_for_psg_write(reg, source_position);
			switch (reg) {
			case 0x0: case 0x4: {
				const int channel = reg == 0x0 ? 0 : 1;
				const int env = channel;
				envelopes_[env].mode = (value & 0x30) >> 4;
				envelopes_[env].speed = value & 0x0f;
				break;
			}
			case 0x1: case 0x5: {
				const int channel = reg == 0x1 ? 0 : 1;
				sweep_on_[channel] = value & 0x80;
				sweep_reload_[channel] = true;
				break;
			}
			case 0x2: case 0x6: {
				const int channel = reg == 0x2 ? 0 : 1;
				frequency_[channel] = (frequency_[channel] & 0xff00) | value;
				break;
			}
			case 0x3: case 0x7: {
				const int channel = reg == 0x3 ? 0 : 1;
				if (enabled_ & (1 << channel)) length_[channel] = kLengthTable[(value >> 3) & 0x1f];
				frequency_[channel] = (frequency_[channel] & 0xff) | ((value & 7) << 8);
				duty_count_[channel] = 7;
				envelopes_[channel].reload = true;
				break;
			}
			case 0x8: break;
			case 0xa: break;
			case 0xb:
				if (enabled_ & 0x04) length_[2] = kLengthTable[(value >> 3) & 0x1f];
				triangle_mode_ = true;
				break;
			case 0xc:
				envelopes_[2].mode = (value & 0x30) >> 4;
				envelopes_[2].speed = value & 0x0f;
				break;
			case 0xe: break;
			case 0xf:
				if (enabled_ & 0x08) length_[3] = kLengthTable[(value >> 3) & 0x1f];
				envelopes_[2].reload = true;
				break;
			}
			psg_[reg] = value;
			return;
		}

		switch (address) {
		case 0x4010:
			flush_channel(4, source_position);
			dmc_format_ = value;
			break;
		case 0x4011:
			flush_channel(4, source_position);
			raw_dac_ = value & 0x7f;
			break;
		case 0x4012:
			dmc_address_latch_ = value;
			break;
		case 0x4013:
			dmc_size_latch_ = value;
			break;
		case 0x4015:
			flush_all_channels(source_position);
			for (int channel = 0; channel < 4; ++channel) if (!(value & (1 << channel))) length_[channel] = 0;
			if (value & 0x10) {
				if (!dmc_size_) {
					dmc_address_ = 0x4000 + (static_cast<std::uint32_t>(dmc_address_latch_) << 6);
					dmc_size_ = (static_cast<std::uint32_t>(dmc_size_latch_) << 4) + 1;
				}
			} else {
				dmc_size_ = 0;
			}
			enabled_ = value & 0x1f;
			break;
		case 0x4017: {
			const std::uint8_t mode = (value & 0xc0) >> 6;
			fcnt_ = 0;
			if (mode & 0x2) frame_sound_update(source_position, cpu_cycle);
			fcnt_ = 1;
			fhcnt_ = fhinc_;
			irq_frame_mode_ = mode;
			break;
		}
		}
	}

	std::vector<std::int32_t> finish_frame(std::uint64_t cycle_end) {
		const std::uint32_t source_end = source_position_for(cycle_end);
		flush_all_channels(source_end);
		write_channel_trace();
		std::vector<std::int32_t> mixed_wavehi(packed_wavehi_.size());
		for (std::size_t i = 0; i < packed_wavehi_.size(); ++i) {
			const std::uint32_t packed = packed_wavehi_[i];
			const std::uint32_t pulse_index = packed >> 24;
			const std::uint32_t tnd_index = (packed >> 16) & 0xff;
			mixed_wavehi[i] = static_cast<std::int32_t>((packed & 0xffff) + wlookup2_[tnd_index] + wlookup1_[pulse_index]);
		}
		return mixed_wavehi;
	}

	void process_trace_events(std::uint64_t cpu_cycle) {
		const std::uint32_t source_position = source_position_for(cpu_cycle);
		if (source_frame_sequencer_) {
			if (cpu_cycle < source_frame_clock_cycle_)
				throw std::runtime_error("source frame-sequencer clock moved backwards");
			const std::uint64_t elapsed = cpu_cycle - source_frame_clock_cycle_;
			if (elapsed) {
				fhcnt_ -= static_cast<std::int32_t>(elapsed * 48);
				source_frame_clock_cycle_ = cpu_cycle;
				if (fhcnt_ <= 0) {
					frame_sound_update(source_position, cpu_cycle);
					fhcnt_ += fhinc_;
					++source_frame_updates_;
				}
			}
		} else if (next_frame_update_ < frame_update_cycles_.size()
				&& frame_update_cycles_[next_frame_update_] < cpu_cycle) {
			throw std::runtime_error("missed a timestamped FCEUX frame-sequencer update");
		}
		if (next_dmc_fetch_ < dmc_fetches_.size() && dmc_fetches_[next_dmc_fetch_].cycle < cpu_cycle)
			throw std::runtime_error("missed a timestamped FCEUX DMC sample-byte fetch");
		if (next_dmc_bit_state_ < dmc_bit_states_.size() && dmc_bit_states_[next_dmc_bit_state_].cycle < cpu_cycle)
			throw std::runtime_error("missed FCEUX DMC bit-state cycle " + std::to_string(dmc_bit_states_[next_dmc_bit_state_].cycle) + " at renderer cycle " + std::to_string(cpu_cycle));
		if (!source_frame_sequencer_) {
			while (next_frame_update_ < frame_update_cycles_.size() && frame_update_cycles_[next_frame_update_] == cpu_cycle) {
				frame_sound_update(source_position, cpu_cycle);
				++next_frame_update_;
			}
		}
		if (source_dmc_engine_) {
			clock_source_dmc(cpu_cycle);
			return;
		}
		process_dac_transitions(cpu_cycle, source_position);
		while (next_dmc_fetch_ < dmc_fetches_.size() && dmc_fetches_[next_dmc_fetch_].cycle == cpu_cycle) {
			clock_dmc_dma(dmc_fetches_[next_dmc_fetch_]);
			++next_dmc_fetch_;
		}
		while (next_dmc_bit_state_ < dmc_bit_states_.size() && dmc_bit_states_[next_dmc_bit_state_].cycle == cpu_cycle) {
			apply_dmc_bit_state(dmc_bit_states_[next_dmc_bit_state_]);
			++next_dmc_bit_state_;
		}
	}

	std::uint64_t dmc_bytes_read() const { return dmc_bytes_read_; }
	std::uint64_t frame_updates_consumed() const { return source_frame_sequencer_ ? source_frame_updates_ : next_frame_update_; }
	std::uint64_t frame_updates_total() const { return source_frame_sequencer_ ? source_frame_updates_ : frame_update_cycles_.size(); }
	std::uint64_t dmc_fetch_events_consumed() const { return source_dmc_callback_mode_ ? next_dmc_fetch_ : (source_dmc_engine_ ? source_dmc_fetches_ : next_dmc_fetch_); }
	std::uint64_t dmc_fetch_events_total() const { return (source_dmc_callback_mode_ || source_dmc_read_replay_mode_) ? dmc_fetches_.size() : (source_dmc_engine_ ? source_dmc_fetches_ : dmc_fetches_.size()); }
	std::uint64_t dmc_bit_states_consumed() const { return source_dmc_state_replay_mode_ ? next_dmc_bit_state_ : (source_dmc_engine_ ? source_dmc_bit_edges_ : next_dmc_bit_state_); }
	std::uint64_t dmc_bit_states_total() const { return source_dmc_state_replay_mode_ ? dmc_bit_states_.size() : (source_dmc_engine_ ? source_dmc_bit_edges_ : dmc_bit_states_.size()); }
	std::uint64_t dmc_dac_transitions_consumed() const { return source_dmc_dac_edge_mode_ ? next_dac_transition_ : (source_dmc_engine_ ? source_dmc_dac_edges_ : next_dac_transition_); }
	std::uint64_t dmc_dac_transitions_total() const { return source_dmc_dac_edge_mode_ ? dac_transitions_.size() : (source_dmc_engine_ ? source_dmc_dac_edges_ : dac_transitions_.size()); }
	std::uint64_t channel_trace_rows() const { return channel_trace_rows_; }
	std::uint64_t first_dmc_source_offset() const { return first_dmc_source_offset_; }
	std::uint64_t source_dmc_callback_address_mismatches() const { return source_dmc_callback_address_mismatches_; }
	std::uint64_t source_dmc_buffer_overruns() const { return source_dmc_buffer_overruns_; }
	const std::vector<std::uint64_t>& source_dmc_buffer_overrun_cycles() const { return source_dmc_buffer_overrun_cycles_; }
	std::uint64_t source_dmc_dac_before_mismatches() const { return source_dmc_dac_before_mismatches_; }

private:
	std::uint32_t source_position_for(std::uint64_t cpu_cycle) const {
		if (cpu_cycle < frame_cycle_start_)
			throw std::runtime_error("FCEUX audio event precedes the current frame-cycle window");
		const std::uint64_t position = cpu_cycle - frame_cycle_start_;
		if (position > packed_wavehi_.size())
			throw std::runtime_error("FCEUX audio event exceeds the current frame-cycle window");
		return static_cast<std::uint32_t>(position);
	}

	void flush_channel_for_psg_write(std::uint8_t reg, std::uint32_t source_position) {
		if (reg <= 0x03) flush_channel(0, source_position);
		else if (reg >= 0x04 && reg <= 0x07) flush_channel(1, source_position);
		else if (reg == 0x0a || reg == 0x0b) flush_channel(2, source_position);
		else if (reg == 0x0c || reg == 0x0e || reg == 0x0f) flush_channel(3, source_position);
	}

	void flush_frame_sound_channels(std::uint32_t source_position) {
		// FrameSoundStuff calls DoSQ1, DoSQ2, DoNoise, and DoTriangle before
		// changing length, sweep, envelope, or linear-counter state. DMC PCM is
		// not flushed by this routine.
		flush_channel(0, source_position);
		flush_channel(1, source_position);
		flush_channel(3, source_position);
		flush_channel(2, source_position);
	}

	void flush_all_channels(std::uint32_t source_position) {
		flush_channel(0, source_position);
		flush_channel(1, source_position);
		flush_channel(2, source_position);
		flush_channel(3, source_position);
		flush_channel(4, source_position);
	}

	void flush_channel(int channel, std::uint32_t target) {
		if (target > packed_wavehi_.size()) throw std::runtime_error("WaveHi channel flush exceeds current frame buffer");
		if (target < channel_bc_[channel]) throw std::runtime_error("WaveHi channel flush moved ChannelBC backwards");
		std::uint32_t position = channel_bc_[channel];
		if (channel == 0 || channel == 1) {
			const int frequency = frequency_[channel];
			if (frequency >= 8 && frequency <= 0x7ff && check_frequency(channel) && length_[channel]) {
				int amp = (envelopes_[channel].mode & 1) ? envelopes_[channel].speed : envelopes_[channel].dec_volume;
				const std::uint32_t packed_amp = static_cast<std::uint32_t>(amp) << 24;
				const int duty_threshold = kRectDuties[(psg_[channel * 4] & 0xc0) >> 6];
				const int period = (frequency + 1) * 2;
				while (position < target) {
					if (duty_count_[channel] < duty_threshold) {
						packed_wavehi_[position] += packed_amp;
						raw_channel_wavehi_[channel][position] += static_cast<std::int32_t>(packed_amp);
					}
					if (--square_period_count_[channel] == 0) {
						square_period_count_[channel] = period;
						duty_count_[channel] = (duty_count_[channel] + 1) & 7;
					}
					++position;
				}
			}
		} else if (channel == 2) {
			const bool active = length_[2] && triangle_count_;
			write_triangle_state("flush", frame_cycle_start_ + position, triangle_step_, triangle_step_,
				triangle_period_count_, triangle_period_count_, active);
			while (position < target) {
				const std::uint64_t cycle = frame_cycle_start_ + position;
				const int step_before = triangle_step_;
				const int timer_before = triangle_period_count_;
				const std::uint32_t contribution = static_cast<std::uint32_t>(triangle_output_level()) << 16;
				packed_wavehi_[position] += contribution;
				raw_channel_wavehi_[2][position] += static_cast<std::int32_t>(contribution);
				if (active && --triangle_period_count_ == 0) {
					triangle_period_count_ = (psg_[0x0a] | ((psg_[0x0b] & 7) << 8)) + 1;
					triangle_step_ = (triangle_step_ + 1) & 0x1f;
					write_triangle_state("step", cycle, step_before, triangle_step_, timer_before,
						triangle_period_count_, active);
				}
				++position;
			}
		} else if (channel == 3) {
			int amp = (envelopes_[2].mode & 1) ? envelopes_[2].speed : envelopes_[2].dec_volume;
			const std::uint32_t active_level = static_cast<std::uint32_t>(amp * 2) << 16;
			std::uint32_t output = length_[3] && ((noise_lfsr_ >> 14) & 1) == 0 ? active_level : 0;
			const int feedback_shift = (psg_[0x0e] & 0x80) ? 8 : 13;
			while (position < target) {
				packed_wavehi_[position] += output;
				raw_channel_wavehi_[3][position] += static_cast<std::int32_t>(output);
				if (--noise_period_count_ == 0) {
					noise_period_count_ = kNoisePeriods[psg_[0x0e] & 0x0f];
					const std::uint16_t feedback = ((noise_lfsr_ >> feedback_shift) ^ (noise_lfsr_ >> 14)) & 1;
					noise_lfsr_ = ((noise_lfsr_ << 1) + feedback) & 0x7fff;
					output = length_[3] && ((noise_lfsr_ >> 14) & 1) == 0 ? active_level : 0;
				}
				++position;
			}
		} else if (channel == 4) {
			const std::uint32_t packed_amp = static_cast<std::uint32_t>(raw_dac_) << 16;
			while (position < target) {
				packed_wavehi_[position] += packed_amp;
				raw_channel_wavehi_[4][position] += static_cast<std::int32_t>(packed_amp);
				++position;
			}
		}
		channel_bc_[channel] = target;
	}

	void write_channel_trace() {
		if (!channel_trace_stream_.is_open()) return;
		for (std::size_t position = 0; position < packed_wavehi_.size(); ++position) {
			const std::uint64_t cycle = frame_cycle_start_ + position;
			if (cycle < channel_trace_start_ || cycle >= channel_trace_end_) continue;
			ChannelWaveHiTraceRecord record{};
			record.cycle = cycle;
			for (std::size_t channel = 0; channel < raw_channel_wavehi_.size(); ++channel)
				record.channel[channel] = raw_channel_wavehi_[channel][position];
			record.raw_wavehi = packed_wavehi_[position];
			channel_trace_stream_.write(reinterpret_cast<const char*>(&record), sizeof(record));
			if (!channel_trace_stream_) throw std::runtime_error("failed to write source channel WaveHi trace record");
			++channel_trace_rows_;
		}
	}

	void write_triangle_state(const char* event, std::uint64_t cycle, int step_before, int step_after,
			int timer_before, int timer_after, bool active) {
		if (!triangle_trace_stream_.is_open() || cycle < triangle_trace_start_ || cycle >= triangle_trace_end_) return;
		triangle_trace_stream_ << triangle_trace_rows_++ << ',' << cycle << ',' << event << ','
			<< step_before << ',' << step_after << ',' << timer_before << ',' << timer_after << ','
			<< length_[2] << ',' << triangle_count_ << ',' << (active ? 1 : 0) << ','
			<< static_cast<int>(psg_[0x08]) << ',' << static_cast<int>(psg_[0x0a]) << ','
			<< static_cast<int>(psg_[0x0b]) << '\n';
	}

	struct Envelope {
		std::uint8_t mode = 0;
		std::uint8_t speed = 0;
		std::uint8_t dec_volume = 0;
		std::uint8_t dec_count_to1 = 0;
		bool reload = false;
	};

	static constexpr std::array<int, 4> kRectDuties = {1, 2, 4, 6};
	static constexpr std::array<std::uint8_t, 32> kLengthTable = {
		10,254,20,2,40,4,80,6,160,8,60,10,14,12,26,14,
		12,16,24,18,48,20,96,22,192,24,72,26,16,28,32,30
	};
	static constexpr std::array<std::uint32_t, 16> kNoisePeriods = {
		4,8,16,32,64,96,128,160,202,254,380,508,762,1016,2034,4068
	};
	static constexpr std::array<std::uint32_t, 16> kDmcPeriods = {
		428,380,340,320,286,254,226,214,190,160,142,128,106,84,72,54
	};

	bool check_frequency(int channel) const {
		const std::uint32_t frequency = frequency_[channel];
		const std::uint8_t sweep = psg_[(channel << 2) | 1];
		if (!(sweep & 0x8)) {
			const std::uint32_t modifier = frequency >> (sweep & 7);
			if ((modifier + frequency) & 0x800) return false;
		}
		return true;
	}
	bool square_is_active(int channel) const {
		return frequency_[channel] >= 8 && frequency_[channel] <= 0x7ff &&
			check_frequency(channel) && length_[channel] != 0;
	}

	void clock_squares() {
		for (int channel = 0; channel < 2; ++channel) {
			if (!square_is_active(channel)) continue;
			if (--square_period_count_[channel] == 0) {
				square_period_count_[channel] = (frequency_[channel] + 1) * 2;
				duty_count_[channel] = (duty_count_[channel] + 1) & 7;
			}
		}
	}

	int triangle_output_level() const {
		int count = triangle_step_ & 0x0f;
		if (!(triangle_step_ & 0x10)) count ^= 0x0f;
		return count * 3;
	}

	void clock_triangle() {
		if (!length_[2] || !triangle_count_) return;
		if (--triangle_period_count_ == 0) {
			triangle_period_count_ = (psg_[0x0a] | ((psg_[0x0b] & 7) << 8)) + 1;
			triangle_step_ = (triangle_step_ + 1) & 0x1f;
		}
	}

	void clock_noise() {
		if (--noise_period_count_ == 0) {
			noise_period_count_ = kNoisePeriods[psg_[0x0e] & 0x0f];
			const int tap = (psg_[0x0e] & 0x80) ? 8 : 13;
			const std::uint16_t feedback = ((noise_lfsr_ >> tap) ^ (noise_lfsr_ >> 14)) & 1;
			noise_lfsr_ = ((noise_lfsr_ << 1) + feedback) & 0x7fff;
		}
	}

	void clock_dmc_dma(const DmcFetchEvent& event) {
		if (!dmc_size_ || dmc_have_dma_)
			throw std::runtime_error("FCEUX trace fetch conflicts with reconstructed DMC state at cycle " + std::to_string(event.cycle) + " (size=" + std::to_string(dmc_size_) + ", have_dma=" + std::to_string(dmc_have_dma_) + ", address=" + std::to_string(dmc_address_) + ")");
		const std::uint32_t cpu_address = 0x8000 + dmc_address_;
		if (cpu_address != event.cpu_address)
			throw std::runtime_error("FCEUX DMC fetch address disagrees with ROM-derived DMC register state");
		if (cpu_address < 0xc000 || cpu_address >= 0xe000)
			throw std::runtime_error("DMC read left the observed $C000-$DFFF bank-$1E window");
		const std::uint32_t offset = cpu_address - 0xc000;
		if (offset >= dmc_prg_bank_.size()) throw std::runtime_error("DMC read exceeds 8 KiB bank");
		dmc_dma_buffer_ = dmc_prg_bank_[offset];
		if (dmc_dma_buffer_ != event.value)
			throw std::runtime_error("FCEUX DMC fetched byte disagrees with the supplied ROM bank");
		if (first_dmc_source_offset_ == UINT64_MAX) first_dmc_source_offset_ = offset;
		++dmc_bytes_read_;
		dmc_have_dma_ = true;
		dmc_address_ = (dmc_address_ + 1) & 0x7fff;
		--dmc_size_;
		if (!dmc_size_) {
			if (dmc_format_ & 0x40) {
				dmc_address_ = 0x4000 + (static_cast<std::uint32_t>(dmc_address_latch_) << 6);
				dmc_size_ = (static_cast<std::uint32_t>(dmc_size_latch_) << 4) + 1;
			} else if (dmc_format_ & 0x80) {
				dmc_irq_pending_ = true;
			}
		}
	}

	void prep_source_dmc() {
		dmc_address_ = 0x4000 + (static_cast<std::uint32_t>(dmc_address_latch_) << 6);
		dmc_size_ = (static_cast<std::uint32_t>(dmc_size_latch_) << 4) + 1;
	}

	void source_dmc_fetch(std::uint64_t cpu_cycle) {
		if (!dmc_size_ || dmc_have_dma_) return;
		const std::uint32_t cpu_address = 0x8000 + dmc_address_;
		if (cpu_address < 0xc000 || cpu_address >= 0xe000)
			throw std::runtime_error("source-mode DMC read left the observed $C000-$DFFF bank-$1E window");
		const std::uint32_t offset = cpu_address - 0xc000;
		if (offset >= dmc_prg_bank_.size()) throw std::runtime_error("source-mode DMC read exceeds bank $1E");
		dmc_dma_buffer_ = dmc_prg_bank_[offset];
		if (first_dmc_source_offset_ == UINT64_MAX) first_dmc_source_offset_ = offset;
		++dmc_bytes_read_;
		++source_dmc_fetches_;
		if (source_dmc_fetch_stream_) {
			source_dmc_fetch_stream_ << source_dmc_fetches_ - 1 << ',' << cpu_cycle << ","
				<< "$" << std::hex << std::uppercase << cpu_address << ","
				<< "$" << static_cast<unsigned>(dmc_dma_buffer_) << std::dec << ",0x1E,0x"
				<< std::hex << std::uppercase << offset << std::dec << '\n';
		}
		dmc_have_dma_ = true;
		dmc_address_ = (dmc_address_ + 1) & 0x7fff;
		--dmc_size_;
		if (!dmc_size_) {
			if (dmc_format_ & 0x40) prep_source_dmc();
			else if (dmc_format_ & 0x80) dmc_irq_pending_ = true;
		}
	}

	void source_dmc_replay_fetch(const DmcFetchEvent& event) {
		if (!dmc_size_)
			throw std::runtime_error("ROM-stepper DMC read conflicts with reconstructed $4010-$4015 state at cycle " + std::to_string(event.cycle)
				+ " (remaining=" + std::to_string(dmc_size_)
				+ ", reader=$" + [&] { std::ostringstream s; s << std::hex << std::uppercase << (0x8000 + dmc_address_); return s.str(); }()
				+ ", value=$" + [&] { std::ostringstream s; s << std::hex << std::uppercase << static_cast<unsigned>(event.value); return s.str(); }() + ")");
		const std::uint32_t expected_address = 0x8000 + dmc_address_;
		if (event.cpu_address != expected_address)
			throw std::runtime_error("ROM-stepper DMC address disagrees with WaveHi's reconstructed DMC reader at cycle " + std::to_string(event.cycle)
				+ " (expected $" + [&] { std::ostringstream s; s << std::hex << std::uppercase << expected_address; return s.str(); }()
				+ ", got $" + [&] { std::ostringstream s; s << std::hex << std::uppercase << event.cpu_address; return s.str(); }() + ")");
		const std::uint32_t offset = event.cpu_address - 0xc000;
		if (offset >= dmc_prg_bank_.size()) throw std::runtime_error("ROM-stepper DMC read exceeds physical bank $1E");
		if (dmc_prg_bank_[offset] != event.value)
			throw std::runtime_error("ROM-stepper DMC byte disagrees with supplied ROM bank $1E");
		if (source_dmc_dac_edge_mode_) {
			if (first_dmc_source_offset_ == UINT64_MAX) first_dmc_source_offset_ = offset;
			++dmc_bytes_read_;
			++source_dmc_fetches_;
			dmc_address_ = (dmc_address_ + 1) & 0x7fff;
			--dmc_size_;
			if (!dmc_size_) {
				if (dmc_format_ & 0x40) prep_source_dmc();
				else if (dmc_format_ & 0x80) dmc_irq_pending_ = true;
			}
			return;
		}
		// The ROM stepper supplies authoritative read events for this candidate.
		// If this renderer's independently modeled bit phase has not released the
		// prior buffer yet, keep the source byte and record that phase mismatch.
		if (dmc_have_dma_) {
			++source_dmc_buffer_overruns_;
			source_dmc_buffer_overrun_cycles_.push_back(event.cycle);
		}
		dmc_dma_buffer_ = event.value;
		if (first_dmc_source_offset_ == UINT64_MAX) first_dmc_source_offset_ = offset;
		++dmc_bytes_read_;
		++source_dmc_fetches_;
		if (source_dmc_fetch_stream_) {
			source_dmc_fetch_stream_ << source_dmc_fetches_ - 1 << ',' << event.cycle << ","
				<< "$" << std::hex << std::uppercase << event.cpu_address << ","
				<< "$" << static_cast<unsigned>(event.value) << std::dec << ",0x1E,0x"
				<< std::hex << std::uppercase << offset << std::dec << '\n';
		}
		dmc_have_dma_ = true;
		dmc_address_ = (dmc_address_ + 1) & 0x7fff;
		--dmc_size_;
		if (!dmc_size_) {
			if (dmc_format_ & 0x40) prep_source_dmc();
			else if (dmc_format_ & 0x80) dmc_irq_pending_ = true;
		}
	}

	void source_nsf_callback_refill(const DmcFetchEvent& event) {
		if (event.cpu_address < 0xc000 || event.cpu_address >= 0xe000)
			throw std::runtime_error("source NSF DMC callback left the observed bank-$1E CPU window");
		const std::uint32_t offset = event.cpu_address - 0xc000;
		if (offset >= dmc_prg_bank_.size()) throw std::runtime_error("source NSF DMC callback exceeds bank $1E");
		if (dmc_prg_bank_[offset] != event.value)
			throw std::runtime_error("source NSF DMC callback byte disagrees with supplied ROM bank $1E");
		// libgme reports when its emulated DMC sample buffer is refilled. It is
		// source-derived timing, but not an authoritative 2A03 DMA bus cycle.
		dmc_dma_buffer_ = event.value;
		dmc_have_dma_ = true;
		++dmc_bytes_read_;
		++source_dmc_fetches_;
		if (first_dmc_source_offset_ == UINT64_MAX) first_dmc_source_offset_ = offset;
		const std::uint32_t expected_address = 0x8000 + dmc_address_;
		if (dmc_size_ && expected_address != event.cpu_address) ++source_dmc_callback_address_mismatches_;
		dmc_address_ = ((event.cpu_address - 0x8000) + 1) & 0x7fff;
		if (dmc_size_) --dmc_size_;
		if (!dmc_size_) {
			if (dmc_format_ & 0x40) prep_source_dmc();
			else if (dmc_format_ & 0x80) dmc_irq_pending_ = true;
		}
		if (source_dmc_fetch_stream_) {
			source_dmc_fetch_stream_ << source_dmc_fetches_ - 1 << ',' << event.cycle << ","
				<< "$" << std::hex << std::uppercase << event.cpu_address << ","
				<< "$" << static_cast<unsigned>(event.value) << std::dec << ",0x1E,0x"
				<< std::hex << std::uppercase << offset << std::dec << '\n';
		}
	}

	void source_dmc_tester() {
		if (dmc_bit_count_ != 0) return;
		if (!dmc_have_dma_) dmc_have_sample_ = false;
		else {
			dmc_have_sample_ = true;
			dmc_shift_ = dmc_dma_buffer_;
			dmc_have_dma_ = false;
		}
	}

	void clock_source_dmc(std::uint64_t cpu_cycle) {
		if (cpu_cycle < source_dmc_clock_cycle_)
			throw std::runtime_error("source DMC clock moved backwards");
		const std::uint64_t elapsed = cpu_cycle - source_dmc_clock_cycle_;
		for (std::uint64_t step = 0; step < elapsed; ++step) {
			const std::uint64_t clock_cycle = source_dmc_clock_cycle_ + step + 1;
			if (source_dmc_read_replay_mode_ && next_dmc_fetch_ < dmc_fetches_.size()
					&& dmc_fetches_[next_dmc_fetch_].cycle < clock_cycle)
				throw std::runtime_error("missed a ROM-stepper DMC byte read at cycle " + std::to_string(dmc_fetches_[next_dmc_fetch_].cycle));
			if (source_dmc_read_replay_mode_) {
				while (next_dmc_fetch_ < dmc_fetches_.size() && dmc_fetches_[next_dmc_fetch_].cycle == clock_cycle) {
					source_dmc_replay_fetch(dmc_fetches_[next_dmc_fetch_]);
					++next_dmc_fetch_;
				}
			}
			if (source_dmc_dac_edge_mode_) {
				while (next_dac_transition_ < dac_transitions_.size()
						&& dac_transitions_[next_dac_transition_].cycle < clock_cycle)
					throw std::runtime_error("missed source DMC DAC edge at cycle " + std::to_string(dac_transitions_[next_dac_transition_].cycle));
				while (next_dac_transition_ < dac_transitions_.size()
						&& dac_transitions_[next_dac_transition_].cycle == clock_cycle) {
					if (raw_dac_ != source_dac_before_[next_dac_transition_]) ++source_dmc_dac_before_mismatches_;
					flush_channel(4, source_position_for(clock_cycle));
					raw_dac_ = dac_transitions_[next_dac_transition_].raw_dac;
					++source_dmc_dac_edges_;
					++next_dac_transition_;
				}
				--dmc_acc_;
				continue;
			}
			if (source_dmc_callback_mode_) {
				while (next_dmc_fetch_ < dmc_fetches_.size() && dmc_fetches_[next_dmc_fetch_].cycle == clock_cycle) {
					source_nsf_callback_refill(dmc_fetches_[next_dmc_fetch_]);
					++next_dmc_fetch_;
				}
			} else if (source_dmc_read_replay_mode_) {
				if (next_dmc_fetch_ < dmc_fetches_.size() && dmc_fetches_[next_dmc_fetch_].cycle < clock_cycle)
					throw std::runtime_error("missed a ROM-stepper DMC byte read at cycle " + std::to_string(dmc_fetches_[next_dmc_fetch_].cycle));
				while (next_dmc_fetch_ < dmc_fetches_.size() && dmc_fetches_[next_dmc_fetch_].cycle == clock_cycle) {
					source_dmc_replay_fetch(dmc_fetches_[next_dmc_fetch_]);
					++next_dmc_fetch_;
				}
			} else {
				source_dmc_fetch(clock_cycle);
			}
			--dmc_acc_;
			while (dmc_acc_ <= 0) {
				if (dmc_have_sample_) {
					const std::uint8_t old_dac = raw_dac_;
					const int delta = ((dmc_shift_ & 1) << 2) - 2;
					int next_dac = static_cast<int>(raw_dac_) + delta;
					if (next_dac < 0 || next_dac > 127) next_dac = old_dac;
					if (next_dac != raw_dac_) {
						flush_channel(4, source_position_for(clock_cycle));
						raw_dac_ = static_cast<std::uint8_t>(next_dac);
						++source_dmc_dac_edges_;
					}
				}
				dmc_acc_ += static_cast<std::int32_t>(kDmcPeriods[dmc_format_ & 0x0f]);
				dmc_bit_count_ = (dmc_bit_count_ + 1) & 7;
				dmc_shift_ >>= 1;
				++source_dmc_bit_edges_;
				source_dmc_tester();
			}
			if (source_dmc_state_replay_mode_) {
				if (next_dmc_bit_state_ < dmc_bit_states_.size() && dmc_bit_states_[next_dmc_bit_state_].cycle < clock_cycle)
					throw std::runtime_error("missed ROM-stepper DMC state event at cycle " + std::to_string(dmc_bit_states_[next_dmc_bit_state_].cycle));
				while (next_dmc_bit_state_ < dmc_bit_states_.size() && dmc_bit_states_[next_dmc_bit_state_].cycle == clock_cycle) {
					apply_dmc_bit_state(dmc_bit_states_[next_dmc_bit_state_]);
					++next_dmc_bit_state_;
				}
			}
		}
		source_dmc_clock_cycle_ = cpu_cycle;
	}

	void apply_dmc_bit_state(const DmcStateEvent& event) {
		if (event.period != static_cast<std::int32_t>(kDmcPeriods[dmc_format_ & 0x0f]))
			throw std::runtime_error("FCEUX DMC period disagrees with ROM-derived $4010 state");
		if (raw_dac_ != event.raw_dac) flush_channel(4, source_position_for(event.cycle));
		dmc_acc_ = event.accumulator;
		dmc_bit_count_ = event.bit_count;
		dmc_address_ = event.address;
		dmc_size_ = event.size;
		dmc_shift_ = event.shift;
		dmc_have_dma_ = event.have_dma;
		dmc_have_sample_ = event.have_sample;
		dmc_dma_buffer_ = event.dma_buffer;
		++dmc_bits_clocked_;
	}

	void process_dac_transitions(std::uint64_t cpu_cycle, std::uint32_t source_position) {
		if (next_dac_transition_ < dac_transitions_.size() && dac_transitions_[next_dac_transition_].cycle < cpu_cycle)
			throw std::runtime_error("missed PCM-corrected FCEUX DMC DAC edge at cycle " + std::to_string(dac_transitions_[next_dac_transition_].cycle) + " while processing " + std::to_string(cpu_cycle));
		while (next_dac_transition_ < dac_transitions_.size() && dac_transitions_[next_dac_transition_].cycle == cpu_cycle) {
			flush_channel(4, source_position);
			raw_dac_ = dac_transitions_[next_dac_transition_].raw_dac;
			++next_dac_transition_;
		}
	}

	void frame_sound_update(std::uint32_t source_position, std::uint64_t cpu_cycle) {
		write_triangle_state("update", cpu_cycle, triangle_step_, triangle_step_, triangle_period_count_,
			triangle_period_count_, length_[2] && triangle_count_);
		flush_frame_sound_channels(source_position);
		if (fcnt_ == 3 && (irq_frame_mode_ & 0x2)) fhcnt_ += fhinc_;
		const int value = fcnt_;
		if (!(value & 1)) {
			if (!(psg_[0x8] & 0x80) && length_[2] > 0) --length_[2];
			if (!(psg_[0x0c] & 0x20) && length_[3] > 0) --length_[3];
			for (int channel = 0; channel < 2; ++channel) {
				if (!(psg_[channel * 4] & 0x20) && length_[channel] > 0) --length_[channel];
				if (sweep_count_[channel] > 0) --sweep_count_[channel];
				if (sweep_count_[channel] <= 0) {
					const int shift = psg_[(channel << 2) + 1] & 7;
					if (sweep_on_[channel] && shift && frequency_[channel] >= 8) {
						const int modifier = frequency_[channel] >> shift;
						if (psg_[(channel << 2) + 1] & 0x8) frequency_[channel] -= modifier + (channel ^ 1);
						else if (modifier + frequency_[channel] < 0x800) frequency_[channel] += modifier;
					}
					sweep_count_[channel] = (((psg_[(channel << 2) + 1] >> 4) & 7) + 1);
				}
				if (sweep_reload_[channel]) {
					sweep_count_[channel] = (((psg_[(channel << 2) + 1] >> 4) & 7) + 1);
					sweep_reload_[channel] = false;
				}
			}
		}

		if (triangle_mode_) triangle_count_ = psg_[0x8] & 0x7f;
		else if (triangle_count_) --triangle_count_;
		if (!(psg_[0x8] & 0x80)) triangle_mode_ = false;

		for (int channel = 0; channel < 3; ++channel) {
			Envelope& envelope = envelopes_[channel];
			if (envelope.reload) {
				envelope.dec_volume = 0x0f;
				envelope.dec_count_to1 = envelope.speed + 1;
				envelope.reload = false;
				continue;
			}
			if (envelope.dec_count_to1 > 0) --envelope.dec_count_to1;
			if (envelope.dec_count_to1 == 0) {
				envelope.dec_count_to1 = envelope.speed + 1;
				if (envelope.dec_volume || (envelope.mode & 0x2)) {
					--envelope.dec_volume;
					envelope.dec_volume &= 0x0f;
				}
			}
		}
		fcnt_ = (fcnt_ + 1) & 3;
	}

	std::array<std::uint8_t, 16> psg_{};
	std::vector<std::uint8_t> dmc_prg_bank_;
	std::vector<std::uint32_t> packed_wavehi_;
	std::array<std::uint32_t, 5> channel_bc_{};
	std::uint64_t frame_cycle_start_ = 0;
	std::vector<std::uint64_t> frame_update_cycles_;
	std::vector<DmcFetchEvent> dmc_fetches_;
	std::vector<DmcStateEvent> dmc_bit_states_;
	std::vector<DmcDacTransition> dac_transitions_;
	std::vector<std::uint8_t> source_dac_before_;
	std::array<std::vector<std::int32_t>, 5> raw_channel_wavehi_;
	std::ofstream source_dmc_fetch_stream_;
	std::ofstream channel_trace_stream_;
	std::ofstream triangle_trace_stream_;
	std::size_t next_frame_update_ = 0;
	bool source_frame_sequencer_ = false;
	bool source_dmc_engine_ = false;
	bool source_dmc_callback_mode_ = false;
	bool source_dmc_read_replay_mode_ = false;
	bool source_dmc_dac_edge_mode_ = false;
	bool source_dmc_state_replay_mode_ = false;
	std::uint64_t source_frame_clock_cycle_ = 0;
	std::uint64_t source_frame_updates_ = 0;
	std::uint64_t source_dmc_clock_cycle_ = 0;
	std::uint64_t source_dmc_fetches_ = 0;
	std::uint64_t source_dmc_bit_edges_ = 0;
	std::uint64_t source_dmc_dac_edges_ = 0;
	std::uint64_t source_dmc_callback_address_mismatches_ = 0;
	std::uint64_t source_dmc_buffer_overruns_ = 0;
	std::vector<std::uint64_t> source_dmc_buffer_overrun_cycles_;
	std::uint64_t source_dmc_dac_before_mismatches_ = 0;
	std::uint64_t channel_trace_start_ = 0;
	std::uint64_t channel_trace_end_ = 0;
	std::uint64_t channel_trace_rows_ = 0;
	std::uint64_t triangle_trace_start_ = 0;
	std::uint64_t triangle_trace_end_ = 0;
	std::uint64_t triangle_trace_rows_ = 0;
	std::size_t next_dmc_fetch_ = 0;
	std::size_t next_dmc_bit_state_ = 0;
	std::size_t next_dac_transition_ = 0;
	std::array<Envelope, 3> envelopes_{};
	std::array<std::uint32_t, 32> wlookup1_{};
	std::array<std::uint32_t, 203> wlookup2_{};
	std::array<int, 2> duty_count_{};
	std::array<int, 2> frequency_{};
	std::array<int, 2> square_period_count_{};
	std::array<int, 2> sweep_count_{};
	std::array<bool, 2> sweep_on_{};
	std::array<bool, 2> sweep_reload_{};
	std::array<int, 4> length_{};
	int triangle_period_count_ = 1;
	int triangle_step_ = 0;
	int triangle_count_ = 0;
	int noise_period_count_ = 2048;
	std::uint16_t noise_lfsr_ = 1;
	std::uint8_t enabled_ = 0;
	std::uint8_t fcnt_ = 0;
	std::uint8_t irq_frame_mode_ = 0;
	std::int32_t fhcnt_ = 0;
	std::int32_t fhinc_ = 0;
	bool triangle_mode_ = false;
	std::uint8_t dmc_format_ = 0;
	std::uint8_t dmc_address_latch_ = 0;
	std::uint8_t dmc_size_latch_ = 0;
	std::uint8_t raw_dac_ = 0;
	std::uint32_t dmc_address_ = 0;
	std::uint32_t dmc_size_ = 0;
	std::int32_t dmc_acc_ = 1;
	std::uint8_t dmc_bit_count_ = 0;
	std::uint8_t dmc_shift_ = 0;
	std::uint8_t dmc_dma_buffer_ = 0;
	bool dmc_have_dma_ = false;
	bool dmc_have_sample_ = false;
	bool dmc_irq_pending_ = false;
	std::uint64_t dmc_bytes_read_ = 0;
	std::uint64_t dmc_bits_clocked_ = 0;
	std::uint64_t first_dmc_source_offset_ = UINT64_MAX;
};
} // namespace

int main(int argc, char** argv) {
	if (argc < 6) {
		std::fprintf(stderr, "usage: %s apu_writes.csv frame_cycles.csv dmc_hook_trace.csv source_rom.nes output.wav [--source-frame-sequencer | --source-frame-update-events FILE] [--source-dmc-engine | --source-dmc-callbacks FILE | --source-dmc-read-replay FILE] [--source-dmc-state-events FILE] [--source-dmc-dac-edges FILE] [--source-dmc-fetches FILE] [--channel-wavehi-raw FILE --channel-cycle-start N --channel-cycle-end N]\n", argv[0]);
		return 2;
	}
	try {
		bool source_frame_sequencer = false;
		bool source_frame_update_event_mode = false;
		bool source_dmc_engine = false;
		bool source_dmc_callback_mode = false;
		bool source_dmc_read_replay_mode = false;
		bool source_dmc_dac_edge_mode = false;
		bool source_dmc_state_replay_mode = false;
		std::string source_dmc_callback_path;
		std::string source_dmc_read_path;
		std::string source_dmc_dac_edge_path;
		std::string source_dmc_state_path;
		std::string source_dmc_fetch_output;
		std::string source_frame_update_path;
		std::string channel_trace_output;
		std::uint64_t channel_trace_start = 0;
		std::uint64_t channel_trace_end = 0;
		std::string triangle_trace_output;
		std::uint64_t triangle_trace_start = 0;
		std::uint64_t triangle_trace_end = 0;
		bool have_channel_trace_start = false;
		bool have_channel_trace_end = false;
		for (int index = 6; index < argc; ++index) {
			const std::string option = argv[index];
			if (option == "--source-frame-sequencer") source_frame_sequencer = true;
			else if (option == "--source-frame-update-events" && index + 1 < argc) {
				source_frame_update_event_mode = true;
				source_frame_update_path = argv[++index];
			}
			else if (option == "--source-dmc-engine") source_dmc_engine = true;
			else if (option == "--source-dmc-callbacks" && index + 1 < argc) {
				source_dmc_callback_mode = true;
				source_dmc_callback_path = argv[++index];
			}
			else if (option == "--source-dmc-read-replay" && index + 1 < argc) {
				source_dmc_read_replay_mode = true;
				source_dmc_read_path = argv[++index];
			}
			else if (option == "--source-dmc-dac-edges" && index + 1 < argc) {
				source_dmc_dac_edge_mode = true;
				source_dmc_dac_edge_path = argv[++index];
			}
			else if (option == "--source-dmc-state-events" && index + 1 < argc) {
				source_dmc_state_replay_mode = true;
				source_dmc_state_path = argv[++index];
			}
			else if (option == "--source-dmc-fetches" && index + 1 < argc) source_dmc_fetch_output = argv[++index];
			else if (option == "--channel-wavehi-raw" && index + 1 < argc) channel_trace_output = argv[++index];
			else if (option == "--channel-cycle-start" && index + 1 < argc) {
				channel_trace_start = std::stoull(argv[++index]);
				have_channel_trace_start = true;
			}
			else if (option == "--channel-cycle-end" && index + 1 < argc) {
				channel_trace_end = std::stoull(argv[++index]);
				have_channel_trace_end = true;
			}
			else if (option == "--triangle-state-trace" && index + 1 < argc) triangle_trace_output = argv[++index];
			else if (option == "--triangle-cycle-start" && index + 1 < argc) triangle_trace_start = std::stoull(argv[++index]);
			else if (option == "--triangle-cycle-end" && index + 1 < argc) triangle_trace_end = std::stoull(argv[++index]);
			else throw std::runtime_error("unknown or incomplete optional renderer argument: " + option);
		}
		if ((!channel_trace_output.empty()) != (have_channel_trace_start && have_channel_trace_end))
			throw std::runtime_error("channel WaveHi trace needs output path and both cycle boundaries");
		if (!channel_trace_output.empty() && channel_trace_end <= channel_trace_start)
			throw std::runtime_error("channel WaveHi trace cycle window must be nonempty");
		if (triangle_trace_output.empty() != (triangle_trace_start == 0 && triangle_trace_end == 0))
			throw std::runtime_error("source triangle state trace needs output path and both cycle boundaries");
		if (!triangle_trace_output.empty() && triangle_trace_end <= triangle_trace_start)
			throw std::runtime_error("source triangle state trace cycle window must be nonempty");
		if (source_frame_sequencer && source_frame_update_event_mode)
			throw std::runtime_error("choose either per-cycle source frame sequencing or ROM-stepper frame-update events");
		if ((source_dmc_callback_mode || source_dmc_read_replay_mode || source_dmc_dac_edge_mode || source_dmc_state_replay_mode) && source_dmc_engine)
			throw std::runtime_error("choose one source DMC schedule: computed cycle model, NSF callbacks, or ROM-stepper source events");
		if (source_dmc_callback_mode || source_dmc_read_replay_mode || source_dmc_dac_edge_mode || source_dmc_state_replay_mode) source_dmc_engine = true;
		const std::string write_path = argv[1];
		const std::string frame_path = argv[2];
		const std::string dmc_trace_path = argv[3];
		const std::string rom_path = argv[4];
		const std::string output_path = argv[5];
		const std::vector<ApuWrite> writes = load_apu_writes(write_path);
		const std::vector<FrameCycles> frames = load_frame_cycles(frame_path);
		DmcTrace dmc_trace;
		if (source_dmc_callback_mode) dmc_trace = load_source_nsf_dmc_callbacks(source_dmc_callback_path);
		else if (source_dmc_read_replay_mode) dmc_trace = load_source_stepper_dmc_reads(source_dmc_read_path);
		else if (!source_dmc_engine && !source_dmc_dac_edge_mode && !source_dmc_state_replay_mode) dmc_trace = load_dmc_trace(dmc_trace_path, !source_frame_sequencer);
		if (source_frame_update_event_mode)
			dmc_trace.frame_update_cycles = load_source_frame_update_events(source_frame_update_path);
		if (source_dmc_dac_edge_mode) {
			DmcTrace source_edge_trace = load_source_dmc_dac_edges(source_dmc_dac_edge_path);
			dmc_trace.dac_transitions = std::move(source_edge_trace.dac_transitions);
			dmc_trace.source_dac_before = std::move(source_edge_trace.source_dac_before);
		}
		if (source_dmc_state_replay_mode) {
			DmcTrace source_state_trace = load_source_dmc_state_events(source_dmc_state_path);
			dmc_trace.bit_states = std::move(source_state_trace.bit_states);
		}
		const std::vector<std::uint8_t> dmc_prg_bank = load_prg_bank_1e(rom_path);
		FceuxApuWaveHi apu(dmc_prg_bank, std::move(dmc_trace), source_frame_sequencer,
			source_dmc_engine, source_dmc_fetch_output, source_dmc_callback_mode, source_dmc_read_replay_mode,
			source_dmc_dac_edge_mode, source_dmc_state_replay_mode, channel_trace_output,
			 channel_trace_start, channel_trace_end, triangle_trace_output, triangle_trace_start,
				 triangle_trace_end);
		FceuxSoundq2Port filter;
		std::vector<std::int16_t> output_samples;
		std::size_t write_index = 0;
		std::uint64_t current_cycle = 0;
		std::uint64_t total_cycles = 0;
		std::uint64_t dmc_register_writes = 0;
		std::uint64_t first_dmc_enable_cycle = UINT64_MAX;
		std::uint64_t first_dmc_source_offset = UINT64_MAX;

		for (const FrameCycles& frame : frames) {
			if (frame.cycle_start != current_cycle) {
				if (frame.cycle_start < current_cycle) throw std::runtime_error("frame-cycle rows are not contiguous");
				current_cycle = frame.cycle_start;
			}
			apu.begin_frame(frame.cycle_start, frame.cycle_end);
			while (current_cycle < frame.cycle_end) {
				apu.process_trace_events(current_cycle);
				while (write_index < writes.size() && writes[write_index].cycle == current_cycle) {
					const ApuWrite& event = writes[write_index];
					if (event.address == 0x4010 || event.address == 0x4012 || event.address == 0x4013 || event.address == 0x4015) ++dmc_register_writes;
					if (event.address == 0x4015 && (event.value & 0x10) && first_dmc_enable_cycle == UINT64_MAX) first_dmc_enable_cycle = event.cycle;
					apu.write(event.address, event.value, current_cycle);
					++write_index;
				}
				if (write_index < writes.size() && writes[write_index].cycle < current_cycle)
					throw std::runtime_error("APU write falls behind synthesized cycle cursor");
				++current_cycle;
				++total_cycles;
			}
			// A bus write can be timestamped exactly at the frame boundary. FCEUX
			// observes the hook/frame events before that same-cycle CPU bus write.
			apu.process_trace_events(current_cycle);
			while (write_index < writes.size() && writes[write_index].cycle == current_cycle) {
				const ApuWrite& event = writes[write_index];
				if (event.address == 0x4010 || event.address == 0x4012 || event.address == 0x4013 || event.address == 0x4015) ++dmc_register_writes;
				if (event.address == 0x4015 && (event.value & 0x10) && first_dmc_enable_cycle == UINT64_MAX) first_dmc_enable_cycle = event.cycle;
				apu.write(event.address, event.value, current_cycle);
				++write_index;
			}
			auto wavehi = apu.finish_frame(frame.cycle_end);
			if (!wavehi.empty()) {
				auto frame_pcm = filter.process_wavehi_frame(wavehi);
				output_samples.insert(output_samples.end(), frame_pcm.begin(), frame_pcm.end());
			}
		}
		if (write_index != writes.size()) throw std::runtime_error("unconsumed writes remain after final frame");
		if (!source_dmc_engine && apu.dmc_fetch_events_consumed() != apu.dmc_fetch_events_total())
			throw std::runtime_error("unconsumed timestamped FCEUX DMC fetch events remain after final frame");
		if ((!source_dmc_engine || source_dmc_state_replay_mode) && apu.dmc_bit_states_consumed() != apu.dmc_bit_states_total())
			throw std::runtime_error("unconsumed timestamped FCEUX DMC bit-state events remain after final frame");
		if (!source_dmc_engine && apu.dmc_dac_transitions_consumed() != apu.dmc_dac_transitions_total())
			throw std::runtime_error("unconsumed PCM-corrected FCEUX DMC DAC transitions remain after final frame");
		if ((source_dmc_callback_mode || source_dmc_read_replay_mode) && apu.dmc_fetch_events_consumed() != apu.dmc_fetch_events_total())
			throw std::runtime_error("unconsumed source DMC input events remain after final frame");
		if (source_dmc_dac_edge_mode && apu.dmc_dac_transitions_consumed() != apu.dmc_dac_transitions_total())
			throw std::runtime_error("unconsumed ROM-stepper source DMC DAC edges remain after final frame");
		if (source_dmc_state_replay_mode && apu.dmc_bit_states_consumed() != apu.dmc_bit_states_total())
			throw std::runtime_error("unconsumed ROM-stepper source DMC state events remain after final frame");
		if (apu.frame_updates_consumed() != apu.frame_updates_total())
			throw std::runtime_error("unconsumed timestamped FCEUX frame-sequencer events remain after final frame");
		first_dmc_source_offset = apu.first_dmc_source_offset();
		if (output_samples.size() > UINT32_MAX / 2) throw std::runtime_error("WAV output exceeds RIFF size limit");
		std::ofstream out(output_path, std::ios::binary);
		if (!out) throw std::runtime_error("unable to create output WAV");
		write_wav_header(out, static_cast<std::uint32_t>(output_samples.size()));
		out.write(reinterpret_cast<const char*>(output_samples.data()), output_samples.size() * sizeof(std::int16_t));
		if (!out) throw std::runtime_error("failed to write output WAV");
		std::cout << "apu_writes=" << writes.size() << "\n"
			<< "synthesized_cycles=" << total_cycles << "\n"
			<< "dmc_register_writes=" << dmc_register_writes << "\n"
			<< "frame_update_events=" << apu.frame_updates_consumed() << "\n"
			<< "frame_sequencer_source=" << (source_frame_update_event_mode ? "ROM-stepper instruction-hook frame-update events" : (source_frame_sequencer ? "ROM APU $4017 + per-cycle fixed-point clock" : "FCEUX trace")) << "\n"
			<< "dmc_fetch_events=" << apu.dmc_fetch_events_consumed() << "\n"
			<< "dmc_bit_state_events=" << apu.dmc_bit_states_consumed() << "\n"
			<< "dmc_dac_transition_events=" << apu.dmc_dac_transitions_consumed() << "\n"
			<< "source_channel_wavehi_rows=" << apu.channel_trace_rows() << "\n"
			<< "first_dmc_enable_cycle=" << first_dmc_enable_cycle << "\n"
			<< "dmc_bytes_read=" << apu.dmc_bytes_read() << "\n"
			<< "first_dmc_source_offset=" << first_dmc_source_offset << "\n"
			<< "wav_samples=" << output_samples.size() << "\n"
			<< "source_dmc_callback_expected_address_mismatches=" << apu.source_dmc_callback_address_mismatches() << "\n"
			<< "source_dmc_buffer_overruns=" << apu.source_dmc_buffer_overruns() << "\n"
			<< "source_dmc_dac_before_mismatches=" << apu.source_dmc_dac_before_mismatches() << "\n"
			<< "dmc_pcm_model=" << (source_dmc_state_replay_mode ? "ROM CPU/PPU stepper bit-edge state corrections over source timer/DAC model" : (source_dmc_dac_edge_mode ? "ROM CPU/PPU stepper DAC-changing bit-edge replay" : (source_dmc_read_replay_mode ? "ROM CPU/PPU stepper DMC read schedule plus source timer/DAC model" : (source_dmc_callback_mode ? "ROM-verified NSF libgme refill callback schedule" : (source_dmc_engine ? "ROM-byte source cycle model" : "FCEUX trace driven"))))) << "\n";
		std::cout << "source_dmc_buffer_overrun_cycles=";
		for (std::size_t i = 0; i < apu.source_dmc_buffer_overrun_cycles().size(); ++i) {
			if (i) std::cout << ',';
			std::cout << apu.source_dmc_buffer_overrun_cycles()[i];
		}
		std::cout << "\n";
		return 0;
	} catch (const std::exception& error) {
		std::cerr << "FCEUX APU WaveHi prototype: " << error.what() << "\n";
		return 1;
	}
}
