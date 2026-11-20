#!/usr/bin/env python3
"""Extract hash-pinned ROM inputs for the first bank-$18 worker prefix."""

from __future__ import annotations

import hashlib
import json
import pathlib
import sys


ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUT = pathlib.Path("reference/rom_extract/gameplay/fresh_bank18_worker_prefix")
SPANS = [
    ("bank18_worker_entry_to_yield_call_800C_8889.bin", 0x18, 0x800C, 0x8889, "low",
     "ROM-byte bank-$18 worker body from `$800C` through its `$C515` yield call."),
    ("bank19_worker_lookup_B3BD_B3D1.bin", 0x19, 0xB3BD, 0xB3D1, "high",
     "ROM descriptor lookup table prefix used by the worker."),
    ("bank19_pass_receiver_descriptor_pointer_B3ED_B3EF.bin", 0x19, 0xB3ED, 0xB3EF, "high",
     "Descriptor-$0F pointer-table entry selected by the worker's bank-$19 `$B3CF,X` lookup; points to `$B58D`."),
    ("bank19_pass_receiver_descriptor_0F_B58D_B5A2.bin", 0x19, 0xB58D, 0xB5A2, "high",
     "ROM descriptor `$0F` header and three row records used by the PASS receiver prompt."),
    ("bank19_pass_receiver_row00_BBED_BBEE.bin", 0x19, 0xBBED, 0xBBEE, "high",
     "Descriptor-$0F blank first text row and its ROM `$FC` terminator."),
    ("bank19_pass_receiver_row01_BBF4_BBFB.bin", 0x19, 0xBBF4, 0xBBFB, "high",
     "Descriptor-$0F center text row and terminator; row 2 points at the same final `$FC` byte at `$BBFA`."),
    ("fixed_pass_receiver_handler_D7E8_D8F7.bin", 0x1E, 0xD7E8, 0xD8F7, "fixed",
     "ROM PASS handler, including `$D7ED LDA #$0F; JSR $EF7F` and the `$D7F2` caller continuation."),
    ("fixed_task_yield_trampoline_C515_C518.bin", 0x1E, 0xC515, 0xC518, "fixed",
     "ROM task-yield trampoline entered by the worker's `$8886` call."),
    ("bank19_descriptor30_pointer_B42F_B431.bin", 0x19, 0xB42F, 0xB431, "high",
     "Little-endian descriptor-$30 pointer selected by the ROM worker's `$B3CF,X` lookup."),
    ("bank19_descriptor30_B8DE_B8EF.bin", 0x19, 0xB8DE, 0xB8EF, "high",
     "Descriptor-$30 header and its two ROM row records."),
    ("bank19_descriptor30_row_BE59_BE63.bin", 0x19, 0xBE59, 0xBE63, "high",
     "Descriptor-$30 row stream at `$BE59`, including its ROM `$FC` terminator."),
    ("bank19_descriptor30_row_BE6D_BE6F.bin", 0x19, 0xBE6D, 0xBE6F, "high",
     "Descriptor-$30 row stream at `$BE6D`, including its ROM `$FC` terminator."),
    ("bank18_dynamic_window_data_8DB9_8DC3.bin", 0x18, 0x8DB9, 0x8DC3, "low",
     "Ten bytes read by the live indexed window-packet loads at `$8931/$8937/$8943` for observed X `$1B/$1E/$21`."),
    ("bank18_callback_pointer_89E2_89E4.bin", 0x18, 0x89E2, 0x89E4, "low",
     "ROM callback pointer consumed by `$CBA2`; selects bank-$18 handler `$8BEA`."),
    ("bank18_dynamic_text_dispatch_89FA_8A56.bin", 0x18, 0x89FA, 0x8A56, "low",
     "ROM dynamic player-line entry stubs and shared dispatch code through `$8A56`."),
    ("bank18_callback_window_entry_8BEA_8BF0.bin", 0x18, 0x8BEA, 0x8BF0, "low",
     "ROM callback entry that reads `$0441` and jumps into `$8D1A`."),
    ("bank18_callback_window_body_8D1A_8D9E.bin", 0x18, 0x8D1A, 0x8D9E, "low",
     "Callback body and inline lookup/data table reached from `$8BEA`; ends before the `$8D9E` tile table."),
    ("fixed_record_pointer_vector_C50C_C50F.bin", 0x1E, 0xC50C, 0xC50F, "fixed",
     "Fixed-bank vector used by the callback to invoke the player-record pointer resolver."),
    ("fixed_record_pointer_slot_transform_CD77_CD7C.bin", 0x1E, 0xCD77, 0xCD7C, "fixed",
     "ROM slot-to-record-index transform called at `$E21D`; falls through into the `$CD7C` pointer resolver."),
    ("fixed_stamina_evaluator_helper_CE08_CE2D.bin", 0x1E, 0xCE08, 0xCE2D, "fixed",
     "Complete ROM evaluator wrapper called by live `$E2D3`; switches to match-stat banks, invokes `$8000`, then restores the caller banks."),
    ("fixed_stamina_bank_switch_CE2D_CE4A.bin", 0x1E, 0xCE2D, 0xCE4A, "fixed",
     "ROM mapper helper called by `$CE08`; selects and restores the two switchable PRG banks from RAM `$24/$25`."),
    ("bank1c_stamina_evaluator_vector_8000_8003.bin", 0x1C, 0x8000, 0x8003, "low",
     "ROM bank-$1C entry vector selected by `$CE08`; jumps to the stamina evaluator at `$802D`."),
    ("bank1c_stamina_evaluator_802D_818E.bin", 0x1C, 0x802D, 0x818E, "low",
     "ROM evaluator reached through `$CE08->$CE2D->$8000`; computes the selected player stat from banked ROM tables."),
    ("bank1c_stamina_profile_pointer_addends_8199_819D.bin", 0x1C, 0x8199, 0x819D, "low",
     "ROM addend bytes read by the evaluator's `$8199,Y` and `$819A,Y` instructions on the live player-record path."),
    ("bank1c_player_profile_selector_map_95D6_9662.bin", 0x1C, 0x95D6, 0x9662, "low",
     "ROM low-ID player-to-stat-profile map read by the bank-$1C evaluator through the `$95D6` pointer."),
    ("bank1c_stamina_energy_values_9F0E_9FCE.bin", 0x1C, 0x9F0E, 0x9FCE, "low",
     "ROM little-endian stamina/energy values read by the source-derived evaluator."),
    ("bank1c_player_stat_profiles_9FCE_A000.bin", 0x1C, 0x9FCE, 0xA000, "low",
     "First bank window of the ROM's 141 player stat profiles, 24 bytes per profile."),
    ("bank1d_player_stat_profiles_A000_AD06.bin", 0x1D, 0xA000, 0xAD06, "high",
     "Second bank window of the ROM's 141 player stat profiles, 24 bytes per profile."),
    ("bank1d_stamina_profile_values_AE86_AFAE.bin", 0x1D, 0xAE86, 0xAFAE, "high",
     "ROM shared profile values read by the common stamina/stat evaluator branch."),
    ("fixed_record_pointer_resolver_CD7C_CD89.bin", 0x1E, 0xCD7C, 0xCD89, "fixed",
     "ROM routine that resolves a selected player-record pointer from its slot index."),
    ("fixed_field_ratio_vector_C521_C524.bin", 0x1E, 0xC521, 0xC524, "fixed",
     "ROM vector `$C521 JMP $CD0D` reached by the live bank-$1A field-coordinate helper."),
    ("fixed_field_ratio_helper_CD0D_CD3C.bin", 0x1E, 0xCD0D, 0xCD3C, "fixed",
     "ROM 16-iteration bitwise ratio helper called through `$C521`; uses live zero-page `$67-$6E` and returns at `$CD3B`."),
    ("fixed_field_clock_vector_C603_C606.bin", 0x1E, 0xC603, 0xC606, "fixed",
     "ROM vector `$C603 JMP $D193` reached by the live field update after `$90E3`."),
    ("fixed_field_frame_entry_prefix_E074_E07E.bin", 0x1F, 0xE074, 0xE07E, "fixed",
     "ROM field-frame entry prefix reached through `$C606->$E074`; branches on `$05FF`, initializes `$062A`, then reaches the separately pinned `$E07E` callsite."),
    ("fixed_field_input_vector_C606_C609.bin", 0x1E, 0xC606, 0xC609, "fixed",
     "ROM vector `$C606 JMP $E074` reached by the live bank-$1A field update callsite `$80ED`."),
    ("fixed_record_pointer_table_CD89_CDB5.bin", 0x1E, 0xCD89, 0xCDB5, "fixed",
     "22-entry ROM table of little-endian player-record pointers consumed by `$CD7C`."),
    ("fixed_callback_string_pointer_F339_F33B.bin", 0x1F, 0xF339, 0xF33B, "fixed",
     "Selected little-endian callback string pointer consumed by ROM lookup `$F30F` for live index `$08`."),
    ("fixed_callback_string_pointer_F33F_F341.bin", 0x1F, 0xF33F, 0xF341, "fixed",
     "Selected little-endian player-name pointer entry `$0B` read by ROM lookup `$F30F` on the live PASS receiver path."),
    ("fixed_callback_text_F52B_F530.bin", 0x1F, 0xF52B, 0xF530, "fixed",
     "Four live ROM text bytes followed by the `$FC` callback terminator selected by the `$F339` pointer."),
    ("fixed_callback_text_F53A_F53F.bin", 0x1F, 0xF53A, 0xF53F, "fixed",
     "ROM player-name stream selected by live pointer entry `$F33F`, including its `$FC` terminator."),
    ("fixed_team_03_name_stream_F785_F789.bin", 0x1F, 0xF785, 0xF789, "fixed",
     "ROM team-ID-3 name stream selected through `$002B=3`; `$ED` emits its three source characters."),
    ("bank18_dynamic_player_line_8CA5_8D1A.bin", 0x18, 0x8CA5, 0x8D1A, "low",
     "ROM player-line position/name emitters and the inline `$8D04` position table."),
    ("fixed_holder_coordinate_copy_E6EC_E709.bin", 0x1F, 0xE6EC, 0xE709, "fixed",
     "ROM holder-coordinate copy routine reached by the source-selected menu/player path."),
    ("fixed_holder_coordinate_index_CDE2_CE08.bin", 0x1E, 0xCDE2, 0xCE08, "fixed",
     "ROM helper called by `$E6EC` to map the selected holder's coordinates to a field index."),
    ("fixed_field_action_vector_C61E_C621.bin", 0x1E, 0xC61E, 0xC621, "fixed",
     "ROM dispatch vector selected by the bank-$1A PASS-result caller at `$8107`; jumps to `$E059`."),
    ("fixed_field_pass_result_E059_E074.bin", 0x1F, 0xE059, 0xE074, "fixed",
     "ROM PASS-result helper reached through `$C61E`; resolves the active record and stores its field index before RTS to `$810A`."),
    ("fixed_field_pass_result_index_DF8B_DFBD.bin", 0x1E, 0xDF8B, 0xDFBD, "fixed",
     "ROM field-distance/index helper called from the `$DE52` result handler; ends at its natural RTS."),
    ("fixed_field_pass_result_index_table_DFBD_DFD1.bin", 0x1E, 0xDFBD, 0xDFD1, "fixed",
     "ROM 20-byte field-distance lookup read by `$DF8B` at `$DFB6,X`; excludes the following code at `$DFD1`."),
    ("fixed_field_action_handler_vector_C612_C615.bin", 0x1E, 0xC612, 0xC615, "fixed",
     "ROM action-handler dispatch vector selected after the `$8107` PASS-result setup; jumps to `$DE52`."),
    ("fixed_field_pass_result_handler_DE52_DE80.bin", 0x1E, 0xDE52, 0xDE80, "fixed",
     "ROM fixed bank-$1E PASS-result handler entry and first caller continuation through `$DE7F`."),
    ("fixed_field_pass_result_tail_DE80_DE96.bin", 0x1E, 0xDE80, 0xDE96, "fixed",
     "ROM PASS-result success tail: restores `$1A/$1B`, calls `$801E`, queues scenario `$1C`, resets SP, and jumps `$E0DF`; excludes the unresolved `$DE96` failure branch."),
    ("fixed_field_pass_result_helper_return_CE6D_CE6E.bin", 0x1E, 0xCE6D, 0xCE6E, "fixed",
     "ROM `$CE6D RTS` byte reached by the PASS-result holder-coordinate helper path; the next source span begins at `$CE6E`."),
    ("fixed_C624_dispatch_vectors_C624_C64E.bin", 0x1E, 0xC624, 0xC64E, "fixed",
     "ROM fourteen-entry fixed-bank dispatch vector table; scenario-$18 pass-result caller reaches vector zero and `$DCDF`."),
    ("fixed_C624_vector0_target_DCDF_DCF0.bin", 0x1E, 0xDCDF, 0xDCF0, "fixed",
     "ROM helper called by the scenario-$18 `$8188` caller; initializes `$044E` from `$00E2` only when its input is zero."),
    ("fixed_field_loop_input_E349_E3CA.bin", 0x1F, 0xE349, 0xE3CA, "fixed",
     "ROM field-input routine called from `$E14A`; contains neutral-loop handling and the source B-button transition into the first match menu."),
    ("fixed_field_loop_caller_E407_E4D7.bin", 0x1F, 0xE407, 0xE4D7, "fixed",
     "ROM caller tail after `$E3CA`; handles repeated field input, held-B scenario dispatch, and the bank-$1A menu jump."),
    ("fixed_field_input_coordinate_scan_E4D7_E54C.bin", 0x1F, 0xE4D7, 0xE54C, "fixed",
     "ROM field-input continuation reached after `$E4D7`, including the `$E501` coordinate-threshold helper and its increment/RTS tail through `$E54B`."),
    ("bank1a_field_update_vector_8000_8003.bin", 0x1A, 0x8000, 0x8003, "low",
     "ROM bank-$1A vector called by the `$E44A` field-loop branch; jumps to bank-$1B `$A103`."),
    ("bank1a_field_update_worker_vector_8033_8036.bin", 0x1A, 0x8033, 0x8036, "low",
     "ROM dispatch vector called from the fixed-bank field-input routine at `$E22D`; jumps to bank-$1A `$8E86`."),
    ("bank1a_field_update_dispatch_8E86_8EE9.bin", 0x1A, 0x8E86, 0x8EE9, "low",
     "ROM field-input dispatcher reached through `$8033`; includes its source conditional path and `$8EE8` return."),
    ("bank1b_field_update_A103_A1EB.bin", 0x1B, 0xA103, 0xA1EB, "high",
     "ROM field-update routine reached through bank-$1A `$8000`, including its indexed `$A1DC` lookup bytes."),
    ("bank1b_field_update_pointers_A6AD_A6B5.bin", 0x1B, 0xA6AD, 0xA6B5, "high",
     "ROM's four little-endian field-update table pointers selected by `$A103` for the recorded ordinary-input path."),
    ("bank1b_field_update_table0_row02_A6DD_A6F1.bin", 0x1B, 0xA6DD, 0xA6F1, "high",
     "Twenty-byte ROM field-update table row reached by the live ordinary-input route at `$A185` through pointer `$A6B5` plus row offset `$28`."),
    ("bank1b_field_update_table0_row12_A7A5_A7B9.bin", 0x1B, 0xA7A5, 0xA7B9, "high",
     "Complete 20-byte ROM field-update table row selected by the recorded route at `$A185` (table 0, row 12)."),
    ("bank1b_field_update_pointer_cell_AB65_AB67.bin", 0x1B, 0xAB65, 0xAB67, "high",
     "ROM little-endian field-update table pointer read by the recorded route at `$A172/$A176` for index zero."),
    ("bank1b_field_update_data_row02_ABA5_ABB9.bin", 0x1B, 0xABA5, 0xABB9, "high",
     "Complete 20-byte ROM field-update row selected by the recorded route through pointer `$AB7D`."),
    ("bank1b_field_update_data_row12_AC6D_AC81.bin", 0x1B, 0xAC6D, 0xAC81, "high",
     "Twenty-byte ROM field-update table row reached by the live ordinary-input route at `$A185`; pointer `$AB7D` plus row offset `$F0`."),
    ("fixed_field_update_stamina_vector_C527_C52A.bin", 0x1E, 0xC527, 0xC52A, "fixed",
     "ROM vector reached by the live `$A1A6` call; jumps to the already decoded `$CE08` stamina evaluator."),
    ("bank1d_stamina_lookup_index00_AFB2_AFB4.bin", 0x1D, 0xAFB2, 0xAFB4, "high",
     "ROM stamina lookup word read by the recorded route for evaluator index `$00`."),
    ("bank1d_stamina_lookup_index00_offset02_AFB4_AFB6.bin", 0x1D, 0xAFB4, 0xAFB6, "high",
     "Second ROM 16-bit lookup word read by the live `$8171 LDA ($32),Y` evaluator when its indexed pointer reaches `$AFB4`."),
    ("bank1d_stamina_lookup_index00_selector1F_AFAE_AFB0.bin", 0x1D, 0xAFAE, 0xAFB0, "high",
     "ROM stamina lookup word read for record index `$00` and selector `$1F` on the recorded route."),
    ("bank1d_stamina_lookup_index01_AFBE_AFC0.bin", 0x1D, 0xAFBE, 0xAFC0, "high",
     "ROM stamina lookup word read by the recorded route for evaluator index `$01`."),
    ("bank1d_stamina_lookup_index03_AFD6_AFD8.bin", 0x1D, 0xAFD6, 0xAFD8, "high",
     "ROM stamina lookup word read by the recorded route for evaluator index `$03`."),
    ("bank1d_stamina_lookup_index04_AFE2_AFE4.bin", 0x1D, 0xAFE2, 0xAFE4, "high",
     "ROM stamina lookup word read by the recorded route for evaluator index `$04`."),
    ("bank1d_stamina_lookup_index06_AFFA_AFFC.bin", 0x1D, 0xAFFA, 0xAFFC, "high",
     "ROM stamina lookup word read by the recorded route for evaluator index `$06`."),
    ("bank1d_stamina_lookup_index07_B006_B008.bin", 0x1D, 0xB006, 0xB008, "high",
     "ROM stamina lookup word read by the recorded route for evaluator index `$07`."),
    ("bank1c_stamina_index_map_818F_8199.bin", 0x1C, 0x818F, 0x8199, "low",
     "Complete 10-byte ROM stamina-index mapping table indexed by `$804A`; the separate pointer-addend table starts at `$8199`."),
    ("bank1c_stamina_profile_records_9A52_9A6A.bin", 0x1C, 0x9A52, 0x9A6A, "low",
     "Two consecutive 12-byte ROM evaluator records selected through the live `$32/$33` pointer; the recorded route reads both rows."),
    ("bank1d_evaluator_record_row_BAF6_BB00.bin", 0x1D, 0xBAF6, 0xBB00, "high",
     "Complete 10-byte ROM evaluator record selected by the source-generated pointer; the recorded route reads fields at `$BAF9` onward."),
    ("fixed_field_coordinate_update_tail_E800_E854.bin", 0x1F, 0xE800, 0xE854, "fixed",
     "Continuation of the ROM field-coordinate routine beginning at `$E7D0`; ends at its RTS before `$E854`."),
    ("fixed_coordinate_magnitude_thresholds_FACC_FB4C.bin", 0x1F, 0xFACC, 0xFB4C, "fixed",
     "Complete 64-entry little-endian magnitude-threshold table scanned by the live `$E82B` coordinate routine."),
    ("fixed_field_record_helper_vectors_C536_C53C.bin", 0x1E, 0xC536, 0xC53C, "fixed",
     "ROM vectors used by the `$A103` field-record updater to call the `$CDC9` and `$CDE2` helpers."),
    ("bank1a_field_context_dispatch_call_8047_804F.bin", 0x1A, 0x8047, 0x804F, "low",
     "Observed bank-$1A field-context dispatch callsite: `$8047 LDA #$02; JSR $C54B; JSR $8F72`."),
    ("fixed_field_context_dispatch_vector_C54B_C54E.bin", 0x1E, 0xC54B, 0xC54E, "fixed",
     "ROM fixed-bank vector `$C54B JMP $CE6E` reached by the source field-context caller."),
    ("fixed_action_scenario_queue_vector_C54E_C551.bin", 0x1E, 0xC54E, 0xC551, "fixed",
     "ROM fixed-bank vector `$C54E JMP $CBB0` reached by the live bank-$1C `$801E` action path."),
    ("fixed_field_context_bank_switch_and_indirect_CE6E_CE99.bin", 0x1E, 0xCE6E, 0xCE99, "fixed",
     "ROM bank-context helper that temporarily maps `$1C/$1D`, dispatches through `$0036`, restores caller banks, then returns through `$CE2D`."),
    ("bank1c_field_context_dispatch_vector_8006_8009.bin", 0x1C, 0x8006, 0x8009, "low",
     "ROM bank-$1C selector vector `$8006 JMP $8609` chosen by field-context index `$02`."),
    ("bank1c_field_context_empty_record_branch_8609_863F.bin", 0x1C, 0x8609, 0x863F, "low",
     "Observed ROM handler branch for `$05FB=$00` and `$0600=$00`; skips the unobserved `$875D` path and returns at `$863E`."),
    ("bank1c_field_action_parameter_vector_8012_8015.bin", 0x1C, 0x8012, 0x8015, "low",
     "ROM bank-$1C vector `$8012 JMP $819D` selected by the live field-context caller with A=`$06`."),
    ("bank1c_field_action_secondary_vector_801E_8021.bin", 0x1C, 0x801E, 0x8021, "low",
     "ROM bank-$1C action vector `$801E JMP $846A` reached by the live PASS-result caller."),
    ("bank1c_field_action_secondary_handler_846A_84C1.bin", 0x1C, 0x846A, 0x84C1, "low",
     "ROM bank-$1C `$801E` target and reached `$8499` helper, including the `$8BBE` lookup path and natural returns."),
    ("bank1c_field_action_secondary_lookup_8BBE_8C1E.bin", 0x1C, 0x8BBE, 0x8C1E, "low",
     "ROM bank-$1C paired lookup values read by the `$8499` helper reached from `$846A`."),
    ("bank1c_field_action_parameters_819D_8298.bin", 0x1C, 0x819D, 0x8298, "low",
     "ROM field action-parameter routine reached through `$8F72->$C54B->$8012`; executes its live RAM-selected branch and returns through `$CE2D`."),
    ("bank1c_field_action_parameter_pointer_table_9460_9468.bin", 0x1C, 0x9460, 0x9468, "low",
     "Four little-endian parameter pointers selected by the `$819D` field-action routine using live `$043B`."),
    ("bank1c_field_action_parameter_record_9500_9505.bin", 0x1C, 0x9500, 0x9505, "low",
     "Five-byte ROM parameter record selected by the live `$9462/$9463` pointer when `$043B=$01`; consumed through `$0032/$0033` at `$81DF-$81EE`."),
    ("fixed_field_record_index_CDC9_CDE2.bin", 0x1E, 0xCDC9, 0xCDE2, "fixed",
     "ROM coordinate/index helper reached by the `$C536` vector during the recorded neutral field update."),
    ("fixed_oam_hide_CB8B_CB99.bin", 0x1E, 0xCB8B, 0xCB99, "fixed",
     "ROM routine called by field scenario `$44` to write the 64 hidden-sprite Y values before the mapper handoff."),
    ("fixed_field_coordinate_update_E709_E800.bin", 0x1F, 0xE709, 0xE800, "fixed",
     "ROM field-coordinate/status updater called at the head of the live `$E407` input loop, including the reached actor-coordinate helper and continuation bytes."),
    ("fixed_field_update_callsite_E07E_E081.bin", 0x1F, 0xE07E, 0xE081, "fixed",
     "ROM `$E07E` JSR callsite reached after the bank-$1A field-update continuation; returns to `$E081`."),
    ("fixed_pass_waiter_caller_E081_E0DE.bin", 0x1F, 0xE081, 0xE0DF, "fixed",
     "ROM PASS input-wait caller body used to stop the bank-$1A outer caller at its `$E0D1` source continuation before resuming the bounded E081 executor."),
    ("fixed_field_neutral_update_E854_E980.bin", 0x1F, 0xE854, 0xE980, "fixed",
     "ROM field-loop no-direction continuation called from `$E48F`; includes its coordinate comparison helpers and inline thresholds."),
    ("fixed_coordinate_transform_CE4A_CE6C.bin", 0x1E, 0xCE4A, 0xCE6C, "fixed",
     "ROM signed coordinate/ratio helper called by the live field update path."),
    ("fixed_coordinate_ratio_table_FB4C_FBCC.bin", 0x1F, 0xFB4C, 0xFBCC, "fixed",
     "ROM lookup values indexed by the `$CE4A` coordinate transform."),
    ("bank1c_field_event_vector_800F_8012.bin", 0x1C, 0x800F, 0x8012, "low",
     "ROM bank-$1C vector selected by the live field update routine's `$800F` call."),
    ("bank1c_field_event_handler_8DA6_8E20.bin", 0x1C, 0x8DA6, 0x8E20, "low",
     "ROM field event handler reached through bank-$1C vector `$800F`; includes the reached helper calls and inline dispatch table."),
    ("fixed_shared_waiter_CC46_CCD2.bin", 0x1E, 0xCC46, 0xCCD2, "fixed",
     "ROM fixed-bank wait and PPU-packet helper entered from the scenario-$44 field update; includes its `$CB0F` yield sites."),
    ("fixed_action_context_tables_D700_D70C.bin", 0x1E, 0xD700, 0xD70C, "fixed",
     "ROM fixed-bank action-window and player-status descriptor indices used by the first in-match command menu."),
    ("bank19_action_menu_descriptor_pointers_B3D3_B3D7.bin", 0x19, 0xB3D3, 0xB3D7, "high",
     "ROM bank-$19 pointers selected by the first in-match Action and player-status menu contexts."),
    ("bank19_action_menu_descriptor_02_B47D_B48A.bin", 0x19, 0xB47D, 0xB48A, "high",
     "ROM descriptor `$02` selected by the first in-match Action menu context."),
    ("bank19_action_menu_descriptor_03_B48A_B4A7.bin", 0x19, 0xB48A, 0xB4A7, "high",
     "ROM descriptor `$03` selected by the first in-match player-status panel context."),
    ("bank19_action_menu_row_02_00_BBE6_BBEE.bin", 0x19, 0xBBE6, 0xBBEE, "high",
     "ROM text row for the initial Action menu descriptor `$02`."),
    ("bank19_action_menu_row_03_00_BC21_BC23.bin", 0x19, 0xBC21, 0xBC23, "high",
     "ROM dynamic player-name row token for the initial status panel descriptor `$03`."),
    ("bank19_action_menu_row_03_01_BC23_BC2E.bin", 0x19, 0xBC23, 0xBC2E, "high",
     "ROM Energy label and dynamic stat token for status panel descriptor `$03`."),
    ("bank19_action_menu_row_03_02_BC2E_BC39.bin", 0x19, 0xBC2E, 0xBC39, "high",
     "ROM Calım label and dynamic stat token for status panel descriptor `$03`."),
    ("bank19_action_menu_row_03_03_BC39_BC44.bin", 0x19, 0xBC39, 0xBC44, "high",
     "ROM Pas label and dynamic stat token for status panel descriptor `$03`."),
    ("bank19_action_menu_row_03_04_BC44_BC4F.bin", 0x19, 0xBC44, 0xBC4F, "high",
     "ROM Sut label and dynamic stat token for status panel descriptor `$03`."),
    ("bank1c_player_stat_value_curve_9E4E_9F0E.bin", 0x1C, 0x9E4E, 0x9F0E, "low",
     "ROM player-stat value curve indexed by the live status-panel renderer for Energy, Calım, Pas, and Sut values."),
]


