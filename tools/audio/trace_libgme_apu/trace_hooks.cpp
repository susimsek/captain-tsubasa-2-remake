#include "trace_hooks.hpp"

#include <cstdio>
#include <cstdlib>

namespace {
FILE* apu_file = nullptr;
FILE* play_file = nullptr;
FILE* dmc_file = nullptr;
uint64_t cycle_base = 0;
uint32_t write_sequence = 0;
uint32_t play_sequence = 0;
uint32_t dmc_sequence = 0;

void write_bootstrap(uint16_t address, uint8_t value) {
	if (apu_file == nullptr) {
		return;
	}
	std::fprintf(apu_file, "%u,%llu,0,$%04X,$%02X,nsf_bootstrap\n",
		write_sequence++, static_cast<unsigned long long>(cycle_base), address, value);
}
} // namespace

void ct2_trace_open(const char* apu_csv_path, const char* play_csv_path, const char* dmc_csv_path) {
	ct2_trace_close();
	apu_file = std::fopen(apu_csv_path, "wb");
	play_file = std::fopen(play_csv_path, "wb");
	dmc_file = std::fopen(dmc_csv_path, "wb");
	if (apu_file == nullptr || play_file == nullptr || dmc_file == nullptr) {
		ct2_trace_close();
		std::fprintf(stderr, "Unable to open trace output files\n");
		std::exit(2);
	}
	std::fputs("sequence,absolute_cpu_cycle,local_cpu_cycle,address,value,origin\n", apu_file);
	std::fputs("play_index,absolute_cpu_cycle,local_cpu_cycle\n", play_file);
	std::fputs("sequence,absolute_cpu_cycle,local_cpu_cycle,cpu_address,value\n", dmc_file);
}

void ct2_trace_close() {
	if (apu_file != nullptr) {
		std::fclose(apu_file);
		apu_file = nullptr;
	}
	if (play_file != nullptr) {
		std::fclose(play_file);
		play_file = nullptr;
	}
	if (dmc_file != nullptr) {
		std::fclose(dmc_file);
		dmc_file = nullptr;
	}
}

void ct2_trace_reset() {
	cycle_base = 0;
	write_sequence = 0;
	play_sequence = 0;
	dmc_sequence = 0;
	// Nsf_Emu::start_track_ resets the NTSC APU, then performs these two host
	// setup writes before the ROM's INIT code starts running.
	write_bootstrap(0x4015, 0x0F);
	write_bootstrap(0x4017, 0x00);
}

void ct2_trace_apu_write(int32_t local_cycle, uint16_t address, int value, uint8_t origin) {
	if (apu_file == nullptr) {
		return;
	}
	const uint64_t absolute_cycle = cycle_base + static_cast<uint32_t>(local_cycle);
	const char* source = origin == 0 ? "cpu_bus" : "nsf_bootstrap";
	std::fprintf(apu_file, "%u,%llu,%d,$%04X,$%02X,%s\n",
		write_sequence++, static_cast<unsigned long long>(absolute_cycle), local_cycle,
		address, static_cast<unsigned>(value & 0xFF), source);
}

void ct2_trace_play_call(int32_t local_cycle) {
	if (play_file == nullptr) {
		return;
	}
	const uint64_t absolute_cycle = cycle_base + static_cast<uint32_t>(local_cycle);
	std::fprintf(play_file, "%u,%llu,%d\n", play_sequence++,
		static_cast<unsigned long long>(absolute_cycle), local_cycle);
}

void ct2_trace_dmc_fetch(int32_t local_cycle, uint16_t address, int value) {
	if (dmc_file == nullptr) {
		return;
	}
	const uint64_t absolute_cycle = cycle_base + static_cast<uint32_t>(local_cycle);
	std::fprintf(dmc_file, "%u,%llu,%d,$%04X,$%02X\n",
		dmc_sequence++, static_cast<unsigned long long>(absolute_cycle), local_cycle,
		address, static_cast<unsigned>(value & 0xFF));
}

void ct2_trace_end_frame(int32_t local_cycles) {
	cycle_base += static_cast<uint32_t>(local_cycles);
}
