extends RefCounted
class_name RomFreshBank18WorkerPrefix
## Source-byte execution from bank-$18:$800C to the first worker's $C515
## yield-trampoline entry. The task-save handler and scheduler are out of scope.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const PASS_WAITER_MANIFEST_SHA256 := "a5222fd8d3573e27fb2f530ea9c9baebe9eeb091f26a52ae9f861f8dd9a4f403"
const SOURCE_ROOT := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/"
const MANIFEST_PATH := SOURCE_ROOT + "manifest.json"
const RAM_SIZE := 0x800
const STACK_PAGE_SIZE := 0x100
const ENTRY_PC := 0x800C
const ENTRY_BANK := 0x18
const END_PC := 0xC515
const END_BANK := 0x1E
const PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_PATH := "res://reference/rom_extract/gameplay/menus/pass_receiver_down_menu/manifest.json"
const PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_SHA256 := "a992da14cb1ed1aede98098928a1f496949ab0927b479190e393cc8883d0a7aa"
const PASS_RECEIVER_DESCRIPTOR_1D_RESOURCE_ROOT := "res://reference/rom_extract/gameplay/menus/pass_receiver_down_menu/"
const PASS_RECEIVER_INPUT_MANIFEST_PATH := "res://reference/rom_extract/gameplay/pass_receiver_input/manifest.json"
const PASS_RECEIVER_INPUT_MANIFEST_SHA256 := "ddd9f9841da3dc79c36644a3f5baf58508c0acf35733e360e8cd2758132be510"
const PASS_RECEIVER_INPUT_RESOURCE_ROOT := "res://reference/rom_extract/gameplay/pass_receiver_input/"
const PASS_RECEIVER_SCAN_RETURN_PC := 0xD96F
const PASS_RECEIVER_SCAN_RETURN_TARGET := 0xD837
const SOURCE_FILES := {
	"bank18_worker_entry_to_yield_call_800C_8889.bin": {"bank": 0x18, "start": 0x800C, "end": 0x8889},
	"bank18_worker_resume_8889_89D7.bin": {"bank": 0x18, "start": 0x8889, "end": 0x89D7},
	"bank19_resumed_worker_text_lead_BBDC_BBDE.bin": {"bank": 0x19, "start": 0xBBDC, "end": 0xBBDE},
	"bank19_resumed_worker_text_row01_BBDE_BBE0.bin": {"bank": 0x19, "start": 0xBBDE, "end": 0xBBE0},
	"bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin": {
		"bank": 0x19, "start": 0xBBE0, "end": 0xBBE3,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/descriptor_01_row_00.bin",
	},
	"bank19_resumed_worker_descriptor01_row02_BBE3_BBE6.bin": {
		"bank": 0x19, "start": 0xBBE3, "end": 0xBBE6,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/descriptor_01_row_02.bin",
	},
	"bank19_resumed_worker_descriptor01_row01_BD9C_BD9F.bin": {
		"bank": 0x19, "start": 0xBD9C, "end": 0xBD9F,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/descriptor_01_row_01.bin",
	},
	"bank19_resumed_worker_descriptor01_row03_BD9F_BDA2.bin": {
		"bank": 0x19, "start": 0xBD9F, "end": 0xBDA2,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/descriptor_01_row_03.bin",
	},
	"bank19_worker_lookup_B3BD_B3D1.bin": {"bank": 0x19, "start": 0xB3BD, "end": 0xB3D1},
	"bank19_pass_receiver_descriptor_pointer_B3ED_B3EF.bin": {
		"bank": 0x19, "start": 0xB3ED, "end": 0xB3EF,
	},
	"bank19_pass_receiver_descriptor_0F_B58D_B5A2.bin": {
		"bank": 0x19, "start": 0xB58D, "end": 0xB5A2,
	},
	"bank19_pass_receiver_row00_BBED_BBEE.bin": {
		"bank": 0x19, "start": 0xBBED, "end": 0xBBEE,
	},
	"bank19_pass_receiver_row01_BBF4_BBFB.bin": {
		"bank": 0x19, "start": 0xBBF4, "end": 0xBBFB,
	},
	"fixed_pass_receiver_handler_D7E8_D8F7.bin": {
		"bank": 0x1E, "start": 0xD7E8, "end": 0xD8F7,
	},
	"bank19_descriptor30_pointer_B42F_B431.bin": {"bank": 0x19, "start": 0xB42F, "end": 0xB431},
	"bank19_descriptor30_B8DE_B8EF.bin": {"bank": 0x19, "start": 0xB8DE, "end": 0xB8EF},
	"bank19_descriptor30_row_BE59_BE63.bin": {"bank": 0x19, "start": 0xBE59, "end": 0xBE63},
	"bank19_descriptor30_row_BE6D_BE6F.bin": {"bank": 0x19, "start": 0xBE6D, "end": 0xBE6F},
	"bank19_match_descriptor_B453_B464.bin": {"bank": 0x19, "start": 0xB453, "end": 0xB464},
	"bank19_worker_lookup_tail_B3D1_B3D3.bin": {
		"bank": 0x19, "start": 0xB3D1, "end": 0xB3D3,
		"path": "res://reference/rom_extract/gameplay/slot05_second_wrapper_return_20261029/bank19_worker_lookup_tail_B3D1_B3D3.bin",
	},
	"bank19_match_descriptor_B464_B475.bin": {
		"bank": 0x19, "start": 0xB464, "end": 0xB475,
		"path": "res://reference/rom_extract/gameplay/slot05_second_wrapper_return_20261029/bank19_match_descriptor_B464_B475.bin",
	},
	"bank19_match_descriptor_B475_B47D.bin": {
		"bank": 0x19, "start": 0xB475, "end": 0xB47D,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/descriptor_01.bin",
		"source_offset": 17,
		"source_file_sha256": "f6812eef1a546a57f38689c72882108c959ac740e3ffea93288355cc6765bb82",
	},
	"fixed_task_yield_trampoline_C515_C518.bin": {"bank": 0x1E, "start": 0xC515, "end": 0xC518},
	"fixed_field_loop_dispatch_vector_C600_C603.bin": {"bank": 0x1E, "start": 0xC600, "end": 0xC603},
	"fixed_field_update_dispatch_D565_D600.bin": {"bank": 0x1E, "start": 0xD565, "end": 0xD600},
	"fixed_shared_waiter_CC46_CCD2.bin": {
		"bank": 0x1E, "start": 0xCC46, "end": 0xCCD2,
		"path": "res://reference/rom_extract/gameplay/field_entry_renderer_wrapper/fixed_shared_waiter_CC46_CCD2.bin",
		"source_file_sha256": "21a4cd33eb56fe3d4da516e0eff910ff375a8d7c3ff42bfa46dfb691a846d5cc",
	},
	"fixed_action_context_tables_D700_D70C.bin": {"bank": 0x1E, "start": 0xD700, "end": 0xD70C},
	"bank19_action_menu_descriptor_pointers_B3D3_B3D7.bin": {"bank": 0x19, "start": 0xB3D3, "end": 0xB3D7},
	"bank19_action_menu_descriptor_02_B47D_B48A.bin": {"bank": 0x19, "start": 0xB47D, "end": 0xB48A},
	"bank19_action_menu_descriptor_03_B48A_B4A7.bin": {"bank": 0x19, "start": 0xB48A, "end": 0xB4A7},
	"bank19_action_menu_row_02_00_BBE6_BBEE.bin": {"bank": 0x19, "start": 0xBBE6, "end": 0xBBEE},
	"bank19_action_menu_row_03_00_BC21_BC23.bin": {"bank": 0x19, "start": 0xBC21, "end": 0xBC23},
	"bank19_action_menu_row_03_01_BC23_BC2E.bin": {"bank": 0x19, "start": 0xBC23, "end": 0xBC2E},
	"bank19_action_menu_row_03_02_BC2E_BC39.bin": {"bank": 0x19, "start": 0xBC2E, "end": 0xBC39},
	"bank19_action_menu_row_03_03_BC39_BC44.bin": {"bank": 0x19, "start": 0xBC39, "end": 0xBC44},
	"bank19_action_menu_row_03_04_BC44_BC4F.bin": {"bank": 0x19, "start": 0xBC44, "end": 0xBC4F},
	"fixed_dispatch_C509_C50C.bin": {"bank": 0x1E, "start": 0xC509, "end": 0xC50C},
	"fixed_field_action_vector_C61E_C621.bin": {
		"bank": 0x1E, "start": 0xC61E, "end": 0xC621,
	},
	"fixed_field_pass_result_E059_E074.bin": {
		"bank": 0x1F, "start": 0xE059, "end": 0xE074,
	},
	"fixed_field_pass_result_index_DF8B_DFBD.bin": {
		"bank": 0x1E, "start": 0xDF8B, "end": 0xDFBD,
	},
	"fixed_field_pass_result_index_table_DFBD_DFD1.bin": {
		"bank": 0x1E, "start": 0xDFBD, "end": 0xDFD1,
	},
	"fixed_field_action_handler_vector_C612_C615.bin": {
		"bank": 0x1E, "start": 0xC612, "end": 0xC615,
	},
	"fixed_field_pass_result_handler_DE52_DE80.bin": {
		"bank": 0x1E, "start": 0xDE52, "end": 0xDE80,
	},
	"fixed_field_pass_result_tail_DE80_DE96.bin": {
		"bank": 0x1E, "start": 0xDE80, "end": 0xDE96,
	},
	"fixed_field_pass_result_helper_return_CE6D_CE6E.bin": {
		"bank": 0x1E, "start": 0xCE6D, "end": 0xCE6E,
	},
	"fixed_C624_dispatch_vectors_C624_C64E.bin": {
		"bank": 0x1E, "start": 0xC624, "end": 0xC64E,
	},
	"fixed_C624_vector0_target_DCDF_DCF0.bin": {
		"bank": 0x1E, "start": 0xDCDF, "end": 0xDCF0,
	},
	"shared_fixed_branch_table_dispatch_CB99_CBAF.bin": {
		"bank": 0x1E, "start": 0xCB99, "end": 0xCBB0,
		"path": "res://reference/rom_extract/gameplay/fresh_daaa_continuation/fixed_branch_table_dispatch_CB99_CBAF.bin",
	},
	"bank18_callback_pointer_89D8_89DA.bin": {"bank": 0x18, "start": 0x89D8, "end": 0x89DA},
	"bank18_callback_pointer_89E2_89E4.bin": {"bank": 0x18, "start": 0x89E2, "end": 0x89E4},
	"bank18_dynamic_text_dispatch_89FA_8A56.bin": {
		"bank": 0x18, "start": 0x89FA, "end": 0x8A56,
	},
	"bank18_resumed_worker_vector_tail_89D7_89DC.bin": {"bank": 0x18, "start": 0x89D7, "end": 0x89DC},
	"bank18_special_handler_8B48_8B77.bin": {"bank": 0x18, "start": 0x8B48, "end": 0x8B77},
	"bank18_f0_match_clock_handler_8B8B_8BD5.bin": {"bank": 0x18, "start": 0x8B8B, "end": 0x8BD5},
	"bank18_callback_window_entry_8BEA_8BF0.bin": {"bank": 0x18, "start": 0x8BEA, "end": 0x8BF0},
	"bank18_callback_window_body_8D1A_8D9E.bin": {"bank": 0x18, "start": 0x8D1A, "end": 0x8D9E},
	"bank18_f0_decimal_formatter_8C55_8C85.bin": {"bank": 0x18, "start": 0x8C55, "end": 0x8C85},
	"fixed_text_helper_vector_C524_C527.bin": {"bank": 0x1E, "start": 0xC524, "end": 0xC527},
	"fixed_field_ratio_vector_C521_C524.bin": {"bank": 0x1E, "start": 0xC521, "end": 0xC524},
	"fixed_field_ratio_helper_CD0D_CD3C.bin": {"bank": 0x1E, "start": 0xCD0D, "end": 0xCD3C},
	"fixed_field_clock_vector_C603_C606.bin": {"bank": 0x1E, "start": 0xC603, "end": 0xC606},
	"fixed_field_frame_entry_prefix_E074_E07E.bin": {"bank": 0x1F, "start": 0xE074, "end": 0xE07E},
	"fixed_field_input_vector_C606_C609.bin": {"bank": 0x1E, "start": 0xC606, "end": 0xC609},
	"fixed_record_pointer_vector_C50C_C50F.bin": {"bank": 0x1E, "start": 0xC50C, "end": 0xC50F},
	"fixed_record_pointer_slot_transform_CD77_CD7C.bin": {"bank": 0x1E, "start": 0xCD77, "end": 0xCD7C},
	"fixed_stamina_evaluator_helper_CE08_CE2D.bin": {"bank": 0x1E, "start": 0xCE08, "end": 0xCE2D},
	"fixed_stamina_bank_switch_CE2D_CE4A.bin": {"bank": 0x1E, "start": 0xCE2D, "end": 0xCE4A},
	"bank1c_stamina_evaluator_vector_8000_8003.bin": {"bank": 0x1C, "start": 0x8000, "end": 0x8003},
	"bank1c_stamina_evaluator_802D_818E.bin": {"bank": 0x1C, "start": 0x802D, "end": 0x818E},
	"bank1c_stamina_index_map_818F_8199.bin": {
		"bank": 0x1C, "start": 0x818F, "end": 0x8199,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1c_stamina_index_map_818F_8199.bin",
	},
	"bank1c_stamina_profile_records_9A52_9A6A.bin": {
		"bank": 0x1C, "start": 0x9A52, "end": 0x9A6A,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1c_stamina_profile_records_9A52_9A6A.bin",
	},
	"bank1c_player_stat_value_curve_9E4E_9F0E.bin": {"bank": 0x1C, "start": 0x9E4E, "end": 0x9F0E},
	"bank1c_stamina_profile_pointer_addends_8199_819D.bin": {"bank": 0x1C, "start": 0x8199, "end": 0x819D},
	"bank1c_player_profile_selector_map_95D6_9662.bin": {
		"bank": 0x1C, "start": 0x95D6, "end": 0x9662,
		"path": "res://reference/rom_extract/gameplay/menus/first_action_menu/player_stat_profile_map_00_22.bin",
		"source_file_sha256": "a16ef4a351fe79c6465741d75e3700b1bfe84f6a28ddee5e837aba226cb4ff48",
	},
	"bank1c_stamina_energy_values_9F0E_9FCE.bin": {
		"bank": 0x1C, "start": 0x9F0E, "end": 0x9FCE,
		"path": "res://reference/rom_extract/gameplay/first_match_player_state/stamina_value_words_9F0E_9FCD.bin",
		"source_file_sha256": "9278cbdf95434a0dc120d6938b6095fc24261d735e8ce4f91c5c95400e291085",
	},
	"bank1c_player_stat_profiles_9FCE_A000.bin": {
		"bank": 0x1C, "start": 0x9FCE, "end": 0xA000,
		"path": "res://reference/rom_extract/gameplay/menus/first_action_menu/player_stat_profiles_00_8c.bin",
		"source_offset": 0,
		"source_file_sha256": "3236a005cc380c17351cf6ebac20f3f090be2a0a67ba6d8849cd8e6bcaf95fff",
	},
	"bank1d_player_stat_profiles_A000_AD06.bin": {
		"bank": 0x1D, "start": 0xA000, "end": 0xAD06,
		"path": "res://reference/rom_extract/gameplay/menus/first_action_menu/player_stat_profiles_00_8c.bin",
		"source_offset": 50,
		"source_file_sha256": "3236a005cc380c17351cf6ebac20f3f090be2a0a67ba6d8849cd8e6bcaf95fff",
	},
	"bank1d_stamina_profile_values_AE86_AFAE.bin": {
		"bank": 0x1D, "start": 0xAE86, "end": 0xAFAE,
		"path": "res://reference/rom_extract/gameplay/first_match_player_state/stamina_profile_values_AE86_AFAE.bin",
		"source_file_sha256": "1c87d94c9754655c7101939c784abf02a7c37f6287cbb89ed674cc40562b6cf8",
	},
	"fixed_record_pointer_resolver_CD7C_CD89.bin": {"bank": 0x1E, "start": 0xCD7C, "end": 0xCD89},
	"fixed_record_pointer_table_CD89_CDB5.bin": {"bank": 0x1E, "start": 0xCD89, "end": 0xCDB5},
	"fixed_callback_string_pointer_F339_F33B.bin": {
		"bank": 0x1F, "start": 0xF339, "end": 0xF33B,
		"path": "res://reference/rom_extract/gameplay/menus/first_action_menu/player_name_pointer_table_00_ef.bin",
		"source_offset": 16,
		"source_file_sha256": "9009e3d6f66a170b0f1d6405894645d119f36caf100552581b4d5faba51b1dd7",
	},
	"fixed_callback_string_pointer_F33F_F341.bin": {
		"bank": 0x1F, "start": 0xF33F, "end": 0xF341,
		"path": "res://reference/rom_extract/gameplay/menus/first_action_menu/player_name_pointer_table_00_ef.bin",
		"source_offset": 0x16,
		"source_file_sha256": "9009e3d6f66a170b0f1d6405894645d119f36caf100552581b4d5faba51b1dd7",
	},
	"fixed_callback_text_F52B_F530.bin": {
		"bank": 0x1F, "start": 0xF52B, "end": 0xF530,
		"path": "res://reference/rom_extract/gameplay/menus/first_action_menu/player_name_streams_f509_fd14.bin",
		"source_offset": 0x22,
		"source_file_sha256": "391afd3e6077ebba2f5e211d6d1baec33a70a4989937e6c231cdb83e26778e90",
	},
	"fixed_callback_text_F53A_F53F.bin": {
		"bank": 0x1F, "start": 0xF53A, "end": 0xF53F,
		"path": "res://reference/rom_extract/gameplay/menus/first_action_menu/player_name_streams_f509_fd14.bin",
		"source_offset": 0x31,
		"source_file_sha256": "391afd3e6077ebba2f5e211d6d1baec33a70a4989937e6c231cdb83e26778e90",
	},
	"fixed_holder_coordinate_copy_E6EC_E709.bin": {
		"bank": 0x1F, "start": 0xE6EC, "end": 0xE709,
		"path": "res://reference/rom_extract/gameplay/first_command_field/holder_coordinates/bank_1f_e6ec_holder_coordinate_copy.bin",
		"source_file_sha256": "3bf0cf8593e6eccf77d32044c666a39713134e8120a2e3e7deba3541bb6fbf8c",
	},
	"fixed_holder_coordinate_index_CDE2_CE08.bin": {
		"bank": 0x1E, "start": 0xCDE2, "end": 0xCE08,
		"path": "res://reference/rom_extract/gameplay/first_command_field/holder_coordinates/bank_1f_cde2_coordinate_index_helper.bin",
		"source_file_sha256": "e5f6dcb9f5d2451ba1770add2906daa504befaf7800e3bfe2e1b163708e58a83",
	},
	"bank18_dynamic_player_line_8CA5_8D1A.bin": {
		"bank": 0x18, "start": 0x8CA5, "end": 0x8D1A,
	},
	"fixed_division_dispatch_C51E_C521.bin": {"bank": 0x1E, "start": 0xC51E, "end": 0xC521},
	"fixed_division_16bit_CD3C_CD77.bin": {"bank": 0x1E, "start": 0xCD3C, "end": 0xCD77},
	"fixed_text_token_converter_CBC2_CBF1.bin": {"bank": 0x1E, "start": 0xCBC2, "end": 0xCBF1},
	"bank18_inline_callback_pointer_89F2_89F4.bin": {"bank": 0x18, "start": 0x89F2, "end": 0x89F4},
	"bank18_ed_text_loop_8A56_8A86.bin": {
		"bank": 0x18, "start": 0x8A56, "end": 0x8A86,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/ed_text_loop_8A56_8A86.bin",
	},
	"bank18_ed_team_handler_8AE7_8B0A.bin": {
		"bank": 0x18, "start": 0x8AE7, "end": 0x8B0A,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/ed_team_handler_8AE7_8B0A.bin",
	},
	"bank18_ed_team_name_lengths_8B0A_8B0E.bin": {
		"bank": 0x18, "start": 0x8B0A, "end": 0x8B0E,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/ed_team_name_lengths_8B0A_8B0E.bin",
	},
	"bank18_ee_numeric_handler_8B2F_8B48.bin": {
		"bank": 0x18, "start": 0x8B2F, "end": 0x8B48,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/ee_numeric_handler_8B2F_8B48.bin",
	},
	"fixed_team_name_dispatch_C53C_C53F.bin": {
		"bank": 0x1E, "start": 0xC53C, "end": 0xC53F,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/fixed_team_name_dispatch_C53C_C53F.bin",
	},
	"fixed_team_name_lookup_F30F_F329.bin": {
		"bank": 0x1F, "start": 0xF30F, "end": 0xF329,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/fixed_team_name_lookup_F30F_F329.bin",
	},
	"fixed_team_name_pointer_entries_76_79_F415_F41D.bin": {
		"bank": 0x1F, "start": 0xF415, "end": 0xF41D,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/fixed_team_name_pointer_entries_76_79_F415_F41D.bin",
	},
	"fixed_team_00_name_stream_F776_F77C.bin": {
		"bank": 0x1F, "start": 0xF776, "end": 0xF77C,
		"path": "res://reference/rom_extract/gameplay/field_entry_window_01/team_00_name_stream.bin",
	},
	"fixed_team_03_name_stream_F785_F789.bin": {
		"bank": 0x1F, "start": 0xF785, "end": 0xF789,
	},
	"bank18_character_buffer_helper_8C85_8C9F.bin": {"bank": 0x18, "start": 0x8C85, "end": 0x8C9F},
	"bank18_character_emit_wrapper_8C9F_8CA5.bin": {"bank": 0x18, "start": 0x8C9F, "end": 0x8CA5},
	"bank18_fc_callback_return_8C52_8C55.bin": {"bank": 0x18, "start": 0x8C52, "end": 0x8C55},
	"bank18_window_3x3_tile_ids_8D9E_8DA7.bin": {
		"bank": 0x18, "start": 0x8D9E, "end": 0x8DA7,
		"path": "res://reference/rom_extract/gameplay/menus/first_action_menu/window_3x3_tile_ids.bin",
	},
	"bank18_dynamic_window_data_8DB9_8DC3.bin": {
		"bank": 0x18, "start": 0x8DB9, "end": 0x8DC3,
	},
	"fixed_wrapper_return_EF99_EFA2.bin": {
		"bank": 0x1F, "start": 0xEF99, "end": 0xEFA2,
		"path": "res://reference/rom_extract/gameplay/slot05_second_wrapper_return_20261029/fixed_wrapper_return_EF99_EFA2.bin",
	},
	"fixed_field_entry_bootstrap_EFA2_F015.bin": {"bank": 0x1F, "start": 0xEFA2, "end": 0xF015},
	"fixed_first_command_packet_code_F015_F15A.bin": {
		"bank": 0x1F, "start": 0xF015, "end": 0xF15A,
		"path": "res://reference/rom_extract/gameplay/first_command_field/packet_producer/bank_1f_f015_f159_code.bin",
	},
	"fixed_first_command_packet_descriptor_bases_F15A_F16A.bin": {
		"bank": 0x1F, "start": 0xF15A, "end": 0xF16A,
		"path": "res://reference/rom_extract/gameplay/first_command_field/packet_producer/bank_1f_f15a_descriptor_addresses.bin",
	},
	"fixed_first_command_packet_descriptor_tiles_F16A_F182.bin": {
		"bank": 0x1F, "start": 0xF16A, "end": 0xF182,
		"path": "res://reference/rom_extract/gameplay/first_command_field/packet_producer/bank_1f_f16a_descriptor_tiles.bin",
	},
	"fixed_first_command_packet_stream_pointers_F182_F18E.bin": {
		"bank": 0x1F, "start": 0xF182, "end": 0xF18E,
		"path": "res://reference/rom_extract/gameplay/first_command_field/packet_producer/bank_1f_f182_packet_pointers.bin",
	},
	"fixed_first_command_packet_streams_F18E_F206.bin": {
		"bank": 0x1F, "start": 0xF18E, "end": 0xF206,
		"path": "res://reference/rom_extract/gameplay/first_command_field/packet_producer/bank_1f_f18e_packet_streams.bin",
	},
	"fixed_bank18_wrapper_EF7F_EF99.bin": {
		"bank": 0x1F, "start": 0xEF7F, "end": 0xEF99,
		"path": "res://reference/rom_extract/gameplay/fresh_daaa_continuation/fixed_bank18_wrapper_EF7F_EF99.bin",
	},
	"fixed_field_entry_setup_E0E9_E349.bin": {
		"bank": 0x1F, "start": 0xE0E9, "end": 0xE349,
		"path": "res://reference/rom_extract/gameplay/field_entry_renderer_wrapper/fixed_field_entry_setup_E0E9_E349.bin",
	},
	"fixed_field_loop_input_E349_E3CA.bin": {"bank": 0x1F, "start": 0xE349, "end": 0xE3CA},
	"fixed_field_loop_caller_E407_E4D7.bin": {"bank": 0x1F, "start": 0xE407, "end": 0xE4D7},
	"fixed_field_input_coordinate_scan_E4D7_E54C.bin": {"bank": 0x1F, "start": 0xE4D7, "end": 0xE54C},
	"bank1a_field_update_vector_8000_8003.bin": {"bank": 0x1A, "start": 0x8000, "end": 0x8003},
	"bank1a_field_update_worker_vector_8033_8036.bin": {
		"bank": 0x1A, "start": 0x8033, "end": 0x8036,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1a_field_update_worker_vector_8033_8036.bin",
	},
	"bank1a_field_update_dispatch_8E86_8EE9.bin": {
		"bank": 0x1A, "start": 0x8E86, "end": 0x8EE9,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1a_field_update_dispatch_8E86_8EE9.bin",
	},
	"bank1b_field_update_A103_A1EB.bin": {"bank": 0x1B, "start": 0xA103, "end": 0xA1EB},
	"bank1b_field_update_pointers_A6AD_A6B5.bin": {
		"bank": 0x1B, "start": 0xA6AD, "end": 0xA6B5,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1b_field_update_pointers_A6AD_A6B5.bin",
	},
	"bank1b_field_update_table0_row02_A6DD_A6F1.bin": {
		"bank": 0x1B, "start": 0xA6DD, "end": 0xA6F1,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1b_field_update_table0_row02_A6DD_A6F1.bin",
	},
	"bank1b_field_update_table0_row12_A7A5_A7B9.bin": {
		"bank": 0x1B, "start": 0xA7A5, "end": 0xA7B9,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1b_field_update_table0_row12_A7A5_A7B9.bin",
	},
	"bank1b_field_update_pointer_cell_AB65_AB67.bin": {
		"bank": 0x1B, "start": 0xAB65, "end": 0xAB67,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1b_field_update_pointer_cell_AB65_AB67.bin",
	},
	"bank1b_field_update_data_row02_ABA5_ABB9.bin": {
		"bank": 0x1B, "start": 0xABA5, "end": 0xABB9,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1b_field_update_data_row02_ABA5_ABB9.bin",
	},
	"bank1b_field_update_data_row12_AC6D_AC81.bin": {
		"bank": 0x1B, "start": 0xAC6D, "end": 0xAC81,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1b_field_update_data_row12_AC6D_AC81.bin",
	},
	"bank1d_stamina_lookup_index00_AFB2_AFB4.bin": {
		"bank": 0x1D, "start": 0xAFB2, "end": 0xAFB4,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1d_stamina_lookup_index00_AFB2_AFB4.bin",
	},
	"bank1d_stamina_lookup_index00_offset02_AFB4_AFB6.bin": {
		"bank": 0x1D, "start": 0xAFB4, "end": 0xAFB6,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1d_stamina_lookup_index00_offset02_AFB4_AFB6.bin",
	},
	"bank1d_stamina_lookup_index00_selector1F_AFAE_AFB0.bin": {
		"bank": 0x1D, "start": 0xAFAE, "end": 0xAFB0,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1d_stamina_lookup_index00_selector1F_AFAE_AFB0.bin",
	},
	"bank1d_stamina_lookup_index01_AFBE_AFC0.bin": {
		"bank": 0x1D, "start": 0xAFBE, "end": 0xAFC0,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1d_stamina_lookup_index01_AFBE_AFC0.bin",
	},
	"bank1d_stamina_lookup_index03_AFD6_AFD8.bin": {
		"bank": 0x1D, "start": 0xAFD6, "end": 0xAFD8,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1d_stamina_lookup_index03_AFD6_AFD8.bin",
	},
	"bank1d_stamina_lookup_index04_AFE2_AFE4.bin": {
		"bank": 0x1D, "start": 0xAFE2, "end": 0xAFE4,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1d_stamina_lookup_index04_AFE2_AFE4.bin",
	},
	"bank1d_stamina_lookup_index06_AFFA_AFFC.bin": {
		"bank": 0x1D, "start": 0xAFFA, "end": 0xAFFC,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1d_stamina_lookup_index06_AFFA_AFFC.bin",
	},
	"bank1d_stamina_lookup_index07_B006_B008.bin": {
		"bank": 0x1D, "start": 0xB006, "end": 0xB008,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1d_stamina_lookup_index07_B006_B008.bin",
	},
	"bank1d_evaluator_record_row_BAF6_BB00.bin": {
		"bank": 0x1D, "start": 0xBAF6, "end": 0xBB00,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1d_evaluator_record_row_BAF6_BB00.bin",
	},
	"fixed_field_record_helper_vectors_C536_C53C.bin": {"bank": 0x1E, "start": 0xC536, "end": 0xC53C},
	"bank1a_field_context_dispatch_call_8047_804F.bin": {"bank": 0x1A, "start": 0x8047, "end": 0x804F},
	"fixed_field_context_dispatch_vector_C54B_C54E.bin": {"bank": 0x1E, "start": 0xC54B, "end": 0xC54E},
	"fixed_action_scenario_queue_vector_C54E_C551.bin": {"bank": 0x1E, "start": 0xC54E, "end": 0xC551},
	"fixed_field_context_bank_switch_and_indirect_CE6E_CE99.bin": {"bank": 0x1E, "start": 0xCE6E, "end": 0xCE99},
	"bank1c_field_context_dispatch_vector_8006_8009.bin": {"bank": 0x1C, "start": 0x8006, "end": 0x8009},
	"bank1c_field_context_empty_record_branch_8609_863F.bin": {"bank": 0x1C, "start": 0x8609, "end": 0x863F},
	"bank1c_field_action_parameter_vector_8012_8015.bin": {"bank": 0x1C, "start": 0x8012, "end": 0x8015},
	"bank1c_field_action_secondary_vector_801E_8021.bin": {"bank": 0x1C, "start": 0x801E, "end": 0x8021},
	"bank1c_field_action_secondary_handler_846A_84C1.bin": {"bank": 0x1C, "start": 0x846A, "end": 0x84C1},
	"bank1c_field_action_secondary_lookup_8BBE_8C1E.bin": {"bank": 0x1C, "start": 0x8BBE, "end": 0x8C1E},
	"bank1c_field_action_parameters_819D_8298.bin": {"bank": 0x1C, "start": 0x819D, "end": 0x8298},
	"bank1c_field_action_parameter_pointer_table_9460_9468.bin": {"bank": 0x1C, "start": 0x9460, "end": 0x9468},
	"bank1c_field_action_parameter_record_9500_9505.bin": {"bank": 0x1C, "start": 0x9500, "end": 0x9505},
	"fixed_field_update_stamina_vector_C527_C52A.bin": {"bank": 0x1E, "start": 0xC527, "end": 0xC52A},
	"fixed_field_coordinate_update_tail_E800_E854.bin": {"bank": 0x1F, "start": 0xE800, "end": 0xE854},
	"fixed_coordinate_magnitude_thresholds_FACC_FB4C.bin": {"bank": 0x1F, "start": 0xFACC, "end": 0xFB4C},
	"fixed_field_record_index_CDC9_CDE2.bin": {"bank": 0x1E, "start": 0xCDC9, "end": 0xCDE2},
	"fixed_oam_hide_CB8B_CB99.bin": {"bank": 0x1E, "start": 0xCB8B, "end": 0xCB99},
	"fixed_field_coordinate_update_E709_E800.bin": {"bank": 0x1F, "start": 0xE709, "end": 0xE800},
	"fixed_field_update_callsite_E07E_E081.bin": {"bank": 0x1F, "start": 0xE07E, "end": 0xE081},
	"fixed_pass_waiter_caller_E081_E0DE.bin": {"bank": 0x1F, "start": 0xE081, "end": 0xE0DF},
	"fixed_field_neutral_update_E854_E980.bin": {"bank": 0x1F, "start": 0xE854, "end": 0xE980},
	"fixed_coordinate_transform_CE4A_CE6C.bin": {"bank": 0x1E, "start": 0xCE4A, "end": 0xCE6C},
	"fixed_coordinate_ratio_table_FB4C_FBCC.bin": {"bank": 0x1F, "start": 0xFB4C, "end": 0xFBCC},
	"bank1c_field_event_vector_800F_8012.bin": {"bank": 0x1C, "start": 0x800F, "end": 0x8012},
	"bank1c_field_event_handler_8DA6_8E20.bin": {"bank": 0x1C, "start": 0x8DA6, "end": 0x8E20},
	"fixed_clock_tick_D193_D299.bin": {
		"bank": 0x1E, "start": 0xD193, "end": 0xD29A,
		"path": "res://reference/rom_extract/gameplay/clock_tick_d193/fixed_clock_tick_D193_D299.bin",
	},
	"fixed_field_entry_descriptor01_call_E0E4_E0E9.bin": {
		"bank": 0x1F, "start": 0xE0E4, "end": 0xE0E9,
		"path": "res://reference/rom_extract/gameplay/field_entry_renderer_wrapper/fixed_field_entry_descriptor01_call_E0E4_E0E9.bin",
	},
	"fixed_mapper_helper_CE2D_CE4A.bin": {
		"bank": 0x1E, "start": 0xCE2D, "end": 0xCE4A,
		"path": "res://reference/rom_extract/gameplay/fresh_daaa_continuation/fixed_mapper_helper_CE2D_CE49.bin",
	},
	"fixed_second_wrapper_caller_DACC_DAD1.bin": {
		"bank": 0x1E, "start": 0xDACC, "end": 0xDAD1,
		"path": "res://reference/rom_extract/gameplay/slot05_second_wrapper_return_20261029/fixed_second_wrapper_caller_DACC_DAD1.bin",
	},
	"fixed_kickoff_caller_DAD1_DAD8.bin": {
		"bank": 0x1E, "start": 0xDAD1, "end": 0xDAD8,
		"path": "res://reference/rom_extract/gameplay/slot05_second_wrapper_return_20261029/fixed_kickoff_caller_DAD1_DAD8.bin",
	},
	"fixed_kickoff_scenario35_caller_DAD8_DADC.bin": {
		"bank": 0x1E, "start": 0xDAD8, "end": 0xDADD,
		"path": "res://reference/rom_extract/gameplay/scenario_task_runtime/fixed_kickoff_scenario35_caller_DAD8_DADC.bin",
	},
	"fixed_scenario_queue_CBB0_CBC1.bin": {
		"bank": 0x1E, "start": 0xCBB0, "end": 0xCBC2,
		"path": "res://reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin",
	},
	# Kept last so existing narrowly-scoped spans retain their source identities.
	"bank1a_field_entry_8003_A000.bin": {
		"bank": 0x1A, "start": 0x8003, "end": 0xA000,
		"path": "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank1a_field_entry_8003_A000.bin",
	},
}

const FLAG_C := 0x01
const FLAG_Z := 0x02
const FLAG_B := 0x10
const FLAG_U := 0x20
const FLAG_V := 0x40
const FLAG_N := 0x80