def file_offset(bank: int, start: int, window: str) -> int:
    if window == "fixed":
        return (0x3C010 + start - 0xC000) if start < 0xE000 else (0x3E010 + start - 0xE000)
    if window == "low":
        return 0x10 + bank * 0x2000 + start - 0x8000
    return 0x10 + bank * 0x2000 + start - 0xA000


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: extract_rom_fresh_bank18_worker_prefix_sources.py <supplied-rom.nes>", file=sys.stderr)
        return 2
    rom_path = pathlib.Path(sys.argv[1])
    rom = rom_path.read_bytes()
    rom_hash = hashlib.sha256(rom).hexdigest()
    if rom_hash != ROM_SHA256:
        raise SystemExit(f"ROM hash mismatch: {rom_hash}")
    OUT.mkdir(parents=True, exist_ok=True)
    manifest_path = OUT / "manifest.json"
    existing_manifest = {}
    if manifest_path.exists():
        existing_manifest = json.loads(manifest_path.read_text())
        if existing_manifest.get("schema") != "ct2-fresh-bank18-worker-prefix-source-v1" \
                or existing_manifest.get("rom_sha256") != ROM_SHA256:
            raise SystemExit("existing worker manifest targets a different schema or ROM")
    spans_by_file = {
        span["file"]: span for span in existing_manifest.get("spans", [])
        if isinstance(span, dict) and isinstance(span.get("file"), str)
        and span["file"] not in {
            "bank1b_field_update_pointer_table_A6AD_A6D9.bin",
            "bank1b_field_update_tables_A6AD_AB65.bin",
            "fixed_field_update_indirect_byte_E2C0_E2C1.bin",
            "bank1b_field_update_table0_row12_col00_A7A5_A7A6.bin",
            "bank1b_field_update_table0_row12_col03_A7A8_A7A9.bin",
            "bank1d_stamina_lookup_word_AFB2_AFB4.bin",
            "bank1d_stamina_lookup_row_01_AFBA_AFC6.bin",
            "bank1d_stamina_lookup_rows_00_04_AFAE_AFEA.bin",
            "bank1b_field_update_index00_data_cell_ABA5_ABA6.bin",
            "bank1c_stamina_index_map_cell_818F_8190.bin",
            "bank1c_stamina_index_map_cell_8190_8191.bin",
            "bank1d_evaluator_record_cell_BAF9_BAFA.bin",
            "bank1c_stamina_lookup_cell_9A55_9A56.bin",
            "bank1c_stamina_record_index_cell_9A53_9A54.bin",
            "bank1a_field_update_dispatch_8E86_8EE7.bin",
        }
    }
    for obsolete_file in (
        "bank1b_field_update_pointer_table_A6AD_A6D9.bin",
        "bank1b_field_update_tables_A6AD_AB65.bin",
        "fixed_field_update_indirect_byte_E2C0_E2C1.bin",
        "bank1b_field_update_table0_row12_col00_A7A5_A7A6.bin",
        "bank1b_field_update_table0_row12_col03_A7A8_A7A9.bin",
        "bank1d_stamina_lookup_word_AFB2_AFB4.bin",
        "bank1d_stamina_lookup_row_01_AFBA_AFC6.bin",
        "bank1d_stamina_lookup_rows_00_04_AFAE_AFEA.bin",
        "bank1b_field_update_index00_data_cell_ABA5_ABA6.bin",
        "bank1c_stamina_index_map_cell_818F_8190.bin",
        "bank1c_stamina_index_map_cell_8190_8191.bin",
        "bank1d_evaluator_record_cell_BAF9_BAFA.bin",
        "bank1c_stamina_lookup_cell_9A55_9A56.bin",
        "bank1c_stamina_record_index_cell_9A53_9A54.bin",
        "bank1a_field_update_dispatch_8E86_8EE7.bin",
    ):
        (OUT / obsolete_file).unlink(missing_ok=True)
    spans = []
    for name, bank, start, end, window, description in SPANS:
        offset = file_offset(bank, start, window)
        data = rom[offset : offset + end - start]
        if len(data) != end - start:
            raise SystemExit(f"short extraction for {name}")
        (OUT / name).write_bytes(data)
        spans.append(
            {
                "file": name,
                "bank": f"0x{bank:02X}",
                "window": window,
                "cpu_start": f"0x{start:04X}",
                "cpu_end_exclusive": f"0x{end:04X}",
                "file_offset": f"0x{offset:06X}",
                "length": len(data),
                "sha256": hashlib.sha256(data).hexdigest(),
                "description": description,
                "bytes": data.hex(" "),
            }
        )
    spans_by_file.update({span["file"]: span for span in spans})
    manifest = dict(existing_manifest)
    manifest.update({
        "schema": "ct2-fresh-bank18-worker-prefix-source-v1",
        "rom_sha256": ROM_SHA256,
        "mapping": "iNES PRG starts at 0x0010; fixed $C000-$DFFF is bank $1E; switchable $8000 and $A000 windows use the source MMC3 low/high bank pair.",
        "scope": "Hash-pinned ROM spans support the fresh match-zero field worker and confirmed PASS receiver route, including the `$D70F->$D568->$E07E->$E081` waiter caller and its bounded helper/data dependencies. Production consumers stop at verified scheduler, call, and yield boundaries; trace captures remain validation-only.",
        "spans": list(spans_by_file.values()),
    })
    limitations = manifest.get("limitations", [])
    for limitation in [
        "CPU/RAM/stack/mapper entry state must be produced by the preceding ROM-source component; this package does not consume trace snapshots.",
        "This component does not execute $C515/$CB0F, task save/resume, scheduler scans, or NMI-ready cadence.",
        "Trace artifacts are validation evidence only and are not packaged as runtime inputs.",
        "The PASS descriptor-$0F worker step is bounded at its first `$8886->$C515` call; it does not claim the asynchronous renderer returned to `$D7F2`.",
        "At the first `$C515` yield, the worker has read descriptor pointer `$B3ED->$B58D` into zero page `$50/$51`; a separately bounded worker continuation from an explicitly labeled yielded-RTS restore executes the descriptor header and blank row `$BBED`, then stages two 24-byte nametable records at `$04A5/$04C0` for `$2228/$2248`.",
        "The `$8889` continuation is not live scheduler/NMI integration unless supplied with an observed scheduler boundary; its focused verifier uses a synthetic restore fixture. The descriptor text row `$BBF4` is not fetched, NMI does not consume the staged records, no PPU application is claimed, and the renderer does not return to `$D7F2`.",
        "For the first PASS route, the same-ROM FCEUX trace records `$A103` at frame 9088 but has no direct PC hook at `$E0AB`, `$CE08`, or `$8171`; those caller/helper steps are established from ROM bytes and production-route execution, not direct trace events.",
        "Only the two-byte bank-$1D lookup word `$AFB4-$AFB5` reached by the evaluator's indexed indirect read is added here; adjacent words in the broader `$AFB2-$AFBD` row are not implied by this span.",
    ]:
        if limitation not in limitations:
            limitations.append(limitation)
    limitations = [limitation for limitation in limitations if limitation !=
        "At that first-yield boundary, the worker reads descriptor pointer `$B3ED->$B58D` into zero page `$50/$51`; descriptor body and text rows `$BBED/$BBF4/$BBFA` are hash-pinned here but are not fetched until a later worker resume."]
    manifest["limitations"] = limitations
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Extracted {len(spans)} spans; preserved {len(spans_by_file)} manifest entries in {OUT}")
    for span in spans:
        print(f"{span['cpu_start']}-{span['cpu_end_exclusive']}: {span['length']} bytes sha256={span['sha256']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
