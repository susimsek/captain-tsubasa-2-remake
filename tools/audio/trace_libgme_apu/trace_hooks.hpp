#pragma once

#include <cstdint>

// Build-only trace hooks injected into a temporary Game_Music_Emu 0.6.5 tree.
// These functions write register/timing metadata only; they never serialize PCM.
void ct2_trace_open(const char* apu_csv_path, const char* play_csv_path, const char* dmc_csv_path);
void ct2_trace_close();
void ct2_trace_reset();
void ct2_trace_apu_write(int32_t local_cycle, uint16_t address, int value, uint8_t origin);
void ct2_trace_play_call(int32_t local_cycle);
void ct2_trace_dmc_fetch(int32_t local_cycle, uint16_t address, int value);
void ct2_trace_end_frame(int32_t local_cycles);