var error_message := ""
var _configured := false
var _sources: Dictionary = {}
var _ram := PackedByteArray()
var _a := 0
var _x := 0
var _y := 0
var _p := FLAG_U
var _p_known_mask := 0xFF
var _stack_status_known_masks: Dictionary = {}
var _sp := 0
var _pc := 0
var _write_trace_pc := 0
var _bank_low := 0
var _bank_high := 1
var _mmc3_select := 0
var _writes: Array[Dictionary] = []
var _mapper_writes: Array[Dictionary] = []
var _calls: Array[Dictionary] = []
var _instructions: Array[Dictionary] = []
var _executed_source_files: Dictionary = {}
var _pass_receiver_descriptor_1d_spans: Array[Dictionary] = []
var _executed_pass_receiver_descriptor_1d_sources: Dictionary = {}
var _pass_receiver_input_scan_span: Dictionary = {}
var _pass_receiver_scan_return_source_active := false
var _pass_receiver_scan_return_source_executed := false
var _blocked_read: Dictionary = {}
var _unsupported_opcode: Dictionary = {}
var _bounded_source_stop_address := -1
var _bounded_source_stop_reached := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	_pass_receiver_descriptor_1d_spans.clear()
	_pass_receiver_input_scan_span.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Fresh bank-$18 worker source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Fresh bank-$18 worker source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-fresh-bank18-worker-prefix-source-v1" \
			or String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Fresh bank-$18 worker package targets an unsupported ROM/schema.")
	var by_file: Dictionary = {}
	for span_variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			by_file[String(span.get("file", ""))] = span
	for file_name: String in SOURCE_FILES:
		if not by_file.has(file_name):
			return _fail("Fresh bank-$18 worker manifest omits %s." % file_name)
		var spec: Dictionary = SOURCE_FILES[file_name]
		var entry: Dictionary = by_file[file_name]
		var source_path := String(spec.get("path", SOURCE_ROOT + file_name))
		var bytes := FileAccess.get_file_as_bytes(source_path)
		if spec.has("source_offset"):
			if _sha256(bytes) != String(spec.get("source_file_sha256", "")):
				return _fail("Fresh bank-$18 worker parent source failed full-file hash validation: %s." % file_name)
			var source_offset := int(spec["source_offset"])
			var source_end := source_offset + int(spec["end"]) - int(spec["start"])
			if source_offset < 0 or source_end > bytes.size():
				return _fail("Fresh bank-$18 worker parent source slice is out of bounds: %s." % file_name)
			bytes = bytes.slice(source_offset, source_end)
		if bytes.size() != int(spec["end"]) - int(spec["start"]) \
				or _sha256(bytes) != String(entry.get("sha256", "")) \
				or String(entry.get("cpu_start", "")) != "0x%04X" % int(spec["start"]) \
				or String(entry.get("cpu_end_exclusive", "")) != "0x%04X" % int(spec["end"]) \
				or String(entry.get("bank", "")) != "0x%02X" % int(spec["bank"]) \
				or String(entry.get("bytes", "")).replace(" ", "").to_lower() != bytes.hex_encode():
			return _fail("Fresh bank-$18 worker ROM span failed provenance/size/hash validation: %s." % file_name)
		_sources[file_name] = bytes
	if not _load_pass_receiver_descriptor_1d_sources():
		return false
	if not _load_pass_receiver_input_scan_source():
		return false
	if not _verify_source_boundaries():
		return false
	_configured = true
	return true


