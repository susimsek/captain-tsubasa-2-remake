#include "trace_hooks.hpp"

#include "gme.h"

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

extern "C" const char* ct2_gme_trace_advance_nsf(Music_Emu* emu, int cycles);

namespace {
bool read_file(const char* path, std::vector<char>& data) {
	std::ifstream file(path, std::ios::binary);
	if (!file) {
		return false;
	}
	data.assign(std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>());
	return !file.bad();
}
} // namespace

int main(int argc, char** argv) {
	if (argc != 6) {
		std::fprintf(stderr, "usage: %s input.nsf apu_writes.csv play_calls.csv dmc_fetches.csv cpu_cycles\n", argv[0]);
		return 2;
	}

	const long cycles = std::strtol(argv[5], nullptr, 10);
	if (cycles <= 0 || cycles > 2000000000L) {
		std::fprintf(stderr, "invalid CPU-cycle count\n");
		return 2;
	}

	std::vector<char> nsf;
	if (!read_file(argv[1], nsf)) {
		std::fprintf(stderr, "unable to read NSF input\n");
		return 2;
	}
	if (nsf.size() < 128 || std::string(nsf.data(), 5) != std::string("NESM\x1A", 5)) {
		std::fprintf(stderr, "input is not an NSF file\n");
		return 2;
	}

	ct2_trace_open(argv[2], argv[3], argv[4]);
	Music_Emu* emu = nullptr;
	const char* error = gme_open_data(nsf.data(), static_cast<long>(nsf.size()), &emu, 44100);
	if (error != nullptr) {
		std::fprintf(stderr, "gme_open_data: %s\n", error);
		ct2_trace_close();
		return 1;
	}

	int result = 0;
	gme_ignore_silence(emu, 1);
	error = gme_start_track(emu, 0);
	if (error != nullptr) {
		std::fprintf(stderr, "gme_start_track: %s\n", error);
		result = 1;
	} else {
		// Keep the ROM driver and CPU active but disconnect all libgme output
		// voices. The temporary-only run_clocks entry advances emulated CPU/APU
		// time directly, without rendering or storing PCM samples.
		gme_mute_voices(emu, -1);
		error = ct2_gme_trace_advance_nsf(emu, static_cast<int>(cycles));
		if (error != nullptr) {
			std::fprintf(stderr, "direct NSF cycle advance: %s\n", error);
			result = 1;
		}
	}

	gme_delete(emu);
	ct2_trace_close();
	return result;
}