func _load_pass_receiver_descriptor_1d_sources() -> bool:
	if not FileAccess.file_exists(PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_PATH) \
			or FileAccess.get_sha256(PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_PATH) \
			!= PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_SHA256:
		return _fail("Descriptor-$1D worker sources are missing or differ from their pinned manifest.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("Descriptor-$1D worker manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-pass-receiver-descriptor-1d-source-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256:
		return _fail("Descriptor-$1D worker sources target an unsupported ROM revision/schema.")
	var expected_addresses := {
		"descriptor_pointer_entry_1D": 0xB409,
		"descriptor_1D": 0xB6C7,
		"row_00": 0xBCF9,
		"row_01": 0xBCFB,
		"row_02": 0xBD06,
		"row_03": 0xBD11,
		"row_04": 0xBD1C,
	}
	var found: Dictionary = {}
	var spans_variant: Variant = manifest.get("spans", [])
	if not spans_variant is Array:
		return _fail("Descriptor-$1D worker manifest has no span list.")
	for span_variant: Variant in spans_variant:
		if not span_variant is Dictionary:
			return _fail("Descriptor-$1D worker manifest contains a malformed span.")
		var span: Dictionary = span_variant
		var name := String(span.get("name", ""))
		if not expected_addresses.has(name):
			continue
		var path := (PASS_RECEIVER_DESCRIPTOR_1D_RESOURCE_ROOT \
			+ String(span.get("resource", ""))).simplify_path()
		if not FileAccess.file_exists(path):
			return _fail("Pinned descriptor-$1D source span is missing: " + path)
		var bytes := FileAccess.get_file_as_bytes(path)
		var start := int(expected_addresses[name])
		if String(span.get("cpu_address", "")) != "0x%04X" % int(expected_addresses[name]) \
				or bytes.size() != int(span.get("length_bytes", -1)) \
				or FileAccess.get_sha256(path) != String(span.get("sha256", "")):
			return _fail("Pinned descriptor-$1D source span failed its address/size/hash check: " + name)
		found[name] = true
		_pass_receiver_descriptor_1d_spans.append({
			"name": name,
			"bank": 0x19,
			"start": start,
			"end": start + bytes.size(),
			"bytes": bytes,
			"sha256": String(span.get("sha256", "")),
			"resource": path,
		})
	for name: String in expected_addresses:
		if not found.has(name):
			return _fail("Descriptor-$1D worker manifest omitted required ROM span " + name)
	if _pass_receiver_descriptor_1d_spans.size() != expected_addresses.size():
		return _fail("Descriptor-$1D worker sources did not load the exact seven required CPU spans.")
	var by_name: Dictionary = {}
	for source_variant: Variant in _pass_receiver_descriptor_1d_spans:
		var source: Dictionary = source_variant
		by_name[String(source["name"])] = source["bytes"]
	if (by_name["descriptor_pointer_entry_1D"] as PackedByteArray) != PackedByteArray([0xC7, 0xB6]) \
			or (by_name["descriptor_1D"] as PackedByteArray).size() != 29:
		return _fail("Descriptor-$1D pointer or descriptor bytes differ from the pinned ROM facts.")
	for row_name: String in ["row_00", "row_01", "row_02", "row_03", "row_04"]:
		var row: PackedByteArray = by_name[row_name]
		if row.is_empty() or row[row.size() - 1] != 0xFC:
			return _fail("Descriptor-$1D worker row %s lacks its ROM `$FC` terminator." % row_name)
	return true


func _load_pass_receiver_input_scan_source() -> bool:
	if not FileAccess.file_exists(PASS_RECEIVER_INPUT_MANIFEST_PATH) \
			or FileAccess.get_sha256(PASS_RECEIVER_INPUT_MANIFEST_PATH) \
			!= PASS_RECEIVER_INPUT_MANIFEST_SHA256:
		return _fail("PASS receiver-input source manifest is missing or differs from its pinned hash.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		PASS_RECEIVER_INPUT_MANIFEST_PATH))
	if not parsed is Dictionary:
		return _fail("PASS receiver-input source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("schema", "")) != "ct2-pass-receiver-input-source-v1" \
			or String(manifest.get("source_rom_sha256", "")) != ROM_SHA256 \
			or int(manifest.get("source_rom_size_bytes", -1)) != 393232:
		return _fail("PASS receiver-input source manifest targets an unsupported ROM revision/schema.")
	var scan_found := false
	var spans_variant: Variant = manifest.get("spans", [])
	if not spans_variant is Array:
		return _fail("PASS receiver-input source manifest has no span list.")
	for span_variant: Variant in spans_variant:
		if not span_variant is Dictionary:
			return _fail("PASS receiver-input source manifest contains a malformed span.")
		var span: Dictionary = span_variant
		if String(span.get("name", "")) != "receiver_candidate_scan":
			continue
		var path := (PASS_RECEIVER_INPUT_RESOURCE_ROOT \
			+ String(span.get("resource", ""))).simplify_path()
		if String(span.get("prg_bank", "")) != "0x1E" \
				or String(span.get("cpu_start", "")) != "0xD8F7" \
				or String(span.get("cpu_end_exclusive", "")) != "0xD979" \
				or String(span.get("file_offset", "")) != "0x03D907" \
				or int(span.get("length_bytes", -1)) != 130 \
				or not FileAccess.file_exists(path):
			return _fail("PASS receiver scan span does not match its pinned bank/address/file-offset contract.")
		var bytes := FileAccess.get_file_as_bytes(path)
		var expected_hash := String(span.get("sha256", ""))
		var return_offset := PASS_RECEIVER_SCAN_RETURN_PC - 0xD8F7
		if bytes.size() != 130 or _sha256(bytes) != expected_hash \
				or expected_hash != "516f3edfaef0868e42229d5f75c609596a21991962647d720037cd041c2d079a" \
				or return_offset < 0 or return_offset >= bytes.size() \
				or int(bytes[return_offset]) != 0x60:
			return _fail("PASS receiver scan span failed length/hash checks or `$D96F` is not the ROM `$60` RTS.")
		_pass_receiver_input_scan_span = {
			"name": "receiver_candidate_scan",
			"bank": 0x1E,
			"start": 0xD8F7,
			"end": 0xD979,
			"return_pc": PASS_RECEIVER_SCAN_RETURN_PC,
			"return_offset": return_offset,
			"return_opcode": int(bytes[return_offset]),
			"bytes": bytes,
			"sha256": expected_hash,
			"resource": path,
			"manifest": PASS_RECEIVER_INPUT_MANIFEST_PATH,
			"manifest_sha256": PASS_RECEIVER_INPUT_MANIFEST_SHA256,
		}
		scan_found = true
		break
	if not scan_found:
		return _fail("PASS receiver-input manifest omitted the hash-checked `$D8F7-$D978` scan span.")
	return true


## Executes only the source bytes between the prior ROM-derived worker-entry
## state and the $C515 trampoline entry. $C515/$CB0F are not executed.
func execute_to_yield_trampoline(worker_entry: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked worker spans before execution.")
		return {}
	if not _validate_worker_entry(worker_entry):
		return {}
	_load_worker_entry(worker_entry)
	var instruction_limit := 256
	while not _at_end_boundary() and _instructions.size() < instruction_limit:
		if not _execute_one():
			return {}
	if not _at_end_boundary():
		_fail("Bank-$18 worker prefix did not reach the source $C515 boundary within its bound.")
		return {}
	return {
		"ok": true,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": ENTRY_PC,
		"entry_bank": ENTRY_BANK,
		"exit_pc": _pc,
		"exit_bank": _current_bank_for_pc(_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p, "p_known_mask": _p_known_mask,
			"sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram": _selected_ram_state(),
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"stack_top_sp_plus_1_to_8": _bytes_hex(0x0100 | ((_sp + 1) & 0xFF), 8),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"entry_profile": String((worker_entry.get("source_context", {}) as Dictionary).get("kind", "fresh_match_daaa")),
		"scope": "ROM-byte execution of bank-$18:$800C->$8851 worker setup through JSR $C515; stops at the $CB0F yield trampoline entry",
		"next_source_call": {"pc": 0xC515, "bank": 0x1E, "target": 0xCB0F},
		"runtime_integrated": false,
		"precondition_gaps": ["This standalone prefix consumes a prior ROM-source state; no asynchronous task save/resume, scheduler scan, or NMI cadence is modeled."],
	}


## Executes the supplied-ROM PASS renderer caller from a scheduler-owned
## `$D7ED` boundary through `$D7EF->$EF7F->$800C` and the worker's first real
## `$8886->$C515` yield call. It intentionally stops before scheduler/NMI work;
## this result is not a renderer-return receipt and does not claim `$D7F2` ran.
func execute_pass_receiver_descriptor_0f_first_yield(boundary: Dictionary) -> Dictionary:
	error_message = ""
	_reset_execution_trace()
	if not _configured and not configure_from_project_sources():
		return _pass_receiver_step_failure(boundary, "source_integrity_failure", error_message)
	var validation := _validate_pass_receiver_boundary(boundary)
	if not bool(validation.get("ok", false)):
		var validation_error := String(validation.get("error", "Invalid `$D7ED` source boundary."))
		var mismatch_variant: Variant = validation.get("mismatches", [])
		if mismatch_variant is Array and not mismatch_variant.is_empty():
			validation_error += " Mismatches: " + JSON.stringify(mismatch_variant)
		return _pass_receiver_step_failure(boundary, "invalid_scheduler_boundary",
			validation_error)
	var mapper: Dictionary = boundary["mapper"]
	_ram = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack_page: PackedByteArray = boundary["stack_page"]
	for index in range(STACK_PAGE_SIZE):
		_ram[0x0100 + index] = stack_page[index]
	_a = int(boundary.get("a", -1)) & 0xFF
	_x = int(boundary.get("x", -1)) & 0xFF
	_y = int(boundary.get("y", -1)) & 0xFF
	_p = (int(boundary.get("p", -1)) | FLAG_U) & 0xFF
	_p_known_mask = int(boundary.get("p_known_mask", -1)) & 0xFF
	_sp = int(boundary.get("sp", -1)) & 0xFF
	_pc = 0xD7ED
	_bank_low = int(boundary.get("bank_low", -1)) & 0xFF
	_bank_high = int(boundary.get("bank_high", -1)) & 0xFF
	_mmc3_select = int(mapper.get("register_select", mapper.get("select", -1))) & 0xFF
	_reset_execution_trace()
	var instruction_limit := 1024
	while not (_pc == 0xC515 and _current_bank_for_pc(_pc) == 0x1E) \
			and _instructions.size() < instruction_limit:
		if not _execute_one():
			return _pass_receiver_step_failure(boundary, "source_execution_stopped",
				error_message)
	if _pc != 0xC515 or _current_bank_for_pc(_pc) != 0x1E:
		return _pass_receiver_step_failure(boundary, "instruction_bound_reached",
			"ROM source execution did not reach the worker's first `$C515` call entry within 1024 instructions.")
	var result := _pass_receiver_step_result(boundary, true, "pass_receiver_descriptor_0f_first_yield")
	if not _pass_receiver_step_contract_matches(result, boundary):
		return _pass_receiver_step_failure(boundary, "source_contract_mismatch",
			"ROM-byte execution reached `$C515` but its descriptor, caller stack, or call chain did not match the pinned source contract.")
	return result


## Executes the shared fixed `$EF7F->$800C` renderer wrapper for a live
## descriptor-$1D call through its first real `$8886->$C515` task-yield entry.
## It does not execute the task-save trampoline, descriptor packet rows, NMI,
## queue consumption, or PPU transfer.
func execute_pass_receiver_descriptor_1d_first_yield(boundary: Dictionary,
		down_result: Dictionary) -> Dictionary:
	error_message = ""
	_reset_execution_trace()
	_executed_pass_receiver_descriptor_1d_sources.clear()
	if not _configured and not configure_from_project_sources():
		return _pass_receiver_1d_step_failure(boundary, "source_integrity_failure", error_message)
	var validation := _validate_pass_receiver_descriptor_1d_boundary(boundary, down_result)
	if not bool(validation.get("ok", false)):
		return _pass_receiver_1d_step_failure(boundary,
			String(validation.get("status", "invalid_live_boundary")),
			String(validation.get("error", "Invalid live descriptor-$1D renderer call.")))
	var mapper: Dictionary = boundary["mapper"]
	_ram = (boundary["ram_image"] as PackedByteArray).duplicate()
	var stack_page: PackedByteArray = boundary["stack_page"]
	for index in range(STACK_PAGE_SIZE):
		_ram[0x0100 + index] = stack_page[index]
	_a = int(boundary["a"]) & 0xFF
	_x = int(boundary["x"]) & 0xFF
	_y = int(boundary["y"]) & 0xFF
	_p = (int(boundary["p"]) | FLAG_U) & 0xFF
	_p_known_mask = int(boundary.get("p_known_mask", 0xFF)) & 0xFF
	_sp = int(boundary["sp"]) & 0xFF
	_pc = 0xEF7F
	_bank_low = int(boundary["bank_low"]) & 0xFF
	_bank_high = int(boundary["bank_high"]) & 0xFF
	_mmc3_select = int(mapper.get("register_select", mapper.get("select", -1))) & 0xFF
	_reset_execution_trace()
	var instruction_limit := 1024
	while not (_pc == END_PC and _current_bank_for_pc(_pc) == END_BANK) \
			and _instructions.size() < instruction_limit:
		if not _execute_one():
			return _pass_receiver_1d_step_failure(boundary,
				"source_execution_stopped", error_message)
	if _pc != END_PC or _current_bank_for_pc(_pc) != END_BANK:
		return _pass_receiver_1d_step_failure(boundary,
			"instruction_bound_reached",
			"ROM-byte descriptor-$1D renderer did not reach its first `$C515` yield within 1024 instructions.")
	var result := _pass_receiver_1d_step_result(boundary)
	if not _pass_receiver_descriptor_1d_first_yield_contract_matches(result, boundary):
		return _pass_receiver_1d_step_failure(boundary,
			"source_contract_mismatch",
			"ROM-byte descriptor-$1D shared renderer result differs from its live-call/yield contract: " \
				+ _pass_receiver_1d_contract_failure_detail(result, boundary))
	return result


## Continues the live descriptor-$1D renderer from a scheduler-restored
## `$8889` state, checking each packet actually written by the ROM worker against
## the complete descriptor candidate list. It stops at the next real `$C515`
## yield or the ROM `$D80C->$CB0F` wait call; NMI and PPU application remain
## owned by the caller's normal scheduler/NMI path.
func execute_pass_receiver_descriptor_1d_packet_batch(first_yield: Dictionary,
		resume_state: Dictionary, packet_candidates: Array) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _pass_receiver_1d_resume_failure(first_yield, resume_state,
			"source_integrity_failure", error_message)
	var input_check := _validate_pass_receiver_descriptor_1d_resume(
		first_yield, resume_state, packet_candidates)
	if not bool(input_check.get("ok", false)):
		return _pass_receiver_1d_resume_failure(first_yield, resume_state,
			"invalid_yielded_rts_boundary", String(input_check.get("error", "Invalid descriptor-$1D continuation.")))
	var resumed := resume_dispatched_slot05_worker(resume_state)
	if not bool(resumed.get("ok", false)):
		var failure := _pass_receiver_1d_resume_failure(first_yield, resume_state,
			String(resumed.get("exit_kind", "worker_resume_failed")),
			String(resumed.get("error", error_message)))
		failure["worker_result"] = resumed
		return failure
	var packet_result := _pass_receiver_descriptor_1d_queue_batch(
		resumed, resume_state, packet_candidates)
	if not bool(packet_result.get("ok", false)):
		var failure := _pass_receiver_1d_resume_failure(first_yield, resume_state,
			"source_packet_contract_mismatch", String(packet_result.get("error", "ROM packet queue differs from descriptor-$1D output.")))
		failure["worker_result"] = resumed
		return failure
	if String(packet_result.get("status", "")) == "waiting_for_pending_ppu_queue":
		return {"ok": true, "status": "pass_receiver_descriptor_1d_queue_wait_yield",
			"rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
			"source_manifest_sha256": _manifest_sha256(),
			"descriptor_source_manifest": PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_PATH,
			"descriptor_source_manifest_sha256": PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_SHA256,
			"input_boundary_kind": "scheduler_snapshot", "input_boundary_fixture": false,
			"route_boundary_observed": bool(first_yield.get("route_boundary_observed", false)),
			"source_execution_executed": true, "worker_entry_pc": 0x8889,
			"worker_entry_bank": 0x18,
			"worker_exit_pc": int(resumed.get("exit_pc", -1)),
			"worker_exit_bank": int(resumed.get("exit_bank", -1)),
			"worker_exit_kind": String(resumed.get("exit_kind", "")),
			"descriptor_pointer": 0xB6C7, "renderer_returned": false,
			"returned_to_D7F2": false, "packet_count": 0,
			"menu_row_progress_before": int(packet_result.get("menu_row_progress_before", -1)),
			"menu_row_progress_after": int(packet_result.get("menu_row_progress_after", -1)),
			"packets": [], "packet_queue_staged": false,
			"queue_control_0515": int(packet_result.get("queue_control_0515", -1)),
			"wait_call": packet_result.get("wait_call", {}).duplicate(true),
			"worker_registers": resumed.get("registers", {}).duplicate(true),
			"worker_mapper": resumed.get("mapper", {}).duplicate(true),
			"worker_result": resumed.duplicate(true),
			"nmi_executed": false, "nmi_queue_consumed": false,
			"ppu_packet_applied": false, "apu_writes_executed": false,
			"trace_state_used": false, "runtime_integrated": false}
	var renderer_returned := String(resumed.get("exit_kind", "")) == "source_call_boundary"
	return {
		"ok": true,
		"status": "pass_receiver_descriptor_1d_renderer_returned_wait_call_entry" \
			if renderer_returned else "pass_receiver_descriptor_1d_packet_batch_staged",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"descriptor_source_manifest": PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_PATH,
		"descriptor_source_manifest_sha256": PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_SHA256,
		"input_boundary_kind": "scheduler_snapshot",
		"input_boundary_fixture": false,
		"route_boundary_observed": bool(first_yield.get("route_boundary_observed", false)),
		"source_execution_executed": true,
		"worker_entry_pc": 0x8889,
		"worker_entry_bank": 0x18,
		"worker_exit_pc": int(resumed.get("exit_pc", -1)),
		"worker_exit_bank": int(resumed.get("exit_bank", -1)),
		"worker_exit_kind": String(resumed.get("exit_kind", "")),
		"descriptor_pointer": 0xB6C7,
		"renderer_returned": renderer_returned,
		"returned_to_D7F2": renderer_returned,
		"packet_count": int(packet_result.get("packet_count", 0)),
		"menu_row_progress_before": int(packet_result.get("menu_row_progress_before", -1)),
		"menu_row_progress_after": int(packet_result.get("menu_row_progress_after", -1)),
		"packets": packet_result.get("packets", []).duplicate(true),
		"packet_queue_staged": int(packet_result.get("packet_count", 0)) > 0,
		"queue_control_0515": int(packet_result.get("queue_control_0515", -1)),
		"nmi_executed": false,
		"nmi_queue_consumed": false,
		"ppu_packet_applied": false,
		"apu_writes_executed": false,
		"executed_source_spans": resumed.get("executed_source_spans", []).duplicate(true),
		"worker_registers": resumed.get("registers", {}).duplicate(true),
		"worker_mapper": resumed.get("mapper", {}).duplicate(true),
		"worker_result": resumed.duplicate(true),
		"renderer_return_receipt": packet_result.get("renderer_return_receipt", {}).duplicate(true),
		"trace_state_used": false,
		"runtime_integrated": false,
		"limitations": ["ROM-generated queue bytes are verified here; only the ordinary scheduler/NMI path may consume them and emit PPU bus events."],
	}


func _validate_pass_receiver_descriptor_1d_resume(first_yield: Dictionary,
		resume_state: Dictionary, packet_candidates: Array) -> Dictionary:
	var first_ram_variant: Variant = first_yield.get("ram_image", PackedByteArray())
	var first_stack_variant: Variant = first_yield.get("stack_page", PackedByteArray())
	var first_mapper_variant: Variant = first_yield.get("mapper", {})
	var first_registers_variant: Variant = first_yield.get("registers", {})
	if String(first_yield.get("status", "")) != "pass_receiver_descriptor_1d_first_yield" \
			or String(first_yield.get("rom_sha256", "")) != ROM_SHA256 \
			or String(first_yield.get("source_manifest", "")) != MANIFEST_PATH \
			or String(first_yield.get("descriptor_source_manifest", "")) != PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_PATH \
			or not bool(first_yield.get("route_boundary_observed", false)) \
			or bool(first_yield.get("input_boundary_fixture", true)) \
			or bool(first_yield.get("trace_state_used", true)) \
			or int(first_yield.get("entry_pc", -1)) != 0xEF7F \
			or int(first_yield.get("exit_pc", -1)) != 0xC515 \
			or bool(first_yield.get("descriptor_body_executed", true)) \
			or bool(first_yield.get("descriptor_text_rows_executed", true)) \
			or not first_ram_variant is PackedByteArray or not first_stack_variant is PackedByteArray \
			or not first_mapper_variant is Dictionary or not first_registers_variant is Dictionary:
		return {"ok": false, "error": "Descriptor-$1D continuation must reuse the live ROM-executed `$EF7F->$C515` first yield."}
	var first_ram: PackedByteArray = first_ram_variant
	var first_stack: PackedByteArray = first_stack_variant
	var first_mapper: Dictionary = first_mapper_variant
	var first_registers: Dictionary = first_registers_variant
	var source_descriptor: Dictionary = first_yield.get("descriptor_source", {})
	if first_ram.size() != RAM_SIZE or first_stack.size() != STACK_PAGE_SIZE \
			or first_ram.slice(0x0100, 0x0200) != first_stack \
			or int(first_ram[0x0050]) != 0xC7 or int(first_ram[0x0051]) != 0xB6 \
			or int(first_mapper.get("bank_low", -1)) != 0x18 \
			or int(first_mapper.get("bank_high", -1)) != 0x19 \
			or int(first_registers.get("pc", -1)) != 0xC515 \
			or int(source_descriptor.get("descriptor_id", -1)) != 0x1D \
			or int(source_descriptor.get("pointer_table_entry", -1)) != 0xB409 \
			or int(source_descriptor.get("descriptor_pointer", -1)) != 0xB6C7 \
			or source_descriptor.get("pointer_bytes", []) != [0xC7, 0xB6] \
			or not bool(source_descriptor.get("pointer_read_by_source", false)) \
			or bool(source_descriptor.get("descriptor_read_by_source", true)) \
			or not source_descriptor.get("text_rows_read_by_source", []) is Array \
			or not (source_descriptor.get("text_rows_read_by_source", []) as Array).is_empty():
		return {"ok": false, "error": "Descriptor-$1D first-yield RAM, pointer, registers, or mapper differs from its ROM-executed source result."}
	if packet_candidates.size() != 11:
		return {"ok": false, "error": "Descriptor-$1D must provide its 11 ROM-derived packet candidates in progress order."}
	for progress in packet_candidates.size():
		if not packet_candidates[progress] is Dictionary:
			return {"ok": false, "error": "Descriptor-$1D packet candidate %d is malformed." % progress}
		var candidate: Dictionary = packet_candidates[progress]
		var packet_variant: Variant = candidate.get("packet", PackedByteArray())
		if int(candidate.get("progress", -1)) != progress \
				or int(candidate.get("ppu_address", -1)) != 0x2232 + progress * 0x20 \
				or not bool(candidate.get("complete", false)) \
				or not packet_variant is PackedByteArray or (packet_variant as PackedByteArray).size() != 15:
			return {"ok": false, "error": "Descriptor-$1D candidate %d lacks a complete 12-tile packet at its ROM address." % progress}
	var resume_check := _validate_resume_state(resume_state)
	if not resume_check:
		return {"ok": false, "error": error_message}
	var dispatch: Dictionary = resume_state.get("source_dispatch", {})
	var registers: Dictionary = resume_state.get("registers", {})
	var mapper: Dictionary = resume_state.get("mapper", {})
	var ram: PackedByteArray = resume_state.get("ram_image", PackedByteArray())
	var stack: PackedByteArray = resume_state.get("stack_page", PackedByteArray())
	var first_sp := int(first_registers.get("sp", -1))
	# Resume with the current scheduler-restored registers. The first yield is
	# older than intervening input scans, which can legitimately change Y.
	if bool(resume_state.get("test_fixture", true)) \
			or String(resume_state.get("source_label", "")).is_empty() \
			or int(dispatch.get("pc", -1)) != 0x8889 \
			or int(registers.get("pc", -1)) != 0x8889 \
			or int(registers.get("sp", -1)) != first_sp + 2 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 0x07 \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack \
			or int(ram[0x0050]) != 0xC7 or int(ram[0x0051]) != 0xB6 \
			or int(stack[(int(registers.get("sp", -1)) + 1) & 0xFF]) != 0x98 \
			or int(stack[(int(registers.get("sp", -1)) + 2) & 0xFF]) != 0xEF:
		var resume_sp := int(registers.get("sp", -1))
		var return_frame := PackedByteArray()
		if resume_sp >= 0 and resume_sp <= 0xFF and stack.size() == STACK_PAGE_SIZE:
			return_frame = PackedByteArray([stack[(resume_sp + 1) & 0xFF],
				stack[(resume_sp + 2) & 0xFF]])
		return {"ok": false, "error": "Descriptor-$1D continuation requires the actual scheduler-restored `$8889` state and its `$EF98` RTS frame; " \
			+ JSON.stringify({"dispatch_pc": int(dispatch.get("pc", -1)),
				"register_pc": int(registers.get("pc", -1)), "resume_sp": resume_sp,
				"resume_state_valid": resume_check, "resume_state_error": error_message,
				"first_yield_sp": first_sp, "expected_resume_sp": first_sp + 2,
				"return_frame": return_frame.hex_encode(),
				"expected_return_frame": "98ef", "descriptor_pointer": ram.slice(0x0050, 0x0052).hex_encode(),
				"ram_stack_match": ram.slice(0x0100, 0x0200) == stack,
				"fixture": bool(resume_state.get("test_fixture", true)),
				"y_pair": [int(first_registers.get("y", -1)), int(registers.get("y", -1))],
				"mapper": mapper,
				"source_label": String(resume_state.get("source_label", "")),
				"cursor_003a": int(ram[0x003A])})}
	return {"ok": true}


func _pass_receiver_descriptor_1d_queue_batch(resumed: Dictionary,
		resume_state: Dictionary, packet_candidates: Array) -> Dictionary:
	var ram_variant: Variant = resumed.get("ram_image", PackedByteArray())
	var registers_variant: Variant = resumed.get("registers", {})
	var mapper_variant: Variant = resumed.get("mapper", {})
	var input_ram_variant: Variant = resume_state.get("ram_image", PackedByteArray())
	if not ram_variant is PackedByteArray or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not input_ram_variant is PackedByteArray:
		return {"ok": false, "error": "Descriptor-$1D worker omitted its ROM RAM/register/mapper output."}
	var ram: PackedByteArray = ram_variant
	var input_ram: PackedByteArray = input_ram_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	if ram.size() != RAM_SIZE or input_ram.size() != RAM_SIZE:
		return {"ok": false, "error": "Descriptor-$1D queue validation needs complete 2 KiB before/after RAM images."}
	var progress_before := int(input_ram[0x05C5])
	var progress_after := int(ram[0x05C5])
	var returned := String(resumed.get("exit_kind", "")) == "source_call_boundary"
	var pending_queue_wait_call := false
	for call_variant in resumed.get("calls", []):
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			if int(call.get("bank", -1)) == 0x1E \
					and int(call.get("callsite", -1)) == 0x8886 \
					and int(call.get("target", -1)) == 0xC515:
				pending_queue_wait_call = true
	var waiting_on_pending_queue := progress_before == progress_after \
			and progress_before in [0, 2, 4, 6, 8, 10] \
			and String(resumed.get("exit_kind", "")) == "yield_at_c515" \
			and int(resumed.get("exit_pc", -1)) == 0xC515 \
			and int(resumed.get("exit_bank", -1)) == 0x1E \
			and int(registers.get("pc", -1)) == 0xC515 \
			and int(ram[0x0515]) == 0x80 and int(input_ram[0x0515]) == 0x80 \
			and ram.slice(0x0515, 0x051A) == input_ram.slice(0x0515, 0x051A) \
			and ram.slice(0x04A5, 0x04F9) == input_ram.slice(0x04A5, 0x04F9) \
			and ram.slice(0x05C5, 0x05D1) == input_ram.slice(0x05C5, 0x05D1) \
			and int(resumed.get("instruction_count", -1)) == 4 \
			and pending_queue_wait_call
	if waiting_on_pending_queue:
		return {"ok": true, "status": "waiting_for_pending_ppu_queue",
			"packets": [], "packet_count": 0,
			"menu_row_progress_before": progress_before,
			"menu_row_progress_after": progress_after,
			"queue_control_0515": int(ram[0x0515]),
			"wait_call": {"callsite": 0x8886, "target": 0xC515,
				"pending_queue": ram.slice(0x0515, 0x051A),
				"progress": progress_before, "trace_state_used": false}}
	if progress_before < 0 or progress_before > 10 or progress_after <= progress_before \
			or progress_after > 11 or progress_after - progress_before not in [1, 2]:
		return {"ok": false, "error": "Descriptor-$1D ROM progress must advance by one or two candidate rows per source continuation: %s" % JSON.stringify({
			"progress": [progress_before, progress_after],
			"input_0515_0519": input_ram.slice(0x0515, 0x051A).hex_encode(),
			"output_0515_0519": ram.slice(0x0515, 0x051A).hex_encode(),
			"input_003a_003d": input_ram.slice(0x003A, 0x003E).hex_encode(),
			"output_003a_003d": ram.slice(0x003A, 0x003E).hex_encode(),
			"input_05c5_05d0": input_ram.slice(0x05C5, 0x05D1).hex_encode(),
			"output_05c5_05d0": ram.slice(0x05C5, 0x05D1).hex_encode(),
			"exit_kind": resumed.get("exit_kind", ""), "exit_pc": resumed.get("exit_pc", -1),
			"registers": registers, "instruction_count": resumed.get("instruction_count", -1),
			"instruction_pcs": resumed.get("instruction_pcs", []), "calls": resumed.get("calls", [])})}
	var delta := progress_after - progress_before
	if String(resumed.get("exit_kind", "")) not in ["yield_at_c515", "source_call_boundary"] \
			or int(resumed.get("exit_bank", -1)) != 0x1E \
			or (String(resumed.get("exit_kind", "")) == "yield_at_c515" and int(resumed.get("exit_pc", -1)) != 0xC515) \
			or (returned and (int(resumed.get("exit_pc", -1)) != 0xCB0F \
				or String(resumed.get("status", "")) != "pass_receiver_wait_source_call_boundary")) \
			or int(registers.get("pc", -1)) != int(resumed.get("exit_pc", -2)) \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 0x07 \
			or int(ram[0x0515]) != 0x80:
		return {"ok": false, "error": "Descriptor-$1D worker did not stop at its ROM queue-ready yield/return boundary: %s" % JSON.stringify({
			"exit_kind": resumed.get("exit_kind", ""), "exit_pc": resumed.get("exit_pc", -1),
			"status": resumed.get("status", ""), "mapper": mapper,
			"progress": [progress_before, progress_after],
			"queue": ram.slice(0x0515, 0x0519).hex_encode()})}
	var packets: Array[Dictionary] = []
	var offset := 0x04A5
	for packet_index in delta:
		if offset + 3 > ram.size():
			return {"ok": false, "error": "Descriptor-$1D queued packet header exceeded source RAM."}
		var payload_size := int(ram[offset])
		var ppu_address := int(ram[offset + 1]) | (int(ram[offset + 2]) << 8)
		if payload_size != 0x0C or offset + 3 + payload_size > ram.size():
			return {"ok": false, "error": "Descriptor-$1D queue packet size/payload is not the ROM's 12-tile descriptor width at $%04X." % offset}
		var actual := PackedByteArray([payload_size, ppu_address & 0xFF, (ppu_address >> 8) & 0xFF])
		actual.append_array(ram.slice(offset + 3, offset + 3 + payload_size))
		var candidate: Dictionary = packet_candidates[progress_before + packet_index]
		var expected: Variant = candidate.get("packet", PackedByteArray())
		if not expected is PackedByteArray or actual != expected:
			return {"ok": false, "error": "Descriptor-$1D queued ROM bytes differ from candidate progress %d: %s" % [
				progress_before + packet_index, JSON.stringify({"actual": actual.hex_encode(),
					"expected": (expected as PackedByteArray).hex_encode() if expected is PackedByteArray else "missing"})]}
		packets.append({"ram_offset": offset, "payload_size": payload_size,
			"ppu_address": ppu_address, "payload_hex": actual.slice(3).hex_encode(),
			"progress": progress_before + packet_index, "packet": actual})
		offset += 3 + payload_size
	if returned:
		var calls: Array = resumed.get("calls", [])
		var saw_wait := false
		for call_variant in calls:
			if call_variant is Dictionary:
				var call: Dictionary = call_variant
				if int(call.get("bank", -1)) == 0x1E and int(call.get("callsite", -1)) == 0xD80C \
						and int(call.get("target", -1)) == 0xCB0F:
					saw_wait = true
		var instruction_pcs: Array[int] = []
		for instruction_variant in resumed.get("instructions", []):
			if instruction_variant is Dictionary:
				instruction_pcs.append(int((instruction_variant as Dictionary).get("pc", -1)))
		for pc in [0xD7F2, 0xD7FC, 0xE6EC, 0xD7FF, 0xD80A, 0xD80C]:
			if not instruction_pcs.has(pc):
				return {"ok": false, "error": "Descriptor-$1D renderer returned without its observed ROM caller instruction `$%04X`." % pc}
		if progress_before != 10 or progress_after != 11 or delta != 1 or not saw_wait \
				or ram.slice(0x0515, 0x0519) != PackedByteArray([0x80, 0x00, 0x40, 0x38]) \
				or int(ram[0x0498]) != 0:
			return {"ok": false, "error": "Descriptor-$1D final source packet did not return to the ROM `$D80C->$CB0F` wait with its pending queue."}
		return {"ok": true, "packets": packets, "packet_count": packets.size(),
			"menu_row_progress_before": progress_before, "menu_row_progress_after": progress_after,
			"queue_control_0515": int(ram[0x0515]), "renderer_return_receipt": {
				"status": "pass_receiver_descriptor_1d_renderer_returned_to_D80C",
				"rom_sha256": ROM_SHA256, "progress_before": progress_before,
				"progress_after": progress_after, "wait_callsite": 0xD80C,
				"queue_signature": ram.slice(0x0515, 0x0519),
				"return_path_instruction_pcs": instruction_pcs.filter(
					func(pc: int) -> bool: return pc in [0xD7F2, 0xD7FC, 0xE6EC, 0xD7FF, 0xD80A, 0xD80C]),
				"queue_drained": false, "queue_pending": true, "trace_state_used": false}}
	if not bool(resumed.get("ok", false)) or delta != 2:
		return {"ok": false, "error": "Non-final descriptor-$1D source worker must stage two packets before its `$C515` yield."}
	return {"ok": true, "packets": packets, "packet_count": packets.size(),
		"menu_row_progress_before": progress_before, "menu_row_progress_after": progress_after,
		"queue_control_0515": int(ram[0x0515]), "renderer_return_receipt": {}}


func _pass_receiver_1d_resume_failure(first_yield: Dictionary,
		resume_state: Dictionary, failure_status: String, message: String) -> Dictionary:
	return {"ok": false, "status": failure_status, "error": message,
		"rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"first_yield_status": String(first_yield.get("status", "")),
		"resume_source_dispatch": resume_state.get("source_dispatch", {}).duplicate(true),
		"blocked_read": _blocked_read.duplicate(true),
		"unsupported_opcode": _unsupported_opcode.duplicate(true),
		"trace_state_used": false}


func _validate_pass_receiver_descriptor_1d_boundary(boundary: Dictionary,
		down_result: Dictionary) -> Dictionary:
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	var down_boundary_variant: Variant = down_result.get("next_boundary_snapshot", {})
	if not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not mapper_variant is Dictionary or not down_boundary_variant is Dictionary:
		return {"ok": false, "status": "invalid_live_boundary",
			"error": "Descriptor-$1D execution requires the adopted Down endpoint and scheduler-owned RAM/stack/mapper boundary."}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	var down_boundary: Dictionary = down_boundary_variant
	var down_ram_variant: Variant = down_boundary.get("ram_image", PackedByteArray())
	var down_stack_variant: Variant = down_boundary.get("stack_page", PackedByteArray())
	var down_mapper_variant: Variant = down_boundary.get("mapper", {})
	var banks_variant: Variant = mapper.get("bank_registers", {})
	var down_registers_variant: Variant = down_result.get("registers", {})
	var sample_receipt_id := int(down_result.get("sample_receipt_id", -1))
	var source_frame_label := int(down_result.get("source_frame_label", -1))
	var down_final_sp := int(down_result.get("final_sp", -1))
	var down_source_y := int((down_registers_variant as Dictionary).get("y", -1)) \
		if down_registers_variant is Dictionary else -1
	var mismatches: Array[String] = []
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or String(down_result.get("rom_sha256", "")) != ROM_SHA256:
		mismatches.append("ROM identity")
	if bool(boundary.get("test_fixture", false)) or bool(down_result.get("test_fixture", false)) \
			or bool(down_result.get("trace_state_used", true)) \
			or String(down_result.get("status", "")) != "receiver_down_scan_stopped_at_renderer_call" \
			or sample_receipt_id <= 0 or source_frame_label < 0:
		mismatches.append("ordinary Down receipt provenance")
	if int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != int(down_boundary.get("phase", -2)) \
			or int(boundary.get("pc", -1)) != 0xEF7F \
			or int(boundary.get("bank_low", -1)) != int(down_boundary.get("bank_low", -2)) \
			or int(boundary.get("bank_high", -1)) != int(down_boundary.get("bank_high", -2)) \
			or int(boundary.get("a", -1)) != 0x1D \
			or int(boundary.get("x", -1)) != 0 \
			or down_source_y < 0 or down_source_y > 0xFF \
			or int(boundary.get("y", -1)) != down_source_y \
			or down_final_sp < 0 or down_final_sp > 0xFB \
			or int(boundary.get("sp", -1)) != down_final_sp \
			or int(down_boundary.get("sp", -1)) != down_final_sp:
		mismatches.append("live slot-$05 $EF7F CPU context")
	if ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack \
			or not down_ram_variant is PackedByteArray \
			or not down_stack_variant is PackedByteArray \
			or down_ram_variant != ram or down_stack_variant != stack:
		mismatches.append("exact scheduler RAM/stack equals adopted Down endpoint")
	if ram.size() == RAM_SIZE:
		if int(ram[0x0000]) != 0x05 \
				or int(ram[0x0024]) != int(down_boundary.get("bank_low", -2)) \
				or int(ram[0x0025]) != int(down_boundary.get("bank_high", -2)) \
				or int(ram[0x0624]) != 0x78 or int(ram[0x0430]) != 1 \
				or int(ram[0x0431]) != 0x0A or int(ram[0x0625]) != 1 \
				or int(ram[0x05FC]) != 0x0A or int(ram[0x0441]) != 0x06:
			mismatches.append("ROM-produced receiver candidate state")
	if stack.size() == STACK_PAGE_SIZE and down_final_sp >= 0 and down_final_sp <= 0xFB \
			and (int(stack[down_final_sp + 1]) != 0x6E \
			or int(stack[down_final_sp + 2]) != 0xD9 \
			or int(stack[down_final_sp + 3]) != 0x36 \
			or int(stack[down_final_sp + 4]) != 0xD8):
		mismatches.append("live nested `$D96C->$EF7F` and `$D834->$D8F7` JSR return words")
	if int(mapper.get("fixed_bank", -1)) != 0x1E \
			or int(boundary.get("executing_cpu_bank", -1)) != 0x1E \
			or not down_mapper_variant is Dictionary \
			or int((down_mapper_variant as Dictionary).get("fixed_bank", -1)) != 0x1E \
			or int((down_mapper_variant as Dictionary).get("cpu_c000_bank", -1)) != 0x1E \
			or int((down_mapper_variant as Dictionary).get("cpu_e000_bank", -1)) != 0x1F \
			or int(mapper.get("bank_low", -1)) != int(down_boundary.get("bank_low", -2)) \
			or int(mapper.get("bank_high", -1)) != int(down_boundary.get("bank_high", -2)) \
			or int(mapper.get("select", mapper.get("register_select", -1))) \
				!= int((down_mapper_variant as Dictionary).get("select", -2)) \
			or not banks_variant is Dictionary \
			or int((banks_variant as Dictionary).get(6, (banks_variant as Dictionary).get("6", -1))) \
				!= int(down_boundary.get("bank_low", -2)) \
			or int((banks_variant as Dictionary).get(7, (banks_variant as Dictionary).get("7", -1))) \
				!= int(down_boundary.get("bank_high", -2)):
		mismatches.append("fixed-bank and task-bank mapper state")
	var request_variant: Variant = down_result.get("renderer_requests", [])
	var request_matches := false
	if request_variant is Array and request_variant.size() == 1 \
			and request_variant[0] is Dictionary:
		var request: Dictionary = request_variant[0]
		var request_registers_variant: Variant = request.get("entry_registers", {})
		request_matches = int(request.get("source_pc", -1)) == 0xD96C \
				and int(request.get("callee_pc", -1)) == 0xEF7F \
				and int(request.get("descriptor_id", -1)) == 0x1D \
				and request_registers_variant is Dictionary \
				and int((request_registers_variant as Dictionary).get("pc", -1)) == 0xEF7F \
				and int((request_registers_variant as Dictionary).get("a", -1)) == 0x1D \
				and int((request_registers_variant as Dictionary).get("x", -1)) == 0 \
				and int((request_registers_variant as Dictionary).get("y", -1)) == down_source_y \
				and int((request_registers_variant as Dictionary).get("sp", -1)) == down_final_sp \
				and int(request.get("entry_sp", -1)) == down_final_sp
	if not request_matches:
		mismatches.append("source-derived $D96C descriptor-$1D renderer request")
	if not mismatches.is_empty():
		return {"ok": false, "status": "invalid_live_boundary",
			"error": "Descriptor-$1D renderer rejected its source boundary: " + ", ".join(mismatches) \
				+ " observed=" + JSON.stringify({
					"cpu": {"slot_base": boundary.get("slot_base", -1),
						"active_task_slot": boundary.get("active_task_slot", -1),
						"phase": boundary.get("phase", -1), "pc": boundary.get("pc", -1),
						"a": boundary.get("a", -1), "x": boundary.get("x", -1),
						"y": boundary.get("y", -1), "sp": boundary.get("sp", -1),
						"bank_low": boundary.get("bank_low", -1),
						"bank_high": boundary.get("bank_high", -1)},
					"down_cpu": {"phase": down_boundary.get("phase", -1),
						"pc": down_boundary.get("pc", -1), "y": down_boundary.get("y", -1),
						"sp": down_boundary.get("sp", -1),
						"bank_low": down_boundary.get("bank_low", -1),
						"bank_high": down_boundary.get("bank_high", -1)},
					"ram": {"slot": ram[0x0000] if ram.size() == RAM_SIZE else -1,
						"shadow_low": ram[0x0024] if ram.size() == RAM_SIZE else -1,
						"shadow_high": ram[0x0025] if ram.size() == RAM_SIZE else -1,
						"cursor": ram[0x0624] if ram.size() == RAM_SIZE else -1,
						"count": ram[0x0430] if ram.size() == RAM_SIZE else -1,
						"candidate": ram[0x0431] if ram.size() == RAM_SIZE else -1,
						"selectable": ram[0x0625] if ram.size() == RAM_SIZE else -1,
						"receiver": ram[0x05FC] if ram.size() == RAM_SIZE else -1,
						"holder": ram[0x0441] if ram.size() == RAM_SIZE else -1},
					"mapper": mapper, "down_mapper": down_boundary.get("mapper", {})})}
	return {"ok": true, "sample_receipt_id": sample_receipt_id,
		"source_frame_label": source_frame_label}


func _pass_receiver_1d_step_result(boundary: Dictionary) -> Dictionary:
	var registers := {"a": _a, "x": _x, "y": _y, "p": _p,
		"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc}
	var ram := _ram.duplicate() if _ram.size() == RAM_SIZE else PackedByteArray()
	var stack := _ram.slice(0x0100, 0x0200) if _ram.size() == RAM_SIZE else PackedByteArray()
	var pointer_bytes: Array = []
	if ram.size() == RAM_SIZE:
		pointer_bytes = [int(ram[0x0050]), int(ram[0x0051])]
	var text_rows_read: Array[String] = []
	for source_name_variant: Variant in _executed_pass_receiver_descriptor_1d_sources.keys():
		var source_name := String(source_name_variant)
		if source_name.begins_with("row_"):
			text_rows_read.append(source_name)
	return {
		"ok": true,
		"status": "pass_receiver_descriptor_1d_first_yield",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"descriptor_source_manifest": PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_PATH,
		"descriptor_source_manifest_sha256": PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_SHA256,
		"entry_pc": 0xEF7F,
		"entry_bank": 0x1E,
		"entry_source_label": String(boundary.get("source_label", "")),
		"input_boundary_kind": "scheduler_snapshot",
		"input_boundary_fixture": false,
		"test_fixture": false,
		"exit_pc": _pc,
		"exit_bank": _current_bank_for_pc(_pc),
		"route_boundary_observed": true,
		"source_execution_executed": not _instructions.is_empty(),
		"renderer_source_executed": _executed_source_files.has("fixed_bank18_wrapper_EF7F_EF99.bin") \
				or _executed_source_files.has("bank18_worker_entry_to_yield_call_800C_8889.bin"),
		"input_sample_receipt_id": int(boundary.get("input_sample_receipt_id", -1)),
		"source_frame_label": int(boundary.get("source_frame_label", -1)),
		"registers": registers,
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high,
			"select": _mmc3_select, "fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": ram,
		"stack_page": stack,
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"executed_source_spans": _executed_source_span_records(),
		"descriptor_source": {"descriptor_id": 0x1D,
			"pointer_table_entry": 0xB409, "descriptor_pointer": 0xB6C7,
			"pointer_bytes": pointer_bytes,
			"pointer_read_by_source": _executed_pass_receiver_descriptor_1d_sources.has("descriptor_pointer_entry_1D"),
			"descriptor_read_by_source": _executed_pass_receiver_descriptor_1d_sources.has("descriptor_1D"),
			"text_rows_read_by_source": text_rows_read},
		"descriptor_body_executed": false,
		"descriptor_text_rows_executed": false,
		"renderer_returned": false,
		"scheduler_yield_executed": false,
		"nmi_queue_consumed": false,
		"ppu_packet_applied": false,
		"apu_writes_executed": false,
		"trace_state_used": false,
		"source_cycle_timing_modeled": false,
		"scope": "ROM-byte execution from the live `$D96C->$EF7F` descriptor-$1D call through the shared renderer's first `$8886->$C515` yield; the descriptor pointer table entry is read, but the descriptor body/text rows are not read until after the `$8889` resume. C515, NMI, queue consumption, and PPU application are not executed.",
	}


func _pass_receiver_1d_contract_failure_detail(result: Dictionary,
		boundary: Dictionary) -> String:
	var registers_variant: Variant = result.get("registers", {})
	var mapper_variant: Variant = result.get("mapper", {})
	var ram_variant: Variant = result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = result.get("stack_page", PackedByteArray())
	var registers: Dictionary = registers_variant if registers_variant is Dictionary else {}
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var ram: PackedByteArray = ram_variant if ram_variant is PackedByteArray else PackedByteArray()
	var stack: PackedByteArray = stack_variant if stack_variant is PackedByteArray else PackedByteArray()
	var sp := int(registers.get("sp", -1))
	var call_pairs: Array = []
	for call_variant: Variant in result.get("calls", []):
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			call_pairs.append([int(call.get("bank", -1)), int(call.get("callsite", -1)),
				int(call.get("target", -1))])
	var span_names: Array[String] = []
	for span_variant: Variant in result.get("executed_source_spans", []):
		if span_variant is Dictionary:
			span_names.append(String((span_variant as Dictionary).get("file", "")))
	var write_tail: Array = []
	var writes_variant: Variant = result.get("writes", [])
	if writes_variant is Array:
		var writes: Array = writes_variant
		for index in range(maxi(0, writes.size() - 4), writes.size()):
			write_tail.append(writes[index])
	var mapper_write_tail: Array = []
	var mapper_writes_variant: Variant = result.get("mapper_writes", [])
	if mapper_writes_variant is Array:
		var mapper_writes: Array = mapper_writes_variant
		for index in range(maxi(0, mapper_writes.size() - 4), mapper_writes.size()):
			mapper_write_tail.append(mapper_writes[index])
	return JSON.stringify({
		"input": {"pc": boundary.get("pc", -1), "a": boundary.get("a", -1),
			"x": boundary.get("x", -1), "y": boundary.get("y", -1), "sp": boundary.get("sp", -1),
			"bank_low": boundary.get("bank_low", -1), "bank_high": boundary.get("bank_high", -1)},
		"result": {"status": result.get("status", ""), "exit_pc": result.get("exit_pc", -1),
			"exit_bank": result.get("exit_bank", -1), "registers": registers, "mapper": mapper,
			"ram_0005_0009": ram.slice(0x0005, 0x0009).hex_encode() if ram.size() == RAM_SIZE else "invalid",
			"ram_0024_0025": ram.slice(0x0024, 0x0026).hex_encode() if ram.size() == RAM_SIZE else "invalid",
			"ram_0050_0052": ram.slice(0x0050, 0x0052).hex_encode() if ram.size() == RAM_SIZE else "invalid",
			"ram_0515_0519": ram.slice(0x0515, 0x0519).hex_encode() if ram.size() == RAM_SIZE else "invalid",
			"ram_05C5_05C7": ram.slice(0x05C5, 0x05C7).hex_encode() if ram.size() == RAM_SIZE else "invalid",
			"stack_return": [int(stack[(sp + 1) & 0xFF]), int(stack[(sp + 2) & 0xFF])] \
				if stack.size() == STACK_PAGE_SIZE and sp >= 0 else [],
			"descriptor_source": result.get("descriptor_source", {}),
			"calls": call_pairs, "executed_source_spans": span_names,
			"write_count": writes_variant.size() if writes_variant is Array else -1,
			"write_tail": write_tail,
			"mapper_write_count": mapper_writes_variant.size() if mapper_writes_variant is Array else -1,
			"mapper_write_tail": mapper_write_tail,
			"instructions_tail": Array(result.get("instructions", [])).slice(
				maxi(0, Array(result.get("instructions", [])).size() - 8))}})


func _pass_receiver_1d_step_failure(boundary: Dictionary, failure_status: String,
		message: String) -> Dictionary:
	var result := _pass_receiver_1d_step_result(boundary)
	result["ok"] = false
	result["status"] = failure_status
	result["error"] = message
	result["blocked_read"] = _blocked_read.duplicate(true)
	result["unsupported_opcode"] = _unsupported_opcode.duplicate(true)
	return result


func _pass_receiver_descriptor_1d_first_yield_contract_matches(result: Dictionary,
		boundary: Dictionary) -> bool:
	var ram_variant: Variant = result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = result.get("stack_page", PackedByteArray())
	var registers_variant: Variant = result.get("registers", {})
	var mapper_variant: Variant = result.get("mapper", {})
	var calls_variant: Variant = result.get("calls", [])
	var spans_variant: Variant = result.get("executed_source_spans", [])
	if not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not calls_variant is Array or not spans_variant is Array:
		return false
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var call_pairs: Array = []
	for call_variant in calls_variant:
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			call_pairs.append([int(call.get("callsite", -1)), int(call.get("target", -1))])
	var span_names: Array[String] = []
	for span_variant in spans_variant:
		if span_variant is Dictionary:
			span_names.append(String((span_variant as Dictionary).get("file", "")))
	var sp := int(registers.get("sp", -1))
	return bool(result.get("ok", false)) \
			and String(result.get("status", "")) == "pass_receiver_descriptor_1d_first_yield" \
			and String(result.get("rom_sha256", "")) == ROM_SHA256 \
			and String(result.get("source_manifest_sha256", "")) == _manifest_sha256() \
			and String(result.get("descriptor_source_manifest_sha256", "")) == PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_SHA256 \
			and int(result.get("entry_pc", -1)) == 0xEF7F \
			and int(result.get("input_sample_receipt_id", -1)) == int(boundary.get("input_sample_receipt_id", -2)) \
			and int(result.get("source_frame_label", -1)) == int(boundary.get("source_frame_label", -2)) \
			and int(result.get("exit_pc", -1)) == END_PC \
			and int(result.get("exit_bank", -1)) == END_BANK \
			and int(registers.get("pc", -1)) == END_PC \
			and int(mapper.get("bank_low", -1)) == 0x18 \
			and int(mapper.get("bank_high", -1)) == 0x19 \
			and int(mapper.get("select", -1)) == 0x07 \
			and ram.size() == RAM_SIZE and stack.size() == STACK_PAGE_SIZE \
			and ram.slice(0x0100, 0x0200) == stack \
			and int(ram[0x0050]) == 0xC7 and int(ram[0x0051]) == 0xB6 \
			and sp >= 0 and sp <= 0xFF \
			and int(stack[(sp + 1) & 0xFF]) == 0x88 \
			and int(stack[(sp + 2) & 0xFF]) == 0x88 \
			and call_pairs.has([0xEF96, 0x800C]) \
			and call_pairs.has([0x8886, 0xC515]) \
			and span_names.has("fixed_bank18_wrapper_EF7F_EF99.bin") \
			and span_names.has("bank18_worker_entry_to_yield_call_800C_8889.bin") \
			and _executed_pass_receiver_descriptor_1d_sources.has("descriptor_pointer_entry_1D") \
			and not _executed_pass_receiver_descriptor_1d_sources.has("descriptor_1D") \
			and not _executed_pass_receiver_descriptor_1d_sources.has("row_00") \
			and not _executed_pass_receiver_descriptor_1d_sources.has("row_01") \
			and not _executed_pass_receiver_descriptor_1d_sources.has("row_02") \
			and not _executed_pass_receiver_descriptor_1d_sources.has("row_03") \
			and not _executed_pass_receiver_descriptor_1d_sources.has("row_04") \
			and not bool(result.get("descriptor_body_executed", true)) \
			and not bool(result.get("descriptor_text_rows_executed", true)) \
			and not bool((result.get("descriptor_source", {}) as Dictionary).get("descriptor_read_by_source", true)) \
			and Array((result.get("descriptor_source", {}) as Dictionary).get("text_rows_read_by_source", [])).is_empty()


## Continues a validated synthetic or scheduler-labeled yielded-RTS restore at
## bank-$18:$8889. The worker executes supplied-ROM bytes until its next
## `$C515` yield boundary, then reports only the packet records actually
## staged in the source RAM queue. A synthetic restore is diagnostic evidence,
## not a live route transition; NMI consumption and PPU application remain out
## of scope.
func execute_pass_receiver_descriptor_0f_first_packet(first_yield: Dictionary,
		resume_state: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _pass_receiver_packet_failure(first_yield, resume_state,
			"source_integrity_failure", error_message)
	var input_check := _validate_pass_receiver_packet_input(first_yield, resume_state)
	if not bool(input_check.get("ok", false)):
		return _pass_receiver_packet_failure(first_yield, resume_state,
			"invalid_yielded_rts_boundary", String(input_check.get("error", "Invalid yielded-RTS source boundary.")))
	var resumed := resume_dispatched_slot05_worker(resume_state)
	if not bool(resumed.get("ok", false)):
		var failure := _pass_receiver_packet_failure(first_yield, resume_state,
			String(resumed.get("exit_kind", "worker_resume_failed")),
			String(resumed.get("error", error_message)))
		failure["worker_result"] = resumed
		return failure
	if String(resumed.get("exit_kind", "")) == "source_call_boundary":
		var returned_boundary := _pass_receiver_renderer_return_boundary(resumed, resume_state)
		if not bool(returned_boundary.get("ok", false)):
			return _pass_receiver_packet_failure(first_yield, resume_state,
				"renderer_return_contract_mismatch", String(returned_boundary.get("error", "Invalid renderer return boundary.")))
		return {
			"ok": true,
			"status": "pass_receiver_descriptor_0f_renderer_returned_wait_call_entry",
			"rom_sha256": ROM_SHA256,
			"source_manifest": MANIFEST_PATH,
			"source_manifest_sha256": _manifest_sha256(),
			"input_boundary_kind": "scheduler_snapshot",
			"input_boundary_fixture": false,
			"route_boundary_observed": bool(first_yield.get("route_boundary_observed", false)),
			"source_execution_executed": true,
			"worker_entry_pc": 0x8889,
			"worker_entry_bank": 0x18,
			"worker_exit_pc": int(resumed.get("exit_pc", -1)),
			"worker_exit_bank": int(resumed.get("exit_bank", -1)),
			"worker_exit_kind": String(resumed.get("exit_kind", "")),
			"descriptor_pointer": 0xB58D,
			"descriptor_body_executed": true,
			"renderer_returned": true,
			"returned_to_D7F2": true,
			"packet_count": 0,
			"packet_queue_staged": false,
			"nmi_executed": false,
			"nmi_queue_consumed": false,
			"ppu_packet_applied": false,
			"apu_writes_executed": false,
			"renderer_return_receipt": returned_boundary.duplicate(true),
			"executed_source_spans": resumed.get("executed_source_spans", []),
			"worker_result": resumed.duplicate(true),
			"runtime_integrated": false,
			"limitations": ["This source boundary proves the renderer returned to its caller; prior queue consumption remains owned by the live scheduler/NMI route."],
		}
	var packet_result := _pass_receiver_packet_batch(resumed, resume_state)
	if not bool(packet_result.get("ok", false)):
		var failure := _pass_receiver_packet_failure(first_yield, resume_state,
			"source_packet_contract_mismatch", String(packet_result.get("error", "ROM-produced packet queue did not match the pinned source contract.")))
		failure["worker_result"] = resumed
		return failure
	var first_fixture := bool(first_yield.get("input_boundary_fixture", false))
	var resume_fixture := bool(resume_state.get("test_fixture", false))
	var output := {
		"ok": true,
		"status": "pass_receiver_descriptor_0f_packet_batch_staged",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"input_boundary_kind": "synthetic_test_fixture" if first_fixture or resume_fixture else "scheduler_snapshot",
		"input_boundary_fixture": first_fixture or resume_fixture,
		"route_boundary_observed": bool(first_yield.get("route_boundary_observed", false)) and not resume_fixture,
		"source_execution_executed": true,
		"worker_entry_pc": 0x8889,
		"worker_entry_bank": 0x18,
		"worker_exit_pc": int(resumed.get("exit_pc", -1)),
		"worker_exit_bank": int(resumed.get("exit_bank", -1)),
		"worker_exit_kind": String(resumed.get("exit_kind", "")),
		"descriptor_pointer": 0xB58D,
		"descriptor_header_executed": true,
		"descriptor_row00_executed": bool(packet_result.get("row00_fetched", false)),
		"descriptor_row01_executed": bool(packet_result.get("row01_fetched", false)),
		"descriptor_row01_address": 0xBBF4,
		"packets": packet_result["packets"],
		"packet_count": int(packet_result["packet_count"]),
		"menu_row_progress_before": int(packet_result.get("menu_row_progress_before", -1)),
		"menu_row_progress_after": int(packet_result.get("menu_state_05c5", -1)),
		"packet_queue_staged": true,
		"queue_control_0515": int(packet_result["queue_control_0515"]),
		"nmi_executed": false,
		"nmi_queue_consumed": false,
		"ppu_packet_applied": false,
		"apu_writes_executed": false,
		"renderer_returned": false,
		"returned_to_D7F2": false,
		"runtime_integrated": false,
		"executed_source_spans": resumed.get("executed_source_spans", []),
		"resume_source_dispatch": (resume_state.get("source_dispatch", {}) as Dictionary).duplicate(true),
		"worker_registers": (resumed.get("registers", {}) as Dictionary).duplicate(true),
		"worker_mapper": (resumed.get("mapper", {}) as Dictionary).duplicate(true),
		"worker_result": resumed.duplicate(true),
		"limitations": [
			"The `$8889` restore is either an explicitly labeled test fixture or an externally supplied scheduler snapshot; this method does not execute task save/restore or establish NMI cadence.",
			"ROM bytes stage two nametable packet records in RAM; queue consumption, PPU register/bus writes, raster timing, and audio are not executed here.",
			"This bounded step does not consume the queue, return through the renderer to `$D7F2`, or establish hardware cycle timing.",
		],
	}
	return output


func _validate_pass_receiver_packet_input(first_yield: Dictionary,
		resume_state: Dictionary) -> Dictionary:
	var first_registers_variant: Variant = first_yield.get("registers", {})
	var first_mapper_variant: Variant = first_yield.get("mapper", {})
	var first_ram_variant: Variant = first_yield.get("ram_image", PackedByteArray())
	var first_stack_variant: Variant = first_yield.get("stack_page", PackedByteArray())
	var dispatch_variant: Variant = resume_state.get("source_dispatch", {})
	var registers_variant: Variant = resume_state.get("registers", {})
	var mapper_variant: Variant = resume_state.get("mapper", {})
	var ram_variant: Variant = resume_state.get("ram_image", PackedByteArray())
	var stack_variant: Variant = resume_state.get("stack_page", PackedByteArray())
	if not first_registers_variant is Dictionary or not first_mapper_variant is Dictionary \
			or not first_ram_variant is PackedByteArray or not first_stack_variant is PackedByteArray \
			or not dispatch_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		return {"ok": false, "error": "Both the source-executed first yield and complete yielded-RTS CPU/mapper/RAM/stack state are required."}
	var first_registers: Dictionary = first_registers_variant
	var first_mapper: Dictionary = first_mapper_variant
	var first_ram: PackedByteArray = first_ram_variant
	var first_stack: PackedByteArray = first_stack_variant
	var dispatch: Dictionary = dispatch_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var first_fixture := bool(first_yield.get("input_boundary_fixture", false))
	var resume_fixture := bool(resume_state.get("test_fixture", false))
	var first_sp := int(first_registers.get("sp", -1))
	var first_calls_variant: Variant = first_yield.get("calls", [])
	var first_calls: Array = first_calls_variant if first_calls_variant is Array else []
	var first_expected_calls := [
		[0x1F, 0xD7EF, 0xEF7F], [0x1E, 0xEF92, 0xCE2D],
		[0x18, 0xEF96, 0x800C], [0x1E, 0x8886, 0xC515],
	]
	var first_calls_match := first_calls.size() == first_expected_calls.size()
	if first_calls_match:
		for index in first_expected_calls.size():
			if not first_calls[index] is Dictionary:
				first_calls_match = false
				break
			var first_call: Dictionary = first_calls[index]
			var expected_call: Array = first_expected_calls[index]
			if int(first_call.get("bank", -1)) != int(expected_call[0]) \
					or int(first_call.get("callsite", -1)) != int(expected_call[1]) \
					or int(first_call.get("target", -1)) != int(expected_call[2]):
				first_calls_match = false
				break
	var first_low := int(first_mapper.get("bank_low", -1))
	var first_high := int(first_mapper.get("bank_high", -1))
	var first_mapper_pair_supported := [first_low, first_high] in [[0x18, 0x19], [0x1A, 0x1B]]
	var first_task_bank_pair := [int(first_ram[0x0007]), int(first_ram[0x0008])] \
		if first_ram.size() == RAM_SIZE else []
	var first_task_bank_pair_supported := first_task_bank_pair in [
		[0x18, 0x19], [0x1A, 0x1B], [0x1C, 0x1D]]
	if String(first_yield.get("status", "")) != "pass_receiver_descriptor_0f_first_yield" \
			or String(first_yield.get("rom_sha256", "")) != ROM_SHA256 \
			or String(first_yield.get("source_manifest", "")) != MANIFEST_PATH \
			or int(first_yield.get("exit_pc", -1)) != 0xC515 \
			or int(first_yield.get("exit_bank", -1)) != 0x1E \
			or not bool(first_yield.get("source_execution_executed", false)) \
			or not bool(first_yield.get("renderer_source_executed", false)) \
			or not bool(first_yield.get("descriptor_source", {}).get("pointer_read_by_source", false)) \
			or int(first_yield.get("entry_pc", -1)) != 0xD7ED \
			or int(first_yield.get("entry_bank", -1)) != 0x1E \
			or int(first_yield.get("descriptor_source", {}).get("descriptor_pointer", -1)) != 0xB58D \
			or first_registers.get("a", -1) != 0x01 or first_registers.get("x", -1) != 0xFF \
			or first_registers.get("y", -1) != 0x03 or first_sp < 2 or first_sp > 0xFF \
			or first_registers.get("pc", -1) != 0xC515 \
			or not first_mapper_pair_supported \
			or first_mapper.get("select", -1) != 0x07 \
			or first_ram.size() != RAM_SIZE or first_stack.size() != STACK_PAGE_SIZE \
			or first_ram.slice(0x0100, 0x0200) != first_stack \
			or not first_task_bank_pair_supported \
			or int(first_ram[0x0050]) != 0x8D or int(first_ram[0x0051]) != 0xB5 \
			or int(first_stack[(first_sp + 1) & 0xFF]) != 0x88 \
			or int(first_stack[(first_sp + 2) & 0xFF]) != 0x88 \
			or not first_calls_match:
		return {"ok": false, "error": "First-yield input does not match the executed `$8886->$C515` PASS descriptor-$0F source signature: " \
			+ JSON.stringify({"status": first_yield.get("status", ""),
				"entry_pc": first_yield.get("entry_pc", -1), "entry_bank": first_yield.get("entry_bank", -1),
				"exit_pc": first_yield.get("exit_pc", -1), "exit_bank": first_yield.get("exit_bank", -1),
				"registers": first_registers, "mapper": first_mapper,
				"task_bank_pair": first_task_bank_pair,
				"stack_return": [first_stack[(first_sp + 1) & 0xFF], first_stack[(first_sp + 2) & 0xFF]] \
					if first_stack.size() == STACK_PAGE_SIZE and first_sp >= 0 else [],
				"pointer": first_ram.slice(0x0050, 0x0052).hex_encode() \
					if first_ram.size() == RAM_SIZE else "invalid",
				"calls": first_calls, "calls_match": first_calls_match})}
	if first_fixture != resume_fixture \
			or String(first_yield.get("source_manifest_sha256", "")) != _manifest_sha256():
		return {"ok": false, "error": "Yield and resume inputs must share fixture/route provenance and the current ROM source manifest."}
	if resume_fixture and String(resume_state.get("fixture_label", "")) != \
			"synthetic yielded-task restore from ROM-byte `$8886->$C515`; NMI cadence not modeled":
		return {"ok": false, "error": "Synthetic yielded-RTS input needs the explicit test-only restore label."}
	if not resume_fixture and (String(resume_state.get("source_label", "")).is_empty() \
			or not bool(first_yield.get("route_boundary_observed", false))):
		return {"ok": false, "error": "A non-fixture continuation needs a scheduler-labeled source boundary and observed first-yield route provenance."}
	var resume_sp := int(registers.get("sp", -1))
	var resume_return_low := int(stack[(resume_sp + 1) & 0xFF]) \
		if stack.size() == STACK_PAGE_SIZE and resume_sp >= 0 else -1
	var resume_return_high := int(stack[(resume_sp + 2) & 0xFF]) \
		if stack.size() == STACK_PAGE_SIZE and resume_sp >= 0 else -1
	if String(dispatch.get("rom_sha256", "")) != ROM_SHA256 \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0x8889 or int(dispatch.get("bank", -1)) != 0x18 \
			or not bool(dispatch.get("source_dispatch_observed", false)) \
			or registers.get("pc", -1) != 0x8889 \
			or registers.get("a", -1) != registers.get("x", -2) \
			or registers.get("y", -1) != 0x03 \
			or resume_sp != first_sp + 2 \
			or mapper.get("bank_low", -1) != 0x18 or mapper.get("bank_high", -1) != 0x19 \
			or mapper.get("select", -1) != 0x07 \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack \
			or int(ram[0x0005]) != 0x00 or int(ram[0x0006]) == 0x00 \
			or int(ram[0x0007]) != 0x18 or int(ram[0x0008]) != 0x19 \
			or int(ram[0x007F]) != 0x01 \
			or int(ram[0x0050]) != 0x8D or int(ram[0x0051]) != 0xB5 \
			or resume_return_low != 0x98 or resume_return_high != 0xEF:
		return {"ok": false, "error": "Yielded-RTS state does not match the scheduler-restored `$8889` registers, mapper, RAM, and stack signature: " \
			+ JSON.stringify({"dispatch": dispatch, "registers": registers, "mapper": mapper,
				"ram_0005_0009": ram.slice(0x0005, 0x0009).hex_encode(),
				"ram_0050_0052": ram.slice(0x0050, 0x0052).hex_encode(),
				"ram_007F": ram[0x007F], "ram_0515_0519": ram.slice(0x0515, 0x0519).hex_encode(),
				"stack_0036_003B": stack.slice(0x36, 0x3C).hex_encode(),
				"stack_return": [stack[(int(registers.get("sp", -1)) + 1) & 0xFF],
					stack[(int(registers.get("sp", -1)) + 2) & 0xFF]]})}
	return {"ok": true}


func _pass_receiver_packet_batch(resumed: Dictionary, resume_state: Dictionary) -> Dictionary:
	var ram_variant: Variant = resumed.get("ram_image", PackedByteArray())
	var registers_variant: Variant = resumed.get("registers", {})
	var mapper_variant: Variant = resumed.get("mapper", {})
	var input_ram_variant: Variant = resume_state.get("ram_image", PackedByteArray())
	if not ram_variant is PackedByteArray or not input_ram_variant is PackedByteArray \
			or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary:
		return {"ok": false, "error": "Resumed source execution omitted input/output RAM or CPU/mapper state."}
	var ram: PackedByteArray = ram_variant
	var input_ram: PackedByteArray = input_ram_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var fixture := bool(resume_state.get("test_fixture", false))
	if ram.size() != RAM_SIZE or input_ram.size() != RAM_SIZE:
		return {"ok": false, "error": "PASS receiver queue transition requires complete 2 KiB input/output RAM images."}
	var progress_before := int(input_ram[0x05C5])
	var progress_after := int(ram[0x05C5])
	if progress_before not in [0, 2, 4, 6, 8] \
			or progress_after != progress_before + 2:
		return {"ok": false, "error": "Descriptor-$0F source row progress did not advance by exactly two records: " \
			+ JSON.stringify({"fixture": fixture, "progress_before": progress_before,
				"progress_after": progress_after})}
	if String(resumed.get("exit_kind", "")) != "yield_at_c515" \
			or int(resumed.get("exit_pc", -1)) != 0xC515 \
			or int(resumed.get("exit_bank", -1)) != 0x1E \
			or int(registers.get("pc", -1)) != 0xC515 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 0x07 \
			or int(ram[0x0515]) != 0x80:
		return {"ok": false, "error": "Resumed ROM worker did not reach its `$C515` yield with a ready packet queue: " \
			+ JSON.stringify({"exit_kind": resumed.get("exit_kind", ""),
				"exit_pc": resumed.get("exit_pc", -1), "exit_bank": resumed.get("exit_bank", -1),
				"registers": registers, "mapper": mapper,
				"menu_row_progress_05c5": progress_after,
				"queue_control_0515": int(ram[0x0515]) if ram.size() == RAM_SIZE else -1,
				"queue_bytes_04A5_04F9": ram.slice(0x04A5, 0x04F9).hex_encode() if ram.size() == RAM_SIZE else "invalid",
				"instruction_count": resumed.get("instruction_count", -1)})}
	var packets: Array[Dictionary] = []
	var offset := 0x04A5
	for packet_index in range(2):
		if offset + 3 > ram.size():
			return {"ok": false, "error": "Staged packet header exceeded the RAM image."}
		var payload_size := int(ram[offset])
		if payload_size <= 0 or offset + 3 + payload_size > ram.size():
			return {"ok": false, "error": "Staged packet length exceeded the RAM image."}
		var ppu_address := int(ram[offset + 1]) | (int(ram[offset + 2]) << 8)
		var payload := ram.slice(offset + 3, offset + 3 + payload_size)
		packets.append({"ram_offset": offset, "payload_size": payload_size,
			"ppu_address": ppu_address, "payload_hex": payload.hex_encode()})
		offset += 3 + payload_size
	var descriptor_bytes: PackedByteArray = _sources["bank19_pass_receiver_descriptor_0F_B58D_B5A2.bin"]
	var descriptor_base := int(descriptor_bytes[0]) | (int(descriptor_bytes[1]) << 8)
	var payload_size := int(descriptor_bytes[2])
	var expected_first_address := descriptor_base + (progress_before << 5)
	var expected_second_address := descriptor_base + ((progress_before + 1) << 5)
	var expected_first := _expected_pass_receiver_descriptor_row(progress_before, payload_size)
	var expected_second := _expected_pass_receiver_descriptor_row(progress_before + 1, payload_size)
	if packets.size() != 2 \
			or int(packets[0]["ram_offset"]) != 0x04A5 \
			or int(packets[0]["payload_size"]) != 0x18 \
			or int(packets[0]["ppu_address"]) != expected_first_address \
			or String(packets[0]["payload_hex"]).hex_decode() != expected_first \
			or int(packets[1]["ram_offset"]) != 0x04C0 \
			or int(packets[1]["payload_size"]) != 0x18 \
			or int(packets[1]["ppu_address"]) != expected_second_address \
			or String(packets[1]["payload_hex"]).hex_decode() != expected_second:
		return {"ok": false, "error": "Staged packet records do not match the source-selected descriptor-$0F window output: " \
			+ JSON.stringify({"fixture": fixture, "progress_before": progress_before,
				"progress_after": progress_after,
				"expected_addresses": [expected_first_address, expected_second_address],
				"packets": packets})}
	var span_files: Array[String] = []
	for span_variant in resumed.get("executed_source_spans", []):
		if span_variant is Dictionary:
			span_files.append(String((span_variant as Dictionary).get("file", "")))
	for required_file in [
		"bank18_worker_resume_8889_89D7.bin",
		"bank19_pass_receiver_descriptor_0F_B58D_B5A2.bin",
	]:
		if not span_files.has(required_file):
			return {"ok": false, "error": "Packet execution source spans omitted %s." % required_file}
	if progress_before <= 6 and not span_files.has("bank18_window_3x3_tile_ids_8D9E_8DA7.bin"):
		var window_tile_instructions: Array[Dictionary] = []
		for instruction_variant in resumed.get("instructions", []):
			if instruction_variant is Dictionary \
					and int((instruction_variant as Dictionary).get("pc", -1)) in [0x8931, 0x8937, 0x8943]:
				window_tile_instructions.append((instruction_variant as Dictionary).duplicate(true))
		return {"ok": false, "error": "Descriptor-$0F progress %d omitted its executed ROM window-tile source span: %s" % [
			progress_before, JSON.stringify({"executed_span_files": span_files,
				"window_tile_instructions": window_tile_instructions})]}
	var row01_executed := span_files.has("bank19_pass_receiver_row01_BBF4_BBFB.bin")
	var row00_executed := span_files.has("bank19_pass_receiver_row00_BBED_BBEE.bin")
	if progress_before == 0 and not row00_executed:
		return {"ok": false, "error": "Progress-zero packet batch omitted its ROM blank-row source span."}
	if progress_before == 0 and row01_executed:
		return {"ok": false, "error": "Progress-zero packet batch unexpectedly fetched the later `$BBF4` text row."}
	if progress_before == 2 and not row01_executed:
		return {"ok": false, "error": "Progress-two packet batch omitted its ROM text-row source span."}
	return {"ok": true, "packets": packets, "packet_count": packets.size(),
		"menu_state_05c5": progress_after, "menu_row_progress_before": progress_before,
		"queue_control_0515": int(ram[0x0515]), "next_ram_offset": offset,
		"row00_fetched": row00_executed, "row01_fetched": row01_executed}


func _pass_receiver_renderer_return_boundary(resumed: Dictionary,
		resume_state: Dictionary) -> Dictionary:
	var registers: Dictionary = resumed.get("registers", {})
	var mapper: Dictionary = resumed.get("mapper", {})
	var ram: PackedByteArray = resumed.get("ram_image", PackedByteArray())
	var stack: PackedByteArray = resumed.get("stack_page", PackedByteArray())
	var input_ram: PackedByteArray = resume_state.get("ram_image", PackedByteArray())
	var calls: Array = resumed.get("calls", [])
	var instructions: Array = resumed.get("instructions", [])
	var source_dispatch: Dictionary = resumed.get("source_dispatch", {})
	var saw_wait_call: Dictionary = {}
	var instruction_pcs: Array[int] = []
	for call_variant in calls:
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			if int(call.get("callsite", -1)) == 0xD80C \
					and int(call.get("target", -1)) == 0xCB0F \
					and int(call.get("bank", -1)) == 0x1E:
				saw_wait_call = call
	for instruction_variant in instructions:
		if instruction_variant is Dictionary:
			instruction_pcs.append(int((instruction_variant as Dictionary).get("pc", -1)))
	var required_return_path := [0xD7F2, 0xD7FC, 0xE6EC, 0xD7FF, 0xD80A, 0xD80C]
	var return_path_executed := true
	for pc in required_return_path:
		if not instruction_pcs.has(pc):
			return_path_executed = false
	var sp := int(registers.get("sp", -1))
	var progress_before := int(input_ram[0x05C5]) if input_ram.size() == RAM_SIZE else -1
	var queue_signature := ram.slice(0x0515, 0x0519) if ram.size() == RAM_SIZE else PackedByteArray()
	var queue_signature_valid := queue_signature == PackedByteArray([0x80, 0x00, 0x40, 0x38]) \
		and int(ram[0x0498]) == 0
	# 6502 JSR at `$D80C` pushes its final operand byte (`$D80E`);
	# RTS then resumes at `$D80F`.
	var stack_return_valid := stack.size() == STACK_PAGE_SIZE and sp >= 0 and sp <= 0xFF \
		and int(stack[(sp + 1) & 0xFF]) == 0x0E \
		and int(stack[(sp + 2) & 0xFF]) == 0xD8
	var ram_stack_mirror_valid := ram.size() == RAM_SIZE and stack.size() == STACK_PAGE_SIZE \
		and ram.slice(0x0100, 0x0200) == stack
	var return_predicates := {
		"ok": bool(resumed.get("ok", false)),
		"status": String(resumed.get("status", "")) == "pass_receiver_wait_source_call_boundary",
		"exit_kind": String(resumed.get("exit_kind", "")) == "source_call_boundary",
		"exit_pc": int(resumed.get("exit_pc", -1)) == 0xCB0F,
		"exit_bank": int(resumed.get("exit_bank", -1)) == 0x1E,
		"dispatch_pc": int(source_dispatch.get("pc", -1)) == 0x8889,
		"dispatch_slot": int(source_dispatch.get("slot_base", -1)) == 0x05,
		"dispatch_observed": bool(source_dispatch.get("source_dispatch_observed", false)),
		"mapper_banks": mapper.get("bank_low", -1) == 0x1C and mapper.get("bank_high", -1) == 0x1D,
		"register_pc_a": int(registers.get("pc", -1)) == 0xCB0F and int(registers.get("a", -1)) == 0x01,
		"ram_stack_sizes": ram.size() == RAM_SIZE and stack.size() == STACK_PAGE_SIZE,
		"ram_stack_mirror": ram_stack_mirror_valid,
		"progress": int(ram[0x05C5]) == 11 and progress_before == 10 if ram.size() == RAM_SIZE else false,
		"queue": queue_signature_valid,
		"return_path": return_path_executed,
		"wait_call": not saw_wait_call.is_empty(),
		"stack_return": stack_return_valid,
	}
	if not bool(resumed.get("ok", false)) \
			or String(resumed.get("status", "")) != "pass_receiver_wait_source_call_boundary" \
			or String(resumed.get("exit_kind", "")) != "source_call_boundary" \
			or int(resumed.get("exit_pc", -1)) != 0xCB0F \
			or int(resumed.get("exit_bank", -1)) != 0x1E \
			or int(source_dispatch.get("pc", -1)) != 0x8889 \
			or int(source_dispatch.get("slot_base", -1)) != 0x05 \
			or not bool(source_dispatch.get("source_dispatch_observed", false)) \
			or mapper.get("bank_low", -1) != 0x1C or mapper.get("bank_high", -1) != 0x1D \
			or registers.get("pc", -1) != 0xCB0F or registers.get("a", -1) != 0x01 \
			or int(registers.get("sp", -1)) < 0 or int(registers.get("sp", -1)) > 0xFF \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack \
			or int(ram[0x05C5]) != 11 or progress_before != 10 \
			or not queue_signature_valid or not return_path_executed \
			or saw_wait_call.is_empty() or not stack_return_valid:
		return {"ok": false, "error": "The final descriptor-$0F resume did not return through the ROM wait call with its source-pending queue and live `$D80F` stack frame: " \
			+ JSON.stringify({"status": resumed.get("status", ""), "source_dispatch": source_dispatch,
				"exit_contract": {"exit_kind": resumed.get("exit_kind", ""),
					"exit_pc": resumed.get("exit_pc", -1), "exit_bank": resumed.get("exit_bank", -1)},
				"ok": resumed.get("ok", false), "return_predicates": return_predicates,
				"registers": registers, "mapper": mapper, "progress_before": progress_before,
				"progress_after": int(ram[0x05C5]) if ram.size() == RAM_SIZE else -1,
				"queue_0515_0498": queue_signature.hex_encode(),
				"primary_count_0498": int(ram[0x0498]) if ram.size() == RAM_SIZE else -1,
				"queue_signature_valid": queue_signature_valid,
				"ram_stack_lengths": [ram.size(), stack.size()], "ram_stack_mirror_valid": ram_stack_mirror_valid,
				"return_path_valid": return_path_executed,
				"stack_return": [stack[(sp + 1) & 0xFF], stack[(sp + 2) & 0xFF]] if stack.size() == STACK_PAGE_SIZE and sp >= 0 else [],
				"wait_call": saw_wait_call, "return_path_instruction_pcs": instruction_pcs.filter(func(pc: int) -> bool: return pc in required_return_path)})}
	return {"ok": true, "status": "pass_receiver_renderer_returned_to_D80C",
		"rom_sha256": ROM_SHA256, "source_manifest_sha256": _manifest_sha256(),
		"progress_before": progress_before, "progress_after": int(ram[0x05C5]),
		"source_dispatch": source_dispatch.duplicate(true), "registers": registers.duplicate(true),
		"mapper": mapper.duplicate(true), "stack_page": stack.duplicate(),
		"return_path_instruction_pcs": required_return_path,
		"wait_call": saw_wait_call.duplicate(true), "source_boundary": resumed.get("source_boundary", {}).duplicate(true),
		"source_spans": resumed.get("executed_source_spans", []).duplicate(true),
		"queue_drained": false, "queue_pending": true,
		"queue_signature": queue_signature.duplicate(),
		"trace_state_used": false, "test_fixture": false}


func _expected_pass_receiver_descriptor_row(row_index: int, payload_size: int) -> PackedByteArray:
	var window_tiles: PackedByteArray = _sources["bank18_window_3x3_tile_ids_8D9E_8DA7.bin"]
	var payload := PackedByteArray()
	if row_index == 1:
		payload.append(window_tiles[0])
		for _index in range(8):
			payload.append(window_tiles[1])
		payload.append(window_tiles[2])
	elif row_index in [2, 4, 5]:
		payload.append(window_tiles[3])
		for _index in range(8):
			payload.append(0x00)
		payload.append(window_tiles[5])
	elif row_index == 3:
		var text_row: PackedByteArray = _sources["bank19_pass_receiver_row01_BBF4_BBFB.bin"]
		payload.append(window_tiles[3])
		payload.append(0x00)
		for tile in text_row:
			if int(tile) == 0xFC:
				break
			payload.append(tile)
		payload.append(0x00)
		payload.append(window_tiles[5])
	elif row_index == 6:
		payload.append(window_tiles[6])
		for _index in range(8):
			payload.append(window_tiles[7])
		payload.append(window_tiles[8])
	while payload.size() < payload_size:
		payload.append(0x00)
	if payload.size() > payload_size:
		payload.resize(payload_size)
	return payload


func _pass_receiver_packet_failure(first_yield: Dictionary, resume_state: Dictionary,
		failure_status: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"status": failure_status,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"input_boundary_kind": "synthetic_test_fixture" if bool(resume_state.get("test_fixture", false)) else "scheduler_snapshot",
		"input_boundary_fixture": bool(resume_state.get("test_fixture", false)),
		"route_boundary_observed": false,
		"error": message,
		"first_yield_status": String(first_yield.get("status", "")),
		"resume_source_dispatch": (resume_state.get("source_dispatch", {}) as Dictionary).duplicate(true) \
			if resume_state.get("source_dispatch", {}) is Dictionary else {},
		"renderer_returned": false,
		"returned_to_D7F2": false,
		"runtime_integrated": false,
	}


func _validate_pass_receiver_boundary(boundary: Dictionary) -> Dictionary:
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	if not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not mapper_variant is Dictionary:
		return {"ok": false, "error": "A complete scheduler boundary must include RAM, stack page, and mapper state."}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	var sp := int(boundary.get("sp", -1))
	var fixture := bool(boundary.get("test_fixture", false))
	var mapper_proof_variant: Variant = boundary.get("mapper_proof", {})
	var mapper_proof: Dictionary = mapper_proof_variant if mapper_proof_variant is Dictionary else {}
	var banks_at_dispatch: Variant = mapper_proof.get("banks_at_fixed_dispatch", [])
	var mapper_low := int(mapper.get("bank_low", boundary.get("bank_low", -1)))
	var mapper_high := int(mapper.get("bank_high", boundary.get("bank_high", -1)))
	var mapper_select := int(mapper.get("register_select", mapper.get("select", -1)))
	var ram_register_select := int(ram[0x0022]) & 0x07 if ram.size() == RAM_SIZE else -1
	var mismatches: Array[Dictionary] = []
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256:
		mismatches.append({"field": "rom_sha256", "expected": ROM_SHA256,
			"actual": String(boundary.get("rom_sha256", ""))})
	if int(boundary.get("slot_base", -1)) != 0x05:
		mismatches.append({"field": "slot_base", "expected": "$05", "actual": "$%02X" % int(boundary.get("slot_base", -1))})
	if int(boundary.get("active_task_slot", -1)) != 0x05:
		mismatches.append({"field": "active_task_slot", "expected": "$05", "actual": "$%02X" % int(boundary.get("active_task_slot", -1))})
	if int(boundary.get("phase", -1)) != 2:
		mismatches.append({"field": "phase", "expected": 2, "actual": int(boundary.get("phase", -1))})
	if int(boundary.get("pc", -1)) != 0xD7ED:
		mismatches.append({"field": "pc", "expected": "$D7ED", "actual": "$%04X" % int(boundary.get("pc", -1))})
	if int(boundary.get("bank_low", -1)) != 0x1C:
		mismatches.append({"field": "bank_low", "expected": "$1C", "actual": "$%02X" % int(boundary.get("bank_low", -1))})
	if int(boundary.get("bank_high", -1)) != 0x1D:
		mismatches.append({"field": "bank_high", "expected": "$1D", "actual": "$%02X" % int(boundary.get("bank_high", -1))})
	if mapper_low != 0x1C:
		mismatches.append({"field": "mapper.bank_low", "expected": "$1C", "actual": "$%02X" % mapper_low})
	if mapper_high != 0x1D:
		mismatches.append({"field": "mapper.bank_high", "expected": "$1D", "actual": "$%02X" % mapper_high})
	if ram_register_select >= 0 and mapper_select != ram_register_select:
		mismatches.append({"field": "mapper.register_select", "expected": "$%02X from RAM[$0022]" % ram_register_select,
			"actual": "$%02X" % mapper_select, "ram_shadow": "$%02X" % ram_register_select,
			"select": int(mapper.get("select", -1)), "register_select": int(mapper.get("register_select", -1))})
	if ram_register_select >= 0 and mapper.has("select") \
			and int(mapper.get("select", -1)) != ram_register_select:
		mismatches.append({"field": "mapper.select", "expected": "$%02X from RAM[$0022]" % ram_register_select,
			"actual": "$%02X" % int(mapper.get("select", -1))})
	if ram.size() != RAM_SIZE:
		mismatches.append({"field": "ram_image.size", "expected": RAM_SIZE, "actual": ram.size()})
	if stack.size() != STACK_PAGE_SIZE:
		mismatches.append({"field": "stack_page.size", "expected": STACK_PAGE_SIZE, "actual": stack.size()})
	if sp < 2 or sp > 0xFF:
		mismatches.append({"field": "sp", "expected": "2..255", "actual": sp})
	if ram.size() == RAM_SIZE and stack.size() == STACK_PAGE_SIZE \
			and ram.slice(0x0100, 0x0200) != stack:
		mismatches.append({"field": "ram_stack_mirror", "expected": "equal", "actual": "different"})
	if ram.size() == RAM_SIZE and int(ram[0x0000]) != 0x05:
		mismatches.append({"field": "ram[$0000]", "expected": "$05", "actual": "$%02X" % int(ram[0x0000])})
	if ram.size() == RAM_SIZE and int(ram[0x0518]) != 0x38:
		mismatches.append({"field": "ram[$0518]", "expected": "$38", "actual": "$%02X" % int(ram[0x0518])})
	if ram.size() == RAM_SIZE and int(ram[0x0441]) >= 22:
		mismatches.append({"field": "ram[$0441]", "expected": "< $16", "actual": "$%02X" % int(ram[0x0441])})
	if sp >= 2 and sp <= 0xFF and stack.size() == STACK_PAGE_SIZE:
		if int(stack[(sp + 1) & 0xFF]) != 0x34:
			mismatches.append({"field": "stack[SP+1]", "expected": "$34", "actual": "$%02X" % int(stack[(sp + 1) & 0xFF])})
		if int(stack[(sp + 2) & 0xFF]) != 0xD6:
			mismatches.append({"field": "stack[SP+2]", "expected": "$D6", "actual": "$%02X" % int(stack[(sp + 2) & 0xFF])})
	if bool(boundary.get("trace_state_used", true)):
		mismatches.append({"field": "trace_state_used", "expected": false,
			"actual": bool(boundary.get("trace_state_used", true))})
	if not banks_at_dispatch.is_empty() and banks_at_dispatch != [0x1C, 0x1D]:
		mismatches.append({"field": "mapper_proof.banks_at_fixed_dispatch",
			"expected": [0x1C, 0x1D], "actual": banks_at_dispatch})
	if mapper_proof.has("fixed_bank") and int(mapper_proof["fixed_bank"]) != 0x1E:
		mismatches.append({"field": "mapper_proof.fixed_bank", "expected": "$1E",
			"actual": "$%02X" % int(mapper_proof["fixed_bank"])})
	if boundary.has("executing_cpu_bank") and int(boundary["executing_cpu_bank"]) != 0x1E:
		mismatches.append({"field": "executing_cpu_bank", "expected": "$1E",
			"actual": "$%02X" % int(boundary["executing_cpu_bank"])})
	if not mismatches.is_empty():
		return {"ok": false, "error": "Boundary does not match the supplied-ROM slot-$05 `$D7ED` source signature.",
			"mismatches": mismatches}
	if fixture:
		if String(boundary.get("fixture_label", "")) != \
				"synthetic D7ED scheduler-return fixture; not a route result":
			return {"ok": false, "error": "A synthetic `$D7ED` boundary needs the explicit test-only label."}
	elif String(boundary.get("source_label", "")).is_empty():
		return {"ok": false, "error": "A live `$D7ED` boundary needs its scheduler source label."}
	return {"ok": true}


func _pass_receiver_step_result(boundary: Dictionary, reached_first_yield: bool,
		result_status: String) -> Dictionary:
	var fixture := bool(boundary.get("test_fixture", false))
	var registers := {"a": _a, "x": _x, "y": _y, "p": _p,
		"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc}
	return {
		"ok": reached_first_yield,
		"status": result_status,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"entry_pc": 0xD7ED,
		"entry_bank": 0x1E,
		"exit_pc": _pc,
		"exit_bank": _current_bank_for_pc(_pc),
		"entry_source_label": String(boundary.get("source_label", "")),
		"input_boundary_kind": "synthetic_test_fixture" if fixture else "scheduler_snapshot",
		"input_boundary_fixture": fixture,
		"route_boundary_observed": not fixture,
		"trace_state_used": bool(boundary.get("trace_state_used", true)),
		"source_execution_executed": not _instructions.is_empty(),
		"renderer_source_executed": _executed_source_files.has("bank18_worker_entry_to_yield_call_800C_8889.bin"),
		"descriptor_body_executed": false,
		"descriptor_text_rows_executed": false,
		"renderer_returned": false,
		"returned_to_D7F2": false,
		"scheduler_yield_executed": false,
		"nmi_queue_consumed": false,
		"ppu_packet_applied": false,
		"apu_writes_executed": false,
		"registers": registers,
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high,
			"select": _mmc3_select, "fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"executed_source_spans": _executed_source_span_records(),
		"descriptor_source": {
			"descriptor_id": 0x0F,
			"pointer_table_address": 0xB3ED,
			"descriptor_pointer": 0xB58D,
			"pointer_loaded_into_zero_page": [_ram[0x0050], _ram[0x0051]],
			"pointer_read_by_source": _executed_source_files.has("bank19_pass_receiver_descriptor_pointer_B3ED_B3EF.bin"),
			"descriptor_body_available_but_not_executed": true,
			"text_rows_available_but_not_executed": true,
			"descriptor_header_span": "bank19_pass_receiver_descriptor_0F_B58D_B5A2.bin",
			"text_rows": [0xBBED, 0xBBF4, 0xBBFA],
			"text_spans": ["bank19_pass_receiver_row00_BBED_BBEE.bin",
				"bank19_pass_receiver_row01_BBF4_BBFB.bin"],
		},
		"scope": "6502 source-byte execution of `$D7ED->$EF7F($0F)->$800C->$C515`; the worker reads `$B3ED->$B58D` but yields before fetching descriptor rows or executing the `$C515` trampoline",
		"next_source_event": {"pc": 0xC515, "bank": 0x1E,
			"bytes": "4c0fcb", "meaning": "ROM JMP to scheduler/NMI wait entry `$CB0F`"},
		"limitations": [
			"This is a bounded CPU-byte execution, not proof that the asynchronous renderer returned to `$D7F2`.",
			"The `$C515` call entry is reached but not executed; `$CB0F` task save/restore and scheduler scan are not modeled here.",
			"NMI queue consumption, PPU register/bus writes, raster timing, and APU effects are not modeled by this worker executor.",
			"A fixture boundary validates source execution only and is not route evidence."
		],
		"runtime_integrated": false,
	}


func _pass_receiver_step_failure(boundary: Dictionary, failure_status: String,
		message: String) -> Dictionary:
	var result := _pass_receiver_step_result(boundary, false, failure_status)
	result["error"] = message
	result["blocked_read"] = _blocked_read.duplicate(true)
	result["unsupported_opcode"] = _unsupported_opcode.duplicate(true)
	return result


func _pass_receiver_step_contract_matches(result: Dictionary, boundary: Dictionary) -> bool:
	var calls_variant: Variant = result.get("calls", [])
	var spans_variant: Variant = result.get("executed_source_spans", [])
	if not calls_variant is Array or not spans_variant is Array:
		return false
	var expected_calls := [[0xD7EF, 0xEF7F], [0xEF96, 0x800C], [0x8886, 0xC515]]
	var observed_calls: Array = []
	for call_variant in calls_variant:
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			observed_calls.append([int(call.get("callsite", -1)), int(call.get("target", -1))])
	for expected in expected_calls:
		if not observed_calls.has(expected):
			return false
	var span_files: Array[String] = []
	for span_variant in spans_variant:
		if span_variant is Dictionary:
			span_files.append(String((span_variant as Dictionary).get("file", "")))
	for required_file in [
		"fixed_pass_receiver_handler_D7E8_D8F7.bin",
		"fixed_bank18_wrapper_EF7F_EF99.bin",
		"bank18_worker_entry_to_yield_call_800C_8889.bin",
		"bank19_pass_receiver_descriptor_pointer_B3ED_B3EF.bin",
	]:
		if not span_files.has(required_file):
			return false
	var ram: PackedByteArray = result["ram_image"]
	var stack: PackedByteArray = result["stack_page"]
	var registers: Dictionary = result["registers"]
	var descriptor_pointer_bytes: PackedByteArray = _sources["bank19_pass_receiver_descriptor_pointer_B3ED_B3EF.bin"]
	var descriptor_bytes: PackedByteArray = _sources["bank19_pass_receiver_descriptor_0F_B58D_B5A2.bin"]
	var handler: PackedByteArray = _sources["fixed_pass_receiver_handler_D7E8_D8F7.bin"]
	var ef_wrapper: PackedByteArray = _sources["fixed_bank18_wrapper_EF7F_EF99.bin"]
	var trampoline: PackedByteArray = _sources["fixed_task_yield_trampoline_C515_C518.bin"]
	var descriptor_row00: PackedByteArray = _sources["bank19_pass_receiver_row00_BBED_BBEE.bin"]
	var descriptor_row01: PackedByteArray = _sources["bank19_pass_receiver_row01_BBF4_BBFB.bin"]
	var expected_descriptor := PackedByteArray([
		0x28, 0x22, 0x18, 0x0A, 0x00, 0x01, 0x0A, 0x05, 0x03, 0x01, 0x02,
		0xED, 0xBB, 0x03, 0x02, 0xF4, 0xBB, 0x05, 0x02, 0xFA, 0xBB,
	])
	return int(result.get("exit_pc", -1)) == 0xC515 \
		and int(result.get("exit_bank", -1)) == 0x1E \
		and int(registers.get("pc", -1)) == 0xC515 \
		and int(registers.get("sp", -1)) >= 0 \
		and descriptor_pointer_bytes == PackedByteArray([0x8D, 0xB5]) \
		and descriptor_bytes == expected_descriptor \
		and descriptor_row00 == PackedByteArray([0xFC]) \
		and descriptor_row01 == PackedByteArray([0x4E, 0x65, 0x05, 0x79, 0x65, 0x3F, 0xFC]) \
		and handler.slice(0xD7ED - 0xD7E8, 0xD7F2 - 0xD7E8) \
			== PackedByteArray([0xA9, 0x0F, 0x20, 0x7F, 0xEF]) \
		and ef_wrapper.slice(0x17, 0x1A) == PackedByteArray([0x20, 0x0C, 0x80]) \
		and trampoline == PackedByteArray([0x4C, 0x0F, 0xCB]) \
		and int(ram[0x0050]) == 0x8D and int(ram[0x0051]) == 0xB5 \
		and bool((result.get("descriptor_source", {}) as Dictionary).get("pointer_read_by_source", false)) \
		and (stack.size() == STACK_PAGE_SIZE) \
		and ram.slice(0x0100, 0x0200) == stack \
		and bool(result.get("renderer_source_executed", false)) \
		and not bool(result.get("descriptor_body_executed", true)) \
		and not bool(result.get("descriptor_text_rows_executed", true)) \
		and not bool(result.get("renderer_returned", true)) \
		and not bool(result.get("scheduler_yield_executed", true)) \
		and not bool(result.get("nmi_queue_consumed", true)) \
		and not bool(result.get("ppu_packet_applied", true)) \
		and not bool(result.get("apu_writes_executed", true)) \
		and bool(boundary.get("test_fixture", false)) == bool(result.get("input_boundary_fixture", false))


## Resumes the source-dispatched slot-$05 worker after the task scheduler has
## restored its yielded RTS continuation at bank-$18:$8889. The caller owns and
## must supply the CPU/mapper/RAM/stack state. P may be omitted because the
## first LDA establishes N/Z before the branch and later carry-dependent ADCs
## clear C; when omitted, the result exposes which P bits are known.
## `stop_before_source_address` retains its source-read boundary semantics.
## `stop_at_source_pc` independently stops before executing that mapped source
## instruction and returns its byte provenance plus the current execution state.
func resume_dispatched_slot05_worker(resume_state: Dictionary,
		stop_before_source_address: int = -1,
		stop_at_source_pc: int = -1) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked worker spans before execution.")
		return {}
	if stop_at_source_pc < -1 or stop_at_source_pc > 0xFFFF:
		_fail("Optional source-PC stop must be -1 or a 16-bit CPU address.")
		return {}
	if not _validate_resume_state(resume_state):
		return {}
	return _resume_slot05_worker_from_validated_boundary(resume_state,
		stop_before_source_address, stop_at_source_pc, 0x8889, false)


## Continues the live bank-$1A caller after the E081 natural RTS adoption.
## The separate proof argument prevents a scheduler return from being mislabeled
## as the emulator-observed `$8889 yielded_rts` dispatch.
func resume_slot05_worker_after_e081_return(boundary: Dictionary,
		return_adoption: Dictionary, stop_before_source_address: int = -1,
		stop_at_source_pc: int = -1) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return {}
	if stop_at_source_pc < -1 or stop_at_source_pc > 0xFFFF:
		_fail("Optional source-PC stop must be -1 or a 16-bit CPU address.")
		return {}
	if not _validate_e081_return_resume_boundary(boundary, return_adoption):
		return {}
	var resume_state := boundary.duplicate(true)
	var cpu_state := {}
	for register_name: String in ["a", "x", "y", "p", "p_known_mask", "sp", "pc"]:
		cpu_state[register_name] = int(boundary.get(register_name, -1))
	resume_state["registers"] = cpu_state
	resume_state["source_dispatch"] = {
		"rom_sha256": ROM_SHA256, "slot_base": 0x05,
		"resume_path": "source_rts_return", "pc": 0x80F0, "bank": 0x1A,
		"source_dispatch_observed": false,
		"source_return_adoption_status": String(return_adoption.get("status", "")),
		"return_word": int(return_adoption.get("return_word", -1)),
	}
	return _resume_slot05_worker_from_validated_boundary(resume_state,
		stop_before_source_address, stop_at_source_pc, 0x80F0, true)


func _resume_slot05_worker_from_validated_boundary(resume_state: Dictionary,
		stop_before_source_address: int, stop_at_source_pc: int,
		entry_pc: int, allow_source_task_yield_call: bool) -> Dictionary:
	_load_resume_state(resume_state, entry_pc)
	_bounded_source_stop_address = stop_before_source_address
	_bounded_source_stop_reached = false
	var requested_source_pc_evidence: Array[Dictionary] = []
	if stop_at_source_pc >= 0:
		requested_source_pc_evidence = _source_pc_evidence(stop_at_source_pc)
		if requested_source_pc_evidence.is_empty():
			_fail("Requested stop PC $%04X is not covered by the active mapper's hash-checked source spans." % stop_at_source_pc)
			return {}
		if _pc == stop_at_source_pc:
			return _requested_source_pc_boundary(resume_state,
				stop_at_source_pc, requested_source_pc_evidence)
	var instruction_limit := 8192
	while not _at_resume_boundary() and _instructions.size() < instruction_limit:
		if stop_at_source_pc >= 0 and _pc == stop_at_source_pc:
			return _requested_source_pc_boundary(resume_state,
				stop_at_source_pc, requested_source_pc_evidence)
		var last_call: Dictionary = _calls.back() if not _calls.is_empty() else {}
		if _pc == 0xCB0F and int(last_call.get("bank", -1)) == 0x1E \
				and int(last_call.get("callsite", -1)) == 0xD5E7 \
				and int(last_call.get("target", -1)) == 0xCB0F:
			return _source_execution_boundary_result(resume_state,
				"slot05_task_yield_source_call_boundary", "source_call_boundary")
		if _pc == 0xCB0F and int(last_call.get("bank", -1)) == 0x1E \
				and int(last_call.get("callsite", -1)) == 0xD80C \
				and int(last_call.get("target", -1)) == 0xCB0F:
			return _source_execution_boundary_result(resume_state,
				"pass_receiver_wait_source_call_boundary", "source_call_boundary")
		if _pc == 0xCB0F and allow_source_task_yield_call \
				and int(last_call.get("target", -1)) == 0xCB0F \
				and int(last_call.get("callsite", -1)) >= 0:
			var source_call_result := _source_execution_boundary_result(resume_state,
				"slot05_source_task_yield_call_boundary", "source_call_boundary")
			source_call_result["call_request"] = {
				"callsite_pc": int(last_call.get("callsite", -1)),
				"target_pc": int(last_call.get("target", -1)),
			}
			return source_call_result
		if _pc == 0xCB0F:
			_stop_before_unmodeled_task_yield_opcode()
			return _incomplete_resume_result(resume_state)
		if not _execute_one():
			return _incomplete_resume_result(resume_state)
	if stop_at_source_pc >= 0 and _pc == stop_at_source_pc:
		return _requested_source_pc_boundary(resume_state,
			stop_at_source_pc, requested_source_pc_evidence)
	if not _at_resume_boundary():
		_fail("Resumed slot-$05 worker did not reach its source $C515 yield boundary within its bound.")
		return {}
	return {
		"ok": true,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"trace_state_used": bool(resume_state.get("trace_state_used", false)),
		"emulator_data_used": bool(resume_state.get("trace_state_used", false)),
		"test_fixture": bool(resume_state.get("test_fixture", false)),
		"executed_source_spans": _executed_source_span_records(),
		"source_dispatch": (resume_state["source_dispatch"] as Dictionary).duplicate(true),
		"exit_kind": "yield_at_c515",
		"exit_pc": _pc,
		"exit_bank": _current_bank_for_pc(_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
			"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"runtime_integrated": false,
		"status_contract": "Incoming P is optional: $8889 LDA sets N/Z before the first branch; subsequent ADC paths clear C; p_known_mask marks output bits established by executed source instructions.",
		"precondition_gaps": ["The caller must produce the yielded_rts dispatch proof and complete restored state from the live source scheduler/NMI composition."],
	}


## Executes the live slot-$05 tail after the PASS confirmation waiter's natural
## `$D716 RTS->$D568` return. The scheduler adoption is the sole provenance for
## this entry; emulator RAM/PPU snapshots are never accepted as CPU state.
## Stops before the hash-pinned `$E07E JSR $E709` instruction.
func resume_live_pass_waiter_field_continuation(boundary: Dictionary,
		cleanup_adoption: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return {}
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	var adopted_variant: Variant = cleanup_adoption.get("next_boundary_snapshot", {})
	if not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not mapper_variant is Dictionary or not adopted_variant is Dictionary:
		_fail("PASS field continuation requires the complete scheduler-owned `$D568` boundary and its cleanup adoption.")
		return {}
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	var adopted: Dictionary = adopted_variant
	if not bool(cleanup_adoption.get("ok", false)) \
			or String(cleanup_adoption.get("status", "")) != "pass_confirmation_waiter_cleanup_adopted" \
			or String(cleanup_adoption.get("rom_sha256", "")) != ROM_SHA256 \
			or String(cleanup_adoption.get("source_manifest_sha256", "")) != PASS_WAITER_MANIFEST_SHA256 \
			or int(cleanup_adoption.get("entry_pc", -1)) != 0xCCD1 \
			or int(cleanup_adoption.get("exit_pc", -1)) != 0xD568 \
			or bool(cleanup_adoption.get("trace_state_used", true)) \
			or bool(cleanup_adoption.get("test_fixture", true)):
		_fail("PASS field continuation does not follow the verified live ROM waiter cleanup.")
		return {}
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != 0xD568 \
			or int(boundary.get("sp", -1)) != 0x4E \
			or int(boundary.get("bank_low", -1)) != 0x1C \
			or int(boundary.get("bank_high", -1)) != 0x1D \
			or int(mapper.get("bank_low", -1)) != 0x1C \
			or int(mapper.get("bank_high", -1)) != 0x1D \
			or int(mapper.get("fixed_low", -1)) != 0x1E \
			or int(mapper.get("fixed_high", -1)) != 0x1F \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack \
			or int(ram[0x0000]) != 0x05 \
			or int(ram[0x0024]) != 0x1A or int(ram[0x0025]) != 0x1B \
			or int(ram[0x062D]) != 0 \
			or not String(boundary.get("source_label", "")).begins_with("ROM-byte PASS waiter caller cleanup `$CCD1->$D70F->$D568`") \
			or bool(boundary.get("test_fixture", true)) \
			or bool(boundary.get("trace_state_used", true)):
		_fail("PASS field continuation rejected a non-live, modified, or incomplete `$D568` scheduler boundary.")
	var adopted_ram: Variant = adopted.get("ram_image", PackedByteArray())
	var adopted_stack: Variant = adopted.get("stack_page", PackedByteArray())
	var adopted_mapper: Variant = adopted.get("mapper", {})
	if int(adopted.get("pc", -1)) != 0xD568 or int(adopted.get("sp", -1)) != int(boundary.get("sp", -2)) \
			or int(adopted.get("a", -1)) != int(boundary.get("a", -2)) \
			or int(adopted.get("x", -1)) != int(boundary.get("x", -2)) \
			or int(adopted.get("y", -1)) != int(boundary.get("y", -2)) \
			or int(adopted.get("p", -1)) != int(boundary.get("p", -2)) \
			or int(adopted.get("p_known_mask", -1)) != int(boundary.get("p_known_mask", -2)) \
			or not adopted_ram is PackedByteArray or adopted_ram != ram \
			or not adopted_stack is PackedByteArray or adopted_stack != stack \
			or not adopted_mapper is Dictionary or adopted_mapper != mapper:
		_fail("The `$D568` worker input differs from the state accepted by the live scheduler cleanup adopter.")
	var registers := {"a": int(boundary.get("a", -1)), "x": int(boundary.get("x", -1)),
		"y": int(boundary.get("y", -1)), "p": int(boundary.get("p", -1)),
		"p_known_mask": int(boundary.get("p_known_mask", -1)),
		"sp": int(boundary.get("sp", -1)), "pc": 0xD568}
	for register_name: String in ["a", "x", "y", "p", "p_known_mask", "sp"]:
		if int(registers[register_name]) < 0 or int(registers[register_name]) > 0xFF:
			_fail("The live `$D568` boundary has invalid register %s." % register_name)
	var resume_state := {"registers": registers, "mapper": mapper.duplicate(true),
		"ram_image": ram.duplicate(), "stack_page": stack.duplicate()}
	_load_resume_state(resume_state, 0xD568)
	var stop_evidence := _source_pc_evidence(0xE07E)
	if stop_evidence.is_empty() \
			or (_sources.get("fixed_field_update_callsite_E07E_E081.bin", PackedByteArray()) \
				as PackedByteArray) != PackedByteArray([0x20, 0x09, 0xE7]):
		_fail("The ROM `$E07E JSR $E709` stop boundary is missing or changed.")
		return {}
	var instruction_limit := 8192
	while _pc != 0xE07E and _instructions.size() < instruction_limit:
		if not _execute_one():
			return _pass_waiter_field_continuation_result(resume_state, false,
				"unresolved_source_boundary")
	if _pc != 0xE07E:
		_fail("PASS waiter field continuation did not reach `$E07E` within the instruction bound.")
		return _pass_waiter_field_continuation_result(resume_state, false,
			"instruction_bound_exceeded")
	var instruction_pcs: Array[int] = []
	for instruction_variant: Variant in _instructions:
		if instruction_variant is Dictionary:
			instruction_pcs.append(int((instruction_variant as Dictionary).get("pc", -1)))
	if instruction_pcs.is_empty() or instruction_pcs[0] != 0xD568 \
			or not instruction_pcs.has(0xCE2D) \
			or not instruction_pcs.has(0x8047) or _bank_low != 0x1A or _bank_high != 0x1B \
			or _current_bank_for_pc(_pc) != 0x1F:
		_fail("The live field-worker path contract differed at `$E07E` (start=$%04X, CE2D=%s, 8047=%s, mapper=$%02X/$%02X, current-bank=$%02X)." % [
			instruction_pcs[0] if not instruction_pcs.is_empty() else -1,
			str(instruction_pcs.has(0xCE2D)), str(instruction_pcs.has(0x8047)), _bank_low, _bank_high,
			_current_bank_for_pc(_pc),
		])
		return _pass_waiter_field_continuation_result(resume_state, false,
			"source_path_contract_mismatch")
	var result := _pass_waiter_field_continuation_result(resume_state, true,
		"pass_waiter_field_continuation_at_e07e")
	result["source_pc_evidence"] = stop_evidence.duplicate(true)
	result["source_boundary"] = {"status": "requested_source_pc_boundary",
		"address": 0xE07E, "bank": 0x1F, "source_bytes_available": true}
	result["holder_transfer_executed"] = false
	result["e709_executed"] = false
	return result


## Executes the live `$E07E->$E709->$E081` ROM call using the scheduler-owned
## post-cleanup CPU/RAM/mapper state. It stops after the callee's natural RTS.
func execute_live_pass_waiter_coordinate_call(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _pass_waiter_coordinate_failure("source_integrity_failure", error_message)
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	if not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not mapper_variant is Dictionary:
		return _pass_waiter_coordinate_failure("invalid_live_boundary", "The E709 call requires complete live RAM, stack, and mapper state.")
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != 0xE07E \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("bank_low", -1)) != 0x1A \
			or int(mapper.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("fixed_low", -1)) != 0x1E \
			or int(mapper.get("fixed_high", -1)) != 0x1F \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack \
			or bool(boundary.get("trace_state_used", true)) \
			or bool(boundary.get("test_fixture", true)):
		return _pass_waiter_coordinate_failure("invalid_live_boundary", "E709 requires the live non-fixture slot-$05 `$E07E` boundary with mapper `$1A/$1B`.")
	var callsite: PackedByteArray = _sources.get("fixed_field_update_callsite_E07E_E081.bin", PackedByteArray())
	var callee: PackedByteArray = _sources.get("fixed_field_coordinate_update_E709_E800.bin", PackedByteArray())
	var callsite_evidence := _source_pc_evidence(0xE07E)
	if callsite != PackedByteArray([0x20, 0x09, 0xE7]) \
			or _sha256(callee) != "6768f99151f2f28bdd2b46ea5b257703125d180ecd55c83d73088c29a523ca10" \
			or callsite_evidence.is_empty():
		return _pass_waiter_coordinate_failure("source_integrity_failure", "Hash-pinned `$E07E->$E709` ROM source bytes are missing or changed.")
	var entry_sp := int(boundary.get("sp", -1))
	var resume_state := {"registers": {"a": int(boundary.get("a", -1)),
		"x": int(boundary.get("x", -1)), "y": int(boundary.get("y", -1)),
		"p": int(boundary.get("p", -1)),
		"p_known_mask": int(boundary.get("p_known_mask", -1)),
		"sp": entry_sp, "pc": 0xE07E},
		"mapper": mapper.duplicate(true), "ram_image": ram.duplicate(),
		"stack_page": stack.duplicate()}
	for register_name: String in ["a", "x", "y", "p", "p_known_mask", "sp"]:
		var register_value := int((resume_state["registers"] as Dictionary).get(register_name, -1))
		if register_value < 0 or register_value > 0xFF:
			return _pass_waiter_coordinate_failure("invalid_live_boundary", "The E709 call boundary has invalid register %s." % register_name)
	_load_resume_state(resume_state, 0xE07E)
	var instruction_limit := 256
	while _pc != 0xE081 and _instructions.size() < instruction_limit:
		if not _execute_one():
			return _pass_waiter_coordinate_failure("source_execution_failed", error_message if not error_message.is_empty() else "Unsupported source instruction at `$%04X`." % _pc)
	if _pc != 0xE081:
		return _pass_waiter_coordinate_failure("instruction_bound_exceeded", "The `$E709` call did not return naturally to `$E081` within its instruction bound.")
	var pcs: Array[int] = []
	for instruction_variant: Variant in _instructions:
		if instruction_variant is Dictionary:
			pcs.append(int((instruction_variant as Dictionary).get("pc", -1)))
	var call: Dictionary = _calls[0] if _calls.size() == 1 else {}
	if pcs.is_empty() or pcs[0] != 0xE07E or pcs[-1] != 0xE73D \
			or int(call.get("callsite", -1)) != 0xE07E \
			or int(call.get("target", -1)) != 0xE709 \
			or int(call.get("sp_after_push", -1)) != ((entry_sp - 2) & 0xFF) \
			or int(_ram[0x0100 + entry_sp]) != 0xE0 \
			or int(_ram[0x0100 + ((entry_sp - 1) & 0xFF)]) != 0x80 \
			or _sp != entry_sp or _bank_low != 0x1A or _bank_high != 0x1B:
		return _pass_waiter_coordinate_failure("source_return_contract_mismatch", "The `$E709` callee did not make its single natural `$E73D RTS->$E081` return with the original stack and mapper.")
	var result := {"ok": true, "status": "pass_waiter_coordinate_call_returned_e081",
		"rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"entry_pc": 0xE07E, "exit_pc": _pc, "exit_bank": _current_bank_for_pc(_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
			"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high,
			"select": _mmc3_select, "fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": _ram.duplicate(), "stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true), "mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true), "instructions": _instructions.duplicate(true),
		"source_instruction_pcs": pcs, "executed_source_spans": _executed_source_span_records(),
		"source_pc_evidence": callsite_evidence.duplicate(true),
		"source_dispatch_proof": {"rom_sha256": ROM_SHA256,
			"callsite_pc": 0xE07E, "target_pc": 0xE709,
			"return_word": 0xE080, "return_pc": 0xE081,
			"rts_pc": 0xE73D, "rts_return_verified": true,
			"trace_state_used": false},
		"trace_state_used": false, "emulator_data_used": false,
		"test_fixture": false, "holder_transfer_executed": false,
		"source_cycle_timing_modeled": false}
	return result


func _pass_waiter_coordinate_failure(status: String, message: String) -> Dictionary:
	_fail(message)
	return {"ok": false, "status": status, "error": error_message,
		"trace_state_used": false, "test_fixture": false}


## Executes the target of a verified call emitted by the E081 field caller.
## The caller's JSR bytes are pinned separately; this worker supplies only the
## naturally returning ROM callee and its scheduler-owned live state changes.
func execute_live_pass_waiter_rom_call(boundary: Dictionary,
		call_contract: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _pass_waiter_coordinate_failure("source_integrity_failure", error_message)
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	if not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not mapper_variant is Dictionary:
		return _pass_waiter_coordinate_failure("invalid_live_boundary", "E081 ROM call requires complete live RAM, stack, and mapper state.")
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	var callsite := int(call_contract.get("callsite_pc", -1))
	var target := int(call_contract.get("target_pc", -1))
	var return_word := int(call_contract.get("return_word", -1))
	var return_pc := int(call_contract.get("return_pc", -1))
	var expected_targets := {0xE0A7: 0xCE2D, 0xE0AB: 0x8000,
		0xE0B1: 0xCD7C, 0xE0CB: 0xCE08, 0xE0CE: 0xE854}
	if not expected_targets.has(callsite) or target != int(expected_targets[callsite]):
		return _pass_waiter_coordinate_failure("unsupported_e081_rom_call", "The E081 call contract does not identify a supported fixed-ROM or bank-$1A worker callee.")
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != callsite \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("bank_low", -1)) != 0x1A \
			or int(mapper.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("fixed_low", -1)) != 0x1E \
			or int(mapper.get("fixed_high", -1)) != 0x1F \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack \
			or bool(boundary.get("trace_state_used", true)) \
			or bool(boundary.get("test_fixture", true)):
		return _pass_waiter_coordinate_failure("invalid_live_boundary", "The E081 ROM call must use the active, non-fixture `$1A/$1B` slot-$05 boundary.")
	if String(call_contract.get("rom_sha256", "")) != ROM_SHA256 \
			or return_word != callsite + 2 or return_pc != callsite + 3 \
			or int(call_contract.get("sp_before_push", -1)) != int(boundary.get("sp", -2)) \
			or bool(call_contract.get("trace_state_used", true)) \
			or bool(call_contract.get("test_fixture", true)):
		return _pass_waiter_coordinate_failure("invalid_e081_call_contract", "E081 call return word, stack, or provenance does not match the live source boundary.")
	var caller_bytes := FileAccess.get_file_as_bytes(
			"res://reference/rom_extract/gameplay/pass_waiter_field_caller_E081/fixed_field_caller_E081_E0DE.bin")
	var caller_offset := callsite - 0xE081
	if caller_bytes.size() != 94 \
			or _sha256(caller_bytes) != "d5c9912b82292028e430cba0615751ec0f95c433df07b6738118c8f9c71261b9" \
			or caller_offset < 0 or caller_offset + 3 > caller_bytes.size() \
			or caller_bytes[caller_offset] != 0x20 \
			or caller_bytes[caller_offset + 1] != (target & 0xFF) \
			or caller_bytes[caller_offset + 2] != ((target >> 8) & 0xFF):
		return _pass_waiter_coordinate_failure("source_integrity_failure", "The hash-pinned E081 caller JSR bytes do not match this ROM call contract.")
	var registers := {"a": int(boundary.get("a", -1)),
		"x": int(boundary.get("x", -1)), "y": int(boundary.get("y", -1)),
		"p": int(boundary.get("p", -1)),
		"p_known_mask": int(boundary.get("p_known_mask", -1)),
		"sp": int(boundary.get("sp", -1)), "pc": callsite}
	var entry_sp := int(registers["sp"])
	for register_name: String in ["a", "x", "y", "p", "p_known_mask", "sp"]:
		var register_value := int(registers[register_name])
		if register_value < 0 or register_value > 0xFF:
			return _pass_waiter_coordinate_failure("invalid_live_boundary", "The E081 ROM call has invalid register %s." % register_name)
	var resume_state := {"registers": registers, "mapper": mapper.duplicate(true),
		"ram_image": ram.duplicate(), "stack_page": stack.duplicate()}
	_load_resume_state(resume_state, target)
	if not _push((return_word >> 8) & 0xFF, callsite, 0x1F) \
			or not _push(return_word & 0xFF, callsite, 0x1F):
		return _pass_waiter_coordinate_failure("call_frame_push_failed", "Could not push the source JSR return word for the E081 ROM callee.")
	_calls.append({"callsite": callsite, "target": target,
		"bank": _current_bank_for_pc(target), "sp_after_push": _sp,
		"return_word": return_word, "return_pc": return_pc,
		"source_call_contract_verified": true})
	_instructions.append({"pc": callsite, "bank": 0x1F, "opcode": 0x20,
		"next_pc": target, "source_contract_verified": true})
	var instruction_limit := 20000
	while _pc != return_pc and _instructions.size() < instruction_limit:
		if _pc == 0xCB0F:
			return _pass_waiter_coordinate_failure("nested_scheduler_yield", "The E081 ROM callee reached `$CB0F`; its nested task wait requires a separate scheduler handoff.")
		if not _execute_one():
			return _pass_waiter_coordinate_failure("source_execution_failed", error_message if not error_message.is_empty() else "Unsupported ROM instruction at `$%04X`." % _pc)
	if _pc != return_pc:
		return _pass_waiter_coordinate_failure("instruction_bound_exceeded", "The E081 ROM callee did not return within its instruction bound.")
	var return_instruction: Dictionary = _instructions.back() if not _instructions.is_empty() else {}
	if int(return_instruction.get("opcode", -1)) != 0x60 \
			or int(return_instruction.get("next_pc", -1)) != return_pc \
			or _sp != entry_sp:
		return _pass_waiter_coordinate_failure("source_return_contract_mismatch", "The E081 ROM callee did not make a natural RTS with the caller's original stack pointer.")
	var pcs: Array[int] = []
	for instruction_variant: Variant in _instructions:
		if instruction_variant is Dictionary:
			pcs.append(int((instruction_variant as Dictionary).get("pc", -1)))
	return {"ok": true, "status": "pass_waiter_rom_call_returned",
		"rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"entry_pc": callsite, "target_pc": target, "exit_pc": return_pc,
		"exit_bank": _current_bank_for_pc(return_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
			"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high,
			"select": _mmc3_select, "fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": _ram.duplicate(), "stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true), "mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true), "instructions": _instructions.duplicate(true),
		"source_instruction_pcs": pcs,
		"executed_source_spans": _executed_source_span_records(),
		"caller_source_evidence": {"path": "res://reference/rom_extract/gameplay/pass_waiter_field_caller_E081/fixed_field_caller_E081_E0DE.bin",
			"sha256": "d5c9912b82292028e430cba0615751ec0f95c433df07b6738118c8f9c71261b9",
			"cpu_address": callsite, "bytes_hex": caller_bytes.slice(caller_offset, caller_offset + 3).hex_encode()},
		"call_contract": call_contract.duplicate(true),
		"call_return_verified": true, "trace_state_used": false,
		"emulator_data_used": false, "test_fixture": false,
		"source_cycle_timing_modeled": false}


func _pass_waiter_field_continuation_result(resume_state: Dictionary,
		ok: bool, result_status: String) -> Dictionary:
	var mapper: Dictionary = resume_state.get("mapper", {}).duplicate(true)
	return {"ok": ok, "status": result_status,
		"error": error_message if not ok else "",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"entry_pc": 0xD568, "entry_bank": 0x1E,
		"entry_registers": resume_state.get("registers", {}).duplicate(true),
		"entry_mapper": mapper,
		"exit_kind": "source_pc_stop" if ok else result_status,
		"exit_pc": _pc, "exit_bank": _current_bank_for_pc(_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
			"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high,
			"select": _mmc3_select, "fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"executed_source_spans": _executed_source_span_records(),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_tail": _instruction_trace_tail(),
		"instruction_count": _instructions.size(),
		"trace_state_used": false, "emulator_data_used": false,
		"test_fixture": false, "runtime_integrated": false}


func _instruction_trace_tail() -> Array[String]:
	var result: Array[String] = []
	var start_index := maxi(0, _instructions.size() - 12)
	for index in range(start_index, _instructions.size()):
		var instruction: Dictionary = _instructions[index]
		result.append("$%04X/bank$%02X->$%04X[%02X]" % [int(instruction.get("pc", -1)),
			int(instruction.get("bank", -1)), int(instruction.get("next_pc", -1)),
			int(instruction.get("opcode", -1))])
	return result


## Bridges only the renderer-return RTS at `$D96F` after the generic worker
## reports that this exact ROM byte is outside its worker manifest. The input
## must be the live partial result from `resume_dispatched_slot05_worker`; this
## method consumes the verified outer `$D834->$D8F7` return frame and returns
## the source caller state at `$D837`. It deliberately stops there.
func execute_pass_receiver_scan_return_bridge(worker_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured and not configure_from_project_sources():
		return _pass_receiver_scan_return_failure("source_integrity_failure", error_message)
	var registers_variant: Variant = worker_result.get("registers", {})
	var mapper_variant: Variant = worker_result.get("mapper", {})
	var ram_variant: Variant = worker_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_result.get("stack_page", PackedByteArray())
	var dispatch_variant: Variant = worker_result.get("source_dispatch", {})
	var blocked_variant: Variant = worker_result.get("blocked_read", {})
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not dispatch_variant is Dictionary or not blocked_variant is Dictionary:
		return _pass_receiver_scan_return_failure("malformed_worker_boundary",
			"PASS scan-return bridge requires the complete failed worker result, including CPU, mapper, RAM, stack, dispatch, and blocked-read receipts.")
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var dispatch: Dictionary = dispatch_variant
	var blocked: Dictionary = blocked_variant
	var sp := int(registers.get("sp", -1))
	var p := int(registers.get("p", -1))
	var p_known_mask := int(registers.get("p_known_mask", -1))
	if String(worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(worker_result.get("source_manifest", "")) != MANIFEST_PATH \
			or String(worker_result.get("source_manifest_sha256", "")) != _manifest_sha256() \
			or String(worker_result.get("exit_kind", "")) != "unresolved_source_span" \
			or int(worker_result.get("exit_pc", -1)) != PASS_RECEIVER_SCAN_RETURN_PC \
			or int(worker_result.get("exit_bank", -1)) != 0x1E \
			or int(blocked.get("instruction_pc", -1)) != PASS_RECEIVER_SCAN_RETURN_PC \
			or int(blocked.get("requested_address", -1)) != PASS_RECEIVER_SCAN_RETURN_PC \
			or int(blocked.get("bank", -1)) != 0x1E \
			or String(dispatch.get("rom_sha256", "")) != ROM_SHA256 \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != 0x8889 \
			or int(dispatch.get("bank", -1)) != 0x18 \
			or not bool(dispatch.get("source_dispatch_observed", false)) \
			or int(registers.get("pc", -1)) != PASS_RECEIVER_SCAN_RETURN_PC \
			or sp < 2 or sp > 0xFD \
			or p < 0 or p > 0xFF or (p & FLAG_U) == 0 \
			or p_known_mask < 0 or p_known_mask > 0xFF \
			or (p_known_mask & FLAG_U) == 0:
		return _pass_receiver_scan_return_failure("invalid_live_return_boundary",
			"Partial worker result does not prove the live slot-$05 `$8889->$D96F` unresolved-source boundary and observed dispatch.")
	if ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack \
			or int(mapper.get("fixed_low", -1)) != 0x1E \
			or int(mapper.get("fixed_high", -1)) != 0x1F \
			or int(mapper.get("bank_low", -1)) < 0 or int(mapper.get("bank_low", -1)) > 0xFF \
			or int(mapper.get("bank_high", -1)) < 0 or int(mapper.get("bank_high", -1)) > 0xFF \
			or int(mapper.get("select", -1)) < 0 or int(mapper.get("select", -1)) > 0xFF:
		return _pass_receiver_scan_return_failure("invalid_live_return_memory",
			"PASS scan-return bridge requires matching 2 KiB RAM/stack and a complete fixed/MMC3 mapper state.")
	var expected_return_frame := PackedByteArray([0x36, 0xD8])
	var expected_inner_renderer_frame := PackedByteArray([0x6E, 0xD9])
	var observed_return_frame := PackedByteArray([
		int(stack[(sp + 1) & 0xFF]), int(stack[(sp + 2) & 0xFF])])
	var observed_inner_frame := PackedByteArray([
		int(stack[(sp - 1) & 0xFF]), int(stack[sp & 0xFF])])
	if observed_return_frame != expected_return_frame \
			or observed_inner_frame != expected_inner_renderer_frame:
		return _pass_receiver_scan_return_failure("invalid_live_return_stack",
			"The `$D96F` RTS requires the stale `$D96E` renderer frame and live `$D836` caller frame at the exact stack offsets.")
	if not _pass_receiver_input_scan_span is Dictionary \
			or int(_pass_receiver_input_scan_span.get("return_opcode", -1)) != 0x60 \
			or int(_pass_receiver_input_scan_span.get("return_pc", -1)) != PASS_RECEIVER_SCAN_RETURN_PC:
		return _pass_receiver_scan_return_failure("source_integrity_failure",
			"The checked receiver-scan manifest does not expose the pinned `$D96F` RTS byte.")
	for register_name: String in ["a", "x", "y"]:
		if not registers.has(register_name) or int(registers[register_name]) < 0 \
				or int(registers[register_name]) > 0xFF:
			return _pass_receiver_scan_return_failure("invalid_live_return_registers",
				"PASS scan-return bridge requires byte-sized live A/X/Y registers.")
	var input_ram := ram.duplicate()
	var input_p := p
	var input_p_known_mask := p_known_mask
	var input_a := int(registers["a"]) & 0xFF
	var input_x := int(registers["x"]) & 0xFF
	var input_y := int(registers["y"]) & 0xFF
	_load_return_bridge_state(registers, mapper, ram, stack)
	_reset_execution_trace()
	_pass_receiver_scan_return_source_active = true
	var executed := _execute_one()
	_pass_receiver_scan_return_source_active = false
	if not executed:
		return _pass_receiver_scan_return_failure("source_execution_failed", error_message)
	var output_ram := _ram.duplicate()
	var output_stack := _ram.slice(0x0100, 0x0200)
	var source_instruction_valid := _instructions.size() == 1 \
			and int(_instructions[0].get("pc", -1)) == PASS_RECEIVER_SCAN_RETURN_PC \
			and int(_instructions[0].get("bank", -1)) == 0x1E \
			and int(_instructions[0].get("opcode", -1)) == 0x60 \
			and int(_instructions[0].get("next_pc", -1)) == PASS_RECEIVER_SCAN_RETURN_TARGET
	if not source_instruction_valid or _pc != PASS_RECEIVER_SCAN_RETURN_TARGET \
			or _sp != ((sp + 2) & 0xFF) \
			or _a != input_a or _x != input_x or _y != input_y \
			or _p != input_p or _p_known_mask != input_p_known_mask \
			or output_ram != input_ram or not _writes.is_empty() \
			or not _mapper_writes.is_empty() or not _calls.is_empty():
		return _pass_receiver_scan_return_failure("source_contract_mismatch",
			"ROM `$D96F` RTS did not preserve RAM/registers/flags or consume exactly its two-byte `$D836` caller frame.")
	var output_registers := {"a": _a, "x": _x, "y": _y, "p": _p,
		"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc}
	var output_mapper := {"bank_low": _bank_low, "bank_high": _bank_high,
		"select": _mmc3_select, "fixed_low": 0x1E, "fixed_high": 0x1F}
	var next_boundary := {
		"rom_sha256": ROM_SHA256,
		"slot_base": 0x05,
		"active_task_slot": 0x05,
		"phase": 2,
		"pc": PASS_RECEIVER_SCAN_RETURN_TARGET,
		"executing_cpu_bank": 0x1E,
		"sp": _sp,
		"a": _a, "x": _x, "y": _y, "p": _p,
		"p_known_mask": _p_known_mask,
		"bank_low": _bank_low, "bank_high": _bank_high,
		"mapper": output_mapper.duplicate(true),
		"registers": output_registers.duplicate(true),
		"ram_image": output_ram.duplicate(),
		"stack_page": output_stack.duplicate(),
		"source_label": "ROM `$D96F` RTS returned from PASS receiver descriptor renderer to `$D837`",
		"trace_state_used": false,
		"test_fixture": bool(worker_result.get("test_fixture", false)),
	}
	return {
		"ok": true,
		"status": "pass_receiver_scan_returned_to_d837",
		"rom_sha256": ROM_SHA256,
		"source_manifest": PASS_RECEIVER_INPUT_MANIFEST_PATH,
		"source_manifest_sha256": PASS_RECEIVER_INPUT_MANIFEST_SHA256,
		"worker_source_manifest": MANIFEST_PATH,
		"worker_source_manifest_sha256": _manifest_sha256(),
		"entry_pc": PASS_RECEIVER_SCAN_RETURN_PC,
		"entry_bank": 0x1E,
		"exit_pc": PASS_RECEIVER_SCAN_RETURN_TARGET,
		"exit_bank": 0x1E,
		"exit_kind": "source_return_boundary",
		"registers": output_registers,
		"mapper": output_mapper,
		"ram_image": output_ram.duplicate(),
		"stack_page": output_stack.duplicate(),
		"next_boundary_snapshot": next_boundary,
		"source_instruction_pcs": [PASS_RECEIVER_SCAN_RETURN_PC],
		"instructions": _instructions.duplicate(true),
		"executed_source_spans": _executed_source_span_records(),
		"return_receipt": {
			"source_pc": PASS_RECEIVER_SCAN_RETURN_PC,
			"opcode": 0x60,
			"target_pc": PASS_RECEIVER_SCAN_RETURN_TARGET,
			"bank": 0x1E,
			"source_resource": String(_pass_receiver_input_scan_span.get("resource", "")),
			"source_span_sha256": String(_pass_receiver_input_scan_span.get("sha256", "")),
			"manifest": PASS_RECEIVER_INPUT_MANIFEST_PATH,
			"manifest_sha256": PASS_RECEIVER_INPUT_MANIFEST_SHA256,
			"consumed_return_word": observed_return_frame.duplicate(),
			"stale_renderer_return_word": observed_inner_frame.duplicate(),
			"sp_before": sp,
			"sp_after": _sp,
			"ram_unchanged": true,
			"registers_a_x_y_unchanged": true,
			"flags_unchanged": true,
			"trace_state_used": false,
		},
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instruction_count": _instructions.size(),
		"route_boundary_observed": not bool(worker_result.get("test_fixture", false)),
		"input_boundary_fixture": bool(worker_result.get("test_fixture", false)),
		"trace_state_used": false,
		"runtime_integrated": false,
	}


func _load_return_bridge_state(registers: Dictionary, mapper: Dictionary,
		ram: PackedByteArray, stack: PackedByteArray) -> void:
	_ram = ram.duplicate()
	for index in range(STACK_PAGE_SIZE):
		_ram[0x0100 + index] = stack[index]
	_a = int(registers["a"]) & 0xFF
	_x = int(registers["x"]) & 0xFF
	_y = int(registers["y"]) & 0xFF
	_p = int(registers["p"]) & 0xFF
	_p_known_mask = int(registers["p_known_mask"]) & 0xFF
	_sp = int(registers["sp"]) & 0xFF
	_pc = PASS_RECEIVER_SCAN_RETURN_PC
	_bank_low = int(mapper["bank_low"]) & 0xFF
	_bank_high = int(mapper["bank_high"]) & 0xFF
	_mmc3_select = int(mapper["select"]) & 0xFF


func _pass_receiver_scan_return_failure(status: String, message: String) -> Dictionary:
	error_message = message
	return {
		"ok": false,
		"status": status,
		"error": message,
		"rom_sha256": ROM_SHA256,
		"source_manifest": PASS_RECEIVER_INPUT_MANIFEST_PATH,
		"source_manifest_sha256": PASS_RECEIVER_INPUT_MANIFEST_SHA256,
		"trace_state_used": false,
		"runtime_integrated": false,
	}



## Executes one source-owned neutral field-loop iteration after the scheduler
## restores slot-$05 at fixed-bank `$E14A`. The ROM's `$E349` input routine
## returns to `$E147`, whose real `$CB0F` call frame is preserved before the
## missing task-save callee is reported as an explicit source boundary.
func resume_dispatched_slot05_field_loop(resume_state: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked worker spans before executing the slot-$05 field loop.")
		return {}
	var mapper_variant: Variant = resume_state.get("mapper", {})
	if not mapper_variant is Dictionary:
		_fail("Slot-$05 field-loop continuation requires its source MMC3 mapper state.")
		return {}
	var mapper: Dictionary = mapper_variant
	var bank_low := int(mapper.get("bank_low", -1))
	var bank_high := int(mapper.get("bank_high", -1))
	if not ((bank_low == 0x1C and bank_high == 0x1D) \
			or (bank_low == 0x1A and bank_high == 0x1B)):
		_fail("Slot-$05 field-loop continuation requires a source-proven $1A/$1B or $1C/$1D mapper pair.")
		return {}
	if not _validate_resume_state(resume_state, 0xE14A, bank_low, bank_high, 0x1F):
		return {}
	_load_resume_state(resume_state, 0xE14A)
	_bounded_source_stop_address = -1
	_bounded_source_stop_reached = false
	var instruction_limit := 256
	while _instructions.size() < instruction_limit:
		if _pc == 0xD193:
			# This ROM routine crosses an asynchronous `$EF7F->$800C->$CB0F`
			# scheduler handoff. Let the dedicated clock-tick executor consume
			# the live boundary instead of running it atomically here.
			_blocked_read = {"instruction_pc": _pc, "requested_address": _pc,
				"bank": _current_bank_for_pc(_pc),
				"reason": "Dedicated D193 source executor owns this async routine."}
			var d193_boundary := _incomplete_resume_result(resume_state)
			d193_boundary["source_executor_handoff"] = "rom_clock_tick_d193_worker"
			return d193_boundary
		if not _execute_one():
			return _incomplete_resume_result(resume_state)
		if _pc == 0xCB0F:
			# The exact JSR and stack frame came from ROM bytes. Stop before
			# fetching the scheduler-owned opcode; its save handler is out of scope.
			_stop_before_unmodeled_task_yield_opcode()
			return _incomplete_resume_result(resume_state)
	_fail("Slot-$05 field loop did not reach its source `$E147->$CB0F` boundary within 256 instructions.")
	return {}


## Resumes the yielded source field-input caller at `$E412`. It executes the
## ROM input routine and neutral-loop continuation until the next `$E40F`
## yield call, scenario `$44`'s nested `$CB0F`, or the `$8003` bank handoff.
func resume_dispatched_slot05_field_input_iteration(resume_state: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked worker spans before executing the field-input continuation.")
		return {}
	var mapper_variant: Variant = resume_state.get("mapper", {})
	if not mapper_variant is Dictionary:
		_fail("Field-input continuation requires its source MMC3 mapper state.")
		return {}
	var mapper: Dictionary = mapper_variant
	var bank_low := int(mapper.get("bank_low", -1))
	var bank_high := int(mapper.get("bank_high", -1))
	var source_field_pair := bank_low == 0x1A and bank_high == 0x1B
	var entry_field_pair := bank_low == 0x1C and bank_high == 0x1D
	# The previous E412 iteration may execute the ROM's E44A->$8000 field
	# update and leave the worker mapped to 1A/1B. The scheduler accepts that
	# result only after checking the source call and both hash-pinned spans.
	if not source_field_pair and not entry_field_pair:
		_fail("Field-input continuation mapper must be the source-proven $1A/$1B or $1C/$1D pair.")
		return {}
	if not _validate_resume_state(resume_state, 0xE412, bank_low, bank_high, 0x1F):
		return {}
	_load_resume_state(resume_state, 0xE412)
	_bounded_source_stop_address = -1
	_bounded_source_stop_reached = false
	# This continuation can run the bounded ten-record scan, its coordinate
	# helpers, and the 64-entry `$CB8B` OAM-hide loop before a source boundary.
	# Keep a safety bound without truncating that ROM path mid-loop.
	var instruction_limit := 4096
	while _instructions.size() < instruction_limit:
		if _pc == 0xE40F:
			return _source_execution_boundary_result(resume_state,
				"field_input_loop_before_yield", "source_call_boundary")
		if _pc == 0x8003:
			return _source_execution_boundary_result(resume_state,
				"field_input_transfer_to_bank1a", "source_jump_boundary")
		if _pc == 0xCB0F:
			_stop_before_unmodeled_task_yield_opcode()
			return _incomplete_resume_result(resume_state)
		if not _execute_one():
			return _incomplete_resume_result(resume_state)
	_fail("Slot-$05 `$E412` field-input continuation did not reach a source call/jump boundary within its instruction bound.")
	return _incomplete_resume_result(resume_state)


## Executes the source-owned scenario-$44 caller target `$8003` using the
## accepted `$E38F` handoff state. It runs until a mapped source gap, a task
## trampoline, a return to `$8003`, or its instruction bound; no endpoint is
## injected and no PPU/APU timing is synthesized.
func execute_scenario44_field_entry(handoff_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked field-entry source spans before execution.")
		return {}
	var registers_variant: Variant = handoff_result.get("registers", {})
	var mapper_variant: Variant = handoff_result.get("mapper", {})
	var ram_variant: Variant = handoff_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = handoff_result.get("stack_page", PackedByteArray())
	if String(handoff_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(handoff_result.get("status", "")) != "scenario44_field_runtime_entered" \
			or int(handoff_result.get("exit_pc", -1)) != 0x8003 \
			or not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray:
		_fail("Scenario-$44 field entry requires the live ROM `$E38F->$8003` handoff result.")
		return {}
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	if ram.size() != RAM_SIZE or stack.size() != 0x100 \
			or ram.slice(0x0100, 0x0200) != stack \
			or int(registers.get("pc", -1)) != 0x8003 \
			or int(registers.get("sp", -1)) != 0x50 \
			or int(mapper.get("bank_low", -1)) != 0x1A \
			or int(mapper.get("bank_high", -1)) != 0x1B \
			or int(ram[0x0518]) != 0x44:
		_fail("Scenario-$44 field entry CPU, RAM, stack, or mapper state is inconsistent with `$8003`.")
		return {}
	var resume_state := {
		"source_dispatch": {"rom_sha256": ROM_SHA256, "slot_base": 0x05,
			"resume_path": "scenario44_rom_entry", "pc": 0x8003,
			"bank": 0x1A, "source_dispatch_observed": true},
		"registers": registers.duplicate(true),
		"mapper": {"bank_low": int(mapper["bank_low"]),
			"bank_high": int(mapper["bank_high"]),
			"select": int(mapper.get("register_select", 7))},
		"ram_image": ram.duplicate(), "stack_page": stack.duplicate(),
	}
	_load_resume_state(resume_state, 0x8003)
	_bounded_source_stop_address = -1
	_bounded_source_stop_reached = false
	for unused in range(4096):
		if _pc in [0xC515, 0xCB0F] or (_pc == 0x8003 and not _instructions.is_empty()):
			return _source_execution_boundary_result(resume_state,
				"scenario44_field_entry_source_call_boundary", "source_call_boundary")
		if not _execute_one():
			var stopped := _incomplete_resume_result(resume_state)
			stopped["ok"] = true
			stopped["status"] = "scenario44_field_entry_source_boundary"
			stopped["runtime_integrated"] = false
			stopped["execution_scope"] = "ROM-byte execution from `$8003` up to the first unmapped or unsupported source boundary"
			return stopped
	_fail("Scenario-$44 field entry exceeded its 4096-instruction source bound.")
	var bounded_result := _incomplete_resume_result(resume_state)
	bounded_result["ok"] = true
	bounded_result["status"] = "scenario44_field_entry_instruction_bound"
	bounded_result["runtime_integrated"] = false
	return bounded_result


## Executes the live scenario-$18 field update from its current ROM boundary to
## the next `$CB0F` yield. This can be the ordinary `$E775` one-frame update
## wait or a later scenario queue; the callsite decides which transition it is.
func execute_scenario18_pass_result_from_live_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked PASS-result spans before execution.")
		return {}
	var registers: Dictionary = {
		"a": int(boundary.get("a", -1)), "x": int(boundary.get("x", -1)),
		"y": int(boundary.get("y", -1)), "p": int(boundary.get("p", -1)),
		"p_known_mask": int(boundary.get("p_known_mask", -1)),
		"sp": int(boundary.get("sp", -1)), "pc": int(boundary.get("pc", -1)),
	}
	var mapper_variant: Variant = boundary.get("mapper", {})
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	if not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		_fail("Scenario-$18 PASS result requires live mapper, RAM, and stack snapshots.")
		return {}
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var entry_pc := int(boundary.get("pc", -1))
	var initial_entry := entry_pc == 0x8112
	var resumed_entry := entry_pc == 0xE778
	var dispatch_variant: Variant = boundary.get("source_dispatch", {})
	var source_dispatch: Dictionary = dispatch_variant if dispatch_variant is Dictionary else {}
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or not (initial_entry or resumed_entry) \
			or (initial_entry and int(boundary.get("sp", -1)) != 0x50) \
			or (resumed_entry and (String(source_dispatch.get("resume_path", "")) != "yielded_rts" \
				or not bool(source_dispatch.get("source_dispatch_observed", false)))) \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("bank_low", -1)) != 0x1A \
			or int(mapper.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("select", mapper.get("register_select", -1))) < 0 \
			or registers["p"] < 0 or registers["p_known_mask"] < 0 \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack or int(ram[0x0518]) != 0x18:
		_fail("Scenario-$18 field update is not a live `$8112` entry or scheduler-restored `$E778` slot-$05 boundary.")
		return {}
	var resume_state := {
		"source_dispatch": source_dispatch.duplicate(true) if resumed_entry else {
			"rom_sha256": ROM_SHA256, "slot_base": 0x05,
			"resume_path": "scenario18_pass_result_entry", "pc": 0x8112,
			"bank": 0x1A, "source_dispatch_observed": false},
		"registers": registers.duplicate(true),
		"mapper": {"bank_low": int(mapper.get("bank_low", 0x1A)),
			"bank_high": int(mapper.get("bank_high", 0x1B)),
			"select": int(mapper.get("select", mapper.get("register_select", 7)))},
		"ram_image": ram.duplicate(), "stack_page": stack.duplicate(),
		"trace_state_used": false, "test_fixture": false,
	}
	_load_resume_state(resume_state, entry_pc)
	for unused in range(4096):
		if _pc == 0xCB0F:
			var result := _source_execution_boundary_result(resume_state,
				"scenario18_pass_result_source_call_boundary", "source_call_boundary")
			var source_call: Dictionary = {}
			for call_variant in _calls:
				if call_variant is Dictionary:
					var call: Dictionary = call_variant
					if int(call.get("target", -1)) == 0xCB0F:
						source_call = call.duplicate(true)
			if source_call.is_empty():
				var missing_call := _source_execution_boundary_result(resume_state,
					"scenario18_pass_result_unresolved_cb0f_boundary", "source_call_boundary")
				missing_call["ok"] = false
				missing_call["source_gap_reason"] = "Scenario-$18 source reached `$CB0F` without a recorded ROM JSR callsite."
				return missing_call
			var callsite_pc := int(source_call.get("callsite", -1))
			result["call_request"] = {"callsite_pc": callsite_pc, "target_pc": 0xCB0F,
				"sp_before_push": (int(source_call.get("sp_after_push", -1)) + 2) & 0xFF,
				"call_frame_already_pushed": true}
			result["cb0f_callsite_pc"] = callsite_pc
			result["scenario_id_at_boundary"] = int(_ram[0x0518])
			result["calls_to_cb0f"] = [source_call.duplicate(true)]
			result["recent_instruction_pcs"] = _recent_instruction_pcs(12)
			if callsite_pc == 0xCBBE:
				result["scenario_id_before_queue"] = 0x18
				result["scenario_id_after_queue"] = int(_ram[0x0518])
				result["holder_id"] = int(_ram[0x0441])
				result["field_action_result"] = int(_ram[0x05FC])
			elif callsite_pc != 0xE775:
				result["status"] = "scenario18_pass_result_unresolved_cb0f_boundary"
				result["source_gap_reason"] = "The source `$CB0F` callsite has no scenario-$18 route contract yet."
			return result
		if not _execute_one():
			var stopped := _incomplete_resume_result(resume_state)
			stopped["ok"] = false
			stopped["status"] = "scenario18_pass_result_source_gap"
			stopped["execution_scope"] = "ROM-byte execution from `$8112` to the first unmapped or unsupported source boundary"
			return stopped
	_fail("Scenario-$18 PASS-result handler exceeded its 4096-instruction source bound.")
	return _incomplete_resume_result(resume_state)


## Resumes scenario `$44`'s packet producer after the scheduler returns from its
## first `$F018->$CB0F` yield. The saved worker result proves the predecessor;
## all execution state comes from the live slot-$05 dispatch.
func resume_scenario44_field_entry_worker(resume_state: Dictionary,
		previous_worker_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked field-entry source spans before resume.")
		return {}
	var previous_registers: Variant = previous_worker_result.get("registers", {})
	var previous_mapper: Variant = previous_worker_result.get("mapper", {})
	var previous_stack: Variant = previous_worker_result.get("stack_page", PackedByteArray())
	var previous_calls: Variant = previous_worker_result.get("calls", [])
	var previous_spans: Variant = previous_worker_result.get("executed_source_spans", [])
	var previous_boundary: Variant = previous_worker_result.get("source_boundary", {})
	if not previous_registers is Dictionary or not previous_mapper is Dictionary \
			or not previous_stack is PackedByteArray or not previous_calls is Array \
			or not previous_spans is Array or not previous_boundary is Dictionary \
			or String(previous_worker_result.get("status", "")) not in [\
				"scenario44_field_entry_source_call_boundary", \
				"scenario44_field_entry_resume_source_call_boundary"] \
			or String(previous_worker_result.get("exit_kind", "")) != "source_call_boundary" \
			or String(previous_worker_result.get("rom_sha256", "")) != ROM_SHA256 \
			or String(previous_worker_result.get("source_manifest", "")) != MANIFEST_PATH \
			or String(previous_worker_result.get("source_manifest_sha256", "")) != _manifest_sha256() \
			or int(previous_worker_result.get("exit_pc", -1)) != 0xCB0F \
			or int(previous_boundary.get("address", -1)) != 0xCB0F \
			or int(previous_mapper.get("bank_low", -1)) != 0x1A \
			or int(previous_mapper.get("bank_high", -1)) != 0x1B:
		_fail("Scenario-$44 field-entry resume lacks its prior ROM packet-producer `$CB0F` boundary.")
		return {}
	var prior_yield_call_pc := -1
	for call_variant in previous_calls:
		if call_variant is Dictionary:
			var call: Dictionary = call_variant
			if int(call.get("callsite", -1)) in [0xF018, 0xF0A8, 0xD5BD, 0xCC50, 0xCCA0, 0xCCCE] \
					and int(call.get("target", -1)) == 0xCB0F \
					and int(call.get("sp_after_push", -1)) == int(previous_registers.get("sp", -2)):
				prior_yield_call_pc = int(call["callsite"])
	var prior_packet_code_seen := false
	for span_variant in previous_spans:
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			var span_file := String(span.get("file", ""))
			var span_sha256 := String(span.get("sha256", ""))
			if prior_yield_call_pc == 0xD5BD:
				prior_packet_code_seen = prior_packet_code_seen \
						or (span_file == "fixed_field_update_dispatch_D565_D600.bin" \
						and span_sha256 == "fef8713ab595c20f8a968c5771fcb94ab929e3092349f3d73340462b22be1947")
			elif prior_yield_call_pc in [0xCC50, 0xCCA0, 0xCCCE]:
				prior_packet_code_seen = prior_packet_code_seen \
						or (span_file == "fixed_shared_waiter_CC46_CCD2.bin" \
						and span_sha256 == "21a4cd33eb56fe3d4da516e0eff910ff375a8d7c3ff42bfa46dfb691a846d5cc")
			else:
				prior_packet_code_seen = prior_packet_code_seen \
						or (span_file == "fixed_first_command_packet_code_F015_F15A.bin" \
						and span_sha256 == "df7c650c952fb5dfc9a8a10de43f739c9fc4cbdef343bae7ba70c4921a281dc9")
	var prior_sp := int(previous_registers.get("sp", -1)) & 0xFF
	var prior_return_word := prior_yield_call_pc + 2
	if prior_yield_call_pc < 0 or not prior_packet_code_seen \
			or (previous_stack as PackedByteArray).size() != 0x100 \
			or int((previous_stack as PackedByteArray)[(prior_sp + 1) & 0xFF]) != (prior_return_word & 0xFF) \
			or int((previous_stack as PackedByteArray)[(prior_sp + 2) & 0xFF]) != ((prior_return_word >> 8) & 0xFF):
		_fail("Previous field-entry result does not prove the ROM call frame and packet-producer bytes.")
		return {}
	var dispatch_variant: Variant = resume_state.get("source_dispatch", {})
	var dispatch: Dictionary = dispatch_variant if dispatch_variant is Dictionary else {}
	var resume_pc := int(dispatch.get("pc", -1))
	if resume_pc != prior_return_word + 1 or resume_pc not in [0xF01B, 0xF0AB, 0xD5C0,
			0xCC53, 0xCCA3, 0xCCD1]:
		_fail("Scenario-$44 field-entry scheduler return does not match the previous ROM callsite.")
		return {}
	var expected_dispatch_bank := 0x1E if resume_pc in [0xD5C0, 0xCC53, 0xCCA3, 0xCCD1] else 0x1F
	if not _validate_resume_state(resume_state, resume_pc, 0x1A, 0x1B,
			expected_dispatch_bank):
		return {}
	_load_resume_state(resume_state, resume_pc)
	_bounded_source_stop_address = -1
	_bounded_source_stop_reached = false
	for unused in range(4096):
		if _pc in [0xCB0F, 0xC515, 0x8003]:
			return _source_execution_boundary_result(resume_state,
				"scenario44_field_entry_resume_source_call_boundary", "source_call_boundary")
		if not _execute_one():
			var stopped := _incomplete_resume_result(resume_state)
			stopped["ok"] = true
			stopped["status"] = "scenario44_field_entry_resume_source_boundary"
			stopped["runtime_integrated"] = false
			return stopped
	_fail("Scenario-$44 field-entry resume exceeded its 4096-instruction source bound.")
	return _incomplete_resume_result(resume_state)


## Continue the active slot-$05 worker from its currently adopted scheduler
## boundary. The old worker result proves continuity only; the current snapshot
## supplies every CPU, RAM, stack, and bank input.
func resume_slot05_live_worker_boundary(live_boundary: Dictionary,
		previous_worker_result: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		_fail("Configure hash-checked worker spans before execution.")
		return {}
	var previous_blocked: Dictionary = previous_worker_result.get("blocked_read", {})
	var previous_registers: Dictionary = previous_worker_result.get("registers", {})
	var previous_mapper: Dictionary = previous_worker_result.get("mapper", {})
	var previous_ram: PackedByteArray = previous_worker_result.get("ram_image", PackedByteArray())
	var previous_stack: PackedByteArray = previous_worker_result.get("stack_page", PackedByteArray())
	var live_ram: PackedByteArray = live_boundary.get("ram_image", PackedByteArray())
	var live_stack: PackedByteArray = live_boundary.get("stack_page", PackedByteArray())
	if String(previous_worker_result.get("exit_kind", "")) != "source_read_boundary" \
			or int(previous_worker_result.get("exit_pc", -1)) != 0x89A0 \
			or int(previous_blocked.get("requested_address", -1)) != 0xBD9C \
			or int(live_boundary.get("slot_base", -1)) != 0x05 \
			or int(live_boundary.get("active_task_slot", -1)) != 0x05 \
			or int(live_boundary.get("phase", -1)) != 2 \
			or int(live_boundary.get("pc", -1)) != 0x89A0 \
			or live_ram.size() != RAM_SIZE or live_stack.size() != 0x100 \
			or previous_ram != live_ram or previous_stack != live_stack \
			or int(live_boundary.get("a", -1)) != int(previous_registers.get("a", -2)) \
			or int(live_boundary.get("x", -1)) != int(previous_registers.get("x", -2)) \
			or int(live_boundary.get("y", -1)) != int(previous_registers.get("y", -2)) \
			or int(live_boundary.get("p", -1)) != int(previous_registers.get("p", -2)) \
			or int(live_boundary.get("p_known_mask", -1)) != int(previous_registers.get("p_known_mask", -2)) \
			or int(live_boundary.get("sp", -1)) != int(previous_registers.get("sp", -2)) \
			or int(live_boundary.get("bank_low", -1)) != int(previous_mapper.get("bank_low", -2)) \
			or int(live_boundary.get("bank_high", -1)) != int(previous_mapper.get("bank_high", -2)) \
			or int(previous_mapper.get("select", -1)) < 0 or int(previous_mapper.get("select", -1)) > 0xFF \
			or int(live_ram[0x0028]) != 0 or int(live_ram[0x003C]) != 1 \
			or int(live_ram[0x003E]) != 0x9C or int(live_ram[0x003F]) != 0xBD:
		_fail("Slot-$05 continuation is not the live adopted `$89A0->$BD9C` boundary.")
		return {}
	_ram = live_ram.duplicate()
	_a = int(live_boundary["a"]) & 0xFF
	_x = int(live_boundary["x"]) & 0xFF
	_y = int(live_boundary["y"]) & 0xFF
	_p = (int(live_boundary["p"]) | FLAG_U) & 0xFF
	_p_known_mask = int(live_boundary["p_known_mask"]) & 0xFF
	_sp = int(live_boundary["sp"]) & 0xFF
	_pc = 0x89A0
	_bank_low = int(live_boundary["bank_low"]) & 0xFF
	_bank_high = int(live_boundary["bank_high"]) & 0xFF
	_mmc3_select = int(previous_mapper["select"]) & 0xFF
	_bounded_source_stop_address = -1
	_bounded_source_stop_reached = false
	_reset_execution_trace()
	for unused in range(8192):
		if _at_resume_boundary():
			return {
				"ok": true, "rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
				"source_manifest_sha256": _manifest_sha256(),
				"executed_source_spans": _executed_source_span_records(),
				"source_continuation": {"entry_pc": 0x89A0, "source_pointer": 0xBD9C,
					"parent_blocked_address": int(previous_blocked["requested_address"])},
				"exit_kind": "yield_at_c515", "exit_pc": _pc,
				"exit_bank": _current_bank_for_pc(_pc),
				"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
					"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
				"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
					"fixed_low": 0x1E, "fixed_high": 0x1F},
				"ram_image": _ram.duplicate(), "stack_page": _ram.slice(0x0100, 0x0200),
				"writes": _writes.duplicate(true), "mapper_writes": _mapper_writes.duplicate(true),
				"calls": _calls.duplicate(true), "instructions": _instructions.duplicate(true),
				"instruction_count": _instructions.size(), "runtime_integrated": false,
			}
		if not _execute_one():
			return {
				"ok": false, "rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
				"source_manifest_sha256": _manifest_sha256(),
				"executed_source_spans": _executed_source_span_records(),
				"source_continuation": {"entry_pc": 0x89A0, "source_pointer": 0xBD9C,
					"parent_blocked_address": int(previous_blocked["requested_address"])},
				"exit_kind": "unresolved_source_span" if not _blocked_read.is_empty() else "unsupported_source_opcode",
				"exit_pc": _pc, "exit_bank": _current_bank_for_pc(_pc),
				"blocked_read": _blocked_read.duplicate(true), "unsupported_opcode": _unsupported_opcode.duplicate(true),
				"error": error_message,
				"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
					"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
				"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
					"fixed_low": 0x1E, "fixed_high": 0x1F},
				"ram_image": _ram.duplicate(), "stack_page": _ram.slice(0x0100, 0x0200),
				"writes": _writes.duplicate(true), "mapper_writes": _mapper_writes.duplicate(true),
				"calls": _calls.duplicate(true), "instructions": _instructions.duplicate(true),
				"instruction_count": _instructions.size(), "runtime_integrated": false,
			}
	_fail("Slot-$05 live continuation exceeded its instruction bound.")
	return {}


## Validates the ROM-owned descriptor path before the resumed worker is allowed
## to read its dynamic text tokens. This proves the live `$0515` branch and the
## hash-checked lookup/descriptor/text/callback bytes; it does not synthesize
## the pointer or claim that an unexecuted `$F0` row was consumed.
func validate_resumed_worker_descriptor_contract(resume_state: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return {"ok": false, "status": "unconfigured", "reason": "Configure hash-checked worker spans first."}
	if not _validate_resume_state(resume_state):
		return {"ok": false, "status": "invalid_live_resume_state", "reason": error_message}
	var registers: Dictionary = resume_state["registers"]
	var mapper: Dictionary = resume_state["mapper"]
	var ram: PackedByteArray = resume_state["ram_image"]
	var flag_0515 := int(ram[0x0515])
	if flag_0515 != 0:
		return {
			"ok": true,
			"status": "source_reyield_before_descriptor",
			"live_flag_0515": flag_0515,
			"worker_branch_pc": 0x8889,
			"descriptor_tokens_reached": false,
		}
	if int(mapper.get("bank_high", -1)) != 0x19:
		return {"ok": false, "status": "unsupported_descriptor_bank", "reason": "Live descriptor table must be mapped in bank $19."}
	var lookup: PackedByteArray = _sources["bank19_worker_lookup_B3BD_B3D1.bin"]
	var descriptor: PackedByteArray = _sources["bank19_match_descriptor_B453_B464.bin"]
	var lookup_second: PackedByteArray = _sources["bank19_worker_lookup_tail_B3D1_B3D3.bin"]
	var descriptor01: PackedByteArray = _sources["bank19_match_descriptor_B464_B475.bin"]
	var descriptor01_row00: PackedByteArray = _sources["bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin"]
	var text_lead: PackedByteArray = _sources["bank19_resumed_worker_text_lead_BBDC_BBDE.bin"]
	var text_second_row: PackedByteArray = _sources["bank19_resumed_worker_text_row01_BBDE_BBE0.bin"]
	var ef_callback: PackedByteArray = _sources["bank18_callback_pointer_89D8_89DA.bin"]
	var fc_callback: PackedByteArray = _sources["bank18_fc_callback_return_8C52_8C55.bin"]
	var descriptor_pointer := int(lookup[18]) | (int(lookup[19]) << 8)
	var text_pointer := int(descriptor[11]) | (int(descriptor[12]) << 8)
	var descriptor01_pointer := int(lookup_second[0]) | (int(lookup_second[1]) << 8)
	var descriptor01_text_pointer := int(descriptor01[11]) | (int(descriptor01[12]) << 8)
	var descriptor01_next_row_pointer := int(descriptor01[15]) | (int(descriptor01[16]) << 8)
	if descriptor_pointer != 0xB453 or text_pointer != 0xBBDC \
			or descriptor01_pointer != 0xB464 or descriptor01_text_pointer != 0xBBE0 \
			or descriptor01_next_row_pointer != 0xBD9C \
			or descriptor01_row00 != PackedByteArray([0xED, 0x00, 0xFC]) \
			or text_lead != PackedByteArray([0xEF, 0xFC]) \
			or text_second_row != PackedByteArray([0xF0, 0xFC]) \
			or ef_callback != PackedByteArray([0x48, 0x8B]) \
			or fc_callback != PackedByteArray([0x68, 0x68, 0x60]):
		return {"ok": false, "status": "unsupported_descriptor_source", "reason": "Hash-checked lookup, descriptor, text lead, or callback bytes differ from the resumed worker contract."}
	return {
		"ok": true,
		"status": "descriptor_source_validated_for_live_worker",
		"live_flag_0515": flag_0515,
		"live_cpu": {"a": int(registers["a"]), "x": int(registers["x"]),
			"y": int(registers["y"]), "sp": int(registers["sp"]), "pc": int(registers["pc"])},
		"live_bank_pair": [int(mapper["bank_low"]), int(mapper["bank_high"])],
		"descriptor_table_pointer_cpu": 0xB453,
		"descriptor_text_pointer_cpu": text_pointer,
		"second_descriptor_pointer_cpu": descriptor01_pointer,
		"descriptor01_text_pointer_cpu": descriptor01_text_pointer,
		"descriptor01_row00_hex": descriptor01_row00.hex_encode(),
		"descriptor01_next_row_pointer_cpu": descriptor01_next_row_pointer,
		"descriptor01_next_row_executed": false,
		"descriptor_text_lead_hex": text_lead.hex_encode(),
		"descriptor_second_row_hex": text_second_row.hex_encode(),
		"descriptor_second_row_source_validated": true,
		"ef_callback_cpu": int(ef_callback[0]) | (int(ef_callback[1]) << 8),
		"fc_callback_cpu": 0x8C52,
		"descriptor_tokens_expected": [0xEF, 0xFC],
		"next_descriptor_row_token": 0xF0,
		"next_descriptor_row_executed": false,
		"source_manifest_sha256": _manifest_sha256(),
	}


## Validates the ROM `$EE 00 FC` handler/formatter return from the adopted live `$BD9C` boundary.
## The worker reaches `$C515`; the descriptor identifies `$BBE3` as the following row, but
## the live text pointer does not advance to it within this worker invocation.
func validate_descriptor01_ee_row00_boundary(live_boundary: Dictionary,
		previous_worker_result: Dictionary, worker_result: Dictionary) -> Dictionary:
	var registers_variant: Variant = worker_result.get("registers", {})
	var mapper_variant: Variant = worker_result.get("mapper", {})
	var ram_variant: Variant = worker_result.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_result.get("stack_page", PackedByteArray())
	var continuation_variant: Variant = worker_result.get("source_continuation", {})
	var previous_blocked_variant: Variant = previous_worker_result.get("blocked_read", {})
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not continuation_variant is Dictionary or not previous_blocked_variant is Dictionary:
		return {"ok": false, "status": "malformed_live_continuation"}
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var continuation: Dictionary = continuation_variant
	var previous_blocked: Dictionary = previous_blocked_variant
	var input_ram: PackedByteArray = live_boundary.get("ram_image", PackedByteArray())
	var descriptor_tail: PackedByteArray = _sources["bank19_match_descriptor_B475_B47D.bin"]
	if String(worker_result.get("source_manifest_sha256", "")) != _manifest_sha256() \
			or String(previous_worker_result.get("source_manifest_sha256", "")) != _manifest_sha256() \
			or String(previous_worker_result.get("exit_kind", "")) != "source_read_boundary" \
			or int(previous_worker_result.get("exit_pc", -1)) != 0x89A0 \
			or int(previous_blocked.get("requested_address", -1)) != 0xBD9C \
			or int(live_boundary.get("active_task_slot", -1)) != 0x05 \
			or int(live_boundary.get("pc", -1)) != 0x89A0 \
			or input_ram.size() != RAM_SIZE or int(input_ram[0x0028]) != 0 \
			or int(input_ram[0x003C]) != 1 \
			or int(continuation.get("entry_pc", -1)) != 0x89A0 \
			or int(continuation.get("source_pointer", -1)) != 0xBD9C \
			or not bool(worker_result.get("ok", false)) \
			or String(worker_result.get("exit_kind", "")) != "yield_at_c515" \
			or int(worker_result.get("exit_pc", -1)) != 0xC515 \
			or int(registers.get("pc", -1)) != 0xC515 \
			or int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or ram.size() != RAM_SIZE or stack.size() != 0x100 \
			or ram.slice(0x0100, 0x0200) != stack \
			or int(ram[0x003E]) != 0x9C or int(ram[0x003F]) != 0xBD \
			or int(ram[0x003C]) != 1 or int(ram[0x0515]) != 0x80 \
			or int(ram[0x05C5]) != 2:
		return {"ok": false, "status": "descriptor01_ee_row00_boundary_mismatch",
			"exit_pc": int(worker_result.get("exit_pc", -1)),
			"live_text_pointer": int(ram[0x003E]) | (int(ram[0x003F]) << 8),
			"previous_exit_kind": String(previous_worker_result.get("exit_kind", "")),
			"previous_blocked": previous_blocked.duplicate(true),
			"live": {"slot": int(live_boundary.get("active_task_slot", -1)),
				"pc": int(live_boundary.get("pc", -1)), "selector": int(input_ram[0x0028]),
				"progress": int(input_ram[0x003C])},
			"worker": {"ok": bool(worker_result.get("ok", false)),
				"kind": String(worker_result.get("exit_kind", "")),
				"pc": int(worker_result.get("exit_pc", -1)),
				"manifest_match": String(worker_result.get("source_manifest_sha256", "")) == _manifest_sha256(),
				"parent_manifest_match": String(previous_worker_result.get("source_manifest_sha256", "")) == _manifest_sha256(),
				"register_pc": int(registers.get("pc", -1)),
				"banks": [int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1))],
				"progress": int(ram[0x003C]), "ready": int(ram[0x0515]), "progress_state": int(ram[0x05C5]),
				"stack_matches": ram.slice(0x0100, 0x0200) == stack}}
	var pcs := {}
	var early_branch := false
	var fc_return := false
	for instruction_variant in worker_result.get("instructions", []):
		if not instruction_variant is Dictionary:
			continue
		var instruction: Dictionary = instruction_variant
		var pc := int(instruction.get("pc", -1))
		pcs[pc] = true
		if pc == 0x8C58 and int(instruction.get("next_pc", -1)) == 0x8C84:
			early_branch = true
		if pc == 0x8C54 and int(instruction.get("next_pc", -1)) == 0x896C:
			fc_return = true
	for required_pc in [0x8B2F, 0x8C55, 0x8C58, 0x8C84, 0x8C52, 0x8C54, 0x896C]:
		if not pcs.has(required_pc):
			return {"ok": false, "status": "missing_source_pc", "pc": required_pc}
	var early_rts := false
	for instruction_variant in worker_result.get("instructions", []):
		if instruction_variant is Dictionary:
			var instruction: Dictionary = instruction_variant
			if int(instruction.get("pc", -1)) == 0x8C84 \
					and int(instruction.get("opcode", -1)) == 0x60:
				early_rts = true
	if not early_branch or not fc_return or not early_rts:
		return {"ok": false, "status": "ee_early_return_or_fc_chain_mismatch",
			"early_branch": early_branch, "fc_return": fc_return,
			"early_rts": early_rts,
			"trace_tail": (worker_result.get("instructions", []) as Array).slice(-16)}
	if descriptor_tail.size() != 8 \
			or (int(descriptor_tail[2]) | (int(descriptor_tail[3]) << 8)) != 0xBBE3:
		return {"ok": false, "status": "next_descriptor_row_source_mismatch"}
	var required_spans := {
		"bank19_resumed_worker_descriptor01_row01_BD9C_BD9F.bin": false,
		"bank18_ee_numeric_handler_8B2F_8B48.bin": false,
		"bank18_f0_decimal_formatter_8C55_8C85.bin": false,
	}
	for span_variant in worker_result.get("executed_source_spans", []):
		if span_variant is Dictionary:
			var name := String((span_variant as Dictionary).get("file", ""))
			if required_spans.has(name):
				required_spans[name] = true
	for name in required_spans:
		if not bool(required_spans[name]):
			return {"ok": false, "status": "missing_source_span", "file": name}
	return {"ok": true, "status": "descriptor01_ee_row00_yielded_at_c515",
		"row_cpu": 0xBD9C, "row_bytes_hex": "ee00fc", "ee_handler_cpu": 0x8B2F,
		"formatter_cpu": 0x8C55, "formatter_early_return_pc": 0x8C84,
		"fc_return_cpu": 0x8C52, "fc_return_to_pc": 0x896C,
		"worker_yield_pc": 0xC515, "live_text_pointer_after_row": 0xBD9C,
		"next_descriptor_row_cpu": 0xBBE3, "next_descriptor_row_pointer_live": false,
		"next_row_bytes_read": false,
		"live_team_selector_0028": int(input_ram[0x0028]),
		"source_progress_input": int(input_ram[0x003C]),
		"source_progress_output": int(ram[0x003C]),
		"source_manifest_sha256": _manifest_sha256()}


## Accepts only the live worker result that has consumed `$BBE0: ED 00 FC`,
## returned through the ROM inline `$FC` handler, and is blocked before the
## next row at `$BD9C`. The `$EE` row itself is deliberately not supplied.
func validate_descriptor01_ed_row00_boundary(worker_input: Dictionary,
		worker_result: Dictionary) -> Dictionary:
	var input_ram_variant: Variant = worker_input.get("ram_image", PackedByteArray())
	var result_ram_variant: Variant = worker_result.get("ram_image", PackedByteArray())
	var result_stack_variant: Variant = worker_result.get("stack_page", PackedByteArray())
	var registers_variant: Variant = worker_result.get("registers", {})
	var mapper_variant: Variant = worker_result.get("mapper", {})
	var blocked_variant: Variant = worker_result.get("blocked_read", {})
	var source_stop_variant: Variant = worker_result.get("source_boundary_stop", {})
	if not input_ram_variant is PackedByteArray or not result_ram_variant is PackedByteArray \
			or not result_stack_variant is PackedByteArray or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not blocked_variant is Dictionary \
			or not source_stop_variant is Dictionary:
		return {"ok": false, "status": "malformed_worker_boundary"}
	var input_ram: PackedByteArray = input_ram_variant
	var result_ram: PackedByteArray = result_ram_variant
	var result_stack: PackedByteArray = result_stack_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var blocked: Dictionary = blocked_variant
	var source_stop: Dictionary = source_stop_variant
	var valid := not bool(worker_result.get("ok", true)) \
		and String(worker_result.get("exit_kind", "")) == "source_read_boundary" \
		and int(source_stop.get("address", -1)) == 0xBD9C \
		and bool(source_stop.get("source_bytes_available", false)) \
		and String(worker_result.get("source_manifest_sha256", "")) == _manifest_sha256() \
		and int(worker_result.get("exit_pc", -1)) == 0x89A0 \
		and int(blocked.get("instruction_pc", -1)) == 0x89A0 \
		and int(blocked.get("requested_address", -1)) == 0xBD9C \
		and int(blocked.get("bank", -1)) == 0x19 \
		and int(registers.get("pc", -1)) == 0x89A0 \
		and int(mapper.get("bank_low", -1)) == 0x18 \
		and int(mapper.get("bank_high", -1)) == 0x19 \
		and input_ram.size() == RAM_SIZE and result_ram.size() == RAM_SIZE \
		and result_stack.size() == 0x100 \
		and int(input_ram[0x002A]) == 0 \
		and int(result_ram[0x002A]) == 0 \
		and int(result_ram[0x003C]) == 1 \
		and int(result_ram[0x0515]) == 1 \
		and int(result_ram[0x05C5]) == 0 \
		and int(result_ram[0x003E]) == 0x9C and int(result_ram[0x003F]) == 0xBD
	if not valid:
		return {"ok": false, "status": "descriptor01_ed_row00_boundary_mismatch",
			"blocked_read": blocked.duplicate(true), "result_pointer": [int(result_ram[0x003E]), int(result_ram[0x003F])]}
	for index in range(0x100):
		if result_ram[0x0100 + index] != result_stack[index]:
			return {"ok": false, "status": "stack_page_mismatch", "index": index}
	var required_pcs := {0x89A0: false, 0x896C: false, 0x8AE7: false, 0x8A6F: false,
		0x8B03: false, 0xC524: false, 0xCBC2: false, 0x8C9F: false,
		0x8C52: false, 0x8C54: false, 0x89A9: false}
	var return_index := -1
	var ee_handler_entered := false
	var instructions_variant: Variant = worker_result.get("instructions", [])
	if not instructions_variant is Array:
		return {"ok": false, "status": "missing_worker_instructions"}
	var instructions: Array = instructions_variant
	for index in range(instructions.size()):
		var instruction_variant: Variant = instructions[index]
		if not instruction_variant is Dictionary:
			continue
		var instruction: Dictionary = instruction_variant
		var pc := int(instruction.get("pc", -1))
		if pc == 0x8B2F:
			ee_handler_entered = true
		if required_pcs.has(pc):
			required_pcs[pc] = true
		if pc == 0x8C54 and int(instruction.get("next_pc", -1)) == 0x896C:
			return_index = index
	for required_pc in required_pcs:
		if not bool(required_pcs[required_pc]):
			return {"ok": false, "status": "missing_source_pc", "pc": required_pc}
	if ee_handler_entered:
		return {"ok": false, "status": "ee_handler_was_executed"}
	if return_index < 0:
		return {"ok": false, "status": "fc_return_not_observed"}
	var required_spans := {
		"bank19_match_descriptor_B464_B475.bin": false,
		"bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin": false,
		"bank18_ed_text_loop_8A56_8A86.bin": false,
		"bank18_ed_team_handler_8AE7_8B0A.bin": false,
		"bank18_ed_team_name_lengths_8B0A_8B0E.bin": false,
		"fixed_team_name_dispatch_C53C_C53F.bin": false,
		"fixed_team_name_lookup_F30F_F329.bin": false,
		"fixed_team_name_pointer_entries_76_79_F415_F41D.bin": false,
		"fixed_team_00_name_stream_F776_F77C.bin": false,
		"fixed_text_token_converter_CBC2_CBF1.bin": false,
	}
	var spans_variant: Variant = worker_result.get("executed_source_spans", [])
	if not spans_variant is Array:
		return {"ok": false, "status": "missing_executed_source_spans"}
	for span_variant in spans_variant:
		if span_variant is Dictionary:
			var file_name := String((span_variant as Dictionary).get("file", ""))
			if required_spans.has(file_name):
				required_spans[file_name] = true
	for file_name in required_spans:
		if not bool(required_spans[file_name]):
			return {"ok": false, "status": "missing_source_span", "file": file_name}
	var row_clear_seen := false
	var row_increment_seen := false
	var writes_variant: Variant = worker_result.get("writes", [])
	if not writes_variant is Array:
		return {"ok": false, "status": "missing_source_writes"}
	for write_variant in writes_variant:
		if not write_variant is Dictionary:
			continue
		var write: Dictionary = write_variant
		if int(write.get("address", -1)) == 0x003C and int(write.get("pc", -1)) == 0x8954 \
				and int(write.get("value", -1)) == 0:
			row_clear_seen = true
		if int(write.get("address", -1)) == 0x003C and int(write.get("pc", -1)) == 0x8960 \
				and int(write.get("value", -1)) == 1:
			row_increment_seen = true
	if not row_clear_seen or not row_increment_seen:
		return {"ok": false, "status": "row_progress_not_source_produced"}
	return {
		"ok": true,
		"status": "descriptor01_ed_row00_returned_before_ee_row",
		"rom_sha256": ROM_SHA256,
		"source_manifest_sha256": _manifest_sha256(),
		"row_cpu": 0xBBE0,
		"row_bytes_hex": "ed00fc",
		"ed_handler_cpu": 0x8AE7,
		"ed_text_loop_cpu": 0x8A6F,
		"fc_return_cpu": 0x8C52,
		"fc_return_to_pc": 0x896C,
		"next_row_cpu": 0xBD9C,
		"next_row_read_executed": false,
		"live_home_team_id": int(input_ram[0x002A]),
		"source_produced_row_progress": int(result_ram[0x003C]),
		"next_text_pointer": int(result_ram[0x003E]) | (int(result_ram[0x003F]) << 8),
		"result_flag_0515": int(result_ram[0x0515]),
		"source_produced_writes": {"row_clear_pc": 0x8954, "row_increment_pc": 0x8960},
	}


func _validate_e081_return_resume_boundary(boundary: Dictionary,
		return_adoption: Dictionary) -> bool:
	var mapper_variant: Variant = boundary.get("mapper", {})
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var adopted_variant: Variant = return_adoption.get("next_boundary_snapshot", {})
	if not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray or not adopted_variant is Dictionary:
		return _fail("E081 caller continuation needs the scheduler-owned return boundary and its adoption proof.")
	var mapper: Dictionary = mapper_variant
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var adopted: Dictionary = adopted_variant
	if not bool(return_adoption.get("ok", false)) \
			or String(return_adoption.get("status", "")) != "pass_waiter_e081_function_return_adopted" \
			or String(return_adoption.get("rom_sha256", "")) != ROM_SHA256 \
			or int(return_adoption.get("entry_pc", -1)) != 0xE0D1 \
			or int(return_adoption.get("exit_pc", -1)) != 0x80F0 \
			or int(return_adoption.get("return_word", -1)) != 0x80EF \
			or int(return_adoption.get("return_bank", -1)) != 0x1A \
			or String(return_adoption.get("source_manifest_sha256", "")) \
			!= "f30f3c014559c45a6ce6c70462d728951c25852ab622a0014b04ea484c7d1e82" \
			or String(return_adoption.get("source_span_sha256", "")) \
			!= "d5c9912b82292028e430cba0615751ec0f95c433df07b6738118c8f9c71261b9" \
			or String(return_adoption.get("caller_source_sha256", "")) \
			!= "cfcde4d67358fc36a7e7e67e039d7f36a046a215bcd55b962eb7decac6a7e5fd" \
			or bool(return_adoption.get("source_return_verified", false)) != true \
			or bool(return_adoption.get("trace_state_used", true)) \
			or bool(return_adoption.get("test_fixture", true)):
		return _fail("The E081 source-return adoption does not prove the pinned `$80EF->$80F0` bank-$1A continuation.")
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != 0x05 \
			or int(boundary.get("active_task_slot", -1)) != 0x05 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pc", -1)) != 0x80F0 \
			or int(boundary.get("sp", -1)) < 0 or int(boundary.get("sp", -1)) > 0xFF \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B \
			or mapper.get("bank_low", -1) != 0x1A \
			or mapper.get("bank_high", -1) != 0x1B \
			or mapper.get("fixed_low", -1) != 0x1E \
			or mapper.get("fixed_high", -1) != 0x1F \
			or ram.size() != RAM_SIZE or stack.size() != STACK_PAGE_SIZE \
			or ram.slice(0x0100, 0x0200) != stack \
			or bool(boundary.get("trace_state_used", true)) \
			or bool(boundary.get("test_fixture", true)):
		return _fail("The E081 caller state is not a clean active slot-$05 bank-$1A:$80F0 source boundary.")
	for key: String in ["pc", "sp", "a", "x", "y", "p", "p_known_mask",
			"bank_low", "bank_high", "mapper", "ram_image", "stack_page"]:
		if adopted.get(key) != boundary.get(key):
			return _fail("The scheduler adoption and E081 continuation boundary disagree on %s." % key)
	return true


func _validate_resume_state(resume_state: Dictionary, expected_pc: int = 0x8889,
		expected_bank_low: int = 0x18, expected_bank_high: int = 0x19,
		expected_dispatch_bank: int = 0x18) -> bool:
	var dispatch_variant: Variant = resume_state.get("source_dispatch", {})
	var registers_variant: Variant = resume_state.get("registers", {})
	var mapper_variant: Variant = resume_state.get("mapper", {})
	var ram_variant: Variant = resume_state.get("ram_image", PackedByteArray())
	var stack_variant: Variant = resume_state.get("stack_page", PackedByteArray())
	if not dispatch_variant is Dictionary or not registers_variant is Dictionary \
			or not mapper_variant is Dictionary or not ram_variant is PackedByteArray \
			or not stack_variant is PackedByteArray:
		return _fail("Worker resume requires source-dispatch proof, complete CPU/mapper state, full RAM image, and stack page.")
	var dispatch: Dictionary = dispatch_variant
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	if String(dispatch.get("rom_sha256", "")) != ROM_SHA256 \
			or int(dispatch.get("slot_base", -1)) != 0x05 \
			or String(dispatch.get("resume_path", "")) != "yielded_rts" \
			or int(dispatch.get("pc", -1)) != expected_pc \
			or int(dispatch.get("bank", -1)) != expected_dispatch_bank \
			or not bool(dispatch.get("source_dispatch_observed", false)):
		return _fail("Worker resume proof must identify the expected source-observed slot-$05 yielded_rts dispatch for the target ROM.")
	for name: String in ["a", "x", "y", "sp", "pc"]:
		if not registers.has(name) or int(registers[name]) < 0 or int(registers[name]) > 0xFFFF:
			return _fail("Worker resume CPU state is incomplete or invalid at register %s." % name)
	if registers.has("p") and (int(registers["p"]) < 0 or int(registers["p"]) > 0xFF):
		return _fail("Worker resume status register P must be an 8-bit value when supplied.")
	if registers.has("p_known_mask") and (int(registers["p_known_mask"]) < 0 \
			or int(registers["p_known_mask"]) > 0xFF):
		return _fail("Worker resume known-status mask must be an 8-bit value when supplied.")
	if int(registers["pc"]) != expected_pc:
		return _fail("Worker resume CPU PC must match the verified `$%04X` continuation." % expected_pc)
	if int(registers["a"]) > 0xFF or int(registers["x"]) > 0xFF \
			or int(registers["y"]) > 0xFF or int(registers["sp"]) > 0xFF:
		return _fail("Worker resume CPU registers must be 8-bit values.")
	if int(mapper.get("bank_low", -1)) != expected_bank_low \
			or int(mapper.get("bank_high", -1)) != expected_bank_high \
			or int(mapper.get("select", -1)) < 0 or int(mapper.get("select", -1)) > 0xFF:
		return _fail("Worker resume mapper state must preserve the source slot-$05 mapping and an 8-bit MMC3 selector.")
	if (ram_variant as PackedByteArray).size() != RAM_SIZE \
			or (stack_variant as PackedByteArray).size() != 0x100:
		return _fail("Worker resume requires an 2 KiB RAM image and a 256-byte stack page.")
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	if ram.slice(0x0100, 0x0200) != stack:
		return _fail("Worker resume stack page does not match bytes $0100-$01FF in its RAM image.")
	return true


func _load_resume_state(resume_state: Dictionary, entry_pc: int = 0x8889) -> void:
	var registers: Dictionary = resume_state["registers"]
	var mapper: Dictionary = resume_state["mapper"]
	_ram = (resume_state["ram_image"] as PackedByteArray).duplicate()
	var stack_page: PackedByteArray = resume_state["stack_page"]
	for index in range(0x100):
		_ram[0x0100 + index] = stack_page[index]
	_a = int(registers["a"]) & 0xFF
	_x = int(registers["x"]) & 0xFF
	_y = int(registers["y"]) & 0xFF
	_p = (int(registers["p"]) | FLAG_U) & 0xFF if registers.has("p") else FLAG_U
	_p_known_mask = (int(registers.get("p_known_mask", 0xFF)) | FLAG_U) & 0xFF \
		if registers.has("p") else FLAG_U
	_sp = int(registers["sp"]) & 0xFF
	_pc = entry_pc
	_bank_low = int(mapper["bank_low"]) & 0xFF
	_bank_high = int(mapper["bank_high"]) & 0xFF
	_mmc3_select = int(mapper["select"]) & 0xFF
	_reset_execution_trace()


func _reset_execution_trace() -> void:
	_writes.clear()
	_mapper_writes.clear()
	_calls.clear()
	_instructions.clear()
	_executed_source_files.clear()
	_executed_pass_receiver_descriptor_1d_sources.clear()
	_pass_receiver_scan_return_source_executed = false
	_stack_status_known_masks.clear()
	_blocked_read.clear()
	_unsupported_opcode.clear()


func _at_resume_boundary() -> bool:
	return _pc == 0xC515 and _current_bank_for_pc(_pc) == 0x1E


func _validate_worker_entry(worker_entry: Dictionary) -> bool:
	if not bool(worker_entry.get("ok", false)) \
			or String(worker_entry.get("rom_sha256", "")) != ROM_SHA256 \
			or int(worker_entry.get("exit_pc", -1)) != ENTRY_PC \
			or int(worker_entry.get("exit_bank", -1)) != ENTRY_BANK:
		return _fail("Worker prefix requires the source-owned bank-$18:$800C result from RomFreshDaaaContinuation.")
	var registers_variant: Variant = worker_entry.get("registers", {})
	var mapper_variant: Variant = worker_entry.get("mapper", {})
	var ram_variant: Variant = worker_entry.get("ram_image", PackedByteArray())
	var stack_variant: Variant = worker_entry.get("stack_page", PackedByteArray())
	if not registers_variant is Dictionary or not mapper_variant is Dictionary \
			or not ram_variant is PackedByteArray or not stack_variant is PackedByteArray:
		return _fail("Worker entry lacks source-derived registers, mapper, full RAM image, or stack page.")
	var registers: Dictionary = registers_variant
	var mapper: Dictionary = mapper_variant
	var source_context_variant: Variant = worker_entry.get("source_context", {})
	var source_context: Dictionary = source_context_variant if source_context_variant is Dictionary else {}
	var scenario36_descriptor00 := String(worker_entry.get("status", "")) \
			== "field_entry_first_renderer_wrapper_returned_to_bank18" \
		and String(source_context.get("kind", "")) == "field_entry_e0df_first_renderer" \
		and int(source_context.get("entry_pc", -1)) == 0xE0DF \
		and int(source_context.get("entry_bank", -1)) == 0x1F \
		and int(source_context.get("renderer_descriptor", -1)) == 0x00
	var scenario1e_minimap_descriptor30 := String(worker_entry.get("status", "")) \
			== "minimap_loader_returned_to_bank18_worker" \
		and String(source_context.get("kind", "")) == "scenario1e_minimap_loader_return" \
		and int(source_context.get("entry_pc", -1)) == 0x82E3 \
		and int(source_context.get("entry_bank", -1)) == 0x1C \
		and int(source_context.get("renderer_descriptor", -1)) == 0x30
	var incoming_p := int(registers.get("p", -1)) & 0xFF
	var incoming_p_known_mask := int(registers.get("p_known_mask", -1))
	var field_entry_status_matches := incoming_p_known_mask >= 0 \
		and incoming_p_known_mask <= 0xFF \
		and ((incoming_p ^ 0x33) & incoming_p_known_mask) == 0
	var minimap_return_registers_match := int(registers.get("a", -1)) == 0x30 \
		and int(registers.get("x", -1)) == 0x36 \
		and int(registers.get("y", -1)) == 0x30 \
		and int(registers.get("p", -1)) == 0x21 \
		and incoming_p_known_mask == 0xFF \
		and int(registers.get("sp", -1)) == 0x46
	var registers_match := minimap_return_registers_match if scenario1e_minimap_descriptor30 \
		else int(registers.get("a", -1)) == 0x00 and int(registers.get("y", -1)) == 0x00 \
		and (int(registers.get("x", -1)) == 0x50 and field_entry_status_matches \
			if scenario36_descriptor00 else int(registers.get("x", -1)) == 0x00 \
			and int(registers.get("p", -1)) == 0x23)
	if not registers_match \
			or (not scenario1e_minimap_descriptor30 and int(registers.get("sp", -1)) != 0x4A) \
			or int(mapper.get("bank_low", -1)) != 0x18 or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper.get("select", -1)) != 0x07:
		return _fail("Worker input CPU/mapper state is not a supported source-owned bank-$18:$800C entry.")
	if (ram_variant as PackedByteArray).size() != RAM_SIZE or (stack_variant as PackedByteArray).size() != 0x100:
		return _fail("Worker input RAM or stack-page size is incomplete.")
	return true


func _load_worker_entry(worker_entry: Dictionary) -> void:
	var registers: Dictionary = worker_entry["registers"]
	var mapper: Dictionary = worker_entry["mapper"]
	_ram = (worker_entry["ram_image"] as PackedByteArray).duplicate()
	var stack_page: PackedByteArray = worker_entry["stack_page"]
	for index in range(0x100):
		_ram[0x0100 + index] = stack_page[index]
	_a = int(registers["a"]) & 0xFF
	_x = int(registers["x"]) & 0xFF
	_y = int(registers["y"]) & 0xFF
	_p = (int(registers["p"]) | FLAG_U) & 0xFF
	_p_known_mask = int(registers.get("p_known_mask", 0xFF)) & 0xFF
	_sp = int(registers["sp"]) & 0xFF
	_pc = ENTRY_PC
	_bank_low = int(mapper["bank_low"]) & 0xFF
	_bank_high = int(mapper["bank_high"]) & 0xFF
	_mmc3_select = int(mapper["select"]) & 0xFF
	_reset_execution_trace()


func _at_end_boundary() -> bool:
	return _pc == END_PC and _current_bank_for_pc(_pc) == END_BANK


func _execute_one() -> bool:
	var start_pc := _pc
	var start_bank := _current_bank_for_pc(_pc)
	var accumulator_before := _a
	var status_before := _p
	var opcode := _read_cpu(_pc)
	if opcode < 0:
		return false
	_write_trace_pc = (_pc + _opcode_length(opcode)) & 0xFFFF
	match opcode:
		0x4C: # JMP abs
			_pc = _read_word(_pc + 1)
			if _pc < 0: return false
		0x6C: # JMP (abs), including the 6502 page-wrap behavior
			var pointer := _read_word(_pc + 1)
			if pointer < 0: return false
			var low := _read_cpu(pointer)
			var high_address := (pointer & 0xFF00) | ((pointer + 1) & 0x00FF)
			var high := _read_cpu(high_address)
			if low < 0 or high < 0: return false
			_pc = low | (high << 8)
		0x10, 0x30, 0x50, 0x70, 0x90, 0xB0, 0xD0, 0xF0: # conditional branches
			var displacement := _read_cpu(_pc + 1)
			if displacement < 0: return false
			if displacement >= 0x80: displacement -= 0x100
			var branch_flag_mask := FLAG_N if opcode in [0x10, 0x30] else \
				FLAG_V if opcode in [0x50, 0x70] else \
				FLAG_C if opcode in [0x90, 0xB0] else FLAG_Z
			if (_p_known_mask & branch_flag_mask) != branch_flag_mask:
				return _fail("Worker branch at $%04X depends on an unknown P flag bit $%02X." % [start_pc, branch_flag_mask])
			var branch := (opcode == 0x10 and (_p & FLAG_N) == 0) \
				or (opcode == 0x30 and (_p & FLAG_N) != 0) \
				or (opcode == 0x50 and (_p & FLAG_V) == 0) \
				or (opcode == 0x70 and (_p & FLAG_V) != 0) \
				or (opcode == 0x90 and (_p & FLAG_C) == 0) \
				or (opcode == 0xB0 and (_p & FLAG_C) != 0) \
				or (opcode == 0xD0 and (_p & FLAG_Z) == 0) \
				or (opcode == 0xF0 and (_p & FLAG_Z) != 0)
			_pc = _pc + 2 + displacement if branch else _pc + 2
		0x18: # CLC
			_set_flag(FLAG_C, false)
			_pc += 1
		0x38: # SEC
			_set_flag(FLAG_C, true)
			_pc += 1
		0x60: # RTS
			var return_low := _pop(start_pc, start_bank)
			var return_high := _pop(start_pc, start_bank)
			if return_low < 0 or return_high < 0: return false
			_pc = ((return_high << 8) | return_low) + 1
		0x48: # PHA
			if not _push(_a, start_pc, start_bank): return false
			_pc += 1
		0x08: # PHP
			var php_stack_address := 0x0100 | _sp
			if not _push((_p | FLAG_B | FLAG_U) & 0xFF, start_pc, start_bank): return false
			_stack_status_known_masks[php_stack_address] = (_p_known_mask | FLAG_B | FLAG_U) & 0xFF
			_pc += 1
		0x28: # PLP
			var plp_stack_address := 0x0100 | ((_sp + 1) & 0xFF)
			var status_known_mask := int(_stack_status_known_masks.get(plp_stack_address, 0))
			var restored_status := _pop(start_pc, start_bank)
			if restored_status < 0: return false
			_p = (restored_status | FLAG_U) & ~FLAG_B & 0xFF
			_p_known_mask = (status_known_mask | FLAG_U) & ~FLAG_B & 0xFF
			_pc += 1
		0x68: # PLA
			_a = _pop(start_pc, start_bank)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 1
		0x6A: # ROR A; bank-$1A field-coordinate helper at $8FB5
			if (_p_known_mask & FLAG_C) != FLAG_C:
				return _fail("Worker ROR A at $%04X depends on an unknown carry flag." % start_pc)
			var carry_in := 0x80 if (_p & FLAG_C) != 0 else 0
			_set_flag(FLAG_C, (_a & 0x01) != 0)
			_a = ((_a >> 1) | carry_in) & 0xFF
			_set_nz(_a)
			_pc += 1
		0xA8: # TAY
			_y = _a
			_set_nz(_y)
			_pc += 1
		0x88: # DEY
			_y = (_y - 1) & 0xFF
			_set_nz(_y)
			_pc += 1
		0xC8: # INY
			_y = (_y + 1) & 0xFF
			_set_nz(_y)
			_pc += 1
		0x0A: # ASL A
			_set_flag(FLAG_C, (_a & 0x80) != 0)
			_a = (_a << 1) & 0xFF
			_set_nz(_a)
			_pc += 1
		0x2A: # ROL A
			if (_p_known_mask & FLAG_C) != FLAG_C:
				return _fail("Worker ROL A at $%04X depends on an unknown carry flag." % start_pc)
			var carry_in := 1 if (_p & FLAG_C) != 0 else 0
			_set_flag(FLAG_C, (_a & 0x80) != 0)
			_a = ((_a << 1) | carry_in) & 0xFF
			_set_nz(_a)
			_pc += 1
		0xAA: # TAX
			_x = _a
			_set_nz(_x)
			_pc += 1
		0x8A: # TXA
			_a = _x
			_set_nz(_a)
			_pc += 1
		0x9A: # TXS; transfer X to the CPU stack pointer without changing flags
			_sp = _x
			_pc += 1
		0xBD: # LDA abs,X
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu((address + _x) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0x85: # STA zp
			var address := _read_cpu(_pc + 1)
			if address < 0 or not _write_cpu(address, _a, start_pc, start_bank): return false
			_pc += 2
		0x98: # TYA
			_a = _y
			_set_nz(_a)
			_pc += 1
		0x29: # AND #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_a &= value
			_set_nz(_a)
			_pc += 2
		0x09: # ORA #imm; fixed mapper helper $CE2D
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_a = (_a | value) & 0xFF
			_set_nz(_a)
			_pc += 2
		0x0D: # ORA abs; D193 clock routine post-scheduler continuation
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_a = (_a | value) & 0xFF
			_set_nz(_a)
			_pc += 3
		0xC5: # CMP zp; used by the ROM match-clock divider
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_compare(_a, value)
			_pc += 2
		0x4A: # LSR A
			_set_flag(FLAG_C, (_a & 0x01) != 0)
			_a = (_a >> 1) & 0xFF
			_set_nz(_a)
			_pc += 1
		0x46: # LSR zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_set_flag(FLAG_C, (value & 0x01) != 0)
			value = (value >> 1) & 0xFF
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_set_nz(value)
			_pc += 2
		0x4E: # LSR abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_set_flag(FLAG_C, (value & 0x01) != 0)
			value = (value >> 1) & 0xFF
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_set_nz(value)
			_pc += 3
		0xB9: # LDA abs,Y
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu((address + _y) & 0xFFFF)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0xBE: # LDX abs,Y; bank-$1C field-action parameter selection at $81BB
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_x = _read_cpu((address + _y) & 0xFFFF)
			if _x < 0: return false
			_set_nz(_x)
			_pc += 3
		0xCA: # DEX
			_x = (_x - 1) & 0xFF
			_set_nz(_x)
			_pc += 1
		0x8D: # STA abs
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu(address, _a, start_pc, start_bank): return false
			_pc += 3
		0x8E: # STX abs
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu(address, _x, start_pc, start_bank): return false
			_pc += 3
		0x8C: # STY abs
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu(address, _y, start_pc, start_bank): return false
			_pc += 3
		0x99: # STA abs,Y
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu((address + _y) & 0xFFFF, _a, start_pc, start_bank): return false
			_pc += 3
		0x9D: # STA abs,X
			var address := _read_word(_pc + 1)
			if address < 0 or not _write_cpu((address + _x) & 0xFFFF, _a, start_pc, start_bank): return false
			_pc += 3
		0x86: # STX zp
			var address := _read_cpu(_pc + 1)
			if address < 0 or not _write_cpu(address, _x, start_pc, start_bank): return false
			_pc += 2
		0x84: # STY zp
			var address := _read_cpu(_pc + 1)
			if address < 0 or not _write_cpu(address, _y, start_pc, start_bank): return false
			_pc += 2
		0xAD: # LDA abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_a = _read_cpu(address)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 3
		0xAE: # LDX abs; source $ED team-name handler reads the live home-team selector
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_x = _read_cpu(address)
			if _x < 0: return false
			_set_nz(_x)
			_pc += 3
		0xA5: # LDA zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			_a = _read_cpu(address)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 2
		0xA4, 0xA6: # LDY zp, LDX zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			if opcode == 0xA4:
				_y = value
				_set_nz(_y)
			else:
				_x = value
				_set_nz(_x)
			_pc += 2
		0xAC: # LDY abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			_y = _read_cpu(address)
			if _y < 0: return false
			_set_nz(_y)
			_pc += 3
		0xA0, 0xA2: # LDY #, LDX #
			var immediate := _read_cpu(_pc + 1)
			if immediate < 0: return false
			if opcode == 0xA0:
				_y = immediate
				_set_nz(_y)
			else:
				_x = immediate
				_set_nz(_x)
			_pc += 2
		0xB1: # LDA (zp),Y
			var target := _indirect_target(_pc + 1)
			if target < 0: return false
			var value := _read_cpu((target + _y) & 0xFFFF)
			if value < 0: return false
			_a = value
			_set_nz(_a)
			_pc += 2
		0x11: # ORA (zp),Y
			var target := _indirect_target(_pc + 1)
			if target < 0: return false
			var value := _read_cpu((target + _y) & 0xFFFF)
			if value < 0: return false
			_a = (_a | value) & 0xFF
			_set_nz(_a)
			_pc += 2
		0x71: # ADC (zp),Y
			var target := _indirect_target(_pc + 1)
			if target < 0: return false
			var value := _read_cpu((target + _y) & 0xFFFF)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 2
		0x91: # STA (zp),Y
			var target := _indirect_target(_pc + 1)
			if target < 0 or not _write_cpu((target + _y) & 0xFFFF, _a, start_pc, start_bank): return false
			_pc += 2
		0xD1: # CMP (zp),Y
			var target := _indirect_target(_pc + 1)
			if target < 0: return false
			var value := _read_cpu((target + _y) & 0xFFFF)
			if value < 0: return false
			_compare(_a, value)
			_pc += 2
		0x6D: # ADC abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 3
		0x79: # ADC abs,Y
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu((address + _y) & 0xFFFF)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 3
		0x7D: # ADC abs,X
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu((address + _x) & 0xFFFF)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 3
		0x65: # ADC zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 2
		0xA9: # LDA #imm
			_a = _read_cpu(_pc + 1)
			if _a < 0: return false
			_set_nz(_a)
			_pc += 2
		0x69: # ADC #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_add_with_carry(value)
			_pc += 2
		0xE9: # SBC #imm; 2A03 ignores decimal mode
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_add_with_carry(value ^ 0xFF)
			_pc += 2
		0xE5: # SBC zp; used by the ROM match-clock divider
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_add_with_carry(value ^ 0xFF)
			_pc += 2
		0xED: # SBC abs; NES 2A03 ignores decimal mode
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_add_with_carry(value ^ 0xFF)
			_pc += 3
		0xE8: # INX
			_x = (_x + 1) & 0xFF
			_set_nz(_x)
			_pc += 1
		0xE6, 0xC6: # INC zp, DEC zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			value = (value + (1 if opcode == 0xE6 else -1)) & 0xFF
			_set_nz(value)
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_pc += 2
		0xEE, 0xCE: # INC abs, DEC abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			value = (value + (1 if opcode == 0xEE else -1)) & 0xFF
			_set_nz(value)
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_pc += 3
		0xE0: # CPX #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_compare(_x, value)
			_pc += 2
		0xEC: # CPX abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_compare(_x, value)
			_pc += 3
		0xC0: # CPY #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_compare(_y, value)
			_pc += 2
		0xC9: # CMP #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_compare(_a, value)
			_pc += 2
		0x49: # EOR #imm
			var value := _read_cpu(_pc + 1)
			if value < 0: return false
			_a = (_a ^ value) & 0xFF
			_set_nz(_a)
			_pc += 2
		0xCD: # CMP abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_compare(_a, value)
			_pc += 3
		0x24: # BIT zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_set_flag(FLAG_N, (value & 0x80) != 0)
			_set_flag(FLAG_V, (value & 0x40) != 0)
			_set_flag(FLAG_Z, (_a & value) == 0)
			_pc += 2
		0x2C: # BIT abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			_set_flag(FLAG_N, (value & 0x80) != 0)
			_set_flag(FLAG_V, (value & 0x40) != 0)
			_set_flag(FLAG_Z, (_a & value) == 0)
			_pc += 3
		0x66: # ROR zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			if (_p_known_mask & FLAG_C) != FLAG_C:
				return _fail("Worker ROR zp at $%04X depends on an unknown carry flag." % start_pc)
			var carry_in := 0x80 if (_p & FLAG_C) != 0 else 0
			_set_flag(FLAG_C, (value & 0x01) != 0)
			value = ((value >> 1) | carry_in) & 0xFF
			_set_nz(value)
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_pc += 2
		0x6E: # ROR abs
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			if (_p_known_mask & FLAG_C) != FLAG_C:
				return _fail("Worker ROR abs at $%04X depends on an unknown carry flag." % start_pc)
			var carry_in := 0x80 if (_p & FLAG_C) != 0 else 0
			_set_flag(FLAG_C, (value & 0x01) != 0)
			value = ((value >> 1) | carry_in) & 0xFF
			_set_nz(value)
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_pc += 3
		0x26: # ROL zp
			var address := _read_cpu(_pc + 1)
			if address < 0: return false
			var value := _read_cpu(address)
			if value < 0: return false
			var carry_in := 1 if (_p & FLAG_C) != 0 else 0
			_set_flag(FLAG_C, (value & 0x80) != 0)
			value = ((value << 1) | carry_in) & 0xFF
			_set_nz(value)
			if not _write_cpu(address, value, start_pc, start_bank): return false
			_pc += 2
		0x1D: # ORA abs,X
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu((address + _x) & 0xFFFF)
			if value < 0: return false
			_a = (_a | value) & 0xFF
			_set_nz(_a)
			_pc += 3
		0x19: # ORA abs,Y
			var address := _read_word(_pc + 1)
			if address < 0: return false
			var value := _read_cpu((address + _y) & 0xFFFF)
			if value < 0: return false
			_a = (_a | value) & 0xFF
			_set_nz(_a)
			_pc += 3
		0xD8: # CLD
			_p &= ~0x08
			_p |= FLAG_U
			_p_known_mask |= 0x28
			_pc += 1
		0x20: # JSR
			_write_trace_pc = (_pc + 2) & 0xFFFF
			var target := _read_word(_pc + 1)
			if target < 0: return false
			var return_minus_one := (_pc + 2) & 0xFFFF
			if not _push((return_minus_one >> 8) & 0xFF, start_pc, start_bank) \
					or not _push(return_minus_one & 0xFF, start_pc, start_bank): return false
			_calls.append({"callsite": start_pc, "target": target,
				"bank": _current_bank_for_pc(target), "sp_after_push": _sp})
			_pc = target
		_:
			_unsupported_opcode = {"pc": start_pc, "bank": start_bank, "opcode": opcode}
			return _fail("Unsupported worker-prefix opcode $%02X at $%04X (bank $%02X)." % [opcode, start_pc, start_bank])
	var instruction_record := {"pc": start_pc, "bank": start_bank, "opcode": opcode, "next_pc": _pc}
	if start_pc >= 0xCBC2 and start_pc < 0xCBF1:
		instruction_record["a_before"] = accumulator_before
		instruction_record["p_before"] = status_before
		instruction_record["a_after"] = _a
		instruction_record["p_after"] = _p
	_instructions.append(instruction_record)
	return true


func _add_with_carry(value: int) -> void:
	var before := _a
	var sum := before + value + (1 if (_p & FLAG_C) != 0 else 0)
	_set_flag(FLAG_C, sum > 0xFF)
	_set_flag(FLAG_V, ((~(before ^ value) & (before ^ sum)) & 0x80) != 0)
	_a = sum & 0xFF
	_set_nz(_a)


func _compare(register_value: int, operand: int) -> void:
	var difference := (register_value & 0xFF) - (operand & 0xFF)
	_set_flag(FLAG_C, difference >= 0)
	_set_nz(difference & 0xFF)


func _read_word(address: int) -> int:
	var low := _read_cpu(address)
	var high := _read_cpu(address + 1)
	if low < 0 or high < 0: return -1
	return low | (high << 8)


func _indirect_target(operand_pc: int) -> int:
	var zp_address := _read_cpu(operand_pc)
	if zp_address < 0:
		return -1
	return int(_ram[zp_address & 0xFF]) | (int(_ram[(zp_address + 1) & 0xFF]) << 8)


func _read_cpu(address: int) -> int:
	if address < 0 or address > 0xFFFF:
		_fail("Worker-prefix read outside address space at $%X." % address)
		return -1
	if _pass_receiver_scan_return_source_active \
			and address == PASS_RECEIVER_SCAN_RETURN_PC \
			and int(_pass_receiver_input_scan_span.get("return_opcode", -1)) == 0x60:
		var scan_bytes: PackedByteArray = _pass_receiver_input_scan_span.get("bytes", PackedByteArray())
		var scan_offset := int(_pass_receiver_input_scan_span.get("return_offset", -1))
		if scan_offset >= 0 and scan_offset < scan_bytes.size():
			_pass_receiver_scan_return_source_executed = true
			return int(scan_bytes[scan_offset])
		_fail("Pinned PASS receiver scan byte `$D96F` is outside its checked source span.")
		return -1
	if _pc == 0x89A0 and _bounded_source_stop_address >= 0 \
			and address == _bounded_source_stop_address:
		_bounded_source_stop_reached = true
		_blocked_read = {"instruction_pc": _pc, "requested_address": address,
			"bank": _current_bank_for_pc(address),
			"reason": "Caller-selected stop before this mapped source row."}
		return -1
	if address < 0x2000:
		return int(_ram[address & 0x07FF])
	var bank := _current_bank_for_pc(address)
	for file_name: String in SOURCE_FILES:
		var spec: Dictionary = SOURCE_FILES[file_name]
		if int(spec["bank"]) == bank and address >= int(spec["start"]) and address < int(spec["end"]):
			_executed_source_files[file_name] = true
			return int((_sources[file_name] as PackedByteArray)[address - int(spec["start"])])
	for source_variant: Variant in _pass_receiver_descriptor_1d_spans:
		if not source_variant is Dictionary:
			continue
		var source: Dictionary = source_variant
		if int(source.get("bank", -1)) == bank \
				and address >= int(source.get("start", -1)) \
				and address < int(source.get("end", -1)):
			var source_bytes: PackedByteArray = source.get("bytes", PackedByteArray())
			var source_name := String(source.get("name", ""))
			_executed_pass_receiver_descriptor_1d_sources[source_name] = true
			return int(source_bytes[address - int(source["start"])])
	_blocked_read = {"instruction_pc": _pc, "requested_address": address, "bank": bank,
		"reason": "ROM byte is not present in the hash-checked source manifest."}
	_fail("Worker-prefix ROM read $%04X in bank $%02X is outside preserved spans while executing $%04X." % [address, bank, _pc])
	return -1


func _stop_before_unmodeled_task_yield_opcode() -> void:
	_blocked_read = {
		"instruction_pc": _pc,
		"requested_address": _pc,
		"bank": _current_bank_for_pc(_pc),
		"opcode_fetch_attempted": false,
		"reason": "Source JSR reached scheduler-owned `$CB0F`; stopped before fetching its unmodeled save-handler opcode.",
	}
	_fail("ROM-byte worker stopped at the source `$CB0F` scheduler entry before opcode fetch.")


func _incomplete_resume_result(resume_state: Dictionary) -> Dictionary:
	var entry_mapper_variant: Variant = resume_state.get("mapper", {})
	var entry_mapper: Dictionary = entry_mapper_variant.duplicate(true) \
		if entry_mapper_variant is Dictionary else {}
	return {
		"ok": false,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"executed_source_spans": _executed_source_span_records(),
		"source_dispatch": (resume_state["source_dispatch"] as Dictionary).duplicate(true),
		"entry_mapper": entry_mapper,
		"exit_kind": "source_read_boundary" if _bounded_source_stop_reached else \
			("unresolved_source_span" if not _blocked_read.is_empty() else "unsupported_source_opcode"),
		"exit_pc": _pc,
		"exit_bank": _current_bank_for_pc(_pc),
		"blocked_read": _blocked_read.duplicate(true),
		"source_boundary_stop": {"address": _bounded_source_stop_address,
			"source_bytes_available": true} if _bounded_source_stop_reached else {},
		"unsupported_opcode": _unsupported_opcode.duplicate(true),
		"error": error_message,
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
			"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high, "select": _mmc3_select,
			"fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"runtime_integrated": false,
	}


func _recent_instruction_pcs(max_count: int) -> Array[int]:
	var output: Array[int] = []
	var first_index := maxi(0, _instructions.size() - maxi(0, max_count))
	for instruction_index in range(first_index, _instructions.size()):
		if _instructions[instruction_index] is Dictionary:
			output.append(int((_instructions[instruction_index] as Dictionary).get("pc", -1)))
	return output


func _source_execution_boundary_result(resume_state: Dictionary, boundary_status: String,
		exit_kind: String) -> Dictionary:
	var entry_mapper_variant: Variant = resume_state.get("mapper", {})
	var entry_mapper: Dictionary = entry_mapper_variant.duplicate(true) \
		if entry_mapper_variant is Dictionary else {}
	var entry_registers_variant: Variant = resume_state.get("registers", {})
	var entry_registers: Dictionary = entry_registers_variant.duplicate(true) \
		if entry_registers_variant is Dictionary else {}
	return {
		"ok": true,
		"status": boundary_status,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_manifest_sha256": _manifest_sha256(),
		"trace_state_used": bool(resume_state.get("trace_state_used", false)),
		"emulator_data_used": bool(resume_state.get("trace_state_used", false)),
		"test_fixture": bool(resume_state.get("test_fixture", false)),
		"executed_source_spans": _executed_source_span_records(),
		"source_dispatch": (resume_state["source_dispatch"] as Dictionary).duplicate(true),
		"entry_registers": entry_registers,
		"entry_mapper": entry_mapper,
		"exit_kind": exit_kind,
		"exit_pc": _pc,
		"exit_bank": _current_bank_for_pc(_pc),
		"registers": {"a": _a, "x": _x, "y": _y, "p": _p,
			"p_known_mask": _p_known_mask, "sp": _sp, "pc": _pc},
		"mapper": {"bank_low": _bank_low, "bank_high": _bank_high,
			"select": _mmc3_select, "fixed_low": 0x1E, "fixed_high": 0x1F},
		"ram_image": _ram.duplicate(),
		"stack_page": _ram.slice(0x0100, 0x0200),
		"writes": _writes.duplicate(true),
		"mapper_writes": _mapper_writes.duplicate(true),
		"calls": _calls.duplicate(true),
		"instructions": _instructions.duplicate(true),
		"instruction_count": _instructions.size(),
		"source_boundary": {"status": boundary_status, "address": _pc,
			"source_bytes_available": true},
		"runtime_integrated": false,
	}


func _requested_source_pc_boundary(resume_state: Dictionary, source_pc: int,
		source_pc_evidence: Array[Dictionary]) -> Dictionary:
	if source_pc != _pc or source_pc_evidence.is_empty():
		_fail("Requested source-PC boundary is not at the current PC or has no mapped byte evidence.")
		return {}
	var result := _source_execution_boundary_result(resume_state,
		"requested_source_pc_boundary", "source_pc_stop")
	result["source_pc_evidence"] = source_pc_evidence.duplicate(true)
	result["writes_ordered_by_execution"] = true
	result["mapper_writes_ordered_by_execution"] = true
	var source_boundary: Dictionary = result.get("source_boundary", {})
	source_boundary["requested_source_pc"] = source_pc
	source_boundary["source_pc_evidence"] = source_pc_evidence.duplicate(true)
	source_boundary["bank"] = _current_bank_for_pc(source_pc)
	source_boundary["validated"] = true
	result["source_boundary"] = source_boundary
	return result


func _source_pc_evidence(source_pc: int) -> Array[Dictionary]:
	var bank := _current_bank_for_pc(source_pc)
	var evidence: Array[Dictionary] = []
	for file_name: String in SOURCE_FILES:
		var spec: Dictionary = SOURCE_FILES[file_name]
		var span_start := int(spec.get("start", -1))
		var span_end := int(spec.get("end", -1))
		if int(spec.get("bank", -1)) != bank or source_pc < span_start \
				or source_pc >= span_end:
			continue
		var bytes: PackedByteArray = _sources.get(file_name, PackedByteArray())
		var source_offset := source_pc - span_start
		if source_offset < 0 or source_offset >= bytes.size():
			continue
		var evidence_end := mini(bytes.size(), source_offset + 8)
		evidence.append({
			"file": file_name,
			"bank": bank,
			"cpu_address": source_pc,
			"span_start": span_start,
			"span_end_exclusive": span_end,
			"resource_offset": source_offset,
			"bytes_hex": bytes.slice(source_offset, evidence_end).hex_encode(),
			"resource_sha256": _sha256(bytes),
		})
	return evidence


func _write_cpu(address: int, value: int, source_pc: int, source_bank: int) -> bool:
	value &= 0xFF
	if address < 0x2000:
		var mirrored := address & 0x07FF
		_ram[mirrored] = value
		if mirrored >= 0x0100 and mirrored < 0x0200:
			_stack_status_known_masks.erase(mirrored)
		_writes.append({"pc": source_pc, "trace_pc": _write_trace_pc, "bank": source_bank,
			"address": mirrored, "value": value})
		return true
	if address == 0x8000:
		_mmc3_select = value & 0x07
		_mapper_writes.append({"pc": source_pc, "address": address, "value": value, "select": _mmc3_select})
		return true
	if address == 0x8001:
		if _mmc3_select == 6: _bank_low = value
		elif _mmc3_select == 7: _bank_high = value
		_mapper_writes.append({"pc": source_pc, "address": address, "value": value, "select": _mmc3_select})
		return true
	return _fail("Unsupported worker-prefix memory-mapped write $%04X=$%02X at $%04X." % [address, value, source_pc])


func _push(value: int, source_pc: int, source_bank: int) -> bool:
	if not _write_cpu(0x0100 | _sp, value, source_pc, source_bank): return false
	_sp = (_sp - 1) & 0xFF
	return true


func _pop(source_pc: int, source_bank: int) -> int:
	_sp = (_sp + 1) & 0xFF
	var stack_address := 0x0100 | _sp
	var value := _read_cpu(stack_address)
	_stack_status_known_masks.erase(stack_address)
	if value < 0:
		_fail("Worker resume stack pop failed at $%04X (bank $%02X)." % [source_pc, source_bank])
	return value


func _set_nz(value: int) -> void:
	_set_flag(FLAG_Z, (value & 0xFF) == 0)
	_set_flag(FLAG_N, (value & 0x80) != 0)


func _set_flag(mask: int, enabled: bool) -> void:
	if enabled: _p |= mask
	else: _p &= ~mask
	_p |= FLAG_U
	_p_known_mask |= mask | FLAG_U


func _current_bank_for_pc(address: int) -> int:
	if address >= 0xC000 and address < 0xE000: return 0x1E
	if address >= 0xE000: return 0x1F
	if address >= 0xA000 and address < 0xC000: return _bank_high
	return _bank_low


func _opcode_length(opcode: int) -> int:
	match opcode:
		0x09, 0x10, 0x11, 0x24, 0x26, 0x29, 0x30, 0x46, 0x49, 0x50, 0x65, 0x66, 0x69, 0x70, 0x71, \
			0x84, 0x85, 0x86, 0x90, 0x91, 0xA0, 0xA2, 0xA4, 0xA5, 0xA6, 0xA9, 0xB0, 0xB1, \
			0xC0, 0xC5, 0xC6, 0xC9, 0xD0, 0xD1, 0xE0, 0xE5, 0xE6, 0xE9, 0xF0:
			return 2
		0x0D, 0x19, 0x1D, 0x20, 0x2C, 0x4C, 0x6C, 0x6D, 0x6E, 0x79, 0x7D, 0x8C, 0x8D, 0x8E, 0x99, 0x9D, 0xAC, 0xAD, 0xAE, 0xB9, 0xBD, 0xBE, 0xCD, 0xCE, 0xEC, 0xED, 0xEE:
			return 3
		_:
			return 1


func _selected_ram_state() -> Dictionary:
	return {
		"$0022": int(_ram[0x0022]), "$0023": int(_ram[0x0023]),
		"$0024": int(_ram[0x0024]), "$0025": int(_ram[0x0025]),
		"$0050": int(_ram[0x0050]), "$0051": int(_ram[0x0051]),
		"$05C5": int(_ram[0x05C5]), "$05C6": int(_ram[0x05C6]),
		"$0700-$0704": _bytes_hex(0x0700, 5),
	}


func _bytes_hex(start: int, count: int) -> String:
	var output := PackedByteArray()
	for offset in range(count): output.append(int(_ram[start + offset]))
	return output.hex_encode()


func _verify_source_boundaries() -> bool:
	var pass_receiver_call: PackedByteArray = _sources["fixed_pass_receiver_handler_D7E8_D8F7.bin"]
	var pass_receiver_wrapper: PackedByteArray = _sources["fixed_bank18_wrapper_EF7F_EF99.bin"]
	var pass_descriptor_pointer: PackedByteArray = _sources["bank19_pass_receiver_descriptor_pointer_B3ED_B3EF.bin"]
	var pass_descriptor: PackedByteArray = _sources["bank19_pass_receiver_descriptor_0F_B58D_B5A2.bin"]
	if pass_receiver_call.slice(0xD7ED - 0xD7E8, 0xD7F2 - 0xD7E8) \
			!= PackedByteArray([0xA9, 0x0F, 0x20, 0x7F, 0xEF]) \
			or pass_receiver_wrapper != PackedByteArray([
				0xA8, 0xA5, 0x24, 0x48, 0xA5, 0x25, 0x48, 0x98, 0x48, 0xA5, 0x22,
				0xA9, 0x18, 0x85, 0x24, 0xA9, 0x19, 0x85, 0x25, 0x20, 0x2D, 0xCE,
				0x68, 0x20, 0x0C, 0x80,
			]) \
			or pass_descriptor_pointer != PackedByteArray([0x8D, 0xB5]) \
			or pass_descriptor != PackedByteArray([
				0x28, 0x22, 0x18, 0x0A, 0x00, 0x01, 0x0A, 0x05, 0x03, 0x01, 0x02,
				0xED, 0xBB, 0x03, 0x02, 0xF4, 0xBB, 0x05, 0x02, 0xFA, 0xBB,
			]) \
			or (_sources["bank19_pass_receiver_row00_BBED_BBEE.bin"] as PackedByteArray) \
			!= PackedByteArray([0xFC]) \
			or (_sources["bank19_pass_receiver_row01_BBF4_BBFB.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4E, 0x65, 0x05, 0x79, 0x65, 0x3F, 0xFC]):
		return _fail("PASS descriptor-$0F caller, bank-$18 wrapper, pointer `$B3ED->$B58D`, or mapped text rows changed.")
	var field_update_pointers: PackedByteArray = _sources["bank1b_field_update_pointers_A6AD_A6B5.bin"]
	var field_update_row02: PackedByteArray = _sources["bank1b_field_update_table0_row02_A6DD_A6F1.bin"]
	var field_update_row: PackedByteArray = _sources["bank1b_field_update_table0_row12_A7A5_A7B9.bin"]
	if field_update_pointers != PackedByteArray([
			0xB5, 0xA6, 0xE1, 0xA7, 0x0D, 0xA9, 0x39, 0xAA]) \
			or field_update_row02 != PackedByteArray([
				0x54, 0x6C, 0x80, 0x80, 0x6F, 0x7C, 0x4B, 0x65, 0x9D, 0xAC,
				0xBF, 0xBF, 0xAE, 0xC7, 0xC4, 0xC4, 0x95, 0xB6, 0xB4, 0xC0]) \
			or field_update_row != PackedByteArray([
				0x7B, 0x7B, 0x5F, 0x77, 0x74, 0x7F, 0x50, 0x66, 0xAD, 0xC4,
				0xBF, 0xCB, 0xA6, 0xAF, 0xC7, 0xC7, 0x96, 0xBD, 0xB4, 0xB4]):
		return _fail("Bank-$1B pointer header or field-update table-0 row-2/row-12 bytes changed.")
	if (_sources["bank1b_field_update_pointer_cell_AB65_AB67.bin"] as PackedByteArray) \
			!= PackedByteArray([0x7D, 0xAB]):
		return _fail("Bank-$1B field-update pointer cell for the observed index-zero path changed.")
	if (_sources["bank1b_field_update_data_row02_ABA5_ABB9.bin"] as PackedByteArray) \
			!= PackedByteArray([
				0x3E, 0x3C, 0x1F, 0x3A, 0x35, 0x34, 0x1B, 0x11, 0xF0, 0x4C,
				0x69, 0x8E, 0x4E, 0x8B, 0x88, 0xA2, 0x63, 0x71, 0xF0, 0xF0]):
		return _fail("Bank-$1B selected field-update data row ABA5-ABB9 changed.")
	if (_sources["bank1b_field_update_data_row12_AC6D_AC81.bin"] as PackedByteArray) \
			!= PackedByteArray([
				0x1C, 0x31, 0x45, 0x47, 0x2A, 0x37, 0x12, 0x20, 0x4D, 0x88,
				0xF0, 0xF0, 0xF0, 0x5D, 0x8B, 0xA1, 0x4F, 0x68, 0x62, 0x85]):
		return _fail("Bank-$1B selected field-update data row AC6D-AC80 changed.")
	if (_sources["fixed_field_update_stamina_vector_C527_C52A.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x08, 0xCE]):
		return _fail("Bank-$1E live field-update vector no longer jumps to the decoded stamina evaluator.")
	if (_sources["bank1a_field_context_dispatch_call_8047_804F.bin"] as PackedByteArray) \
			!= PackedByteArray([0xA9, 0x02, 0x20, 0x4B, 0xC5, 0x20, 0x72, 0x8F]) \
			or (_sources["fixed_field_context_dispatch_vector_C54B_C54E.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x6E, 0xCE]) \
			or (_sources["fixed_action_scenario_queue_vector_C54E_C551.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0xB0, 0xCB]) \
			or (_sources["fixed_field_context_bank_switch_and_indirect_CE6E_CE99.bin"] as PackedByteArray).slice(0xCE96 - 0xCE6E, 0xCE99 - 0xCE6E) \
			!= PackedByteArray([0x6C, 0x36, 0x00]) \
			or (_sources["bank1c_field_context_dispatch_vector_8006_8009.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x09, 0x86]) \
			or (_sources["bank1c_field_context_empty_record_branch_8609_863F.bin"] as PackedByteArray).slice(0, 5) \
			!= PackedByteArray([0xAD, 0xFB, 0x05, 0xF0, 0x03]) \
			or (_sources["bank1c_field_context_empty_record_branch_8609_863F.bin"] as PackedByteArray).slice(8, 13) \
			!= PackedByteArray([0xAD, 0x00, 0x06, 0xF0, 0x28]) \
			or (_sources["bank1c_field_context_empty_record_branch_8609_863F.bin"] as PackedByteArray)[53] != 0x60:
		return _fail("ROM field-context dispatch bytes or its observed `$05FB=$00/$0600=$00` return path changed.")
	if (_sources["bank1c_field_action_parameter_vector_8012_8015.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x9D, 0x81]) \
			or (_sources["bank1c_field_action_secondary_vector_801E_8021.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x6A, 0x84]) \
			or (_sources["bank1c_field_action_secondary_handler_846A_84C1.bin"] as PackedByteArray).size() != 0x57 \
			or (_sources["bank1c_field_action_secondary_handler_846A_84C1.bin"] as PackedByteArray).slice(0, 5) \
			!= PackedByteArray([0xA9, 0x00, 0x8D, 0x28, 0x06]) \
			or (_sources["bank1c_field_action_secondary_handler_846A_84C1.bin"] as PackedByteArray).slice(0x2F, 0x32) \
			!= PackedByteArray([0xAD, 0xFB, 0x05]) \
			or (_sources["bank1c_field_action_secondary_handler_846A_84C1.bin"] as PackedByteArray)[0x56] != 0x60 \
			or (_sources["bank1c_field_action_secondary_lookup_8BBE_8C1E.bin"] as PackedByteArray).size() != 0x60 \
			or (_sources["bank1c_field_action_parameters_819D_8298.bin"] as PackedByteArray).size() != 0xFB \
			or (_sources["bank1c_field_action_parameters_819D_8298.bin"] as PackedByteArray).slice(0, 15) \
			!= PackedByteArray([0xAD, 0x3B, 0x04, 0x08, 0x0A, 0x6D, 0x3B, 0x04, 0x6D, 0x4E, 0x04, 0xA8, 0x28, 0xD0, 0x0F]) \
			or (_sources["bank1c_field_action_parameters_819D_8298.bin"] as PackedByteArray).slice(0x1E, 0x21) \
			!= PackedByteArray([0xBE, 0x06, 0x82]) \
			or (_sources["bank1c_field_action_parameter_pointer_table_9460_9468.bin"] as PackedByteArray) \
			!= PackedByteArray([0x74, 0x94, 0x00, 0x95, 0x10, 0x95, 0x2C, 0x95]) \
			or (_sources["bank1c_field_action_parameter_record_9500_9505.bin"] as PackedByteArray) \
			!= PackedByteArray([0x00, 0x02, 0x14, 0x00, 0xB2]):
		return _fail("ROM bank-$1C field-action vectors/handler/table or `$8012->$819D` parameter source changed.")
	if (_sources["bank1c_stamina_index_map_818F_8199.bin"] as PackedByteArray) \
			!= PackedByteArray([0x03, 0x03, 0x03, 0x03, 0x04, 0x05, 0x04, 0x05, 0x04, 0x05]):
		return _fail("Bank-$1C stamina-index mapping table `$818F-$8198` changed.")
	if (_sources["bank1a_field_update_worker_vector_8033_8036.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x86, 0x8E]):
		return _fail("Bank-$1A field-input dispatch vector `$8033` changed.")
	if (_sources["fixed_field_loop_dispatch_vector_C600_C603.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x65, 0xD5]) \
			or (_sources["fixed_field_update_dispatch_D565_D600.bin"] as PackedByteArray).slice(0, 3) \
			!= PackedByteArray([0x20, 0x73, 0xD5]):
		return _fail("Fixed-bank field-entry dispatch `$C600->$D565` or its first ROM call changed.")
	if (_sources["fixed_field_clock_vector_C603_C606.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x93, 0xD1]):
		return _fail("Fixed-bank field clock vector `$C603->$D193` changed.")
	if (_sources["fixed_field_input_vector_C606_C609.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x74, 0xE0]):
		return _fail("Fixed-bank field-input vector `$C606->$E074` changed.")
	if (_sources["fixed_field_frame_entry_prefix_E074_E07E.bin"] as PackedByteArray) \
			!= PackedByteArray([0xAD, 0xFF, 0x05, 0xF0, 0x65, 0xA9, 0x0F, 0x8D, 0x2A, 0x06]):
		return _fail("Fixed-bank field-frame prefix `$E074-$E07D` changed.")
	if (_sources["fixed_field_update_callsite_E07E_E081.bin"] as PackedByteArray) \
			!= PackedByteArray([0x20, 0x09, 0xE7]):
		return _fail("Fixed-bank field-update callsite `$E07E->$E709` changed.")
	var pass_waiter_caller: PackedByteArray = _sources["fixed_pass_waiter_caller_E081_E0DE.bin"]
	if pass_waiter_caller.size() != 94 \
			or pass_waiter_caller.slice(0, 8) \
			!= PackedByteArray([0xA9, 0x00, 0x48, 0xA9, 0x01, 0x20, 0x0F, 0xCB]) \
			or pass_waiter_caller.slice(0x5D, 0x5E) != PackedByteArray([0x60]):
		return _fail("PASS waiter E081 source span or natural-RTS tail changed.")
	if (_sources["fixed_field_ratio_vector_C521_C524.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x0D, 0xCD]) \
			or (_sources["fixed_field_ratio_helper_CD0D_CD3C.bin"] as PackedByteArray).slice(0, 3) \
			!= PackedByteArray([0x8A, 0x48, 0xA9]) \
			or (_sources["fixed_field_ratio_helper_CD0D_CD3C.bin"] as PackedByteArray)[0x3C - 0x0D - 1] != 0x60:
		return _fail("Fixed-bank field ratio vector/helper `$C521->$CD0D->$CD3B` changed.")
	if _sources["fixed_action_context_tables_D700_D70C.bin"] != PackedByteArray([
			0x03, 0x04, 0x05, 0x03, 0x03, 0x03, 0x02, 0x02, 0x02, 0x02, 0x02, 0x2C]):
		return _fail("Fixed-bank action/status context tables `$D700-$D70B` changed.")
	if _sources["bank19_action_menu_descriptor_pointers_B3D3_B3D7.bin"] \
			!= PackedByteArray([0x7D, 0xB4, 0x8A, 0xB4]):
		return _fail("Bank-$19 action and status descriptor pointers `$B3D3-$B3D6` changed.")
	if (_sources["fixed_field_entry_bootstrap_EFA2_F015.bin"] as PackedByteArray).slice(0, 5) \
			!= PackedByteArray([0xAD, 0x21, 0x06, 0xC9, 0x04]) \
			or (_sources["fixed_first_command_packet_code_F015_F15A.bin"] as PackedByteArray).slice(0, 6) \
			!= PackedByteArray([0x48, 0xA9, 0x01, 0x20, 0x0F, 0xCB]):
		return _fail("ROM field-entry bootstrap or first-command packet producer bytes changed.")
	var field_input_dispatch: PackedByteArray = _sources["bank1a_field_update_dispatch_8E86_8EE9.bin"]
	if field_input_dispatch.size() != 0x63 \
			or field_input_dispatch.slice(0, 5) != PackedByteArray([0xAD, 0x46, 0x04, 0xC9, 0x05]) \
			or field_input_dispatch.slice(0x5F, 0x63) != PackedByteArray([0x4C, 0xAC, 0x85, 0x60]):
		return _fail("Bank-$1A field-input dispatcher `$8E86-$8EE8` changed.")
	if (_sources["bank1a_field_entry_8003_A000.bin"] as PackedByteArray).slice(0x8FB5 - 0x8003, 0x8FB8 - 0x8003) \
			!= PackedByteArray([0x6A, 0x09, 0x80]):
		return _fail("Bank-$1A field-coordinate helper bytes `$8FB5-$8FB7` changed.")
	if (_sources["bank1d_evaluator_record_row_BAF6_BB00.bin"] as PackedByteArray) \
			!= PackedByteArray([0x00, 0x00, 0x76, 0x77, 0x77, 0x78, 0xA0, 0x1F, 0x1F, 0x0F]):
		return _fail("Bank-$1D source evaluator record BAF6-BAFF changed.")
	if (_sources["bank1c_stamina_profile_records_9A52_9A6A.bin"] as PackedByteArray) \
			!= PackedByteArray([
				0x18, 0x00, 0x10, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
				0x19, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00]):
		return _fail("Bank-$1C evaluator records `$9A52-$9A69` changed.")
	if (_sources["bank1d_stamina_lookup_index00_AFB2_AFB4.bin"] as PackedByteArray) \
			!= PackedByteArray([0x40, 0x04]) \
			or (_sources["bank1d_stamina_lookup_index00_offset02_AFB4_AFB6.bin"] as PackedByteArray) \
			!= PackedByteArray([0xA5, 0x03]) \
			or (_sources["bank1d_stamina_lookup_index00_selector1F_AFAE_AFB0.bin"] as PackedByteArray) \
			!= PackedByteArray([0x80, 0x03]) \
			or (_sources["bank1d_stamina_lookup_index01_AFBE_AFC0.bin"] as PackedByteArray) \
			!= PackedByteArray([0x50, 0x04]) \
			or (_sources["bank1d_stamina_lookup_index03_AFD6_AFD8.bin"] as PackedByteArray) \
			!= PackedByteArray([0x70, 0x04]) \
			or (_sources["bank1d_stamina_lookup_index04_AFE2_AFE4.bin"] as PackedByteArray) \
			!= PackedByteArray([0x40, 0x04]) \
			or (_sources["bank1d_stamina_lookup_index06_AFFA_AFFC.bin"] as PackedByteArray) \
			!= PackedByteArray([0x50, 0x04]) \
			or (_sources["bank1d_stamina_lookup_index07_B006_B008.bin"] as PackedByteArray) \
			!= PackedByteArray([0x70, 0x04]):
		return _fail("Bank-$1D source stamina lookup words for observed evaluator indices changed.")
	var coordinate_update_tail: PackedByteArray = _sources["fixed_field_coordinate_update_tail_E800_E854.bin"]
	if coordinate_update_tail.size() != 0x54 \
			or coordinate_update_tail[0] != 0x38 \
			or coordinate_update_tail[coordinate_update_tail.size() - 1] != 0x60:
		return _fail("Fixed-bank field-coordinate continuation no longer starts at `$E800` and ends at its `$E853` RTS.")
	var coordinate_magnitude_thresholds: PackedByteArray = _sources["fixed_coordinate_magnitude_thresholds_FACC_FB4C.bin"]
	if coordinate_magnitude_thresholds.size() != 0x80 \
			or coordinate_magnitude_thresholds.slice(0, 2) != PackedByteArray([0x06, 0x00]):
		return _fail("Fixed-bank coordinate magnitude table is not the 64-entry `$FACC` source sequence.")
	var worker_bytes: PackedByteArray = _sources["bank18_worker_entry_to_yield_call_800C_8889.bin"]
	var resume_bytes: PackedByteArray = _sources["bank18_worker_resume_8889_89D7.bin"]
	var descriptor01_row00: PackedByteArray = _sources["bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin"]
	var descriptor01_row02: PackedByteArray = _sources["bank19_resumed_worker_descriptor01_row02_BBE3_BBE6.bin"]
	var descriptor01_row01: PackedByteArray = _sources["bank19_resumed_worker_descriptor01_row01_BD9C_BD9F.bin"]
	var descriptor01_row03: PackedByteArray = _sources["bank19_resumed_worker_descriptor01_row03_BD9F_BDA2.bin"]
	var descriptor01_tail: PackedByteArray = _sources["bank19_match_descriptor_B475_B47D.bin"]
	var ee_handler: PackedByteArray = _sources["bank18_ee_numeric_handler_8B2F_8B48.bin"]
	var call_offset := 0x8886 - 0x800C
	if worker_bytes.slice(0, 3) != PackedByteArray([0x4C, 0x51, 0x88]) \
			or worker_bytes.slice(call_offset - 2, call_offset + 3) != PackedByteArray([0xA9, 0x01, 0x20, 0x15, 0xC5]):
		return _fail("Bank-$18 worker entry or $8886 JSR boundary bytes changed.")
	var ed_vector_offset := (0x89BA - 0x8889) + ((0xED - 0xE0) * 2)
	if descriptor01_row00 != PackedByteArray([0xED, 0x00, 0xFC]) \
			or descriptor01_row02 != PackedByteArray([0xED, 0x01, 0xFC]) \
			or descriptor01_row01 != PackedByteArray([0xEE, 0x00, 0xFC]) \
			or descriptor01_row03 != PackedByteArray([0xEE, 0x01, 0xFC]) \
			or descriptor01_tail != PackedByteArray([0x03, 0x01, 0xE3, 0xBB, 0x03, 0x05, 0x9F, 0xBD]) \
			or ee_handler != PackedByteArray([0xA4, 0x40, 0xE6, 0x40, 0xB1, 0x3E, 0xAA,
				0xBD, 0x28, 0x00, 0xAC, 0x27, 0x00, 0xC0, 0x04, 0xD0, 0x03,
				0xBD, 0x10, 0x06, 0xA2, 0x00, 0x4C, 0x55, 0x8C]) \
			or resume_bytes.slice(ed_vector_offset, ed_vector_offset + 2) != PackedByteArray([0xE7, 0x8A]) \
			or (_sources["bank18_ed_team_handler_8AE7_8B0A.bin"] as PackedByteArray).slice(0, 6) \
			!= PackedByteArray([0xA4, 0x40, 0xE6, 0x40, 0xAE, 0x2A]) \
			or (_sources["bank18_ed_team_name_lengths_8B0A_8B0E.bin"] as PackedByteArray) \
			!= PackedByteArray([0x03, 0x04, 0x03, 0x03]) \
			or (_sources["fixed_team_name_pointer_entries_76_79_F415_F41D.bin"] as PackedByteArray).slice(0, 2) \
			!= PackedByteArray([0x76, 0xF7]) \
			or (_sources["fixed_team_00_name_stream_F776_F77C.bin"] as PackedByteArray).slice(0, 3) \
			!= PackedByteArray([0x53, 0x41, 0x4F]):
		return _fail("Descriptor-$01 ED row bytes, team handler vector, or ROM team-name source bytes changed.")
	if (_sources["bank18_ed_text_loop_8A56_8A86.bin"] as PackedByteArray).size() != 0x30 \
			or (_sources["fixed_team_name_lookup_F30F_F329.bin"] as PackedByteArray).size() != 0x1A \
			or (_sources["fixed_team_name_dispatch_C53C_C53F.bin"] as PackedByteArray).size() != 3 \
			or (_sources["fixed_team_03_name_stream_F785_F789.bin"] as PackedByteArray) \
			!= PackedByteArray([0x46, 0x4C, 0x55, 0xFC]):
		return _fail("Descriptor-$01 `$ED` name converter/lookup source spans changed size.")
	if (_sources["bank19_worker_lookup_B3BD_B3D1.bin"] as PackedByteArray).slice(18, 20) != PackedByteArray([0x53, 0xB4]) \
			or (_sources["fixed_task_yield_trampoline_C515_C518.bin"] as PackedByteArray) != PackedByteArray([0x4C, 0x0F, 0xCB]):
		return _fail("Bank-$19 lookup pointer or fixed $C515->$CB0F trampoline bytes changed.")
	if (_sources["bank18_worker_resume_8889_89D7.bin"] as PackedByteArray).slice(0, 5) != PackedByteArray([0xAD, 0x15, 0x05, 0xD0, 0xF6]) \
		or (_sources["bank19_resumed_worker_text_lead_BBDC_BBDE.bin"] as PackedByteArray) != PackedByteArray([0xEF, 0xFC]) \
		or (_sources["bank19_resumed_worker_text_row01_BBDE_BBE0.bin"] as PackedByteArray) != PackedByteArray([0xF0, 0xFC]) \
			or (_sources["bank19_match_descriptor_B453_B464.bin"] as PackedByteArray).slice(0, 4) != PackedByteArray([0x21, 0x22, 0x07, 0x04]):
		return _fail("Resumed worker or descriptor source bytes changed.")
	if (_sources["fixed_dispatch_C509_C50C.bin"] as PackedByteArray) != PackedByteArray([0x4C, 0x99, 0xCB]) \
			or (_sources["bank1a_field_entry_8003_A000.bin"] as PackedByteArray).slice(0x80ED - 0x8003, 0x80F6 - 0x8003) \
			!= PackedByteArray([0x20, 0x06, 0xC6, 0xAD, 0x3B, 0x04, 0x20, 0x09, 0xC5]) \
			or (_sources["fixed_field_action_vector_C61E_C621.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x59, 0xE0]) \
			or (_sources["fixed_field_pass_result_E059_E074.bin"] as PackedByteArray).size() != 27 \
			or (_sources["fixed_field_pass_result_E059_E074.bin"] as PackedByteArray)[26] != 0x60 \
			or (_sources["fixed_field_pass_result_index_DF8B_DFBD.bin"] as PackedByteArray).size() != 50 \
			or (_sources["fixed_field_pass_result_index_DF8B_DFBD.bin"] as PackedByteArray)[49] != 0x60 \
			or (_sources["fixed_field_pass_result_index_table_DFBD_DFD1.bin"] as PackedByteArray) \
			!= PackedByteArray([0x02, 0x03, 0x03, 0x03, 0x03, 0x04, 0x04, 0x04, 0x04, 0x04,
				0x04, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05]) \
			or (_sources["fixed_field_action_handler_vector_C612_C615.bin"] as PackedByteArray) \
			!= PackedByteArray([0x4C, 0x52, 0xDE]) \
			or (_sources["fixed_field_pass_result_handler_DE52_DE80.bin"] as PackedByteArray).size() != 46 \
			or (_sources["fixed_field_pass_result_handler_DE52_DE80.bin"] as PackedByteArray).slice(0, 3) \
			!= PackedByteArray([0xA9, 0xFF, 0x2C]) \
			or (_sources["shared_fixed_branch_table_dispatch_CB99_CBAF.bin"] as PackedByteArray).size() != 23 \
			or (_sources["bank18_callback_pointer_89D8_89DA.bin"] as PackedByteArray) != PackedByteArray([0x48, 0x8B]) \
			or (_sources["bank18_resumed_worker_vector_tail_89D7_89DC.bin"] as PackedByteArray).slice(1, 5) != PackedByteArray([0x48, 0x8B, 0x8B, 0x8B]) \
			or (_sources["bank18_special_handler_8B48_8B77.bin"] as PackedByteArray).size() != 47 \
			or (_sources["bank18_f0_match_clock_handler_8B8B_8BD5.bin"] as PackedByteArray).slice(0, 3) != PackedByteArray([0xA2, 0x00, 0xAD]) \
			or (_sources["bank18_f0_decimal_formatter_8C55_8C85.bin"] as PackedByteArray).size() != 48 \
			or (_sources["fixed_division_dispatch_C51E_C521.bin"] as PackedByteArray) != PackedByteArray([0x4C, 0x3C, 0xCD]) \
			or (_sources["fixed_division_16bit_CD3C_CD77.bin"] as PackedByteArray).size() != 59 \
			or (_sources["bank18_special_handler_8B48_8B77.bin"] as PackedByteArray)[0] != 0xA9 \
			or (_sources["bank18_special_handler_8B48_8B77.bin"] as PackedByteArray)[42] != 0xFF \
			or (_sources["bank18_special_handler_8B48_8B77.bin"] as PackedByteArray)[46] != 0xFF \
			or (_sources["bank18_inline_callback_pointer_89F2_89F4.bin"] as PackedByteArray) != PackedByteArray([0x52, 0x8C]) \
			or (_sources["bank18_fc_callback_return_8C52_8C55.bin"] as PackedByteArray) != PackedByteArray([0x68, 0x68, 0x60]) \
			or (_sources["bank18_window_3x3_tile_ids_8D9E_8DA7.bin"] as PackedByteArray) != PackedByteArray([0x9C, 0xA8, 0x9D, 0xAA, 0x00, 0xAB, 0x9E, 0xA9, 0x9F]):
		return _fail("The `$C509->$CB99->$8B48` match-zero callback path failed its source-boundary checks.")
	if (_sources["fixed_wrapper_return_EF99_EFA2.bin"] as PackedByteArray) \
			!= PackedByteArray([0x68, 0x85, 0x25, 0x68, 0x85, 0x24, 0x4C, 0x2D, 0xCE]) \
			or (_sources["fixed_mapper_helper_CE2D_CE4A.bin"] as PackedByteArray).size() != 29 \
			or (_sources["fixed_second_wrapper_caller_DACC_DAD1.bin"] as PackedByteArray) \
			!= PackedByteArray([0xA9, 0x01, 0x20, 0x7F, 0xEF]) \
			or (_sources["fixed_kickoff_caller_DAD1_DAD8.bin"] as PackedByteArray) \
			!= PackedByteArray([0xAD, 0x29, 0x06, 0xC9, 0x04, 0xF0, 0x11]) \
			or (_sources["fixed_kickoff_scenario35_caller_DAD8_DADC.bin"] as PackedByteArray) \
			!= PackedByteArray([0xA9, 0x35, 0x20, 0xB0, 0xCB]) \
			or (_sources["fixed_scenario_queue_CBB0_CBC1.bin"] as PackedByteArray) \
			!= PackedByteArray([0x8D, 0x18, 0x05, 0xA9, 0x80, 0x8D, 0x16, 0x05,
				0xA9, 0x00, 0x85, 0x05, 0xA9, 0x00, 0x20, 0x0F, 0xCB, 0x60]):
		return _fail("The wrapper return, second caller, scenario-$35 branch, or enqueue source bytes changed.")
	return true


func _manifest_sha256() -> String:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return ""
	return _sha256(file.get_buffer(file.get_length()))


func source_manifest_sha256() -> String:
	return _manifest_sha256()


func _executed_source_span_records() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return output
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return output
	for span_variant in parsed.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			var file_name := String(span.get("file", ""))
			if _executed_source_files.has(file_name):
				output.append({"file": file_name, "bank": span.get("bank", ""),
					"cpu_start": span.get("cpu_start", ""), "cpu_end_exclusive": span.get("cpu_end_exclusive", ""),
					"sha256": span.get("sha256", "")})
	for source_variant: Variant in _pass_receiver_descriptor_1d_spans:
		if not source_variant is Dictionary:
			continue
		var source: Dictionary = source_variant
		var source_name := String(source.get("name", ""))
		if _executed_pass_receiver_descriptor_1d_sources.has(source_name):
			output.append({"file": source_name, "bank": "0x19",
				"cpu_start": "0x%04X" % int(source.get("start", -1)),
				"cpu_end_exclusive": "0x%04X" % int(source.get("end", -1)),
				"sha256": String(source.get("sha256", "")),
				"manifest": PASS_RECEIVER_DESCRIPTOR_1D_MANIFEST_PATH})
	if _pass_receiver_scan_return_source_executed:
		output.append({"file": "receiver_candidate_scan",
			"bank": "0x1E", "cpu_start": "0xD8F7", "cpu_end_exclusive": "0xD979",
			"sha256": String(_pass_receiver_input_scan_span.get("sha256", "")),
			"manifest": PASS_RECEIVER_INPUT_MANIFEST_PATH,
			"manifest_sha256": PASS_RECEIVER_INPUT_MANIFEST_SHA256,
			"executed_cpu_addresses": [PASS_RECEIVER_SCAN_RETURN_PC]})
	return output


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
