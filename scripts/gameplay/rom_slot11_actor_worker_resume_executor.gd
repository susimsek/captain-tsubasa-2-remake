extends RefCounted
class_name RomSlot11ActorWorkerResumeExecutor
## Executes the source-backed slot-$11 resume from `$804A` through the first
## `$CC50->$CB0F` task-save entry. This is a narrow ROM-byte executor, not a
## general 6502 interpreter or a timing/PPU/APU emulator.

const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/manifest.json"
const ROOT := "res://reference/rom_extract/gameplay/slot11_actor_worker_resume_wait/"
const WORKER_FILE := "bank18_actor_worker_resume_804a_80fd.bin"
const STREAM_EVENT_DISPATCH_FILE := "bank18_actor_stream_dispatch_8218_822e.bin"
const STREAM_SHORT_EVENT_FILE := "bank18_actor_stream_short_event_decoder_81d1_81e4.bin"
const STREAM_FILE := "bank18_actor_stream_f4_f5_9f42_9f53.bin"
const STREAM_FOLLOWUP_FILE := "bank18_actor_stream_followup_9f54_9f7f.bin"
const PARAMETER47_STREAM_FILE := "bank18_actor_stream_parameter47_9917_9920.bin"
const PARAMETER00_STREAM_FILE := "bank18_actor_stream_parameter00_9400_9401.bin"
const PARAMETER58_STREAM_FILE := "bank18_actor_stream_parameter58_9A62_9A6F.bin"
const PARAMETER6D_MANIFEST_PATH := "res://reference/rom_extract/gameplay/slot11_actor_parameter_6d/manifest.json"
const PARAMETER6D_ROOT := "res://reference/rom_extract/gameplay/slot11_actor_parameter_6d/"
const PARAMETER6D_POINTER_FILE := "bank18_actor_parameter_6d_pointer_92fa.bin"
const PARAMETER6D_STREAM_FILE := "bank18_actor_parameter_6d_stream_9be3_9c70.bin"
const PARAMETER48_BOUNDARY_FILE := "bank18_actor_parameter_48_boundary_pointer_92B0.bin"
const SEQUENCE_ROW_HANDLER_FILE := "bank18_actor_sequence_row_handler_811E_8122.bin"
const F4_SELECTOR03_TABLE_FILE := "bank19_actor_f4_selector03_table_A3BD_A3C9.bin"
const ACTOR_EVENT_STREAM_FILE := "bank19_actor_event_stream_a3c9_a43b.bin"
const ACTOR_EVENT_STREAM_CONTINUATION_FILE := "bank19_actor_event_stream_continuation_A43C.bin"
const ACTOR_EVENT_STREAM_TEXT_FILE := "bank19_actor_event_stream_text_A43D_A446.bin"
const ACTOR_EVENT_DISPATCH_FILE := "bank18_actor_event_dispatch_and_wait_8218_8273.bin"
const ACTOR_EVENT_QUEUE_CONSUMER_FILE := "bank18_actor_event_queue_consumer_8273_82f1.bin"
const ANIMATION_PACKET_WAIT_FILE := "bank18_actor_animation_packet_wait_82f2_82f6.bin"
const ACTOR_EVENT_TYPE_TABLE_FILE := "bank18_actor_event_type_lookup_86b8_86bb.bin"
const ACTOR_EVENT_TYPE5_LOOKUP_FILE := "bank18_actor_event_type_lookup_86bd_86be.bin"
const ACTOR_EVENT_POINTER_TABLE_FILE := "bank18_actor_event_payload_pointer_8dc4_8dc8.bin"
const ACTOR_EVENT_POINTER_TYPE5_FILE := "bank18_actor_event_payload_pointer_8dcc_8dce.bin"
const ACTOR_EVENT_PAYLOAD_TYPE1_FILE := "bank18_actor_event_payload_type1_8e37_8e3a.bin"
const ACTOR_EVENT_PAYLOAD_TYPE2_FILE := "bank18_actor_event_payload_type2_8e94_8e97.bin"
const ACTOR_EVENT_PAYLOAD_STREAM_TYPE5_FILE := "bank18_actor_event_payload_stream_type5_8fbf_9015.bin"
const ACTOR_EVENT_PAYLOAD_STREAM_FILE := "bank18_actor_event_payload_stream_8e94_8f14.bin"
const ACTOR_EVENT_PAYLOAD_STREAM_TYPE1_FILE := "bank18_actor_event_payload_stream_type1_8e37_8e94.bin"
const ACTOR_EVENT_NEXT_STATE_TABLE_FILE := "bank18_actor_event_next_state_table_86c8_86d8.bin"
const ACTOR_PACKET_RESUME_FILE := "bank18_actor_packet_resume_82f7_8652.bin"
const ACTOR_PACKET_RESUME_CONTINUATION_FILE := "bank18_actor_packet_resume_continuation_8653_86e8.bin"
const PARAMETER47_INDEX1_PACKET_LOOKUP_FILE := "bank18_actor_packet_parameter47_index01_lookup_875a_875e.bin"
const PARAMETER47_ACTOR_TEXT_POINTER_FILE := "fixed_actor_text_pointer_entry_00_F329_F32B.bin"
const RECORD_POINTER_TABLE_FILE := "fixed_record_pointer_table_CD89_CD97.bin"
const RECORD_POINTER_TABLE_FULL_FILE := "../scenario36_fd00_mirror/fixed_player_record_pointer_table_CD89_CDC9.bin"
const ACTOR_PACKET_ROW_ADDRESS_FILE := "bank18_actor_packet_row_address_86e8_86ed.bin"
const TEXT_POINTER_LOOKUP_FILE := "fixed_text_pointer_lookup_F30F_F328.bin"
const TEXT_POINTER_76_FILE := "fixed_text_pointer_entry_76_F415_F416.bin"
const ACTOR_TEXT_76_FILE := "fixed_actor_text_76_F776_F77B.bin"
const PLAYER_NAME_POINTER_08_FILE := "fixed_player_name_pointer_08_F339_F33A.bin"
const PLAYER_NAME_STREAM_08_FILE := "fixed_player_name_stream_08_F52B_F530.bin"
const TEXT_POINTER_TABLE_FILE := "fixed_text_pointer_table_F329_F528.bin"
const TEXT_STREAM_E6_FILE := "fixed_text_stream_E6_FAB0_FAB3.bin"
const TEXT_STREAM_F9A4_FILE := "fixed_text_stream_F9A4_F9A7.bin"
const TEXT_STREAM_F53A_FILE := "fixed_text_stream_F53A_F53E.bin"
const YIELD_TRAMPOLINE_FILE := "fixed_task_yield_trampoline_C515.bin"
const SELECTOR_FILE := "bank18_match_index_pointer_resolver_8122_8138.bin"
const F5_HANDLER_FILE := "bank18_actor_stream_command_f5_81fd_8200.bin"
const C52D_FILE := "fixed_c52d_jump_to_cc46.bin"
const WAITER_FILE := "fixed_task_yield_waiter_cc46_cc5d.bin"
const PACKET_BUILDER_FILE := "fixed_wait_packet_builder_CC53_CC9E.bin"
const COUNTER_TAIL_FILE := "fixed_wait_counter_tail_CC9E_CCD1.bin"
const F5_TAIL_FILE := "bank18_actor_stream_f5_tail_8200_8217.bin"
const C560_STUB_FILE := "fixed_c560_bank1a_call_stub.bin"
const CF72_WRAPPER_FILE := "fixed_cf72_bank1a_call_and_restore.bin"
const BANK1A_ENTRY_FILE := "bank1a_worker_entry_802a_802d.bin"
const ANIMATION_GATE_FILE := "bank1b_actor_animation_gate_A1EB_A219.bin"
const ANIMATION_INDEX_FILE := "bank1b_actor_animation_index_0D_A2AC_A2AD.bin"
const ANIMATION_INDEX_TABLE_FILE := "bank1b_actor_animation_pointer_table_A292_A2AD.bin"
const ANIMATION_COMMAND_LOOP_FILE := "bank1b_actor_animation_command_loop_A21A_A291.bin"
const ANIMATION_STREAM_FILE := "bank1b_actor_animation_stream_0D_A425_A426.bin"
const ANIMATION_STREAM_ZERO_FILE := "bank1b_actor_animation_stream_00_A2AE_A2CA.bin"
const ANIMATION_STREAM_INDEX1_FILE := "bank1b_actor_animation_stream_01_A2CB_A2E7.bin"
const ANIMATION_STREAM_INDEX2_FILE := "bank1b_actor_animation_stream_02_A2E8_A2FC.bin"
const ANIMATION_POINTER_FILE := "bank1b_actor_animation_pointer_00_A42A_A42B.bin"
const ANIMATION_PACKET_POINTER_TABLE_FILE := "bank1b_actor_animation_packet_pointer_table_A42A_A433.bin"
const ANIMATION_INDEX2_PACKET_POINTER_TABLE_FILE := "bank1b_actor_animation_packet_pointer_table_A42A_A439.bin"
const ANIMATION_PPU_PACKETS_FILE := "bank1b_actor_animation_ef_00_ppu_packets_A46A_A48E.bin"
const ANIMATION_PPU_PACKETS_01_FILE := "bank1b_actor_animation_packets_01_A48F_A493.bin"
const ANIMATION_PPU_PACKETS_02_FILE := "bank1b_actor_animation_packets_02_A494_A498.bin"
const ANIMATION_PPU_PACKETS_03_FILE := "bank1b_actor_animation_packets_03_A499_A49D.bin"
const ANIMATION_PPU_PACKETS_04_FILE := "bank1b_actor_animation_packets_04_A49E_A4C2.bin"
const ANIMATION_PPU_PACKETS_05_FILE := "bank1b_actor_animation_packets_05_A4C3_A4E7.bin"
const ANIMATION_PPU_PACKETS_06_FILE := "bank1b_actor_animation_packets_06_A4E8_A4EC.bin"
const ANIMATION_PPU_PACKETS_07_FILE := "bank1b_actor_animation_packets_07_A4ED_A4F1.bin"
const ANIMATION_INDEX2_MANIFEST_PATH := "res://reference/rom_extract/gameplay/animations/kickoff/slot11_animation_index_02/manifest.json"
const ANIMATION_INDEX2_ROOT := "res://reference/rom_extract/gameplay/animations/kickoff/slot11_animation_index_02/"
const MAPPER_HELPER_PATH := "res://reference/rom_extract/gameplay/ee9f_empty_actor_call/fixed_mapper_helper_CE2D_CE49.bin"
const WORKER_PREFIX_PATH := "res://reference/rom_extract/gameplay/task_context/bank18_actor_worker_entry_8000_804A.bin"
const INLINE_DISPATCH_FILE := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/fixed_dispatch_C509_C50C.bin"
const INLINE_DISPATCH_SHA256 := "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441"
const TRAMPOLINE_FILE := "res://reference/rom_extract/gameplay/fresh_daaa_continuation/fixed_branch_table_dispatch_CB99_CBAF.bin"
const TRAMPOLINE_SHA256 := "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"
const TEXT_HELPER_VECTOR_PATH := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/fixed_text_helper_vector_C524_C527.bin"
const TEXT_TOKEN_CONVERTER_PATH := "res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/fixed_text_token_converter_CBC2_CBF1.bin"
const TEXT_POINTER_VECTOR_PATH := "res://reference/rom_extract/gameplay/field_entry_window_01/fixed_team_name_dispatch_C53C_C53F.bin"
const RECORD_POINTER_VECTOR_PATH := "res://reference/rom_extract/gameplay/first_match_player_state/fixed_record_pointer_vector_C50C_C50F.bin"
const RECORD_POINTER_RESOLVER_PATH := "res://reference/rom_extract/gameplay/first_match_player_state/fixed_record_pointer_resolver_CD7C_CD89.bin"
const SLOT_11 := 0x11
const RAM_SIZE := 0x800
const STACK_SIZE := 0x100
const P_C := 0x01
const P_Z := 0x02
const P_B := 0x10
const P_U := 0x20
const P_V := 0x40
const P_N := 0x80

var error_message := ""
var _configured := false
var _sources: Dictionary = {}


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_sources.clear()
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Slot-$11 resume source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Slot-$11 resume source manifest is malformed.")
	var manifest: Dictionary = parsed
	if String(manifest.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Slot-$11 resume manifest targets another ROM revision.")
	var required := {
		WORKER_FILE: [0x804A, 0x03005A, 179, "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e"],
		STREAM_EVENT_DISPATCH_FILE: [0x8218, 0x030228, 22, "a46488bd47acb67282e03aa63e4111b7efc1677dc8f10dc52e90a2d80ae7aa5c"],
		STREAM_SHORT_EVENT_FILE: [0x81D1, 0x0301E1, 19, "7e59d0713a7eb14d55dcca569ff75b2e6fea37d394fa72531eabcfabe4c106be"],
		STREAM_FILE: [0x9F42, 0x031F52, 18, "907c3653f2e64fa9d27a0a14a7dd38e404f0f1c05a97c0367be24e587f5ebadf"],
		STREAM_FOLLOWUP_FILE: [0x9F54, 0x031F64, 44, "79be558cb1fe9bfbf950a23486ed0da89c1dc37e20daa52feed8f6a124225fe4"],
		PARAMETER47_STREAM_FILE: [0x9917, 0x031927, 10, "1c33322d68d5d662476619ddd88fd2cfd3df15d6112aa4d3ab4a110dea89ae8f"],
		PARAMETER00_STREAM_FILE: [0x9400, 0x031410, 2, "fe770f516cf9f97533711e76a9477f63a7477d5152ba22ab0d81fa93a95c1600"],
		PARAMETER58_STREAM_FILE: [0x9A62, 0x031A72, 14, "15779004184bd0d73ede7e28bb543f63a92f64cc67a99cc49a4f14ec66d60274"],
		PARAMETER48_BOUNDARY_FILE: [0x92B0, 0x0312C0, 2, "70ebc34f8ddbee7b588187e4245864d7d4c37238eee99f136c1cde6edf4d9415"],
		SEQUENCE_ROW_HANDLER_FILE: [0x811E, 0x03012E, 4, "e05d702a76bbdb1c18f36ac1523b9b7b5eb0bacd791953b61da2e1dd41fc75f6"],
		F4_SELECTOR03_TABLE_FILE: [0xA3BD, 0x0323CD, 12, "1d5435b3ff8bf70f3978c927fcd1d49051ff7254a724f0b27aa2585fd3cc6de8"],
		ACTOR_EVENT_STREAM_FILE: [0xA3C9, 0x0323D9, 115, "d1f080bd08e18fbce24895ef9d11887febc6961d23f9b48bd271f56c7442fd1c"],
		ACTOR_EVENT_STREAM_CONTINUATION_FILE: [0xA43C, 0x03244C, 1, "98722e2ebed8ed3d3652e11e4181f0dccc1ce7d192d8f1db370af8ec4a4e174a"],
		ACTOR_EVENT_STREAM_TEXT_FILE: [0xA43D, 0x03244D, 10, "8368859c91cb9632996f9674b98d47b90d23e5e58f4a084fb972e82d57eaab70"],
		ACTOR_EVENT_DISPATCH_FILE: [0x8218, 0x030228, 91, "ad89d4999241da3618d8c3c06822986cb9f0ba561683e112c5ce71f2b5b05bfb"],
		ACTOR_EVENT_QUEUE_CONSUMER_FILE: [0x8273, 0x030283, 127, "2bfbf1443a6faaddd4fb0c06ddbf7936dd2370cde55c52477571c0df58a03a2a"],
		ANIMATION_PACKET_WAIT_FILE: [0x82F2, 0x030302, 5, "66dd891f98da1e60546ec6ee4b58ef81d3c1c55a43af989117504566178c06d1"],
		ACTOR_EVENT_TYPE_TABLE_FILE: [0x86B8, 0x0306C8, 3, "76fb4484e771b7e9628dbf321e34ef11d1f953a164db859398e5b54f7fa6fa99"],
		ACTOR_EVENT_TYPE5_LOOKUP_FILE: [0x86BD, 0x0306CD, 1, "4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47"],
		ACTOR_EVENT_POINTER_TABLE_FILE: [0x8DC4, 0x030DD4, 4, "772bad1ed64aa4e9543211333c2f1213f88cd418ec117a66b4367bae89a33ea8"],
		ACTOR_EVENT_POINTER_TYPE5_FILE: [0x8DCC, 0x030DDC, 2, "831f787fb2c566d6acca65c7faf4a2091bac4c6993daa80ce2d842277ac0c772"],
		ACTOR_EVENT_PAYLOAD_TYPE1_FILE: [0x8E37, 0x030E47, 3, "6d591cefc508d55b2022f08972e0eb34b31fa14d33e2ba0aa4b7fcb9f5c1ba35"],
		ACTOR_EVENT_PAYLOAD_TYPE2_FILE: [0x8E94, 0x030EA4, 3, "6d591cefc508d55b2022f08972e0eb34b31fa14d33e2ba0aa4b7fcb9f5c1ba35"],
		ACTOR_EVENT_PAYLOAD_STREAM_TYPE5_FILE: [0x8FBF, 0x030FCF, 86, "48b367fb4e65f7bc3507a96b4b160e02407755e5810f81a51072a7693cee37dd"],
		ACTOR_EVENT_PAYLOAD_STREAM_FILE: [0x8E94, 0x030EA4, 128, "d07ed3b8e8583cc18718d8f5534cf8eda338ed192ae2285216c8f9793649d375"],
		ACTOR_EVENT_PAYLOAD_STREAM_TYPE1_FILE: [0x8E37, 0x030E47, 93, "375de5d8bd3612c321f2748c1235adbea1816467c44979b920decc1e49ec30de"],
		ACTOR_EVENT_NEXT_STATE_TABLE_FILE: [0x86C8, 0x0306D8, 16, "ad93181c969ca4595a83c4837a6fa7c83bb2f8904590a6b018957de6237890ca"],
		ACTOR_PACKET_RESUME_FILE: [0x82F7, 0x030307, 860, "978aad12034e7113bb0366808145d6408b5a70098274e6a00c241bae2d8d6a12"],
		ACTOR_PACKET_RESUME_CONTINUATION_FILE: [0x8653, 0x030663, 149, "86db4642e0a3aaa45796069b995d22a4093f8036227c82ae81e28c47f19410e5"],
		PARAMETER47_INDEX1_PACKET_LOOKUP_FILE: [0x875A, 0x03076A, 4, "456db556cef5802457e8666bf34d2d83fc8d713565f385eadeec8e7fe8d9e3fd"],
		PARAMETER47_ACTOR_TEXT_POINTER_FILE: [0xF329, 0x03F339, 2, "4e48ab6b84301af8b8fa92c04373b79b5d6f0f37d207c775c98fbce001ff67fe"],
		RECORD_POINTER_TABLE_FILE: [0xCD89, 0x03CD99, 14, "5b9f6e3ab4a8858805b9d8c94d306e9313d319bd7cf52398dff269c374ecd60e"],
		RECORD_POINTER_TABLE_FULL_FILE: [0xCD89, 0x03CD99, 64, "69928f23546876b56ef0e1c47913e5bcf8b34d2aaab39f521916e8e028cf0dba"],
		ACTOR_PACKET_ROW_ADDRESS_FILE: [0x86E8, 0x0306F8, 6, "d96e385a2efac7078c2039c2cba7be185bf570689d4d3c11642b71b53ddc07fe"],
		TEXT_POINTER_LOOKUP_FILE: [0xF30F, 0x03F31F, 26, "f9dc5864adabc5db33189a020b140fc4ecaad375427c97fe23b3be1b65771b92"],
		TEXT_POINTER_76_FILE: [0xF415, 0x03F425, 2, "7b0ede93dd7a46b4084c470accbde1cd0c3e79f11de2acda14789c756bc1bc1d"],
		ACTOR_TEXT_76_FILE: [0xF776, 0x03F786, 6, "43d56de68e6197feddf34fcb5ebf127fbd8efb3c00b8fde7232e136a9056bdea"],
		PLAYER_NAME_POINTER_08_FILE: [0xF339, 0x03F349, 2, "e12533f65374f184d86d85fc4af8d5caf3adc82ce0e3c807aa59156ec9f4fde8"],
		PLAYER_NAME_STREAM_08_FILE: [0xF52B, 0x03F53B, 5, "b3a3a5e4da898b911055f80b1915e7c52adaef2f592d0be88895d0e6762d890a"],
		TEXT_POINTER_TABLE_FILE: [0xF329, 0x03F339, 0x200, "a9f5fe1065b10b827ed01b3e5785bd7e588d634d39775d8cff0c0b871b90c8bf"],
		TEXT_STREAM_E6_FILE: [0xFAB0, 0x03FAC0, 4, "b14618dbd1ace58f36d2aa7d0e046d9155d3a14c78ae50e6fa537077096690e9"],
		TEXT_STREAM_F9A4_FILE: [0xF9A4, 0x03F9B4, 4, "f2a75ea55767154b617239e02a7f6f68140df718904be878818f48fe98d23009"],
		TEXT_STREAM_F53A_FILE: [0xF53A, 0x03F54A, 5, "f51cba1dfe206478670952db060ddbbf73e7cbb46ff8ca93ccf52c9004582c17"],
		YIELD_TRAMPOLINE_FILE: [0xC515, 0x03C525, 3, "86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e"],
		SELECTOR_FILE: [0x8122, 0x030132, 22, "f4acc27853404adda00ba3dcee5f5f4ecdb2939a5d026a6d8f459261497d35b0"],
		F5_HANDLER_FILE: [0x81FD, 0x03020D, 3, "9ae06ade354ced65b80ae98704cd748b28b3fb80829dae0172ce09859fa37405"],
		C52D_FILE: [0xC52D, 0x03C53D, 3, "eb93189d38ebaea8201970900e5b276a27c54c6fa2001a705945cb1d5172f371"],
		WAITER_FILE: [0xCC46, 0x03CC56, 23, "dce4d011f0e612ea074e546e43c28c5395220f2af924a49aee4b35c2491775e3"],
		PACKET_BUILDER_FILE: [0xCC53, 0x03CC63, 75, "681bf402c35efba946da16d63cb53787bf50ed5ba87261929c10d19906b66d0c"],
		COUNTER_TAIL_FILE: [0xCC9E, 0x03CCAE, 52, "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0"],
		F5_TAIL_FILE: [0x8200, 0x030210, 24, "f99ead3dbc9481250bab0c306693651ab2ac705bd5feeb82ea3975167c3663a0"],
		C560_STUB_FILE: [0xC560, 0x03C570, 3, "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc"],
		CF72_WRAPPER_FILE: [0xCF72, 0x03CF82, 29, "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13"],
		BANK1A_ENTRY_FILE: [0x802A, 0x03403A, 3, "d8ec35aefd2671a7a810a2fa342db297bfb35011862ec3b907aa09fced64da90"],
		ANIMATION_GATE_FILE: [0xA1EB, 0x0361FB, 47, "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618"],
		ANIMATION_INDEX_FILE: [0xA2AC, 0x0362BC, 2, "588eba1d324cbcd9381797960eb1a81d099ef8277be6a1f92b935389647e1ae2"],
		ANIMATION_INDEX_TABLE_FILE: [0xA292, 0x0362A2, 28, "ad3e81a3ca712cd37059bd8e8eaa52468f09e6ba17b32100b53e39a5e3dfdef6"],
		ANIMATION_COMMAND_LOOP_FILE: [0xA21A, 0x03622A, 120, "c315087f3f361a05abbbc63748d1c890aea1a2be7f40fb325150cb71688f1cfd"],
		ANIMATION_STREAM_FILE: [0xA425, 0x036435, 2, "c80e57d27a62d8f8ae98f6976e64d0a1e4f9cebe78cf5b16e79ecd927b985da6"],
		ANIMATION_STREAM_ZERO_FILE: [0xA2AE, 0x0362BE, 29, "9016d1464cdeda45f92924cbb80750f4a5e448eba0733f4ecc903c39f19ca152"],
		ANIMATION_STREAM_INDEX1_FILE: [0xA2CB, 0x0362DB, 29, "c49f05054d80e56b0b67d6aa54fd8df627a141788bafe2ba462cc2dac3ce8275"],
		ANIMATION_POINTER_FILE: [0xA42A, 0x03643A, 2, "48dceebd8704067b3697888d1f847f69d77a5fbbcb8e57ac3a9a0b41205e47cf"],
		ANIMATION_PACKET_POINTER_TABLE_FILE: [0xA42A, 0x03643A, 10, "faf0f900066396fec637d1db3b62437835c010e10fb67f87d03e89496f877ff7"],
		ANIMATION_PPU_PACKETS_FILE: [0xA46A, 0x03647A, 37, "4fd878c7cc59ffec84362bfc6f973474f72c83087d302687958b844682b2d678"],
		ANIMATION_PPU_PACKETS_01_FILE: [0xA48F, 0x03649F, 5, "ddb3daefa3e57138841317c468338120ff1f0941a11955c3640f5d5828c7b34a"],
		ANIMATION_PPU_PACKETS_02_FILE: [0xA494, 0x0364A4, 5, "cd0bf13e4ccb0d5738e1f83917201a7bf355dd9f82716d3594e9752af37994f1"],
		ANIMATION_PPU_PACKETS_03_FILE: [0xA499, 0x0364A9, 5, "92de63c44c57852ef97b0a1aed56b897f4731d7c38c2b7a35a61f4eb3c7741ed"],
		ANIMATION_PPU_PACKETS_04_FILE: [0xA49E, 0x0364AE, 37, "4cf2f13165526f20ed00ddf94286986b6c6afa2fed1977ac2378ba61948d31cf"],
	}
	var entries_by_file: Dictionary = {}
	for entry_variant: Variant in manifest.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries_by_file[String(entry.get("file", ""))] = entry
	for file_name_variant: Variant in required:
		var file_name := String(file_name_variant)
		var spec: Array = required[file_name]
		var entry: Dictionary = entries_by_file.get(file_name, {})
		var path := ROOT + file_name
		if entry.is_empty() or _manifest_hex(entry.get("cpu_address", "0x0")) != int(spec[0]) \
				or _manifest_hex(entry.get("file_offset", "0x0")) != int(spec[1]) \
				or int(entry.get("length", -1)) != int(spec[2]) \
				or String(entry.get("sha256", "")) != String(spec[3]) \
				or not FileAccess.file_exists(path):
			return _fail("Manifest mapping or source file differs for %s: expected=%s got cpu=$%04X offset=$%06X length=%d hash=%s exists=%s." % [
				file_name, str(spec), _manifest_hex(entry.get("cpu_address", "0x0")),
				_manifest_hex(entry.get("file_offset", "0x0")), int(entry.get("length", -1)),
				String(entry.get("sha256", "")), str(FileAccess.file_exists(path))])
		var source := FileAccess.get_file_as_bytes(path)
		if source.size() != int(spec[2]) or _sha256(source) != String(spec[3]) \
				or String(entry.get("bytes", "")).replace(" ", "").to_lower() != source.hex_encode():
			return _fail("Packaged ROM bytes failed validation for %s." % file_name)
		_sources[file_name] = source
	if not _load_parameter6d_sources():
		return false
	if not _load_animation_index2_sources():
		return false
	var mapper_helper := FileAccess.get_file_as_bytes(MAPPER_HELPER_PATH)
	if mapper_helper != PackedByteArray([
		0xA5, 0x22, 0x09, 0x06, 0x85, 0x23, 0x8D, 0x00, 0x80,
		0xA5, 0x24, 0x8D, 0x01, 0x80, 0xA5, 0x22, 0x09, 0x07,
		0x85, 0x23, 0x8D, 0x00, 0x80, 0xA5, 0x25, 0x8D, 0x01,
		0x80, 0x60]) \
			or _sha256(mapper_helper) != "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c":
		return _fail("The shared `$CE2D->$CE49` MMC3 pair mapper source span failed validation.")
	_sources["mapper_helper"] = mapper_helper
	var text_helper_vector := FileAccess.get_file_as_bytes(TEXT_HELPER_VECTOR_PATH)
	var text_token_converter := FileAccess.get_file_as_bytes(TEXT_TOKEN_CONVERTER_PATH)
	var text_pointer_vector := FileAccess.get_file_as_bytes(TEXT_POINTER_VECTOR_PATH)
	if text_helper_vector != PackedByteArray([0x4C, 0xC2, 0xCB]) \
			or _sha256(text_helper_vector) != "ec16977c3bfaa36e30d39a6e50ef3a1478d7c5a122f029c905be8413dc0a3b2f" \
			or text_token_converter.size() != 47 \
			or _sha256(text_token_converter) != "840a83b978d52de7009769a5ef383299928a7af77f34d3e639d5393bef43d129" \
			or text_pointer_vector != PackedByteArray([0x4C, 0x0F, 0xF3]) \
			or _sha256(text_pointer_vector) != "6419d5a470082bb95466023cfc1b7b935f42415f3a318be99c4c612ea9bfd9e5":
		return _fail("The shared fixed-bank ROM text helper vectors/converter failed validation.")
	_sources["text_helper_vector"] = text_helper_vector
	_sources["text_token_converter"] = text_token_converter
	_sources["text_pointer_vector"] = text_pointer_vector
	var record_pointer_vector := FileAccess.get_file_as_bytes(RECORD_POINTER_VECTOR_PATH)
	var record_pointer_resolver := FileAccess.get_file_as_bytes(RECORD_POINTER_RESOLVER_PATH)
	if record_pointer_vector != PackedByteArray([0x4C, 0x7C, 0xCD]) \
			or _sha256(record_pointer_vector) != "71f4bb6ccdc5573bcfceef2422fe8636bc1dd1068675da3d860282d577e78b44" \
			or record_pointer_resolver.size() != 13 \
			or _sha256(record_pointer_resolver) != "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24":
		return _fail("The shared `$C50C->$CD7C` player-record pointer resolver failed validation.")
	_sources["record_pointer_vector"] = record_pointer_vector
	_sources["record_pointer_resolver"] = record_pointer_resolver
	var worker_prefix := FileAccess.get_file_as_bytes(WORKER_PREFIX_PATH)
	if worker_prefix.size() != 74 \
			or _sha256(worker_prefix) != "2187af6881ea2f4e7eb16c0c5550bb24ead076be918d429d8ab63564ed8fd46c" \
			or worker_prefix.slice(0x45, 0x4A) != PackedByteArray([0xA9, 0x01, 0x20, 0x15, 0xC5]):
		return _fail("The shared bank-$18 `$8045->$8047` actor yield callsite failed validation.")
	_sources["worker_prefix"] = worker_prefix
	var inline_dispatch := PackedByteArray()
	var trampoline := PackedByteArray()
	if FileAccess.file_exists(INLINE_DISPATCH_FILE):
		inline_dispatch = FileAccess.get_file_as_bytes(INLINE_DISPATCH_FILE)
	if FileAccess.file_exists(TRAMPOLINE_FILE):
		trampoline = FileAccess.get_file_as_bytes(TRAMPOLINE_FILE)
	if inline_dispatch != PackedByteArray([0x4C, 0x99, 0xCB]) \
			or _sha256(inline_dispatch) != INLINE_DISPATCH_SHA256 \
			or trampoline != PackedByteArray([
			0x0A, 0xA8, 0x68, 0x85, 0x36, 0x68, 0x85, 0x37, 0xC8, 0xB1, 0x36,
			0x48, 0xC8, 0xB1, 0x36, 0x85, 0x37, 0x68, 0x85, 0x36, 0x6C, 0x36, 0x00]) \
			or _sha256(trampoline) != TRAMPOLINE_SHA256:
		return _fail("The shared `$C509->$CB99` inline-table trampoline differs from its verified ROM span.")
	_sources["inline_dispatch"] = inline_dispatch
	_sources["trampoline"] = trampoline
	if not _expect(WORKER_FILE, 0x804A, [0x20, 0x53, 0x80, 0x20, 0x60, 0xC5, 0x4C, 0x45, 0x80]) \
			or not _expect(ACTOR_PACKET_RESUME_FILE, 0x82F7, [0xAD, 0x15, 0x05, 0xD0, 0xF6, 0xA9, 0x01]) \
			or not _expect(ACTOR_PACKET_RESUME_FILE, 0x8475, [0xAD, 0xFB, 0x05, 0xAC, 0x2A, 0x00]) \
			or not _expect(ACTOR_PACKET_RESUME_FILE, 0x85D6, [0xA9, 0x80, 0x8D, 0x15, 0x05]) \
			or not _expect(ACTOR_PACKET_RESUME_FILE, 0x8629, [0x20, 0x24, 0xC5, 0xA6, 0x3A]) \
		or _sources[ACTOR_PACKET_ROW_ADDRESS_FILE] != PackedByteArray([0x70, 0x22, 0xB0, 0x22, 0xF0, 0x22]) \
		or _sources[PARAMETER47_ACTOR_TEXT_POINTER_FILE] != PackedByteArray([0xEB, 0x05]) \
			or not _expect(TEXT_POINTER_LOOKUP_FILE, 0xF30F, [0xA0, 0x29, 0x84, 0x30, 0xA0, 0xF3]) \
			or _sources[TEXT_POINTER_76_FILE] != PackedByteArray([0x76, 0xF7]) \
			or _sources[ACTOR_TEXT_76_FILE] != PackedByteArray([0x53, 0x41, 0x4F, 0x20, 0x50, 0xFC]) \
			or not _expect(WORKER_FILE, 0x8062, [0xAD, 0xE4, 0x05, 0x20, 0x09, 0xC5, 0x6E, 0x80]) \
			or not _expect(WORKER_FILE, 0x8068, [0x6E, 0x80, 0x18, 0x82]) \
			or not _expect(STREAM_EVENT_DISPATCH_FILE, 0x8218, [0xAC, 0xE5, 0x05, 0xB1, 0x5F, 0xC9, 0x90, 0xB0, 0x0D]) \
			or not _expect(PARAMETER47_STREAM_FILE, 0x9917, [0xF2, 0x01, 0x51]) \
			or not _expect(PARAMETER00_STREAM_FILE, 0x9400, [0xF2, 0xF0]) \
			or not _expect(ACTOR_EVENT_TYPE5_LOOKUP_FILE, 0x86BD, [0x0E]) \
			or not _expect(ACTOR_EVENT_POINTER_TYPE5_FILE, 0x8DCC, [0xBF, 0x8F]) \
			or not _expect(ACTOR_EVENT_PAYLOAD_STREAM_TYPE5_FILE, 0x8FBF, [0x2C, 0x22, 0x14]) \
			or not _expect(STREAM_SHORT_EVENT_FILE, 0x81D1, [0x4A, 0xA2, 0x00, 0xC9, 0x01, 0x90, 0x0B, 0xE8, 0xC9, 0x05]) \
			or not _expect(WORKER_FILE, 0x8080, [0x8D, 0xE9, 0x05, 0xEE, 0xE4, 0x05, 0x60]) \
			or not _expect(WORKER_FILE, 0x806E, [0xAC, 0xE5, 0x05, 0xEE, 0xE5, 0x05, 0xB1, 0x5F, 0xC9, 0xF0]) \
			or not _expect(WORKER_FILE, 0x8098, [0xA9, 0x00, 0x8D, 0xE3, 0x05, 0x68, 0x68, 0x60]) \
			or not _expect(WORKER_FILE, 0x80CB, [0xAC, 0xE5, 0x05, 0xB1, 0x5F, 0x20, 0xEA, 0x80]) \
			or not _expect(WORKER_FILE, 0x80D3, [0x8A, 0x0A, 0x38, 0x6D, 0xE5, 0x05, 0xA8, 0xB1, 0x5F, 0xAA, 0xC8, 0xB1, 0x5F, 0x86, 0x5F, 0x85, 0x60, 0xA9, 0x00, 0x8D, 0xE5, 0x05, 0x60]) \
			or not _expect(WORKER_FILE, 0x8087, [0x29, 0x0F, 0x20, 0x09, 0xC5]) \
			or not _expect(WORKER_FILE, 0x80B5, [0x4C, 0x2D, 0xC5]) \
			or not _expect(WORKER_FILE, 0x80EA, [0x20, 0x09, 0xC5]) \
			or not _expect(SELECTOR_FILE, 0x8122, [0xA2, 0x00, 0xA5, 0x26, 0xDD, 0x31, 0x81]) \
			or not _expect(F5_HANDLER_FILE, 0x81FD, [0x20, 0x2D, 0xC5]) \
			or not _expect(C52D_FILE, 0xC52D, [0x4C, 0x46, 0xCC]) \
			or not _expect(WAITER_FILE, 0xCC46, [0xA9, 0x00, 0x8D, 0xF4, 0x05, 0xA9, 0x06, 0x48, 0xA9, 0x01, 0x20, 0x0F, 0xCB]) \
			or not _expect(PACKET_BUILDER_FILE, 0xCC53, [0xAD, 0x15, 0x05, 0xD0, 0xF6, 0xA9, 0x01, 0x8D, 0x15, 0x05]) \
			or not _expect(PACKET_BUILDER_FILE, 0xCC5D, [0xA0, 0x4F, 0xA2, 0x00, 0x8A, 0x9D, 0xA5, 0x04, 0xE8, 0x88, 0xD0, 0xF9]) \
			or not _expect(PACKET_BUILDER_FILE, 0xCC93, [0xA9, 0x80, 0x8D, 0x15, 0x05, 0x68, 0x38, 0xE9, 0x01, 0x10, 0xAF]) \
			or not _expect(COUNTER_TAIL_FILE, 0xCC9E, [0xA9, 0x01, 0x20, 0x0F, 0xCB, 0xAD, 0x15, 0x05, 0xD0, 0xF6]) \
			or not _expect(COUNTER_TAIL_FILE, 0xCCAF, [0x8D, 0xA5, 0x04, 0xA9, 0xE0, 0x8D, 0xA6, 0x04, 0xA9, 0x23, 0x8D, 0xA7, 0x04]) \
			or not _expect(COUNTER_TAIL_FILE, 0xCCBC, [0xA2, 0x00, 0x8A, 0x9D, 0xA8, 0x04, 0xE8, 0xE0, 0x21, 0xD0, 0xF8, 0xA9, 0x80, 0x8D, 0x15, 0x05, 0xA9, 0x01, 0x20, 0x0F, 0xCB, 0x60]) \
			or not _expect(F5_TAIL_FILE, 0x8200, [0xA9, 0x0D, 0x8D, 0xF3, 0x05, 0xA9, 0x80, 0x8D, 0xF4, 0x05]) \
			or not _expect(F5_TAIL_FILE, 0x820A, [0xAC, 0xE5, 0x05, 0xB1, 0x5F, 0x8D, 0xE9, 0x05, 0xEE, 0xE5, 0x05, 0x68, 0x68, 0x60]) \
			or not _expect(C560_STUB_FILE, 0xC560, [0x4C, 0x72, 0xCF]) \
			or not _expect(CF72_WRAPPER_FILE, 0xCF72, [0x48, 0xA5, 0x22, 0xA9, 0x1A, 0x85, 0x24, 0xA9, 0x1B, 0x85, 0x25, 0x20, 0x2D, 0xCE]) \
			or not _expect(BANK1A_ENTRY_FILE, 0x802A, [0x4C, 0xEB, 0xA1]) \
			or not _expect(ANIMATION_GATE_FILE, 0xA1EB, [0xAD, 0xF4, 0x05, 0xD0, 0x01, 0x60, 0x10, 0x19]) \
			or not _expect(ANIMATION_GATE_FILE, 0xA20C, [0xAD, 0xF5, 0x05, 0xF0, 0x04, 0xCE, 0xF5, 0x05, 0x60]) \
			or not _expect(CF72_WRAPPER_FILE, 0xCF84, [0xA9, 0x18, 0x85, 0x24, 0xA9, 0x19, 0x85, 0x25, 0x4C, 0x2D, 0xCE]) \
			or not _expect(ANIMATION_GATE_FILE, 0xA215, [0xA9, 0x01, 0x20, 0x15, 0xC5]) \
			or not _expect(ANIMATION_INDEX_FILE, 0xA2AC, [0x25, 0xA4]) \
			or not _expect(ANIMATION_INDEX_TABLE_FILE, 0xA292, [0xAE, 0xA2]) \
			or not _expect(ANIMATION_STREAM_ZERO_FILE, 0xA2AE, [0x05, 0x00]) \
			or not _expect(ANIMATION_STREAM_INDEX1_FILE, 0xA2CB, [0x05, 0x04]) \
			or not _expect(ANIMATION_STREAM_INDEX1_FILE, 0xA2E5, [0xFF, 0xCB, 0xA2]) \
			or not _expect(ANIMATION_PACKET_POINTER_TABLE_FILE, 0xA42A, [0x6A, 0xA4, 0x8F, 0xA4, 0x94, 0xA4, 0x99, 0xA4, 0x9E, 0xA4]) \
			or not _expect(ANIMATION_PACKET_WAIT_FILE, 0x82F2, [0xA9, 0x01, 0x20, 0x15, 0xC5]) \
			or not _expect(ACTOR_EVENT_QUEUE_CONSUMER_FILE, 0x8273, [0xA9, 0x02, 0x85, 0x3B, 0xA2, 0x00]) \
			or not _expect(ACTOR_EVENT_QUEUE_CONSUMER_FILE, 0x82DB, [0x68, 0x68, 0x68, 0xAA, 0xBD, 0xC8, 0x86]):
		return _fail("A source opcode in the `$804A->$CC50` bounded path changed.")
	if not _expect(PARAMETER6D_POINTER_FILE, 0x92FA, [0xE3, 0x9B]) \
			or not _expect(PARAMETER6D_STREAM_FILE, 0x9BE3, [0xF2, 0xF4, 0x01, 0xEA, 0x9B]):
		return _fail("The actor-$6D `$92FA->$9BE3` pointer or initial `$F2` stream bytes changed.")
	if _sources[STREAM_FILE] != PackedByteArray([
		0xF4, 0x04, 0x52, 0x9F, 0xE1, 0x9F, 0x8B, 0xA0, 0x2A,
		0xA1, 0x25, 0xA2, 0x92, 0xA2, 0x02, 0xA3, 0xF5, 0x02]):
		return _fail("The packaged actor stream no longer contains the audited F4-to-F5 bytes.")
	if _sources[SEQUENCE_ROW_HANDLER_FILE] != PackedByteArray([0xAE, 0x29, 0x06, 0x60]) \
			or _sources[F4_SELECTOR03_TABLE_FILE] != PackedByteArray([
			0xF4, 0x03, 0xC9, 0xA3, 0xE3, 0xA3, 0xF7, 0xA3, 0x0C, 0xA4, 0x29, 0xA4]):
		return _fail("The selector-$03 `$0629` row handler or `$A3BD` pointer table differs from the pinned ROM bytes.")
	_configured = true
	return true


func is_scenario1c_parameter58_initial_delay_boundary(boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	return ram is PackedByteArray and stack is PackedByteArray \
			and (_is_scenario1c_parameter58_live_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_live_worker_profile(ram, stack, boundary))


func _is_scenario1e_actor58_source_root_profile(ram: PackedByteArray) -> bool:
	var callback_pending: bool = int(ram[0x0516]) in [0x61, 0x71] \
			and int(ram[0x0519]) <= 0x20 \
			and int(ram[0x0526]) == 0x80 and int(ram[0x052A]) == 0x40
	var callback_wait_restarted: bool = int(ram[0x0516]) == 0x01 \
			and int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x07 \
			and int(ram[0x0526]) == 0x00 and int(ram[0x052A]) == 0x40
	var callback_postprocessed: bool = int(ram[0x0516]) == 0x29 \
			and int(ram[0x0519]) > 0 and int(ram[0x0519]) <= 0x20 \
			and int(ram[0x0526]) == 0x00 and int(ram[0x052A]) == 0x00
	return (callback_pending or callback_wait_restarted or callback_postprocessed) \
			and int(ram[0x0517]) == 0x40 and int(ram[0x0518]) == 0x1E \
			and ram.slice(0x005D, 0x005F) == PackedByteArray([0xE3, 0xB7]) \
			and int(ram[0x0522]) == 0x00 \
			and ram.slice(0x0523, 0x052A) == PackedByteArray([0x07, 0x45, 0x06, int(ram[0x0526]), 0x3C, 0x90, 0xFF])


func _is_scenario1e_actor58_terminal_root_idle_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
			and ram.slice(0x0516, 0x051A) in [PackedByteArray([0x29, 0x40, 0x1E, 0x00]), PackedByteArray([0x00, 0x40, 0x1E, 0x00])] \
			and ram.slice(0x051A, 0x051D) == PackedByteArray([0xE8, 0x9B, 0x00]) \
			and int(ram[0x005D]) == 0xE3 and int(ram[0x005E]) == 0xB7 \
			and int(ram[0x0522]) == 0x00 \
			and ram.slice(0x0523, 0x052A) == PackedByteArray([0x07, 0x45, 0x06, int(ram[0x0526]), 0x3C, 0x90, 0xFF]) \
			and int(ram[0x0526]) == 0x00 and int(ram[0x052A]) == 0x00


## Validates the separate `$05F4=0` idle path for the live scenario-$1E/$58
## actor state. ROM `$A1EB` returns immediately here; `$05F5` and `$A2BA` stay put.
func is_scenario1e_actor58_inactive_zero_mode_resume_boundary(boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var record: Variant = boundary.get("record", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	if not ram is PackedByteArray or not stack is PackedByteArray \
			or not record is PackedByteArray or not mapper is Dictionary \
			or ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x804A \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19 \
			or int(ram[0x0000]) != SLOT_11 \
			or int(boundary.get("a", -1)) != 0x04 \
			or int(boundary.get("x", -1)) != 0x04 \
			or int(boundary.get("y", -1)) != 0x04 \
			or stack.slice(0xC7, 0xCB) != PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			or (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) != 0x9A62 \
			or int(ram[0x0518]) != 0x1E or int(ram[0x05EA]) != 0x58 \
			or not (_is_scenario1e_actor58_source_root_profile(ram) \
				or _is_scenario1e_actor58_terminal_root_idle_profile(ram)) \
			or ram[0x051A] != 0xE8 or ram[0x051B] != 0x9B or ram[0x051C] != 0x00 \
			or ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			or ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x00, 0x00, 0x01]) \
			or ram.slice(0x0063, 0x0065) != PackedByteArray([0xBA, 0xA2]) \
			or int(ram[0x0515]) not in [0x00, 0x80] or int(ram[0x0022]) != 0x00 \
			or int(ram[0x0629]) != 0x00:
		return false
	var bank_registers: Dictionary = mapper.get("bank_registers", {})
	return int(mapper.get("bank_low", -1)) == 0x18 \
			and int(mapper.get("bank_high", -1)) == 0x19 \
			and int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x18 \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x19


func is_scenario1e_actor58_animation_countdown_boundary(
		boundary: Dictionary, allow_zero_counter: bool = false
) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var record: Variant = boundary.get("record", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	if not ram is PackedByteArray or not stack is PackedByteArray \
			or not record is PackedByteArray or not mapper is Dictionary:
		return false
	if ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x804A \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19 \
			or int(ram[0x0000]) != SLOT_11:
		return false
	var registers: Dictionary = {
		"a": int(boundary.get("a", -1)),
		"x": int(boundary.get("x", -1)),
		"y": int(boundary.get("y", -1)),
	}
	# Index-$00's source stream advances on these even command boundaries.
	if registers != {"a": 0x04, "x": 0x04, "y": 0x04} \
			or int(boundary.get("p", -1)) not in [0x20, 0x21] \
			or int(boundary.get("p_known_mask", -1)) != 0x83 \
			or stack.slice(0xC7, 0xCB) != PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			or (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) != 0x9A62 \
			or int(ram[0x0518]) != 0x1E or int(ram[0x05EA]) != 0x58 \
			or not _is_scenario1e_actor58_source_root_profile(ram) \
			or ram[0x051A] != 0xE8 or ram[0x051B] != 0x9B or ram[0x051C] != 0x00 \
			or ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			or int(ram[0x05F3]) != 0x00 or int(ram[0x05F4]) != 0x01 \
			or (int(ram[0x05F5]) not in [1, 2, 3, 4, 5] \
				and not (allow_zero_counter and int(ram[0x05F5]) == 0)) \
			or (int(ram[0x0064]) != 0xA2 or int(ram[0x0063]) not in [
				0xB0, 0xB2, 0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6, 0xC8
			]) \
			or int(ram[0x0515]) != 0 or int(ram[0x0022]) != 0 or int(ram[0x0629]) != 0:
		return false
	var bank_registers: Dictionary = mapper.get("bank_registers", {})
	return int(mapper.get("bank_low", -1)) == 0x18 \
			and int(mapper.get("bank_high", -1)) == 0x19 \
			and int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x18 \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x19


func is_scenario1e_actor58_animation_countdown_saved_boundary(
		boundary: Dictionary, allow_zero_counter: bool = false
) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var record: Variant = boundary.get("record", PackedByteArray())
	if not ram is PackedByteArray or not stack is PackedByteArray or not record is PackedByteArray:
		return false
	if ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]):
		return false
	return int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("a", -1)) == 0x01 \
			and int(boundary.get("y", -1)) == 0x04 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9A62 \
			and int(ram[0x0518]) == 0x1E and int(ram[0x05EA]) == 0x58 \
			and _is_scenario1e_actor58_source_root_profile(ram) \
			and ram[0x051A] == 0xE8 and ram[0x051B] == 0x9B and ram[0x051C] == 0x00 \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and int(ram[0x05F3]) == 0x00 and int(ram[0x05F4]) == 0x01 \
			and (int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
				or (allow_zero_counter and int(ram[0x05F5]) == 0)) \
			and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0063]) in [
				0xB0, 0xB2, 0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6, 0xC8
			] \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0


func is_scenario1c_parameter58_delay_boundary(boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	return ram is PackedByteArray and stack is PackedByteArray \
			and (_is_scenario1c_parameter58_live_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_live_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_parameter58_countdown_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_countdown_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_parameter58_stream_dispatch_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_stream_dispatch_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_parameter58_post_packet_delay_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_post_packet_delay_worker_profile(ram, stack, boundary))


func is_scenario1c_parameter58_phase29_cursor10_queue_busy_animation_boundary(
		boundary: Dictionary
) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var record: Variant = boundary.get("record", PackedByteArray())
	if not ram is PackedByteArray or not stack is PackedByteArray or not record is PackedByteArray:
		return false
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and record == PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			and int(boundary.get("a", -1)) in [0x01, 0x04] \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04 \
			and int(boundary.get("bank_low", -1)) == 0x18 \
			and int(boundary.get("bank_high", -1)) == 0x19 \
			and ram.slice(0x0516, 0x0519) == PackedByteArray([0x29, 0x40, 0x1C]) \
			and int(ram[0x0519]) in [0x24, 0x25] \
			and int(ram[0x003A]) == 0x0A \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xA5, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x00]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and int(ram[0x05FB]) == 0x00 \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ((int(ram[0x0519]) == 0x25 and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x02])) \
			or (int(ram[0x0519]) == 0x24 and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x01]))) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB2, 0xA2]) \
			and int(ram[0x0515]) == 0x80 and int(ram[0x0022]) == 0 \
			and int(ram[0x0629]) == 0 \
			and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80])


func is_scenario1c_parameter58_zero_counter_queue_busy_animation_boundary(
		boundary: Dictionary
) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var record: Variant = boundary.get("record", PackedByteArray())
	if not ram is PackedByteArray or not stack is PackedByteArray or not record is PackedByteArray:
		return false
	if ram.size() != RAM_SIZE or stack.size() != STACK_SIZE:
		return false
	var pc := int(boundary.get("pc", -1))
	var at_countdown_dispatch := pc == 0xCB0F \
			and int(boundary.get("phase", -1)) == 3 \
			and int(boundary.get("pending_resume", -1)) == 2 \
			and int(boundary.get("active_task_slot", -1)) == -1
	var at_countdown_worker := pc == 0x804A \
			and int(boundary.get("phase", -1)) == 2 \
			and int(boundary.get("pending_resume", -1)) == 0 \
			and int(boundary.get("active_task_slot", -1)) == SLOT_11
	var at_animation_resume := pc == 0xA21A \
			and int(boundary.get("phase", -1)) == 2 \
			and int(boundary.get("pending_resume", -1)) == 0 \
			and int(boundary.get("active_task_slot", -1)) == SLOT_11
	if not at_countdown_dispatch and not at_countdown_worker and not at_animation_resume:
		return false
	var at_countdown_boundary := at_countdown_dispatch or at_countdown_worker
	var expected_record := PackedByteArray([0x00, 0xC6, 0x18, 0x19]) if at_countdown_boundary \
		else PackedByteArray([0x00, 0xC2, 0x1A, 0x1B])
	var expected_bank_low := 0x18 if at_countdown_boundary else 0x1A
	var expected_bank_high := 0x19 if at_countdown_boundary else 0x1B
	var expected_stack_frame := PackedByteArray([0x04, 0x04, 0x49, 0x80]) if at_countdown_boundary \
		else PackedByteArray([0x83, 0xCF, 0x4F, 0x80])
	var initial_counter_cursor_pair: bool = ram.slice(0x0516, 0x051D) \
			== PackedByteArray([0x29, 0x40, 0x1C, 0x23, 0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x00
	# The source worker decrements the scenario-local counter while the queue is
	# busy; `$A21A` itself gates only on `$0515`, so preserve that countdown.
	var advanced_animation_counter_cursor_pair: bool = at_animation_resume \
			and ram.slice(0x0516, 0x0519) == PackedByteArray([0x29, 0x40, 0x1C]) \
			and int(ram[0x0519]) <= 0x22 \
			and ram.slice(0x051A, 0x051D) == PackedByteArray([0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x0A
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and record == expected_record \
			and int(boundary.get("bank_low", -1)) == expected_bank_low \
			and int(boundary.get("bank_high", -1)) == expected_bank_high \
			and int(boundary.get("a", -1)) in [0x01, 0x04] \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04 \
			and (initial_counter_cursor_pair or advanced_animation_counter_cursor_pair) \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xA5, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x00]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and int(ram[0x05FB]) == 0x00 \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x00]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB2, 0xA2]) \
			and int(ram[0x0515]) == 0x80 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54 \
			and stack.slice(0xC7, 0xCB) == expected_stack_frame


func is_scenario1c_parameter58_post_packet_delay_boundary(boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	return ram is PackedByteArray and stack is PackedByteArray \
			and (_is_scenario1c_parameter58_post_packet_delay_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_post_packet_delay_worker_profile(ram, stack, boundary))


func is_scenario1c_parameter58_followup_post_packet_delay_boundary(boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	return ram is PackedByteArray and stack is PackedByteArray \
			and (_is_scenario1c_parameter58_followup_post_packet_delay_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_followup_post_packet_delay_worker_profile(ram, stack, boundary))


func is_scenario1c_parameter58_followup_text_terminal_boundary(boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	return ram is PackedByteArray and stack is PackedByteArray \
			and (_is_scenario1c_parameter58_followup_text_terminal_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_followup_text_terminal_worker_profile(ram, stack, boundary))


func is_scenario1c_parameter58_followup_packet_wait_boundary(boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	return ram is PackedByteArray and stack is PackedByteArray \
			and (_is_scenario1c_parameter58_followup_packet_wait_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_followup_packet_wait_profile(ram, stack, boundary))


func _is_scenario1c_parameter58_live_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and ((int(boundary.get("pc", -1)) == 0x804A and int(boundary.get("sp", -1)) == 0xCA) \
				or (int(boundary.get("pc", -1)) == 0xCB0F and int(boundary.get("sp", -1)) == 0xC6)) \
			and int(boundary.get("a", -1)) in [0x01, 0x62] \
			and int(boundary.get("x", -1)) == 0x62 \
			and int(boundary.get("y", -1)) == 0xB1 \
			and ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x40, 0x1C, 0x3B, 0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xA5, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x00, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xD7, 0xA2]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0xB1, 0x62, 0x49, 0x80])


## PASS callback-$63/map-$51 resumes the same ROM `$9A62` `$01` command from
## the source route's `$B4BD` actor chain. Keep this branch separate from the
## callback-$01/map-$12 profile above; the paired FCEUX snapshot confirms the
## command's `$05E4/$05E5/$05E9` writes at the following `$C515` boundary.
func _is_scenario1c_callback63_parameter58_live_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA \
			and int(boundary.get("a", -1)) == 0x62
	var yielded := pc == 0xCB0F and sp == 0xC6 \
			and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x62 \
			and int(boundary.get("y", -1)) == 0xB1 \
			and ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x40, 0x1C, 0x37, 0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x00, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xD7, 0xA2]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0xB1, 0x62, 0x49, 0x80])


func _is_scenario1c_parameter58_countdown_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA \
			and int(boundary.get("a", -1)) == 0x62
	var yielded := pc == 0xCB0F and sp == 0xC6 \
			and int(boundary.get("a", -1)) == 0x01
	var stream_index := int(ram[0x05E4]) if ram.size() == RAM_SIZE else -1
	var max_stream_delay := 0x01 if stream_index == 0x01 else 0x10 if stream_index == 0x02 else 0xE4 if stream_index == 0x03 else 0
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x62 \
			and int(boundary.get("y", -1)) == 0x00 \
			and stream_index in [0x01, 0x02, 0x03] \
			and int(ram[0x05E5]) == stream_index \
			and int(ram[0x05E9]) in range(1, max_stream_delay + 1) \
			and int(ram[0x0516]) == 0x01 and int(ram[0x0517]) == 0x40 \
			and int(ram[0x0518]) == 0x1C and int(ram[0x051A]) == 0xE8 \
			and int(ram[0x051B]) == 0x9B and int(ram[0x051C]) == 0x00 \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xA5, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram[0x05E3] == 0x01 and ram[0x05E6] == 0x0E \
			and ram[0x05E7] == 0x02 and ram[0x05E8] == 0x02 \
			and ram[0x05EA] == 0x58 \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xD7, 0xA2]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x00, 0x62, 0x49, 0x80])


## Callback-$63/map-$51 resumes the `$9A62` actor stream after its first
## delay tick. FCEUX seq. 2503–2507 pins the `$36` phase and pending `$05E9`
## tick; the ROM worker consumes that tick before the next saved state.
func _is_scenario1c_callback63_parameter58_countdown_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA \
			and int(boundary.get("a", -1)) == 0x62
	var yielded := pc == 0xCB0F and sp == 0xC6 \
			and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x62 \
			and int(boundary.get("y", -1)) == 0x00 \
			and ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x40, 0x1C, 0x36, 0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x01, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xD7, 0xA2]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x00, 0x62, 0x49, 0x80])


func _is_scenario1c_parameter58_stream_dispatch_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA \
			and int(boundary.get("a", -1)) == 0x62
	var yielded := pc == 0xCB0F and sp == 0xC6 \
			and int(boundary.get("a", -1)) == 0x01
	var stream_index := int(ram[0x05E4]) if ram.size() == RAM_SIZE else -1
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x62 \
			and int(boundary.get("y", -1)) == 0x00 \
			and stream_index in [0x01, 0x02] \
			and int(ram[0x05E5]) == stream_index and int(ram[0x05E9]) == 0x00 \
			and int(ram[0x0516]) == 0x01 and int(ram[0x0517]) == 0x40 \
			and int(ram[0x0518]) == 0x1C \
			and int(ram[0x051A]) == 0xE8 and int(ram[0x051B]) == 0x9B \
			and int(ram[0x051C]) == 0x00 \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xA5, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, stream_index, stream_index, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xD7, 0xA2]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x00, 0x62, 0x49, 0x80])


## Callback-$63/map-$51 dispatches the next `$A2D7` animation pair after the
## `$05E9` countdown reaches zero. This pins the observed `$35` phase so the
## ROM `$05 02` command selects packet row `$A494` through the normal decoder.
func _is_scenario1c_callback63_parameter58_stream_dispatch_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA \
			and int(boundary.get("a", -1)) == 0x62
	var yielded := pc == 0xCB0F and sp == 0xC6 \
			and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x62 \
			and int(boundary.get("y", -1)) == 0x00 \
			and ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x40, 0x1C, 0x35, 0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xD7, 0xA2]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x00, 0x62, 0x49, 0x80])


func _is_scenario1c_parameter58_post_packet_delay_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var mapper_variant: Variant = boundary.get("mapper", {})
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	var bank_registers: Dictionary = bank_registers_variant if bank_registers_variant is Dictionary else {}
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA and int(boundary.get("a", -1)) == 0x05
	var yielded := pc == 0xCB0F and sp == 0xC6 and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x04 \
			and (yielded or (int(boundary.get("p", -1)) == 0x20 \
				and int(boundary.get("p_known_mask", -1)) == 0x83)) \
			and (yielded or int(mapper.get("select", -1)) in [6, 7]) \
			and int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x18 \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x19 \
			and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9A62 \
			and ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x40, 0x1C, 0x2F, 0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xA5, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x02, 0x05, 0x0E, 0x02, 0x02, 0x01, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x04]) \
			and int(ram[0x05EA]) == 0x58 \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x05, 0x49, 0x80])


## PASS callback-$63/map-$51 reaches the same `$82F2` packet-wait routine
## through its own scenario/task chain. Keep this exact phase separate from
## the older callback-$01/map-$12 compatibility profile above.
func _is_scenario1c_callback63_parameter58_followup_packet_wait_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var mapper_variant: Variant = boundary.get("mapper", {})
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	var bank_registers: Dictionary = bank_registers_variant if bank_registers_variant is Dictionary else {}
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA and int(boundary.get("a", -1)) == 0x05
	var yielded := pc == 0xCB0F and sp == 0xC6 and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x04 \
			and (yielded or (int(boundary.get("p", -1)) == 0x20 \
				and int(boundary.get("p_known_mask", -1)) == 0x83)) \
			and (yielded or int(mapper.get("select", -1)) in [6, 7]) \
			and int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x18 \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x19 \
			and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9A62 \
			and ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x40, 0x1C, 0x2A, 0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x02, 0x05, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x03]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x05, 0x49, 0x80])


## PASS callback-$63/map-$51 resumes the ROM animation stream at `$A2B0`.
## Its `$05,$01` command selects packet `$A48F`; keep the callback's
## `$2B` phase and actor/map context pinned while the ROM countdown code runs.
func _is_scenario1c_callback63_parameter58_post_packet_delay_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var mapper_variant: Variant = boundary.get("mapper", {})
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	var bank_registers: Dictionary = bank_registers_variant if bank_registers_variant is Dictionary else {}
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA and int(boundary.get("a", -1)) == 0x05
	var yielded := pc == 0xCB0F and sp == 0xC6 and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x04 \
			and (yielded or (int(boundary.get("p", -1)) == 0x20 \
				and int(boundary.get("p_known_mask", -1)) == 0x83)) \
			and (yielded or int(mapper.get("select", -1)) in [6, 7]) \
			and int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x18 \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x19 \
			and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9A62 \
			and ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x40, 0x1C, 0x2B, 0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x02, 0x05, 0x0E, 0x02, 0x02, 0x01, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x04]) \
			and int(ram[0x05EA]) == 0x58 \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x05, 0x49, 0x80])


func _is_scenario1c_parameter58_followup_post_packet_delay_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var mapper_variant: Variant = boundary.get("mapper", {})
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	var bank_registers: Dictionary = bank_registers_variant if bank_registers_variant is Dictionary else {}
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA and int(boundary.get("a", -1)) == 0x06
	var yielded := pc == 0xCB0F and sp == 0xC6 and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A \
			and (yielded or (int(boundary.get("p", -1)) == 0x20 \
				and int(boundary.get("p_known_mask", -1)) == 0x83)) \
			and (yielded or int(mapper.get("select", -1)) in [6, 7]) \
			and int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x18 \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x19 \
			and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9A62 \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xA5, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x0D, 0x0E, 0x02, 0x02, 0x01, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x02]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x3A, 0x06, 0x49, 0x80])


## PASS callback-$63/map-$51 follow-up text packet executes one ordinary
## `$804A` animation countdown tick. This is a separate frame-9247 source
## profile from the callback-$01/map-$12 branch above.
func _is_scenario1c_callback63_parameter58_followup_post_packet_delay_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var mapper_variant: Variant = boundary.get("mapper", {})
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	var bank_registers: Dictionary = bank_registers_variant if bank_registers_variant is Dictionary else {}
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA and int(boundary.get("a", -1)) == 0x06
	var yielded := pc == 0xCB0F and sp == 0xC6 and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A \
			and (yielded or (int(boundary.get("p", -1)) == 0x20 \
				and int(boundary.get("p_known_mask", -1)) == 0x83)) \
			and (yielded or int(mapper.get("select", -1)) in [6, 7]) \
			and int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x18 \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x19 \
			and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9A62 \
			and ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x40, 0x1C, 0x28, 0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x0D, 0x0E, 0x02, 0x02, 0x01, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x02]) \
			and int(ram[0x05EA]) == 0x58 \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and int(ram[0x052B]) == 0 and int(ram[0x05FB]) == 0 \
			and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x3A, 0x06, 0x49, 0x80])


func _is_scenario1c_parameter58_followup_text_terminal_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var mapper_variant: Variant = boundary.get("mapper", {})
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	var bank_registers: Dictionary = bank_registers_variant if bank_registers_variant is Dictionary else {}
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA and int(boundary.get("a", -1)) == 0x06
	var yielded := pc == 0xCB0F and sp == 0xC6 and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A \
			and (yielded or (int(boundary.get("p", -1)) == 0x20 \
				and int(boundary.get("p_known_mask", -1)) == 0x83)) \
			and (yielded or int(mapper.get("select", -1)) in [6, 7]) \
			and int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x18 \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x19 \
			and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9A62 \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xA5, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x0D, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x01]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x3A, 0x06, 0x49, 0x80])


## Callback-$63/map-$51's phase-$29 actor stream reaches ROM `$F0` at
## `$9A62+$05E5=$9A6F`. The same worker terminal handler as the older
## callback-$01 path clears `$05E3`, then the `$A1EB` animation gate consumes
## the last `$05F5` tick before the `$C515` yield.
func _is_scenario1c_callback63_parameter58_followup_text_terminal_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var mapper_variant: Variant = boundary.get("mapper", {})
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	var bank_registers: Dictionary = bank_registers_variant if bank_registers_variant is Dictionary else {}
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA and int(boundary.get("a", -1)) == 0x06
	var yielded := pc == 0xCB0F and sp == 0xC6 and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A \
			and (yielded or (int(boundary.get("p", -1)) == 0x20 \
				and int(boundary.get("p_known_mask", -1)) == 0x83)) \
			and (yielded or int(mapper.get("select", -1)) in [6, 7]) \
			and int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x18 \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x19 \
			and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9A62 \
			and ram.slice(0x0516, 0x051D) == PackedByteArray([0x29, 0x40, 0x1C, 0x27, 0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x01 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xBD, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x38, 0x63, 0x02, 0x3C, 0x4A, 0x7A, 0x58, 0x00]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x51, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and int(ram[0x05EA]) == 0x58 \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x0D, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x01]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and int(ram[0x052B]) == 0 and int(ram[0x05FB]) == 0 \
			and int(ram[0x0635]) == 0x84 and int(ram[0x0637]) == 0x54 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x3A, 0x06, 0x49, 0x80])


func _is_scenario1c_parameter58_followup_packet_wait_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary
) -> bool:
	var mapper_variant: Variant = boundary.get("mapper", {})
	var mapper: Dictionary = mapper_variant if mapper_variant is Dictionary else {}
	var bank_registers_variant: Variant = mapper.get("bank_registers", {})
	var bank_registers: Dictionary = bank_registers_variant if bank_registers_variant is Dictionary else {}
	var pc := int(boundary.get("pc", -1))
	var sp := int(boundary.get("sp", -1))
	var dispatched := pc == 0x804A and sp == 0xCA and int(boundary.get("a", -1)) == 0x05
	var yielded := pc == 0xCB0F and sp == 0xC6 and int(boundary.get("a", -1)) == 0x01
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
			and (dispatched or yielded) \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x04 \
			and (yielded or (int(boundary.get("p", -1)) == 0x20 \
				and int(boundary.get("p_known_mask", -1)) == 0x83)) \
			and (yielded or int(mapper.get("select", -1)) in [6, 7]) \
			and int(bank_registers.get(6, bank_registers.get("6", -1))) == 0x18 \
			and int(bank_registers.get(7, bank_registers.get("7", -1))) == 0x19 \
			and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9A62 \
			and ram.slice(0x0516, 0x0519) == PackedByteArray([0x01, 0x40, 0x1C]) \
			and ram.slice(0x051A, 0x051D) == PackedByteArray([0xE8, 0x9B, 0x00]) \
			and int(ram[0x003A]) == 0x06 \
			and ram.slice(0x005D, 0x0061) == PackedByteArray([0xA5, 0xB4, 0x62, 0x9A]) \
			and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x3C, 0x01, 0x02, 0x3C, 0x4A, 0x78, 0x58, 0x40]) \
			and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x00, 0x01, 0x12, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x02, 0x05, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x03]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x05, 0x49, 0x80])


## Consumes only a live yielded-task scheduler snapshot restored to `$804A`.
## Output PC is `$CB0F` after the actual `$CC50 JSR $CB0F` stack entry.
func execute_from_resumed_slot11_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported scheduler boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {
		"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"]),
	})
	mapper = mapper.duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var callsite_registers: Dictionary = {}
	var callsite_stack := PackedByteArray()
	var initial_stream_pointer := int(ram[0x005F]) | (int(ram[0x0060]) << 8)
	var is_parameter47_stream := initial_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 and int(ram[0x0026]) == 0
	var is_scenario1c_parameter00_stream := initial_stream_pointer == 0x9400 \
			and int(ram[0x05EA]) == 0x00 and int(ram[0x0026]) == 0 \
			and _is_scenario1c_actor00_live_worker_profile(ram)
	var is_scenario2e_callback36_map2f_parameter6d_stream := initial_stream_pointer == 0x9BE3 \
			and int(ram[0x05EA]) == 0x6D \
			and (_is_scenario2e_callback36_map2f_actor6d_live_worker_profile(ram, stack, boundary) \
			or _is_scenario2e_callback36_map2f_actor6d_f2_waiter_entry_profile(ram, stack, boundary))
	var is_parameter73_stream := initial_stream_pointer == 0x9F42 \
			and int(ram[0x0026]) == 0
	var is_sequence_selector03_stream := initial_stream_pointer == 0xA3BD \
			and int(ram[0x0629]) <= 4 and int(ram[0x05E4]) == 0 and int(ram[0x05E5]) == 0
	var is_sequence_selector03_event_stream := initial_stream_pointer == 0xA3C9 \
			and int(ram[0x0629]) == 0 and int(ram[0x05E4]) == 1 and int(ram[0x05E5]) == 1
	var is_a439_initial_delay_stream := initial_stream_pointer == 0xA439 \
			and int(ram[0x05E4]) == 0 and int(ram[0x05E5]) == 0 \
			and int(ram[0x05F5]) == 0x05
	var is_scenario1e_actor58_inactive_zero_mode_stream := \
			is_scenario1e_actor58_inactive_zero_mode_resume_boundary(boundary)
	if (int(ram[0x05E3]) != 1 and not is_scenario1e_actor58_inactive_zero_mode_stream) \
			or int(ram[0x05E9]) != 0 \
			or not (is_parameter47_stream or is_scenario1c_parameter00_stream \
			or is_scenario2e_callback36_map2f_parameter6d_stream \
			or is_parameter73_stream or is_sequence_selector03_stream \
			or is_sequence_selector03_event_stream or is_a439_initial_delay_stream \
			or is_scenario1e_actor58_inactive_zero_mode_stream):
		return _unsupported("Live worker state is outside the verified actor-$47, scenario-$1C actor-$00, scenario-$2E actor-$6D, parameter-$73, or selector-$03 stream entry.")

	# `$804A JSR $8053`; execute the ROM's `$05E3/$05E9/$05E4` guards.
	instruction_pcs.append(0x804A)
	_jsr(cpu, stack, stack_writes, 0x804A, 0x8053)
	instruction_pcs.append(0x8053)
	_set_a(cpu, int(ram[0x05E3]))
	_read_event(source_reads, 0x8053, 0x05E3, int(ram[0x05E3]), "worker_active_flag")
	if int(cpu["a"]) != 1:
		return _unsupported("The source `$8053` inactive-worker RTS branch is outside this route slice.")
	instruction_pcs.append(0x8056)
	instruction_pcs.append(0x8059)
	_set_a(cpu, int(ram[0x05E9]))
	_read_event(source_reads, 0x8059, 0x05E9, int(ram[0x05E9]), "worker_delay")
	instruction_pcs.append(0x805C)
	if int(cpu["a"]) != 0:
		return _unsupported("The live `$05E9` delay-countdown branch does not reach the audited F4/F5 dispatch.")
	instruction_pcs.append(0x8062)
	_set_a(cpu, int(ram[0x05E4]))
	_read_event(source_reads, 0x8062, 0x05E4, int(ram[0x05E4]), "actor_stream_dispatch_index")
	if int(cpu["a"]) != 0:
		return _unsupported("Only stream-dispatch index `$00` is packaged for this first resume.")
	instruction_pcs.append(0x8065)
	_jsr(cpu, stack, stack_writes, 0x8065, 0xC509)
	var first_handler := _inline_dispatch(cpu, ram, stack, ram_writes, stack_writes,
		stack_reads, source_reads, 0x8065, 0x8068, instruction_pcs)
	if first_handler != 0x806E:
		return _unsupported("Live `$05E4` resolves outside the packaged first stream handler.")

	# `$806E` parses the F4 command. Its selector `$04` reads the match-zero
	# pointer row at `$9F44/$9F45`, then the same source loop sees `$F5` at `$9F52`.
	while true:
		instruction_pcs.append(0x806E)
		_set_y(cpu, int(ram[0x05E5]))
		_read_event(source_reads, 0x806E, 0x05E5, int(ram[0x05E5]), "actor_stream_index")
		instruction_pcs.append(0x8071)
		_write_ram(ram, ram_writes, 0x05E5, (int(ram[0x05E5]) + 1) & 0xFF, 0x8071)
		_read_event(source_reads, 0x8074, 0x005F, int(ram[0x005F]), "actor_stream_pointer_low")
		_read_event(source_reads, 0x8074, 0x0060, int(ram[0x0060]), "actor_stream_pointer_high")
		var stream_address := ((int(ram[0x0060]) << 8) | int(ram[0x005F])) + int(cpu["y"])
		var stream_byte := _read_stream_byte(stream_address)
		if stream_byte < 0:
			return _unsupported("Actor stream pointer/index leaves the hash-checked `$9F42-$9F53` span.")
		_read_event(source_reads, 0x8074, stream_address, stream_byte, "actor_stream_command")
		_set_a(cpu, stream_byte)
		instruction_pcs.append(0x8076)
		_compare_a(cpu, 0xF0)
		instruction_pcs.append(0x8078)
		if stream_byte < 0xF0:
			if is_sequence_selector03_stream and stream_byte == 0x01 \
					and int(cpu["y"]) == 0:
				return _unsupported("ROM `$A3BD` selector `$03` resolved `$%04X`; `$8080` reads the first `$01` delay byte, and its live `$804D` wrapper continuation is not yet modeled." % (int(ram[0x005F]) | (int(ram[0x0060]) << 8)))
			return _unsupported("The source takes the timed `$05E9` payload branch; it is not the immediate F4/F5 yield.")
		instruction_pcs.append(0x807A)
		_jsr(cpu, stack, stack_writes, 0x807A, 0x8087)
		instruction_pcs.append(0x8087)
		_set_a(cpu, stream_byte & 0x0F)
		instruction_pcs.append(0x8089)
		_jsr(cpu, stack, stack_writes, 0x8089, 0xC509)
		var command_handler := _inline_dispatch(cpu, ram, stack, ram_writes,
			stack_writes, stack_reads, source_reads, 0x8089, 0x808C, instruction_pcs)
		if command_handler == 0x80CB:
			# `$80CB`: selector byte 04, table lookup at `$8122`, then pointer fetch.
			instruction_pcs.append(0x80CB)
			_set_y(cpu, int(ram[0x05E5]))
			_read_event(source_reads, 0x80CE, 0x005F, int(ram[0x005F]), "F4_stream_pointer_low")
			_read_event(source_reads, 0x80CE, 0x0060, int(ram[0x0060]), "F4_stream_pointer_high")
			var selector_address := ((int(ram[0x0060]) << 8) | int(ram[0x005F])) + int(cpu["y"])
			var selector := _read_stream_byte(selector_address)
			if selector not in [0x03, 0x04] \
					or (selector == 0x03 and not is_sequence_selector03_stream) \
					or (selector == 0x04 and not is_parameter73_stream):
				return _unsupported("F4 selector is not the active source-backed selector-$03 or parameter-$73 selector-$04 command.")
			_read_event(source_reads, 0x80CE, selector_address, selector, "F4_selector")
			_set_a(cpu, selector)
			instruction_pcs.append(0x80D0)
			_jsr(cpu, stack, stack_writes, 0x80D0, 0x80EA)
			instruction_pcs.append(0x80EA)
			_jsr(cpu, stack, stack_writes, 0x80EA, 0xC509)
			var row_handler := _inline_dispatch(cpu, ram, stack, ram_writes,
				stack_writes, stack_reads, source_reads, 0x80EA, 0x80ED, instruction_pcs)
			var selected_row := -1
			if selector == 0x04:
				if row_handler != 0x8122:
					return _unsupported("F4 selector `$04` no longer resolves to its ROM match-index row selector `$8122`.")
				selected_row = _run_match_index_selector(cpu, ram, source_reads, instruction_pcs)
				if selected_row != 0:
					return _unsupported("The live `$0026` selector chooses a pointer row outside this match-zero stream slice.")
				_rts(cpu, stack, stack_reads, 0x8130)
			else:
				if row_handler != 0x811E:
					return _unsupported("F4 selector `$03` no longer resolves to the ROM `$811E` sequence-row handler.")
				instruction_pcs.append(0x811E)
				selected_row = int(ram[0x0629])
				_read_event(source_reads, 0x811E, 0x0629, selected_row, "actor_sequence_row")
				_set_x(cpu, selected_row)
				instruction_pcs.append(0x8121)
				_rts(cpu, stack, stack_reads, 0x8121)
				if int(cpu["pc"]) != 0x80D3:
					return _unsupported("The ROM `$811E` RTS did not return to the `$80D3` F4 pointer calculation.")
			# Selector `$03` reads the sequence row from `$0629`; selector `$04`
			# still derives the match row through `$8122`.
			# Resume `$80CB` after JSR $80EA.
			instruction_pcs.append(0x80D3)
			_set_a(cpu, int(cpu["x"]))
			instruction_pcs.append(0x80D4)
			var doubled_row := (int(cpu["a"]) << 1) & 0xFF
			_set_flag(cpu, P_C, (int(cpu["a"]) & 0x80) != 0)
			_set_a(cpu, doubled_row)
			instruction_pcs.append(0x80D5)
			_set_flag(cpu, P_C, true)
			instruction_pcs.append(0x80D6)
			var adc_before := int(cpu["a"]) & 0xFF
			var adc_operand := int(ram[0x05E5])
			_read_event(source_reads, 0x80D6, 0x05E5, adc_operand, "F4_pointer_row_index")
			var adc_carry := 1 if (int(cpu["p"]) & P_C) != 0 else 0
			var adc_sum := adc_before + adc_operand + adc_carry
			var pointer_offset := adc_sum & 0xFF
			_set_flag(cpu, P_C, adc_sum > 0xFF)
			_set_flag(cpu, P_V, ((~(adc_before ^ adc_operand) & (adc_before ^ adc_sum)) & 0x80) != 0)
			_set_a(cpu, pointer_offset)
			instruction_pcs.append(0x80D9)
			_set_y(cpu, int(cpu["a"]))
			var low_address := ((int(ram[0x0060]) << 8) | int(ram[0x005F])) + pointer_offset
			var pointer_low := _read_stream_byte(low_address)
			var pointer_high := _read_stream_byte(low_address + 1)
			var resolved_target := pointer_low | (pointer_high << 8)
			if selector == 0x04 and resolved_target != 0x9F52:
				return _unsupported("F4 selector `$04` no longer resolves to the verified match-zero target `$9F52`.")
			if selector == 0x03 and (resolved_target < 0xA3C9 or resolved_target > 0xA429):
				return _unsupported("F4 selector `$03` resolved outside the five verified bank-$19 sequence streams.")
			instruction_pcs.append(0x80DA)
			_read_event(source_reads, 0x80DA, low_address, pointer_low, "F4_target_pointer_low")
			_set_a(cpu, pointer_low)
			instruction_pcs.append(0x80DC)
			_set_x(cpu, int(cpu["a"]))
			instruction_pcs.append(0x80DD)
			_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
			instruction_pcs.append(0x80DE)
			_read_event(source_reads, 0x80DE, low_address + 1, pointer_high, "F4_target_pointer_high")
			_set_a(cpu, pointer_high)
			instruction_pcs.append(0x80E0)
			_write_ram(ram, ram_writes, 0x005F, int(cpu["x"]), 0x80E0)
			instruction_pcs.append(0x80E2)
			_write_ram(ram, ram_writes, 0x0060, int(cpu["a"]), 0x80E2)
			instruction_pcs.append(0x80E4)
			_set_a(cpu, 0)
			instruction_pcs.append(0x80E6)
			_write_ram(ram, ram_writes, 0x05E5, 0, 0x80E6)
			instruction_pcs.append(0x80E9)
			_rts(cpu, stack, stack_reads, 0x80E9)
			# The handler RTS consumes the `$807A JSR $8087` return word and
			# resumes at `$807D`, whose ROM instruction jumps back to `$806E`.
			if int(cpu["pc"]) != 0x807D:
				return _unsupported("The F4 handler RTS did not restore the audited `$807D` parser continuation.")
			instruction_pcs.append(0x807D)
			continue
		if command_handler == 0x80B5:
			var is_parameter00_f2 := is_scenario1c_parameter00_stream \
					and stream_address == 0x9400 and stream_byte == 0xF2 \
					and _expect(PARAMETER00_STREAM_FILE, 0x9400, [0xF2, 0xF0])
			var is_parameter6d_f2 := is_scenario2e_callback36_map2f_parameter6d_stream \
					and stream_address == 0x9BE3 and stream_byte == 0xF2 \
					and _expect(PARAMETER6D_STREAM_FILE, 0x9BE3, [0xF2])
			if not ((is_parameter47_stream and stream_address == 0x9917 \
					and stream_byte == 0xF2 and int(ram[0x05E4]) == 0 \
					and int(ram[0x05E5]) == 1 and int(ram[0x05EA]) == 0x47) \
				or (is_parameter00_f2 and int(ram[0x05E4]) == 0 \
					and int(ram[0x05E5]) == 1 and int(ram[0x05EA]) == 0x00) \
				or (is_parameter6d_f2 and int(ram[0x05E4]) == 0 \
					and int(ram[0x05E5]) == 1 and int(ram[0x05EA]) == 0x6D)) \
					or not _expect(WORKER_FILE, 0x80B5, [0x4C, 0x2D, 0xC5]) \
					or not _expect(C52D_FILE, 0xC52D, [0x4C, 0x46, 0xCC]) \
					or not _expect(WAITER_FILE, 0xCC46, [
						0xA9, 0x00, 0x8D, 0xF4, 0x05, 0xA9, 0x06, 0x48,
						0xA9, 0x01, 0x20, 0x0F, 0xCB]):
				return _unsupported("The `$80B5` direct-JMP waiter requires a verified live parameter-$47, scenario-$1C actor-$00, or scenario-$2E actor-$6D F2 source byte.")
			instruction_pcs.append(0x80B5)
			_read_event(source_reads, 0x80B5, 0x80B5, 0x4C, "F2_direct_jmp_opcode")
			cpu["pc"] = 0xC52D
			instruction_pcs.append(0xC52D)
			_read_event(source_reads, 0xC52D, 0xC52D, 0x4C, "shared_waiter_jmp_opcode")
			cpu["pc"] = 0xCC46
			instruction_pcs.append(0xCC46)
			_read_event(source_reads, 0xCC46, 0xCC46, 0xA9, "waiter_entry_opcode")
			_set_a(cpu, 0x00)
			instruction_pcs.append(0xCC48)
			_write_ram(ram, ram_writes, 0x05F4, 0x00, 0xCC48)
			instruction_pcs.append(0xCC4B)
			_set_a(cpu, 0x06)
			instruction_pcs.append(0xCC4D)
			_push(cpu, stack, stack_writes, 0x06, 0xCC4D, "PHA")
			instruction_pcs.append(0xCC4E)
			_set_a(cpu, 0x01)
			instruction_pcs.append(0xCC50)
			cpu["pc"] = 0xCC50
			callsite_registers = cpu.duplicate(true)
			callsite_stack = stack.duplicate()
			_jsr(cpu, stack, stack_writes, 0xCC50, 0xCB0F)
			instruction_pcs.append(0xCB0F)
			_read_event(source_reads, 0xCC50, 0xCC50, 0x20, "task_save_jsr_opcode")
			var expected_f2_saved_x := 0x00 if is_parameter00_f2 else (0xE3 if is_parameter6d_f2 else 0x17)
			var expected_f2_saved_y := 0x06
			var expected_f2_saved_outer_stack := PackedByteArray([0x7C, 0x80])
			if int(cpu["pc"]) != 0xCB0F or int(cpu["sp"]) != 0xC3 \
					or int(cpu["a"]) != 0x01 or int(cpu["x"]) != expected_f2_saved_x \
					or int(cpu["y"]) != expected_f2_saved_y \
					or int(stack[0xC4]) != 0x52 or int(stack[0xC5]) != 0xCC \
					or int(stack[0xC6]) != 0x06 \
					or stack.slice(0xC7, 0xC9) != expected_f2_saved_outer_stack:
				return _reject("Source-derived actor F2 JMP stack frame failed its `$CC50->$CB0F` boundary invariant.")
			var f2_result := _result(boundary, entry_cpu, entry_ram, entry_stack,
				cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
				source_reads, instruction_pcs, callsite_registers, callsite_stack)
			f2_result["stream_route"] = "scenario2e_callback36_map2f_parameter6d_f2_waiter" \
					if is_parameter6d_f2 else ("scenario1c_parameter00_f2_terminal" if is_parameter00_f2 else "parameter47_f2")
			f2_result["stream_command"] = 0xF2
			f2_result["resolved_dispatch_target"] = 0x80B5
			f2_result.erase("resolved_f4_target")
			f2_result.erase("resolved_f5_handler")
			var f2_source_span_hashes := {
				WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
				C52D_FILE: "eb93189d38ebaea8201970900e5b276a27c54c6fa2001a705945cb1d5172f371",
				WAITER_FILE: "dce4d011f0e612ea074e546e43c28c5395220f2af924a49aee4b35c2491775e3",
				"inline_dispatch": INLINE_DISPATCH_SHA256,
				"trampoline": TRAMPOLINE_SHA256,
			}
			if is_parameter6d_f2:
				f2_source_span_hashes[PARAMETER6D_POINTER_FILE] = \
					"0aebdd98608aa88311ca8ab9bedd486c26160ed4a842df5297fd8572eb568bf4"
				f2_source_span_hashes[PARAMETER6D_STREAM_FILE] = \
					"0b787ded174d6496196c978f5b835c4e89c9858a8499617b02bacc5b3f7b7d1e"
				f2_result["actor_parameter"] = 0x6D
				f2_result["actor_parameter_manifest"] = PARAMETER6D_MANIFEST_PATH
			elif is_parameter00_f2:
				f2_source_span_hashes[PARAMETER00_STREAM_FILE] = \
					"fe770f516cf9f97533711e76a9477f63a7477d5152ba22ab0d81fa93a95c1600"
			else:
				f2_source_span_hashes[PARAMETER47_STREAM_FILE] = \
					"1c33322d68d5d662476619ddd88fd2cfd3df15d6112aa4d3ab4a110dea89ae8f"
			f2_result["source_span_hashes"] = f2_source_span_hashes
			var f2_save_contract: Dictionary = f2_result["scheduler_save_contract"]
			f2_save_contract["expected_saved_sp_after_cb0f_pushes"] = 0xC1
			return f2_result
		if command_handler == 0x81FD:
			# `$81FD JSR $C52D`, `$C52D JMP $CC46`, then the verified waiter.
			instruction_pcs.append(0x81FD)
			_jsr(cpu, stack, stack_writes, 0x81FD, 0xC52D)
			instruction_pcs.append(0xC52D)
			cpu["pc"] = 0xCC46
			_set_a(cpu, 0)
			instruction_pcs.append(0xCC46)
			_write_ram(ram, ram_writes, 0x05F4, 0, 0xCC48)
			instruction_pcs.append(0xCC4B)
			_set_a(cpu, 6)
			instruction_pcs.append(0xCC4D)
			_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCC4D, "PHA")
			instruction_pcs.append(0xCC4E)
			_set_a(cpu, 1)
			instruction_pcs.append(0xCC50)
			cpu["pc"] = 0xCC50
			callsite_registers = cpu.duplicate(true)
			callsite_stack = stack.duplicate()
			_jsr(cpu, stack, stack_writes, 0xCC50, 0xCB0F)
			instruction_pcs.append(0xCB0F)
			if int(cpu["pc"]) != 0xCB0F or int(cpu["sp"]) != 0xC1 \
					or int(cpu["a"]) != 0x01 or int(cpu["x"]) != 0x52 \
					or int(cpu["y"]) != 0x0C \
					or int(stack[0xC2]) != 0x52 or int(stack[0xC3]) != 0xCC \
					or int(stack[0xC4]) != 0x06 or int(stack[0xC5]) != 0xFF \
					or int(stack[0xC6]) != 0x81 or int(stack[0xC7]) != 0x7C \
					or int(stack[0xC8]) != 0x80:
				return _reject("Source-derived `$CC50->$CB0F` stack frame failed its boundary invariant.")
			return _result(boundary, entry_cpu, entry_ram, entry_stack, cpu, mapper,
				ram, stack, ram_writes, stack_writes, stack_reads, source_reads,
				instruction_pcs, callsite_registers, callsite_stack)


		return _unsupported("F4/F5 stream opcode resolves outside the packaged source rows.")

	return _unsupported("The actor-stream loop left the bounded F4/F5 command path.")


## Executes the ROM's one-tick `$05E9` delay from the live parameter-$47 F2
## continuation. It stops at `$804D` before the following animation gate.
func execute_from_slot11_parameter47_f2_delay_tick_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x804A \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return _reject("Input is not the live slot-$11 parameter-$47 F2 `$804A` delay tick.")
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or not ram_variant is PackedByteArray or ram_variant.size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or stack_variant.size() != STACK_SIZE \
			or not mapper_variant is Dictionary:
		return _reject("The F2 delay tick omitted its exact scheduler record, RAM, stack, or mapper snapshot.")
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant.duplicate(true)
	var mapper_registers_variant: Variant = mapper.get("bank_registers", {})
	if not mapper_registers_variant is Dictionary:
		return _reject("The F2 delay tick mapper snapshot omits MMC3 bank registers 6/7.")
	var mapper_registers: Dictionary = mapper_registers_variant
	var is_f2_countdown_tick := int(ram[0x05E9]) == 0x01 \
			and int(boundary.get("a", -1)) == 0x21
	var is_f2_type5_event := int(ram[0x05E9]) == 0x00 \
			and int(boundary.get("a", -1)) == 0x21
	if bool(boundary.get("trace_state_used", true)) \
			or bool(boundary.get("test_fixture", true)) \
			or int(ram[0x0000]) != SLOT_11 \
			or int(ram[0x005F]) != 0x17 or int(ram[0x0060]) != 0x99 \
			or int(ram[0x05EA]) != 0x47 \
			or int(ram[0x05E3]) != 0x01 or int(ram[0x05E4]) != 0x01 \
			or int(ram[0x05E5]) != 0x02 or int(ram[0x05E6]) != 0x0E \
			or int(ram[0x05E7]) != 0x02 or int(ram[0x05E8]) != 0x02 \
			or not (is_f2_countdown_tick or is_f2_type5_event) \
			or int(ram[0x05F3]) != 0x00 or int(ram[0x05F4]) != 0x00 \
			or int(ram[0x05F5]) != 0x01 or int(ram[0x0515]) != 0x00 \
			or int(ram[0x0063]) != 0xBC or int(ram[0x0064]) != 0xA2 \
			or int(stack[0xC7]) != 0x01 or int(stack[0xC8]) != 0x21 \
			or int(stack[0xC9]) != 0x49 or int(stack[0xCA]) != 0x80 \
			or int(boundary.get("x", -1)) != 0x21 \
			or int(boundary.get("y", -1)) != 0x01 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper_registers.get(6, mapper_registers.get("6", -1))) != 0x18 \
			or int(mapper_registers.get(7, mapper_registers.get("7", -1))) != 0x19 \
			or int(mapper.get("select", -1)) not in [6, 7]:
		return _reject("The live F2 `$804A` delay/event profile differs from the confirmed parameter-$47 state.")
	for stack_offset in STACK_SIZE:
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return _reject("The F2 `$804A` RAM and stack snapshots disagree at `$%02X`." % stack_offset)
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return _reject("The F2 `$804A` boundary omits valid CPU status and known-bit values.")
	if not _expect(WORKER_FILE, 0x804A, [0x20, 0x53, 0x80]) \
			or not _expect(WORKER_FILE, 0x8053, [0xAD, 0xE3, 0x05, 0xD0, 0x01, 0x60]) \
			or not _expect(WORKER_FILE, 0x8059, [0xAD, 0xE9, 0x05, 0xF0, 0x04, 0xCE, 0xE9, 0x05, 0x60]) \
			or not _expect(WORKER_FILE, 0x8062, [0xAD, 0xE4, 0x05, 0x20, 0x09, 0xC5, 0x6E, 0x80, 0x18, 0x82]):
		return _reject("The ROM `$804A->$8053->$8059->$805E->$8061` delay-tick bytes changed.")
	if is_f2_type5_event:
		return _execute_parameter47_f2_type5_event(boundary)
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	for offset in 3:
		_read_event(source_reads, 0x804A, 0x804A + offset,
			int(_sources[WORKER_FILE][0x804A + offset - _source_base(WORKER_FILE)]), "jsr_8053_byte")
	instruction_pcs.append(0x804A)
	_jsr(cpu, stack, stack_writes, 0x804A, 0x8053)
	for offset in 6:
		_read_event(source_reads, 0x8053, 0x8053 + offset,
			int(_sources[WORKER_FILE][0x8053 + offset - _source_base(WORKER_FILE)]), "worker_flag_branch_byte")
	instruction_pcs.append(0x8053)
	_set_a(cpu, int(ram[0x05E3]))
	_read_event(source_reads, 0x8053, 0x05E3, int(ram[0x05E3]), "worker_active_flag")
	instruction_pcs.append(0x8056)
	if int(cpu["a"]) == 0:
		return _unsupported("The F2 E9 countdown does not take the confirmed active-worker `$8056` branch.")
	cpu["pc"] = 0x8059
	for offset in 9:
		_read_event(source_reads, 0x8059, 0x8059 + offset,
			int(_sources[WORKER_FILE][0x8059 + offset - _source_base(WORKER_FILE)]), "delay_countdown_branch_byte")
	instruction_pcs.append(0x8059)
	_set_a(cpu, int(ram[0x05E9]))
	_read_event(source_reads, 0x8059, 0x05E9, int(ram[0x05E9]), "actor_animation_delay")
	instruction_pcs.append(0x805C)
	if int(cpu["a"]) == 0:
		return _unsupported("The F2 E9 countdown no longer takes the confirmed nonzero `$805C` branch.")
	cpu["pc"] = 0x805E
	instruction_pcs.append(0x805E)
	var next_delay := (int(ram[0x05E9]) - 1) & 0xFF
	_write_ram(ram, ram_writes, 0x05E9, next_delay, 0x805E)
	_set_nz(cpu, next_delay)
	instruction_pcs.append(0x8061)
	_rts(cpu, stack, stack_reads, 0x8061)
	if int(cpu["pc"]) != 0x804D or int(cpu["sp"]) != 0xCA \
			or int(cpu["a"]) != 0x01 or int(cpu["x"]) != 0x21 \
			or int(cpu["y"]) != 0x01 or int(ram[0x05E9]) != 0x00:
		return _unsupported("The ROM F2 E9 countdown failed its `$804D` RTS boundary invariant.")
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "slot11_actor_parameter47_f2_delay_tick_at_804d",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": {
			WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
			PARAMETER47_STREAM_FILE: "1c33322d68d5d662476619ddd88fd2cfd3df15d6112aa4d3ab4a110dea89ae8f",
		},
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"initial_mapper": mapper.duplicate(true),
		"mapper": mapper.duplicate(true),
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"exit_registers": cpu.duplicate(true),
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"source_timing_modeled": false,
	}


func execute_from_slot11_scenario2e_actor6d_type5_event_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x804A \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return _reject("Input is not the live scenario-$2E actor-$6D `$804A` type-5 event boundary.")
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or not ram_variant is PackedByteArray or ram_variant.size() != RAM_SIZE \
			or not stack_variant is PackedByteArray or stack_variant.size() != STACK_SIZE \
			or not mapper_variant is Dictionary:
		return _reject("The scenario-$2E type-5 event omitted its scheduler record, RAM, stack, or mapper snapshot.")
	var ram: PackedByteArray = ram_variant
	var stack: PackedByteArray = stack_variant
	var mapper: Dictionary = mapper_variant
	var mapper_registers_variant: Variant = mapper.get("bank_registers", {})
	if not mapper_registers_variant is Dictionary:
		return _reject("The scenario-$2E type-5 mapper snapshot omits MMC3 bank registers 6/7.")
	var mapper_registers: Dictionary = mapper_registers_variant
	if bool(boundary.get("trace_state_used", true)) \
			or bool(boundary.get("test_fixture", true)) \
			or int(ram[0x0000]) != SLOT_11 \
			or ram.slice(0x0516, 0x051D) != PackedByteArray([0x01, 0x00, 0x2E, 0x6C, 0xE8, 0x9B, 0x00]) \
			or int(ram[0x005F]) != 0xFE or int(ram[0x0060]) != 0x9B \
			or int(ram[0x05EA]) != 0x6D \
			or ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x6D]) \
			or ram.slice(0x05F3, 0x05F6) != PackedByteArray([0x00, 0x00, 0x01]) \
			or int(ram[0x0515]) != 0x00 \
			or ram.slice(0x0063, 0x0065) != PackedByteArray([0xBA, 0xA2]) \
			or ram.slice(0x04A5, 0x04A8) != PackedByteArray([0x20, 0xE0, 0x23]) \
			or int(boundary.get("a", -1)) != 0xFE \
			or int(boundary.get("x", -1)) != 0xFE \
			or int(boundary.get("y", -1)) != 0x00 \
			or stack.slice(0xC7, 0xCB) != PackedByteArray([0x00, 0xFE, 0x49, 0x80]) \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(mapper_registers.get(6, mapper_registers.get("6", -1))) != 0x18 \
			or int(mapper_registers.get(7, mapper_registers.get("7", -1))) != 0x19 \
			or int(mapper.get("select", -1)) not in [6, 7]:
		return _reject("The live scenario-$2E actor-$6D `$804A` event profile differs from frame 9488.")
	for stack_offset in STACK_SIZE:
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return _reject("The scenario-$2E `$804A` RAM and stack snapshots disagree at `$%02X`." % stack_offset)
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return _reject("The scenario-$2E `$804A` boundary omits valid CPU status and known-bit values.")
	if not _expect(WORKER_FILE, 0x804A, [0x20, 0x53, 0x80]) \
			or not _expect(WORKER_FILE, 0x8053, [0xAD, 0xE3, 0x05, 0xD0, 0x01, 0x60]) \
			or not _expect(WORKER_FILE, 0x8059, [0xAD, 0xE9, 0x05, 0xF0, 0x04, 0xCE, 0xE9, 0x05, 0x60]) \
			or not _expect(WORKER_FILE, 0x8062, [0xAD, 0xE4, 0x05, 0x20, 0x09, 0xC5, 0x6E, 0x80, 0x18, 0x82]) \
			or not _expect(PARAMETER6D_STREAM_FILE, 0x9BFF, [0x52]) \
			or not _expect(ACTOR_EVENT_TYPE5_LOOKUP_FILE, 0x86BD, [0x0E]) \
			or not _expect(ACTOR_EVENT_POINTER_TYPE5_FILE, 0x8DCC, [0xBF, 0x8F]) \
			or not _expect(ACTOR_EVENT_PAYLOAD_STREAM_TYPE5_FILE, 0x8FBF, [0x2C, 0x22, 0x14]):
		return _unsupported("The scenario-$2E actor-$6D type-5 event source bytes changed.")
	return _execute_actor_type5_event(boundary, true)


func _execute_parameter47_f2_type5_event(boundary: Dictionary) -> Dictionary:
	return _execute_actor_type5_event(boundary, false)


func _execute_actor_type5_event(boundary: Dictionary, scenario2e_actor6d: bool) -> Dictionary:
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var record: PackedByteArray = boundary["record"]
	var mapper: Dictionary = boundary["mapper"].duplicate(true)
	var stream_base := 0x9BFE if scenario2e_actor6d else 0x9917
	var expected_stream_index := 0x01 if scenario2e_actor6d else 0x02
	var event_address := 0x9BFF if scenario2e_actor6d else 0x9919
	var event_byte_expected := 0x52 if scenario2e_actor6d else 0x51
	if record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or int(cpu["pc"]) != 0x804A or int(cpu["sp"]) != 0xCA \
			or int(cpu["a"]) != (0xFE if scenario2e_actor6d else 0x21) \
			or int(cpu["x"]) != (0xFE if scenario2e_actor6d else 0x21) \
			or int(cpu["y"]) != (0x00 if scenario2e_actor6d else 0x01) \
			or (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) != stream_base \
			or int(ram[0x05EA]) != (0x6D if scenario2e_actor6d else 0x47) \
			or int(ram[0x05E3]) != 0x01 or int(ram[0x05E4]) != 0x01 \
			or int(ram[0x05E5]) != expected_stream_index or int(ram[0x05E6]) != 0x0E \
			or int(ram[0x05E7]) != 0x02 or int(ram[0x05E8]) != 0x02 \
			or int(ram[0x05E9]) != 0x00 \
			or int(ram[0x05F3]) != 0x00 or int(ram[0x05F4]) != 0x00 \
			or int(ram[0x05F5]) != 0x01 or int(ram[0x0515]) != 0x00 \
			or int(ram[0x0063]) != (0xBA if scenario2e_actor6d else 0xBC) or int(ram[0x0064]) != 0xA2 \
			or int(stack[0xC7]) != (0x00 if scenario2e_actor6d else 0x01) \
			or int(stack[0xC8]) != (0xFE if scenario2e_actor6d else 0x21) \
			or int(stack[0xC9]) != 0x49 or int(stack[0xCA]) != 0x80:
		return _unsupported("The type-5 event does not match its live `$804A` record, CPU, RAM, animation, or stack profile.")
	if not _expect(WORKER_FILE, 0x804A, [0x20, 0x53, 0x80]) \
			or not _expect(WORKER_FILE, 0x8053, [0xAD, 0xE3, 0x05, 0xD0, 0x01]) \
			or not _expect(WORKER_FILE, 0x8059, [0xAD, 0xE9, 0x05, 0xF0, 0x04]) \
			or not _expect(WORKER_FILE, 0x8062, [0xAD, 0xE4, 0x05, 0x20, 0x09, 0xC5, 0x6E, 0x80, 0x18, 0x82]) \
			or not _expect(ACTOR_EVENT_DISPATCH_FILE, 0x8218, [0xAC, 0xE5, 0x05, 0xB1, 0x5F, 0xC9, 0x90, 0xB0, 0x0D]) \
			or not _expect(PARAMETER6D_STREAM_FILE if scenario2e_actor6d else PARAMETER47_STREAM_FILE,
					event_address, [event_byte_expected]) \
			or not _expect(ACTOR_EVENT_TYPE5_LOOKUP_FILE, 0x86BD, [0x0E]) \
			or not _expect(ACTOR_EVENT_POINTER_TYPE5_FILE, 0x8DCC, [0xBF, 0x8F]) \
			or not _expect(ACTOR_EVENT_PAYLOAD_STREAM_TYPE5_FILE, 0x8FBF, [0x2C, 0x22, 0x14]):
		return _unsupported("The ROM type-5 event source bytes or its exact lookup/pointer/payload spans changed.")
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var callsite_registers: Dictionary = {}
	var callsite_stack := PackedByteArray()
	for offset in 3:
		_read_event(source_reads, 0x804A, 0x804A + offset,
			int(_sources[WORKER_FILE][0x804A + offset - _source_base(WORKER_FILE)]), "worker_jsr_8053_byte")
	instruction_pcs.append(0x804A)
	_jsr(cpu, stack, stack_writes, 0x804A, 0x8053)
	for offset in 5:
		_read_event(source_reads, 0x8053, 0x8053 + offset,
			int(_sources[WORKER_FILE][0x8053 + offset - _source_base(WORKER_FILE)]), "worker_active_branch_byte")
	instruction_pcs.append(0x8053)
	_set_a(cpu, int(ram[0x05E3]))
	_read_event(source_reads, 0x8053, 0x05E3, int(ram[0x05E3]), "worker_active_flag")
	instruction_pcs.append(0x8056)
	if int(cpu["a"]) != 0x01:
		return _unsupported("The F2 type-5 event leaves the active-worker branch at `$8056`.")
	cpu["pc"] = 0x8059
	for offset in 5:
		_read_event(source_reads, 0x8059, 0x8059 + offset,
			int(_sources[WORKER_FILE][0x8059 + offset - _source_base(WORKER_FILE)]), "worker_delay_branch_byte")
	instruction_pcs.append(0x8059)
	_set_a(cpu, int(ram[0x05E9]))
	_read_event(source_reads, 0x8059, 0x05E9, int(ram[0x05E9]), "actor_animation_delay")
	instruction_pcs.append(0x805C)
	if int(cpu["a"]) != 0:
		return _unsupported("The F2 type-5 event does not take the ROM's zero-delay `$805C->$8062` branch.")
	cpu["pc"] = 0x8062
	instruction_pcs.append(0x8062)
	_set_a(cpu, int(ram[0x05E4]))
	_read_event(source_reads, 0x8062, 0x05E4, int(ram[0x05E4]), "actor_stream_dispatch_index")
	if int(cpu["a"]) != 0x01:
		return _unsupported("The F2 type-5 event dispatch index is not the ROM-observed `$01` row.")
	instruction_pcs.append(0x8065)
	_jsr(cpu, stack, stack_writes, 0x8065, 0xC509)
	var event_handler := _inline_dispatch(cpu, ram, stack, ram_writes, stack_writes,
		stack_reads, source_reads, 0x8065, 0x8068, instruction_pcs)
	if event_handler != 0x8218:
		return _unsupported("The F2 dispatch index `$01` no longer resolves through `$8068` to `$8218`.")
	var stream_index := int(ram[0x05E5])
	_set_y(cpu, stream_index)
	_read_event(source_reads, 0x8218, 0x05E5, stream_index, "actor_event_stream_index")
	var stream_address := (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) + stream_index
	var event_byte := _read_stream_byte(stream_address)
	if stream_index != (0x01 if scenario2e_actor6d else 0x02) \
			or stream_address != event_address or event_byte != event_byte_expected:
		return _unsupported("The `$8218` type-5 event does not match its verified ROM stream byte.")
	_read_event(source_reads, 0x8218, stream_address, event_byte, "actor_event_byte")
	for offset in 9:
		_read_event(source_reads, 0x8218, 0x8218 + offset,
			int(_sources[ACTOR_EVENT_DISPATCH_FILE][offset]), "type5_event_dispatch_code_byte")
	_set_a(cpu, event_byte)
	instruction_pcs.append(0x8218)
	instruction_pcs.append(0x821B)
	instruction_pcs.append(0x821D)
	_compare_a(cpu, 0x90)
	instruction_pcs.append(0x821F)
	if (int(cpu["p"]) & P_C) != 0:
		return _unsupported("The F2 `$51` event unexpectedly branches to `$822E->$C52D`.")
	instruction_pcs.append(0x8221)
	_set_a(cpu, event_byte & 0x0F)
	_set_nz(cpu, int(cpu["a"]))
	instruction_pcs.append(0x8223)
	_write_ram(ram, ram_writes, 0x05F3, int(cpu["a"]), 0x8223)
	instruction_pcs.append(0x8226)
	_set_a(cpu, 0x80)
	instruction_pcs.append(0x8228)
	_write_ram(ram, ram_writes, 0x05F4, 0x80, 0x8228)
	instruction_pcs.append(0x8234)
	_read_event(source_reads, 0x8234, stream_address, event_byte, "actor_event_payload_command")
	_set_a(cpu, event_byte)
	var event_type := (int(cpu["a"]) >> 4) & 0x0F
	_set_x(cpu, event_type)
	var event_value := _read_actor_event_source_byte(0x86B8 + event_type)
	if event_type != 0x05 or event_value != 0x0E:
		return _unsupported("ROM type-5 lookup `$86BD` no longer resolves to `$0E`.")
	_read_event(source_reads, 0x823B, 0x86BD, event_value, "actor_event_type_value")
	_set_a(cpu, event_value)
	_write_ram(ram, ram_writes, 0x05E6, event_value, 0x823E)
	_set_a(cpu, event_type)
	_set_a(cpu, int(cpu["a"]) << 1)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0x8241, "PHA")
	_set_x(cpu, int(cpu["a"]))
	var pointer_address := 0x8DC2 + int(cpu["x"])
	var payload_low := _read_actor_event_source_byte(pointer_address)
	var payload_high := _read_actor_event_source_byte(pointer_address + 1)
	if pointer_address != 0x8DCC or payload_low != 0xBF or payload_high != 0x8F:
		return _unsupported("Type-5 pointer `$8DCC` no longer resolves to the ROM payload at `$8FBF`.")
	_read_event(source_reads, 0x8245, pointer_address, payload_low, "actor_event_payload_pointer_low")
	_write_ram(ram, ram_writes, 0x0061, payload_low, 0x8248)
	_read_event(source_reads, 0x824A, pointer_address + 1, payload_high, "actor_event_payload_pointer_high")
	_write_ram(ram, ram_writes, 0x0062, payload_high, 0x824D)
	var payload_address := (payload_high << 8) | payload_low
	var payload := PackedByteArray()
	var payload_source: PackedByteArray = _sources[ACTOR_EVENT_PAYLOAD_STREAM_TYPE5_FILE]
	for payload_index in 3:
		_set_y(cpu, payload_index)
		var payload_byte := _read_actor_event_source_byte(payload_address + payload_index)
		if payload_byte != int(payload_source[payload_index]):
			return _unsupported("The type-5 ROM payload at `$8FBF-$8FC1` differs from its manifest span.")
		_read_event(source_reads, 0x8251 + payload_index * 4, payload_address + payload_index,
			payload_byte, "actor_event_payload_byte_%d" % payload_index)
		_set_a(cpu, payload_byte)
		if payload_index < 2:
			_push(cpu, stack, stack_writes, payload_byte, 0x8251 + payload_index * 4, "PHA")
		else:
			_write_ram(ram, ram_writes, 0x05E7, payload_byte, 0x825B)
		payload.append(payload_byte)
	_set_y(cpu, 0x03)
	_set_a(cpu, 0x06)
	_write_ram(ram, ram_writes, 0x05E8, 0x06, 0x8261)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0x8266)
	cpu["pc"] = 0x8266
	callsite_registers = cpu.duplicate(true)
	callsite_stack = stack.duplicate()
	_jsr(cpu, stack, stack_writes, 0x8266, 0xC515)
	instruction_pcs.append(0xC515)
	var yield_jump_opcode := int(_sources[YIELD_TRAMPOLINE_FILE][0])
	if yield_jump_opcode != 0x4C:
		return _unsupported("The fixed task-yield trampoline no longer jumps from `$C515`.")
	_read_event(source_reads, 0xC515, 0xC515, yield_jump_opcode, "task_yield_dispatch_opcode")
	cpu["pc"] = 0xCB0F
	instruction_pcs.append(0xCB0F)
	var event_yield := _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
		cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
		source_reads, instruction_pcs, callsite_registers, callsite_stack,
		0x8266, 0x8269, "slot11_actor_event_payload_at_cb0f")
	event_yield["source_span_hashes"] = {
		WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
		ACTOR_EVENT_DISPATCH_FILE: "ad89d4999241da3618d8c3c06822986cb9f0ba561683e112c5ce71f2b5b05bfb",
		ACTOR_EVENT_TYPE5_LOOKUP_FILE: "4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47",
		ACTOR_EVENT_POINTER_TYPE5_FILE: "831f787fb2c566d6acca65c7faf4a2091bac4c6993daa80ce2d842277ac0c772",
		ACTOR_EVENT_PAYLOAD_STREAM_TYPE5_FILE: "48b367fb4e65f7bc3507a96b4b160e02407755e5810f81a51072a7693cee37dd",
		YIELD_TRAMPOLINE_FILE: "86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e",
	}
	if scenario2e_actor6d:
		event_yield["source_span_hashes"][PARAMETER6D_STREAM_FILE] = \
			"0b787ded174d6496196c978f5b835c4e89c9858a8499617b02bacc5b3f7b7d1e"
	else:
		event_yield["source_span_hashes"][PARAMETER47_STREAM_FILE] = \
			"1c33322d68d5d662476619ddd88fd2cfd3df15d6112aa4d3ab4a110dea89ae8f"
	event_yield["decoded_event"] = {
		"address": stream_address, "byte": event_byte, "type": event_type,
		"type_value": event_value, "dispatch_index": 0x01,
		"payload_address": payload_address, "payload": payload,
		"wait_counter": int(ram[0x05E8]),
	}
	return event_yield


## Executes the live nested wait resumed by the scheduler at `$CC53`. It follows
## the `$0515` branch and, when the queue is clear, builds one ROM-owned packet
## from the loop counter already present on the 6502 stack before yielding again
## at `$CC50`. The zero-counter tail beyond `$CC9E` remains out of scope.
func execute_from_slot11_waiter_resume_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_waiter_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 waiter boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {
		"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"]),
	}).duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var callsite_registers: Dictionary = {}
	var callsite_stack := PackedByteArray()

	# `$CC53 LDA $0515 / BNE $CC4E`: a pending packet repeats the exact
	# source yield without consuming the caller's stack-resident pass counter.
	instruction_pcs.append(0xCC53)
	var pending_queue := int(ram[0x0515])
	_read_event(source_reads, 0xCC53, 0x0515, pending_queue, "ppu_queue_pending_flag")
	_set_a(cpu, pending_queue)
	instruction_pcs.append(0xCC56)
	if pending_queue != 0:
		instruction_pcs.append(0xCC4E)
		_set_a(cpu, 0x01)
		instruction_pcs.append(0xCC50)
		cpu["pc"] = 0xCC50
		callsite_registers = cpu.duplicate(true)
		callsite_stack = stack.duplicate()
		_jsr(cpu, stack, stack_writes, 0xCC50, 0xCB0F)
		instruction_pcs.append(0xCB0F)
		return _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
			cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
			source_reads, instruction_pcs, callsite_registers, callsite_stack)

	# The cleared-queue branch sets the poll flag to one, then starts the packet
	# builder at `$CC5D`. The loop writes X into `$04A5,X` for Y=$4F..$01.
	instruction_pcs.append(0xCC58)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xCC5A)
	_write_ram(ram, ram_writes, 0x0515, 0x01, 0xCC5A)
	instruction_pcs.append(0xCC5D)
	_set_y(cpu, 0x4F)
	instruction_pcs.append(0xCC5F)
	_set_x(cpu, 0x00)
	while int(cpu["y"]) != 0:
		instruction_pcs.append(0xCC61)
		_set_a(cpu, int(cpu["x"]))
		instruction_pcs.append(0xCC62)
		_write_ram(ram, ram_writes, 0x04A5 + int(cpu["x"]), int(cpu["a"]), 0xCC62)
		instruction_pcs.append(0xCC65)
		_set_x(cpu, int(cpu["x"]) + 1)
		instruction_pcs.append(0xCC66)
		_set_y(cpu, int(cpu["y"]) - 1)
		instruction_pcs.append(0xCC67)
	_set_a(cpu, 0x18)
	instruction_pcs.append(0xCC69)
	_write_ram(ram, ram_writes, 0x04A5, 0x18, 0xCC6B)
	_write_ram(ram, ram_writes, 0x04C0, 0x18, 0xCC6E)
	_set_a(cpu, 0x20)
	_write_ram(ram, ram_writes, 0x04A6, 0x20, 0xCC73)
	_write_ram(ram, ram_writes, 0x04C1, 0x20, 0xCC76)

	# The ROM rotates the pass count into the packet header, then emits its
	# source-owned queue-ready flag before deciding whether to repeat.
	var pass_count := _pop(cpu, stack, stack_reads, 0xCC76)
	_push(cpu, stack, stack_writes, pass_count, 0xCC77, "PHA")
	_set_a(cpu, int(cpu["a"]) | 0x08)
	var carry := int(cpu["a"]) & 0x01
	_set_flag(cpu, P_C, carry != 0)
	_set_a(cpu, int(cpu["a"]) >> 1)
	var mem_value := int(ram[0x04A6])
	var rotated := ((0x80 if (int(cpu["p"]) & P_C) != 0 else 0) | (mem_value >> 1)) & 0xFF
	_set_flag(cpu, P_C, (mem_value & 0x01) != 0)
	_set_nz(cpu, rotated)
	_write_ram(ram, ram_writes, 0x04A6, rotated, 0xCC7B)
	carry = int(cpu["a"]) & 0x01
	_set_flag(cpu, P_C, carry != 0)
	_set_a(cpu, int(cpu["a"]) >> 1)
	mem_value = int(ram[0x04A6])
	rotated = ((0x80 if (int(cpu["p"]) & P_C) != 0 else 0) | (mem_value >> 1)) & 0xFF
	_set_flag(cpu, P_C, (mem_value & 0x01) != 0)
	_set_nz(cpu, rotated)
	_write_ram(ram, ram_writes, 0x04A6, rotated, 0xCC7F)
	_set_a(cpu, int(cpu["a"]) | 0x20)
	_write_ram(ram, ram_writes, 0x04A7, int(cpu["a"]), 0xCC84)
	_write_ram(ram, ram_writes, 0x04C2, int(cpu["a"]), 0xCC87)
	_read_event(source_reads, 0xCC8A, 0x04A6, int(ram[0x04A6]), "packet_address_high")
	_set_a(cpu, int(ram[0x04A6]))
	_set_flag(cpu, P_C, false)
	var adc_sum := int(cpu["a"]) + 0x20
	var adc_result := adc_sum & 0xFF
	_set_flag(cpu, P_C, adc_sum > 0xFF)
	_set_flag(cpu, P_V, ((~(int(cpu["a"]) ^ 0x20) & (int(cpu["a"]) ^ adc_result)) & 0x80) != 0)
	_set_a(cpu, adc_result)
	_write_ram(ram, ram_writes, 0x04C1, int(cpu["a"]), 0xCC90)
	_set_a(cpu, 0x80)
	_write_ram(ram, ram_writes, 0x0515, 0x80, 0xCC95)
	var decremented_count := _pop(cpu, stack, stack_reads, 0xCC98)
	_set_flag(cpu, P_C, true)
	var subtraction := decremented_count - 1
	_set_flag(cpu, P_C, subtraction >= 0)
	var result_count := subtraction & 0xFF
	_set_flag(cpu, P_V, (((decremented_count ^ result_count) & (decremented_count ^ 1) & 0x80) != 0))
	_set_a(cpu, result_count)
	instruction_pcs.append(0xCC9C)
	if (int(cpu["p"]) & P_N) != 0:
		# `$CC9E LDA #$01 / JSR $CB0F` waits for the pending `$0515` packet;
		# RTS returns to `$CCA3`, which polls the flag before building the final
		# `$23E0` packet.
		instruction_pcs.append(0xCC9E)
		_set_a(cpu, 0x01)
		instruction_pcs.append(0xCCA0)
		cpu["pc"] = 0xCCA0
		callsite_registers = cpu.duplicate(true)
		callsite_stack = stack.duplicate()
		_jsr(cpu, stack, stack_writes, 0xCCA0, 0xCB0F)
		instruction_pcs.append(0xCB0F)
		return _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
			cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
			source_reads, instruction_pcs, callsite_registers, callsite_stack,
			0xCCA0, 0xCCA3, "slot11_actor_waiter_tail_at_cb0f_from_cca0")
	# `$CC9C BPL $CC4D` retains the decremented counter and returns to the
	# wait/yield call. The next scheduler dispatch re-enters at `$CC53`.
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCC4D, "PHA")
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xCC4E)
	instruction_pcs.append(0xCC50)
	cpu["pc"] = 0xCC50
	callsite_registers = cpu.duplicate(true)
	callsite_stack = stack.duplicate()
	_jsr(cpu, stack, stack_writes, 0xCC50, 0xCB0F)
	instruction_pcs.append(0xCB0F)
	return _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
		cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
		source_reads, instruction_pcs, callsite_registers, callsite_stack)


## Resumes the counter-tail wait at `$CCA3`. A nonzero `$0515` returns to the
## same `$CCA0->$CB0F` wait; zero builds the final `$23E0` packet and yields at
## `$CCCE`. The following `$CCD1 RTS` remains a separate continuation.
func execute_from_slot11_waiter_tail_poll_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_waiter_tail_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 counter-tail boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {
		"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"]),
	}).duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0xCCA3, 0xCCA6]
	var callsite_registers: Dictionary = {}
	var callsite_stack := PackedByteArray()
	var ready_flag := int(ram[0x0515])
	_read_event(source_reads, 0xCCA3, 0x0515, ready_flag, "counter_tail_queue_flag")
	_set_a(cpu, ready_flag)
	if ready_flag != 0:
		# `$CCA6 BNE $CC9E`; yield again from `$CCA0` and resume at `$CCA3`.
		instruction_pcs.append(0xCC9E)
		_set_a(cpu, 0x01)
		instruction_pcs.append(0xCCA0)
		cpu["pc"] = 0xCCA0
		callsite_registers = cpu.duplicate(true)
		callsite_stack = stack.duplicate()
		_jsr(cpu, stack, stack_writes, 0xCCA0, 0xCB0F)
		instruction_pcs.append(0xCB0F)
		return _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
			cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
			source_reads, instruction_pcs, callsite_registers, callsite_stack,
			0xCCA0, 0xCCA3, "slot11_actor_waiter_tail_at_cb0f_from_cca0")

	# `$CCA8-$CCBB`: raise the one-byte poll flag and define the final packet at
	# `$04A5` as length `$20`, destination `$23E0`.
	instruction_pcs.append(0xCCA8)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xCCAA)
	_write_ram(ram, ram_writes, 0x0515, 0x01, 0xCCAA)
	instruction_pcs.append(0xCCAD)
	_set_a(cpu, 0x20)
	instruction_pcs.append(0xCCAF)
	_write_ram(ram, ram_writes, 0x04A5, 0x20, 0xCCAF)
	instruction_pcs.append(0xCCB2)
	_set_a(cpu, 0xE0)
	instruction_pcs.append(0xCCB4)
	_write_ram(ram, ram_writes, 0x04A6, 0xE0, 0xCCB4)
	instruction_pcs.append(0xCCB7)
	_set_a(cpu, 0x23)
	instruction_pcs.append(0xCCB9)
	_write_ram(ram, ram_writes, 0x04A7, 0x23, 0xCCB9)
	instruction_pcs.append(0xCCBC)
	_set_x(cpu, 0x00)
	while int(cpu["x"]) != 0x21:
		instruction_pcs.append(0xCCBE)
		_set_a(cpu, int(cpu["x"]))
		instruction_pcs.append(0xCCBF)
		_write_ram(ram, ram_writes, 0x04A8 + int(cpu["x"]), int(cpu["a"]), 0xCCBF)
		instruction_pcs.append(0xCCC2)
		_set_x(cpu, int(cpu["x"]) + 1)
		instruction_pcs.append(0xCCC3)
		var compare_result := (int(cpu["x"]) - 0x21) & 0xFF
		_set_flag(cpu, P_C, int(cpu["x"]) >= 0x21)
		_set_flag(cpu, P_Z, int(cpu["x"]) == 0x21)
		_set_flag(cpu, P_N, (compare_result & 0x80) != 0)
		instruction_pcs.append(0xCCC5)
	instruction_pcs.append(0xCCC7)
	_set_a(cpu, 0x80)
	instruction_pcs.append(0xCCC9)
	_write_ram(ram, ram_writes, 0x0515, 0x80, 0xCCC9)
	instruction_pcs.append(0xCCCC)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xCCCE)
	cpu["pc"] = 0xCCCE
	callsite_registers = cpu.duplicate(true)
	callsite_stack = stack.duplicate()
	_jsr(cpu, stack, stack_writes, 0xCCCE, 0xCB0F)
	instruction_pcs.append(0xCB0F)
	return _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
		cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
		source_reads, instruction_pcs, callsite_registers, callsite_stack,
		0xCCCE, 0xCCD1, "slot11_actor_waiter_final_packet_at_cb0f_from_ccce")


## Resumes the final `$CCD1 RTS`, executes the ROM's F5 post-wait handler, and
## returns to the live actor worker at `$804D`. The next `$C560` command dispatch
## remains a separate source transition.
func execute_from_slot11_final_packet_return_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_final_packet_return_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 final-packet return boundary.")))
	if bool(valid.get("parameter47_f2", false)):
		return _execute_parameter47_f2_final_packet_return(boundary)
	if bool(valid.get("scenario1c_parameter00_f2", false)):
		return _execute_scenario1c_parameter00_f2_final_packet_return(boundary)
	if bool(valid.get("scenario2e_actor6d_f2", false)):
		return _execute_scenario2e_actor6d_f4_delay_return(boundary)
	var scenario2e_actor6d_f2: bool = false
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {
		"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"]),
	}).duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []

	# `$CCD1 RTS` consumes the final `$CCCE JSR $CB0F` return word.
	instruction_pcs.append(0xCCD1)
	_rts(cpu, stack, stack_reads, 0xCCD1)
	if int(cpu["pc"]) != 0x8200 or int(cpu["sp"]) != 0xC6:
		return _unsupported("Final packet RTS did not resume the F5 handler at `$8200`.")

	# Hash-checked bank-$18 F5 tail: `$8200-$8217`.
	instruction_pcs.append(0x8200)
	_set_a(cpu, 0x0D)
	instruction_pcs.append(0x8202)
	_write_ram(ram, ram_writes, 0x05F3, 0x0D, 0x8202)
	instruction_pcs.append(0x8205)
	_set_a(cpu, 0x80)
	instruction_pcs.append(0x8207)
	_write_ram(ram, ram_writes, 0x05F4, 0x80, 0x8207)
	instruction_pcs.append(0x820A)
	var stream_index := int(ram[0x05E5])
	_read_event(source_reads, 0x820A, 0x05E5, stream_index, "F5_parameter_index")
	_set_y(cpu, stream_index)
	instruction_pcs.append(0x820D)
	var stream_pointer := int(ram[0x005F]) | (int(ram[0x0060]) << 8)
	_read_event(source_reads, 0x820D, 0x005F, int(ram[0x005F]), "actor_stream_pointer_low")
	_read_event(source_reads, 0x820D, 0x0060, int(ram[0x0060]), "actor_stream_pointer_high")
	var parameter_address := (stream_pointer + stream_index) & 0xFFFF
	var parameter := _read_stream_byte(parameter_address)
	if parameter < 0:
		return _unsupported("The F5 parameter read leaves the hash-checked actor-stream source span.")
	_read_event(source_reads, 0x820D, parameter_address, parameter, "F5_actor_stream_parameter")
	_set_a(cpu, parameter)
	instruction_pcs.append(0x820F)
	_write_ram(ram, ram_writes, 0x05E9, int(cpu["a"]), 0x820F)
	instruction_pcs.append(0x8212)
	var next_stream_index := (stream_index + 1) & 0xFF
	_write_ram(ram, ram_writes, 0x05E5, next_stream_index, 0x8212)
	_set_nz(cpu, next_stream_index)
	instruction_pcs.append(0x8215)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0x8215))
	instruction_pcs.append(0x8216)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0x8216))
	instruction_pcs.append(0x8217)
	_rts(cpu, stack, stack_reads, 0x8217)
	if int(cpu["pc"]) != 0x804D or int(cpu["sp"]) != 0xCA \
			or int(cpu["a"]) != 0x80 or int(cpu["x"]) != 0x21 \
			or int(cpu["y"]) != stream_index:
		return _unsupported("The F5 tail did not return through the live `$804D` actor-worker frame.")
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	var tail_source_hashes := {
		COUNTER_TAIL_FILE: "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0",
		F5_TAIL_FILE: "f99ead3dbc9481250bab0c306693651ab2ac705bd5feeb82ea3975167c3663a0",
		STREAM_FILE: "907c3653f2e64fa9d27a0a14a7dd38e404f0c1f05a97c0367be24e587f5ebadf",
	}
	if scenario2e_actor6d_f2:
		tail_source_hashes.erase(STREAM_FILE)
		tail_source_hashes[PARAMETER6D_STREAM_FILE] = \
				"0b787ded174d6496196c978f5b835c4e89c9858a8499617b02bacc5b3f7b7d1e"
	var result := {
		"ok": true,
		"status": "slot11_actor_scenario2e_actor6d_f2_f5_tail_returned_to_804d" \
				if scenario2e_actor6d_f2 else "slot11_actor_f5_tail_returned_to_804d",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": tail_source_hashes,
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"mapper": mapper,
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": [],
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"exit_registers": cpu.duplicate(true),
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}
	if scenario2e_actor6d_f2:
		result["actor_parameter_manifest"] = PARAMETER6D_MANIFEST_PATH
	return result


## Resumes actor-$6D's F2 task after its final packet. `$CCD1 RTS` returns to
## `$807D`, then the ROM parser follows F4 selectors `$01/$02` and reads the
## `$01` delay at `$9BFE`; it returns to `$804D` for the source animation gate.
func _execute_scenario2e_actor6d_f4_delay_return(boundary: Dictionary) -> Dictionary:
	var handler01_file := "bank18_actor_f4_selector01_handler_8106_810d.bin"
	var handler02_file := "bank18_actor_f4_selector02_handler_810e_811d.bin"
	var handler01_hash := "543554f20106c3af49e9db047fc997857dde066667f5360f28d4caa8a00d9d70"
	var handler02_hash := "290805dbb03488e93873e528ef0a3977e240f967c47de822b4879beed3a6e88c"
	var actor_manifest_file := FileAccess.open(PARAMETER6D_MANIFEST_PATH, FileAccess.READ)
	if actor_manifest_file == null:
		return _unsupported("Actor-$6D parser manifest is unavailable.")
	var manifest_variant: Variant = JSON.parse_string(actor_manifest_file.get_as_text())
	if not manifest_variant is Dictionary:
		return _unsupported("Actor-$6D parser manifest is malformed.")
	var actor_manifest: Dictionary = manifest_variant
	var source_rom: Dictionary = actor_manifest.get("source_rom", {})
	var spans_by_name: Dictionary = {}
	var actor_spans: Variant = actor_manifest.get("spans", [])
	if actor_spans is Array:
		for span_variant: Variant in actor_spans:
			if span_variant is Dictionary:
				spans_by_name[String(span_variant.get("name", ""))] = span_variant
	var handler_specs := {
		handler01_file: ["bank18_f4_selector01_handler_8106_810d", 0x8106, 8, handler01_hash,
			PackedByteArray([0xAE, 0xFB, 0x05, 0xF0, 0x02, 0xA2, 0x01, 0x60])],
		handler02_file: ["bank18_f4_selector02_handler_810e_811d", 0x810E, 16, handler02_hash,
			PackedByteArray([0xAE, 0x00, 0x06, 0xF0, 0x08, 0xCA, 0xE0, 0x03,
				0x90, 0x02, 0xA2, 0x02, 0x60, 0xA2, 0x03, 0x60])],
	}
	var handler_bytes: Dictionary = {}
	for file_variant: Variant in handler_specs:
		var file_name := String(file_variant)
		var spec: Array = handler_specs[file_name]
		var span: Dictionary = spans_by_name.get(String(spec[0]), {})
		var path := PARAMETER6D_ROOT + file_name
		var bytes := FileAccess.get_file_as_bytes(path)
		if String(actor_manifest.get("schema", "")) != "ct2-slot11-actor-parameter-6d-source-v1" \
				or String(source_rom.get("sha256", "")) != ROM_SHA256 \
				or String(span.get("file", "")) != file_name \
				or _manifest_hex(span.get("cpu_start", "0x0")) != int(spec[1]) \
				or int(span.get("length_bytes", -1)) != int(spec[2]) \
				or String(span.get("sha256", "")) != String(spec[3]) \
				or bytes != spec[4] or _sha256(bytes) != String(spec[3]):
			return _unsupported("Actor-$6D F4 handler failed ROM manifest/byte validation: %s." % file_name)
		handler_bytes[file_name] = bytes
	if not _expect(WORKER_FILE, 0x806E, [0xAC, 0xE5, 0x05, 0xEE, 0xE5, 0x05,
			0xB1, 0x5F, 0xC9, 0xF0, 0x90, 0x06]) \
			or not _expect(WORKER_FILE, 0x807D, [0x4C, 0x6E, 0x80]) \
			or not _expect(WORKER_FILE, 0x8080, [0x8D, 0xE9, 0x05, 0xEE, 0xE4, 0x05, 0x60]) \
			or not _expect(WORKER_FILE, 0x8087, [0x29, 0x0F, 0x20, 0x09, 0xC5]) \
			or not _expect(WORKER_FILE, 0x80CB, [0xAC, 0xE5, 0x05, 0xB1, 0x5F, 0x20, 0xEA, 0x80]) \
			or not _expect(WORKER_FILE, 0x80D3, [0x8A, 0x0A, 0x38, 0x6D, 0xE5, 0x05]) \
			or not _expect(PARAMETER6D_STREAM_FILE, 0x9BE3, [0xF2, 0xF4, 0x01, 0xEA, 0x9B, 0xF4, 0x9B, 0xF4, 0x02, 0xFE, 0x9B]) \
			or not _expect("inline_dispatch", 0xC509, [0x4C, 0x99, 0xCB]):
		return _unsupported("Actor-$6D F4 parser or selector source bytes differ from the verified ROM spans.")
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {}).duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0xCCD1]
	_rts(cpu, stack, stack_reads, 0xCCD1)
	if int(cpu["pc"]) != 0x807D or int(cpu["sp"]) != 0xC8:
		return _unsupported("Actor-$6D `$CCD1 RTS` did not resume the ROM parser at `$807D`.")
	var parsed_selectors: Array[int] = []
	while parsed_selectors.size() < 2:
		instruction_pcs.append(0x807D)
		_read_event(source_reads, 0x807D, 0x807D, 0x4C, "actor_parser_return_jump")
		cpu["pc"] = 0x806E
		instruction_pcs.append(0x806E)
		var stream_index := int(ram[0x05E5])
		_set_y(cpu, stream_index)
		_read_event(source_reads, 0x806E, 0x05E5, stream_index, "actor_stream_index")
		_write_ram(ram, ram_writes, 0x05E5, (stream_index + 1) & 0xFF, 0x8071)
		var stream_pointer := int(ram[0x005F]) | (int(ram[0x0060]) << 8)
		var stream_address := stream_pointer + int(cpu["y"])
		var stream_byte := _read_stream_byte(stream_address)
		if stream_byte < 0:
			return _unsupported("Actor-$6D stream parser left its hash-checked ROM span.")
		_read_event(source_reads, 0x8074, stream_address, stream_byte, "actor_stream_command")
		_set_a(cpu, stream_byte)
		_compare_a(cpu, 0xF0)
		if stream_byte != 0xF4:
			return _unsupported("Actor-$6D continuation expected one of the two observed ROM F4 commands.")
		instruction_pcs.append(0x807A)
		_jsr(cpu, stack, stack_writes, 0x807A, 0x8087)
		_set_a(cpu, int(cpu["a"]) & 0x0F)
		instruction_pcs.append(0x8089)
		_jsr(cpu, stack, stack_writes, 0x8089, 0xC509)
		var handler := _inline_dispatch(cpu, ram, stack, ram_writes, stack_writes,
			stack_reads, source_reads, 0x8089, 0x808C, instruction_pcs)
		if handler != 0x80CB:
			return _unsupported("ROM command `$F4` no longer resolves to the actor pointer-table handler.")
		instruction_pcs.append(0x80CB)
		var selector_index := int(ram[0x05E5])
		_set_y(cpu, selector_index)
		var selector_address := stream_pointer + selector_index
		var selector := _read_stream_byte(selector_address)
		if selector not in [0x01, 0x02]:
			return _unsupported("Actor-$6D continuation left the verified F4 selector `$01/$02` path.")
		_read_event(source_reads, 0x80CE, selector_address, selector, "F4_selector")
		parsed_selectors.append(selector)
		_set_a(cpu, selector)
		instruction_pcs.append(0x80D0)
		_jsr(cpu, stack, stack_writes, 0x80D0, 0x80EA)
		instruction_pcs.append(0x80EA)
		_jsr(cpu, stack, stack_writes, 0x80EA, 0xC509)
		var row_handler := _inline_dispatch(cpu, ram, stack, ram_writes, stack_writes,
			stack_reads, source_reads, 0x80EA, 0x80ED, instruction_pcs)
		var target_handler := 0x8106 if selector == 0x01 else 0x810E
		if row_handler != target_handler:
			return _unsupported("F4 selector `$%02X` resolved outside its ROM handler." % selector)
		instruction_pcs.append(target_handler)
		if selector == 0x01:
			_read_event(source_reads, 0x8106, 0x05FB, int(ram[0x05FB]), "F4_selector01_input")
			_set_x(cpu, int(ram[0x05FB]))
			if int(cpu["x"]) != 0:
				_set_x(cpu, 1)
		else:
			_read_event(source_reads, 0x810E, 0x0600, int(ram[0x0600]), "F4_selector02_input")
			var match_index := int(ram[0x0600])
			_set_x(cpu, match_index)
			if match_index == 0:
				_set_x(cpu, 3)
			else:
				var adjusted_index := (match_index - 1) & 0xFF
				_set_x(cpu, adjusted_index)
				_set_flag(cpu, P_C, adjusted_index >= 3)
				_set_flag(cpu, P_Z, adjusted_index == 3)
				_set_flag(cpu, P_N, (adjusted_index & 0x80) != 0)
				if adjusted_index >= 3:
					_set_x(cpu, 2)
		_rts(cpu, stack, stack_reads, target_handler)
		if int(cpu["pc"]) != 0x80D3:
			return _unsupported("ROM F4 selector handler did not return to its pointer calculation.")
		instruction_pcs.append(0x80D3)
		var row := int(cpu["x"])
		_set_a(cpu, row)
		var doubled_row := (row << 1) & 0xFF
		_set_flag(cpu, P_C, (row & 0x80) != 0)
		_set_a(cpu, doubled_row)
		instruction_pcs.append(0x80D5)
		_set_flag(cpu, P_C, true)
		var pointer_index := int(ram[0x05E5])
		_read_event(source_reads, 0x80D6, 0x05E5, pointer_index, "F4_pointer_row_index")
		var adc_sum := int(cpu["a"]) + pointer_index + 1
		var pointer_offset := adc_sum & 0xFF
		_set_flag(cpu, P_C, adc_sum > 0xFF)
		_set_flag(cpu, P_V, ((~(int(cpu["a"]) ^ pointer_index) & (int(cpu["a"]) ^ adc_sum)) & 0x80) != 0)
		_set_a(cpu, pointer_offset)
		_set_y(cpu, pointer_offset)
		var low_address := stream_pointer + pointer_offset
		var pointer_low := _read_stream_byte(low_address)
		var pointer_high := _read_stream_byte(low_address + 1)
		if pointer_low < 0 or pointer_high < 0:
			return _unsupported("Actor-$6D F4 pointer row left the verified stream span.")
		var resolved_target := pointer_low | (pointer_high << 8)
		var expected_target := 0x9BEA if selector == 0x01 and int(ram[0x05FB]) == 0 \
			else 0x9BF4 if selector == 0x01 else 0x9BFE if int(ram[0x0600]) == 0x01 \
			else -1
		if resolved_target != expected_target:
			return _unsupported("F4 selector `$%02X` pointer row resolved to unsupported `$%04X`." % [selector, resolved_target])
		_read_event(source_reads, 0x80DA, low_address, pointer_low, "F4_target_pointer_low")
		_read_event(source_reads, 0x80DE, low_address + 1, pointer_high, "F4_target_pointer_high")
		_set_x(cpu, pointer_low)
		_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
		_set_a(cpu, pointer_high)
		_write_ram(ram, ram_writes, 0x005F, int(cpu["x"]), 0x80E0)
		_write_ram(ram, ram_writes, 0x0060, int(cpu["a"]), 0x80E2)
		_set_a(cpu, 0)
		_write_ram(ram, ram_writes, 0x05E5, 0, 0x80E6)
		_rts(cpu, stack, stack_reads, 0x80E9)
		if int(cpu["pc"]) != 0x807D:
			return _unsupported("ROM F4 pointer handler did not return to `$807D`.")
	var delay_pointer := int(ram[0x005F]) | (int(ram[0x0060]) << 8)
	if parsed_selectors != [0x01, 0x02] or delay_pointer != 0x9BFE:
		return _unsupported("Actor-$6D F4 selectors did not resolve the observed delay stream at `$9BFE`.")
	instruction_pcs.append(0x807D)
	cpu["pc"] = 0x806E
	instruction_pcs.append(0x806E)
	var delay_index := int(ram[0x05E5])
	_set_y(cpu, delay_index)
	_read_event(source_reads, 0x806E, 0x05E5, delay_index, "actor_stream_index")
	_write_ram(ram, ram_writes, 0x05E5, (delay_index + 1) & 0xFF, 0x8071)
	var delay_byte := _read_stream_byte(delay_pointer + delay_index)
	if delay_byte != 0x01:
		return _unsupported("Actor-$6D F4 selector `$02` did not reach the ROM `$01` delay byte.")
	_read_event(source_reads, 0x8074, delay_pointer + delay_index, delay_byte, "actor_stream_delay")
	_set_a(cpu, delay_byte)
	_compare_a(cpu, 0xF0)
	instruction_pcs.append(0x8080)
	_write_ram(ram, ram_writes, 0x05E9, int(cpu["a"]), 0x8080)
	var next_command_index := (int(ram[0x05E4]) + 1) & 0xFF
	_write_ram(ram, ram_writes, 0x05E4, next_command_index, 0x8083)
	_set_nz(cpu, next_command_index)
	_rts(cpu, stack, stack_reads, 0x8086)
	if int(cpu["pc"]) != 0x804D or int(cpu["sp"]) != 0xCA \
			or int(cpu["a"]) != 0x01 or int(cpu["x"]) != 0xFE \
			or int(cpu["y"]) != 0x00 \
			or ram.slice(0x05E3, 0x05EB) != PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x01, 0x6D]):
		return _unsupported("Actor-$6D `$01` delay did not return to `$804D` with the observed ROM parser state.")
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "slot11_actor_scenario2e_actor6d_f2_parser_delay_returned_to_804d",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"actor_parameter_manifest": PARAMETER6D_MANIFEST_PATH,
		"actor_parameter": 0x6D,
		"source_span_hashes": {
			WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
			PARAMETER6D_POINTER_FILE: "0aebdd98608aa88311ca8ab9bedd486c26160ed4a842df5297fd8572eb568bf4",
			PARAMETER6D_STREAM_FILE: "0b787ded174d6496196c978f5b835c4e89c9858a8499617b02bacc5b3f7b7d1e",
			handler01_file: handler01_hash,
			handler02_file: handler02_hash,
			"inline_dispatch": INLINE_DISPATCH_SHA256,
		},
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]), "exit_pc": int(cpu["pc"]),
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu, "entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack, "mapper": mapper,
		"ram_image": output_ram, "stack_page": stack,
		"ram_writes": ram_writes, "stack_writes": stack_writes,
		"stack_reads": stack_reads, "source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"exit_registers": cpu.duplicate(true),
		"ppu_bus_events": [], "apu_register_writes": [],
		"trace_state_used": false, "ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}


## Follows the scenario-$1C parameter-$00 `$F0` terminator after the final
## `$23E0` packet. Unlike parameter-$47 F2, this clears the actor-active flag.
func _execute_scenario1c_parameter00_f2_final_packet_return(boundary: Dictionary) -> Dictionary:
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {
		"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"]),
	}).duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0xCCD1]

	_rts(cpu, stack, stack_reads, 0xCCD1)
	if int(cpu["pc"]) != 0x807D or int(cpu["sp"]) != 0xC8:
		return _unsupported("Scenario-$1C F2 final-packet RTS did not restore its `$807D` parser continuation.")
	if not _expect(WORKER_FILE, 0x807D, [0x4C, 0x6E, 0x80]) \
			or not _expect(PARAMETER00_STREAM_FILE, 0x9400, [0xF2, 0xF0]) \
			or not _expect(WORKER_FILE, 0x8098, [0xA9, 0x00, 0x8D, 0xE3, 0x05, 0x68, 0x68, 0x60]):
		return _unsupported("The scenario-$1C `$807D` jump, `$9401=$F0`, or `$8098` terminator bytes failed their ROM checks.")
	instruction_pcs.append(0x807D)
	for offset in range(3):
		_read_event(source_reads, 0x807D, 0x807D + offset,
			[0x4C, 0x6E, 0x80][offset], "actor_stream_parser_jump_byte")
	cpu["pc"] = 0x806E
	instruction_pcs.append(0x806E)
	var stream_index := int(ram[0x05E5])
	_set_y(cpu, stream_index)
	_read_event(source_reads, 0x806E, 0x05E5, stream_index, "actor_stream_index")
	if stream_index != 0x01:
		return _unsupported("The scenario-$1C F2 tail did not resume at stream index `$01`.")
	var next_stream_index := (stream_index + 1) & 0xFF
	_write_ram(ram, ram_writes, 0x05E5, next_stream_index, 0x8071)
	instruction_pcs.append(0x8071)
	instruction_pcs.append(0x8074)
	_read_event(source_reads, 0x8074, 0x005F, int(ram[0x005F]), "actor_stream_pointer_low")
	_read_event(source_reads, 0x8074, 0x0060, int(ram[0x0060]), "actor_stream_pointer_high")
	var stream_address := (int(ram[0x0060]) << 8 | int(ram[0x005F])) + stream_index
	var stream_byte := _read_stream_byte(stream_address)
	if stream_address != 0x9401 or stream_byte != 0xF0:
		return _unsupported("The live scenario-$1C stream did not read its ROM `$9401=$F0` terminator.")
	_read_event(source_reads, 0x8074, stream_address, stream_byte, "actor_stream_terminator")
	_set_a(cpu, stream_byte)
	instruction_pcs.append(0x8076)
	_compare_a(cpu, 0xF0)
	if (int(cpu["p"]) & P_C) == 0:
		return _unsupported("The scenario-$1C `$F0` comparison did not take the ROM terminal branch.")
	instruction_pcs.append(0x8078)
	instruction_pcs.append(0x807A)
	_jsr(cpu, stack, stack_writes, 0x807A, 0x8087)
	instruction_pcs.append(0x8087)
	_set_a(cpu, stream_byte & 0x0F)
	instruction_pcs.append(0x8089)
	_jsr(cpu, stack, stack_writes, 0x8089, 0xC509)
	var terminal_handler := _inline_dispatch(cpu, ram, stack, ram_writes,
		stack_writes, stack_reads, source_reads, 0x8089, 0x808C, instruction_pcs)
	if terminal_handler != 0x8098:
		return _unsupported("Scenario-$1C `$F0` no longer resolves through ROM dispatch to `$8098`.")
	var terminator_bytes: PackedByteArray = _sources[WORKER_FILE].slice(
		0x8098 - 0x804A, 0x80A0 - 0x804A)
	if terminator_bytes != PackedByteArray([0xA9, 0x00, 0x8D, 0xE3, 0x05, 0x68, 0x68, 0x60]):
		return _unsupported("The ROM `$8098` actor-stream terminator bytes changed.")
	for index in terminator_bytes.size():
		_read_event(source_reads, 0x8098 + index, 0x8098 + index,
			int(terminator_bytes[index]), "actor_stream_terminator_handler_byte")
	instruction_pcs.append(0x8098)
	_set_a(cpu, 0x00)
	instruction_pcs.append(0x809A)
	_write_ram(ram, ram_writes, 0x05E3, 0x00, 0x809A)
	instruction_pcs.append(0x809D)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0x809D))
	_set_nz(cpu, int(cpu["a"]))
	instruction_pcs.append(0x809E)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0x809E))
	_set_nz(cpu, int(cpu["a"]))
	instruction_pcs.append(0x809F)
	_rts(cpu, stack, stack_reads, 0x809F)
	if int(cpu["pc"]) != 0x804D or int(cpu["sp"]) != 0xCA \
			or int(cpu["a"]) != 0x80 or int(cpu["y"]) != 0x02 \
			or int(ram[0x05E3]) != 0x00 or int(ram[0x05E5]) != 0x02:
		return _unsupported("Scenario-$1C `$F0` did not clear the actor and return to `$804D` with the observed registers.")
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "slot11_actor_scenario1c_parameter00_f2_terminal_returned_to_804d",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": {
			WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
			PARAMETER00_STREAM_FILE: "fe770f516cf9f97533711e76a9477f63a7477d5152ba22ab0d81fa93a95c1600",
			COUNTER_TAIL_FILE: "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0",
			"inline_dispatch": INLINE_DISPATCH_SHA256,
			"trampoline": TRAMPOLINE_SHA256,
		},
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"mapper": mapper,
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"exit_registers": cpu.duplicate(true),
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}


## The parameter-$47 F2 waiter returns directly into the actor-stream parser.
## Its final packet's `$CCD1 RTS` restores `$807D`, then the ROM's `$807D JMP`
## re-enters `$806E`; the next `$01` stream byte is the worker delay command.
func _execute_parameter47_f2_final_packet_return(boundary: Dictionary) -> Dictionary:
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {
		"bank_low": int(boundary["bank_low"]), "bank_high": int(boundary["bank_high"]),
	}).duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = [0xCCD1]

	_rts(cpu, stack, stack_reads, 0xCCD1)
	if int(cpu["pc"]) != 0x807D or int(cpu["sp"]) != 0xC8:
		return _unsupported("The parameter-$47 F2 return did not restore its `$807D` parser continuation.")
	if not _expect(WORKER_FILE, 0x807D, [0x4C, 0x6E, 0x80]) \
			or not _expect(PARAMETER47_STREAM_FILE, 0x9917,
				[0xF2, 0x01, 0x51, 0xE4, 0xFC, 0x04, 0xE2, 0x20, 0xFC, 0xF0]):
		return _unsupported("The F2 `$807D` parser jump or `$9917` continuation bytes changed.")
	instruction_pcs.append(0x807D)
	_read_event(source_reads, 0x807D, 0x807D, 0x4C, "actor_stream_parser_jmp_opcode")
	_read_event(source_reads, 0x807D, 0x807E, 0x6E, "actor_stream_parser_jmp_low")
	_read_event(source_reads, 0x807D, 0x807F, 0x80, "actor_stream_parser_jmp_high")
	cpu["pc"] = 0x806E
	instruction_pcs.append(0x806E)
	var stream_index := int(ram[0x05E5])
	_set_y(cpu, stream_index)
	_read_event(source_reads, 0x806E, 0x05E5, stream_index, "actor_stream_index")
	instruction_pcs.append(0x8071)
	var next_stream_index := (stream_index + 1) & 0xFF
	_write_ram(ram, ram_writes, 0x05E5, next_stream_index, 0x8071)
	_set_nz(cpu, next_stream_index)
	instruction_pcs.append(0x8074)
	_read_event(source_reads, 0x8074, 0x005F, int(ram[0x005F]), "actor_stream_pointer_low")
	_read_event(source_reads, 0x8074, 0x0060, int(ram[0x0060]), "actor_stream_pointer_high")
	var stream_address := ((int(ram[0x0060]) << 8) | int(ram[0x005F])) + stream_index
	var stream_byte := _read_stream_byte(stream_address)
	if stream_byte != 0x01:
		return _unsupported("The F2 post-packet actor stream no longer reads its verified `$01` delay byte.")
	_read_event(source_reads, 0x8074, stream_address, stream_byte, "actor_stream_followup_delay")
	_set_a(cpu, stream_byte)
	instruction_pcs.append(0x8076)
	_compare_a(cpu, 0xF0)
	instruction_pcs.append(0x8078)
	if (int(cpu["p"]) & P_C) != 0:
		return _unsupported("The F2 `$01` continuation unexpectedly enters the ROM command-dispatch branch.")
	instruction_pcs.append(0x8080)
	_write_ram(ram, ram_writes, 0x05E9, int(cpu["a"]), 0x8080)
	instruction_pcs.append(0x8083)
	var next_dispatch_index := (int(ram[0x05E4]) + 1) & 0xFF
	_write_ram(ram, ram_writes, 0x05E4, next_dispatch_index, 0x8083)
	_set_nz(cpu, next_dispatch_index)
	instruction_pcs.append(0x8086)
	_rts(cpu, stack, stack_reads, 0x8086)
	if int(cpu["pc"]) != 0x804D or int(cpu["sp"]) != 0xCA \
			or int(cpu["a"]) != 0x01 or int(cpu["x"]) != 0x21 \
			or int(cpu["y"]) != 0x01:
		return _unsupported("The source `$01` delay command did not return to the live `$804D` actor loop.")
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "slot11_actor_parameter47_f2_delay_returned_to_804d",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": {
			WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
			PARAMETER47_STREAM_FILE: "1c33322d68d5d662476619ddd88fd2cfd3df15d6112aa4d3ab4a110dea89ae8f",
			COUNTER_TAIL_FILE: "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0",
		},
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"mapper": mapper,
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": [],
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"exit_registers": cpu.duplicate(true),
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}


## Executes the next source step after the F5 tail: `$804D->$C560->$CF72`,
## maps banks `$1A/$1B`, resolves the live `$05F3` animation row, and returns
## the pre-pushed `$A217->$C515->$CB0F` yield contract.
func execute_from_slot11_f5_animation_gate_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_f5_animation_gate_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 F5 animation gate boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}

	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {}).duplicate(true)
	var initial_mapper := mapper.duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []

	# Worker `$804D JSR $C560`; the fixed-bank vector jumps to `$CF72`.
	instruction_pcs.append(0x804D)
	_jsr(cpu, stack, stack_writes, 0x804D, 0xC560)
	_read_event(source_reads, 0xC560, 0xC560, int(_sources[C560_STUB_FILE][0]), "fixed_call_stub_opcode")
	cpu["pc"] = 0xCF72
	# `$CF72` saves A, writes the pair to `$24/$25`, and calls `$CE2D`.
	instruction_pcs.append(0xCF72)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCF72, "PHA")
	instruction_pcs.append(0xCF73)
	_set_a(cpu, int(ram[0x0022]))
	_read_event(source_reads, 0xCF73, 0x0022, int(ram[0x0022]), "mapper_shadow")
	instruction_pcs.append(0xCF75)
	_set_a(cpu, 0x1A)
	instruction_pcs.append(0xCF77)
	_write_ram(ram, ram_writes, 0x0024, 0x1A, 0xCF77)
	instruction_pcs.append(0xCF79)
	_set_a(cpu, 0x1B)
	instruction_pcs.append(0xCF7B)
	_write_ram(ram, ram_writes, 0x0025, 0x1B, 0xCF7B)
	instruction_pcs.append(0xCF7D)
	_jsr(cpu, stack, stack_writes, 0xCF7D, 0xCE2D)
	var mapper_helper: PackedByteArray = _sources["mapper_helper"]
	if mapper_helper.size() != 29:
		return _unsupported("The shared `$CE2D` mapper helper span is unavailable.")
	var helper_offsets := [0, 2, 3, 6, 9, 11, 13, 14, 15, 17, 18, 21, 23, 24, 27, 28]
	for offset in helper_offsets:
		instruction_pcs.append(0xCE2D + offset)
	var selector_low := int(ram[0x0022]) | 0x06
	_write_ram(ram, ram_writes, 0x0023, selector_low, 0xCE31)
	_set_mapper_pair_register(mapper, mapper_writes, selector_low, 6, 0xCE33, true)
	_read_event(source_reads, 0xCE36, 0x0024, int(ram[0x0024]), "mapper_bank_6_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0024]), 6, 0xCE38)
	var selector_high := int(ram[0x0022]) | 0x07
	_write_ram(ram, ram_writes, 0x0023, selector_high, 0xCE3F)
	_set_mapper_pair_register(mapper, mapper_writes, selector_high, 7, 0xCE41, true)
	_read_event(source_reads, 0xCE44, 0x0025, int(ram[0x0025]), "mapper_bank_7_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0025]), 7, 0xCE46)
	if int(mapper.get("bank_low", -1)) != 0x1A or int(mapper.get("bank_high", -1)) != 0x1B \
			or int(mapper.get("select", -1)) != 7:
		return _unsupported("The ROM `$CE2D` mapper helper did not select the `$1A/$1B` pair.")
	_rts(cpu, stack, stack_reads, 0xCE49)
	if int(cpu["pc"]) != 0xCF80:
		return _unsupported("The mapper-helper RTS did not return to `$CF80`.")
	instruction_pcs.append(0xCF80)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0xCF80))
	instruction_pcs.append(0xCF81)
	_jsr(cpu, stack, stack_writes, 0xCF81, 0x802A)
	if int(mapper.get("bank_low", -1)) != 0x1A or int(mapper.get("bank_high", -1)) != 0x1B:
		return _unsupported("The bank-$1A `$802A` entry is not mapped at its source call.")
	instruction_pcs.append(0x802A)
	cpu["pc"] = 0xA1EB

	# Bank-$1B `$A1EB` reads its stream pointer from `$A292 + 2 * $05F3`.
	instruction_pcs.append(0xA1EB)
	_set_a(cpu, int(ram[0x05F4]))
	_read_event(source_reads, 0xA1EB, 0x05F4, int(ram[0x05F4]), "animation_gate_mode")
	if int(cpu["a"]) == 0:
		if bool(valid.get("parameter47_f2_delay", false)) \
				or bool(valid.get("scenario2e_actor6d_f4_delay", false)) \
				or bool(valid.get("scenario1c_f0_zero_mode", false)):
			instruction_pcs.append(0xA1EE)
			instruction_pcs.append(0xA1F0)
			_rts(cpu, stack, stack_reads, 0xA1F0)
			if int(cpu["pc"]) != 0xCF84:
				return _unsupported("The F2 zero-mode animation gate did not return to the ROM mapper-restoration tail.")
			instruction_pcs.append(0xCF84)
			_set_a(cpu, 0x18)
			instruction_pcs.append(0xCF86)
			_write_ram(ram, ram_writes, 0x0024, 0x18, 0xCF86)
			instruction_pcs.append(0xCF88)
			_set_a(cpu, 0x19)
			instruction_pcs.append(0xCF8A)
			_write_ram(ram, ram_writes, 0x0025, 0x19, 0xCF8A)
			if not _expect(CF72_WRAPPER_FILE, 0xCF84, [0xA9, 0x18, 0x85, 0x24, 0xA9, 0x19, 0x85, 0x25]):
				return _unsupported("The ROM bank-restore instructions after the F2 zero-mode gate changed.")
			_apply_animation_mapper_helper(ram, mapper, ram_writes, mapper_writes,
				source_reads, instruction_pcs)
			_rts(cpu, stack, stack_reads, 0xCE49)
			if int(cpu["pc"]) != 0x8050 or int(cpu["sp"]) != 0xCA \
					or int(mapper.get("bank_low", -1)) != 0x18 \
					or int(mapper.get("bank_high", -1)) != 0x19:
				return _unsupported("The F2 zero-mode wrapper did not restore `$18/$19` and return to `$8050`.")
			instruction_pcs.append(0x8050)
			cpu["pc"] = 0x8045
			instruction_pcs.append(0x8045)
			_set_a(cpu, 0x01)
			cpu["pc"] = 0x8047
			instruction_pcs.append(0x8047)
			var f2_callsite_registers := cpu.duplicate(true)
			var f2_callsite_stack := stack.duplicate()
			var f2_output_ram := ram.duplicate()
			for stack_offset in STACK_SIZE:
				f2_output_ram[0x0100 + stack_offset] = stack[stack_offset]
			var is_scenario1c_f0_zero_mode := bool(valid.get("scenario1c_f0_zero_mode", false))
			var is_scenario2e_actor6d_f4_delay := bool(valid.get("scenario2e_actor6d_f4_delay", false))
			var zero_mode_status := "slot11_actor_scenario1c_f0_zero_mode_gate_at_8047" \
					if is_scenario1c_f0_zero_mode else "slot11_actor_scenario2e_actor6d_f4_delay_gate_at_8047" \
					if is_scenario2e_actor6d_f4_delay else "slot11_actor_parameter47_f2_delay_gate_at_8047"
			return {
				"ok": true,
				"status": zero_mode_status,
				"rom_sha256": ROM_SHA256,
				"source_manifest": MANIFEST_PATH,
				"source_span_hashes": {
					WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
					C560_STUB_FILE: "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc",
					CF72_WRAPPER_FILE: "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13",
					BANK1A_ENTRY_FILE: "d8ec35aefd2671a7a810a2fa342db297bfb35011862ec3b907aa09fced64da90",
					ANIMATION_GATE_FILE: "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618",
					"fixed_mapper_helper_CE2D_CE49.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
				},
				"slot_base": SLOT_11,
				"entry_pc": int(entry_cpu["pc"]), "exit_pc": int(cpu["pc"]),
				"yield_callsite_pc": 0x8047, "yield_target_pc": 0xCB0F,
				"resume_pc_after_rts": 0x804A,
				"entry_record": PackedByteArray(boundary["record"]),
				"entry_registers": entry_cpu, "entry_ram_image": entry_ram,
				"entry_stack_page": entry_stack,
				"yield_callsite_registers": f2_callsite_registers,
				"yield_callsite_stack_page": f2_callsite_stack,
				"call_frame_already_pushed": false,
				"mapper": mapper, "initial_mapper": initial_mapper,
				"ram_image": f2_output_ram, "stack_page": stack,
				"ram_writes": ram_writes, "stack_writes": stack_writes,
				"stack_reads": stack_reads, "mapper_writes": mapper_writes,
				"source_reads": source_reads, "instruction_pcs": instruction_pcs,
				"ppu_bus_events": [], "apu_register_writes": [],
				"trace_state_used": false, "ppu_apu_effects_applied": false,
				"source_timing_modeled": false,
			}
		return _unsupported("The live `$05F4` actor-animation mode takes the unimplemented early RTS path.")
	instruction_pcs.append(0xA1EE)
	if (int(cpu["p"]) & P_N) != 0:
		# `$A1F1 BPL $A20C` is not taken for `$80`; execution falls into setup.
		instruction_pcs.append(0xA1F1)
	else:
		return _unsupported("The live `$05F4` mode takes `$A1F1 BPL $A20C`, outside the F5 setup branch.")
	instruction_pcs.append(0xA1F3)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xA1F5)
	_write_ram(ram, ram_writes, 0x05F4, 0x01, 0xA1F5)
	instruction_pcs.append(0xA1F8)
	_set_a(cpu, int(ram[0x05F3]))
	_read_event(source_reads, 0xA1F8, 0x05F3, int(ram[0x05F3]), "animation_index")
	var animation_index := int(cpu["a"])
	var animation_index_table: PackedByteArray = _sources[ANIMATION_INDEX_TABLE_FILE]
	if animation_index < 0 or animation_index >= animation_index_table.size() / 2:
		return _unsupported("The live animation index is outside the fourteen ROM pointer rows.")
	instruction_pcs.append(0xA1FB)
	var doubled_animation_index := (int(cpu["a"]) << 1) & 0xFF
	_set_flag(cpu, P_C, (int(cpu["a"]) & 0x80) != 0)
	_set_a(cpu, doubled_animation_index)
	instruction_pcs.append(0xA1FC)
	_set_x(cpu, int(cpu["a"]))
	instruction_pcs.append(0xA1FD)
	var pointer_table_address := 0xA292 + doubled_animation_index
	var pointer_low := int(animation_index_table[doubled_animation_index])
	var pointer_high := int(animation_index_table[doubled_animation_index + 1])
	_read_event(source_reads, 0xA1FD, pointer_table_address, pointer_low, "animation_pointer_low")
	_set_a(cpu, pointer_low)
	instruction_pcs.append(0xA200)
	_write_ram(ram, ram_writes, 0x0063, pointer_low, 0xA200)
	instruction_pcs.append(0xA202)
	_read_event(source_reads, 0xA202, pointer_table_address + 1, pointer_high, "animation_pointer_high")
	_set_a(cpu, pointer_high)
	instruction_pcs.append(0xA205)
	_write_ram(ram, ram_writes, 0x0064, pointer_high, 0xA205)
	instruction_pcs.append(0xA207)
	_set_a(cpu, 0x00)
	instruction_pcs.append(0xA209)
	_write_ram(ram, ram_writes, 0x05F5, 0x00, 0xA209)
	instruction_pcs.append(0xA20C)
	_set_a(cpu, int(ram[0x05F5]))
	_read_event(source_reads, 0xA20C, 0x05F5, int(ram[0x05F5]), "animation_wait_counter")
	if int(cpu["a"]) != 0:
		return _unsupported("The first `$A20F BEQ $A215` animation-wait branch is not taken.")
	instruction_pcs.append(0xA20F)
	instruction_pcs.append(0xA215)
	_set_a(cpu, 0x01)
	cpu["pc"] = 0xA217
	instruction_pcs.append(0xA217)
	var callsite_registers := cpu.duplicate(true)
	var callsite_stack := stack.duplicate()
	_jsr(cpu, stack, stack_writes, 0xA217, 0xC515)
	instruction_pcs.append(0xC515)
	_read_event(source_reads, 0xC515, 0xC515, 0x4C, "task_yield_dispatch_opcode")
	cpu["pc"] = 0xCB0F # `$C515 JMP $CB0F`.
	instruction_pcs.append(0xCB0F)
	var cb0f_registers := cpu.duplicate(true)
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "slot11_f5_animation_gate_at_cb0f_from_a217",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": {
			C560_STUB_FILE: "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc",
			CF72_WRAPPER_FILE: "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13",
			BANK1A_ENTRY_FILE: "d8ec35aefd2671a7a810a2fa342db297bfb35011862ec3b907aa09fced64da90",
			ANIMATION_GATE_FILE: "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618",
			ANIMATION_INDEX_FILE: "588eba1d324cbcd9381797960eb1a81d099ef8277be6a1f92b935389647e1ae2",
			ANIMATION_INDEX_TABLE_FILE: "ad3e81a3ca712cd37059bd8e8eaa52468f09e6ba17b32100b53e39a5e3dfdef6",
			"fixed_mapper_helper_CE2D_CE49.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
		},
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"yield_callsite_pc": 0xA217,
		"yield_target_pc": 0xCB0F,
		"resume_pc_after_rts": 0xA21A,
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"yield_callsite_registers": callsite_registers,
		"yield_callsite_stack_page": callsite_stack,
		"call_frame_already_pushed": true,
		"pre_jsr_sp": int(callsite_registers["sp"]),
		"cb0f_entry_registers": cb0f_registers,
		"mapper": mapper,
		"initial_mapper": initial_mapper,
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"mapper_writes": mapper_writes,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}




## Executes the first `$A21A` animation command after the `$A217` task yield.
## It builds the ROM packet queue in RAM and stops at the next `$8047` yield
## callsite; NMI consumption and visible PPU rendering remain separate.
func execute_from_slot11_animation_after_a217_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_a21a_animation_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 `$A21A` continuation.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {}).duplicate(true)
	var initial_mapper := mapper.duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []

	# `$A21A` waits for the previous secondary queue, then decodes the live ROM
	# stream selected by `$0063/$0064` and its ROM packet-pointer row.
	instruction_pcs.append(0xA21A)
	_set_a(cpu, int(ram[0x0515]))
	_read_event(source_reads, 0xA21A, 0x0515, int(ram[0x0515]), "animation_queue_ready")
	if int(cpu["a"]) != 0:
		# ROM `$A21A` uses BNE `$A215` for any nonzero queue flag. `$A215`
		# yields through `$C515`; it does not keep the scheduler task active.
		var command_loop: PackedByteArray = _sources[ANIMATION_COMMAND_LOOP_FILE]
		var gate_prefix: PackedByteArray = _sources[ANIMATION_GATE_FILE]
		var gate_offset := 0xA215 - 0xA1EB
		if command_loop.size() < 10 \
				or command_loop.slice(0, 5) != PackedByteArray([0xAD, 0x15, 0x05, 0xD0, 0xF6]) \
				or gate_prefix.slice(gate_offset, gate_offset + 5) != PackedByteArray([0xA9, 0x01, 0x20, 0x15, 0xC5]):
			return _unsupported("The ROM `$A21A->$A215->$A217` busy-queue yield bytes changed.")
		instruction_pcs.append(0xA21D)
		_read_event(source_reads, 0xA21D, 0xA21D, 0xD0, "animation_queue_busy_branch_opcode")
		_read_event(source_reads, 0xA21D, 0xA21E, 0xF6, "animation_queue_busy_branch_displacement")
		instruction_pcs.append(0xA215)
		_read_event(source_reads, 0xA215, 0xA215, 0xA9, "animation_queue_busy_yield_opcode")
		_read_event(source_reads, 0xA215, 0xA216, 0x01, "animation_queue_busy_yield_value")
		_set_a(cpu, 0x01)
		cpu["pc"] = 0xA217
		instruction_pcs.append(0xA217)
		_read_event(source_reads, 0xA217, 0xA217, 0x20, "animation_queue_busy_yield_jsr_opcode")
		_read_event(source_reads, 0xA217, 0xA218, 0x15, "animation_queue_busy_yield_jsr_low")
		_read_event(source_reads, 0xA217, 0xA219, 0xC5, "animation_queue_busy_yield_jsr_high")
		var callsite_registers := cpu.duplicate(true)
		var callsite_stack := stack.duplicate()
		_jsr(cpu, stack, stack_writes, 0xA217, 0xC515)
		if int(cpu["sp"]) != 0xC4 or int(stack[0xC5]) != 0x19 or int(stack[0xC6]) != 0xA2:
			return _unsupported("The `$A21A` busy-queue `$A217->$C515` gate did not save return `$A21A`.")
		var trampoline_opcode := int(_sources[YIELD_TRAMPOLINE_FILE][0])
		if trampoline_opcode != 0x4C:
			return _unsupported("The fixed `$C515` task trampoline is not a JMP.")
		_read_event(source_reads, 0xC515, 0xC515, trampoline_opcode, "task_yield_dispatch_opcode")
		cpu["pc"] = 0xCB0F
		instruction_pcs.append(0xCB0F)
		var cb0f_registers := cpu.duplicate(true)
		var gate_output_ram := ram.duplicate()
		for stack_offset in STACK_SIZE:
			gate_output_ram[0x0100 + stack_offset] = stack[stack_offset]
		return {
			"ok": true,
			"status": "slot11_f5_animation_busy_gate_at_cb0f_from_a217",
			"rom_sha256": ROM_SHA256,
			"source_manifest": MANIFEST_PATH,
			"source_span_hashes": {
				ANIMATION_COMMAND_LOOP_FILE: "c315087f3f361a05abbbc63748d1c890aea1a2be7f40fb325150cb71688f1cfd",
				ANIMATION_GATE_FILE: "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618",
				YIELD_TRAMPOLINE_FILE: "86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e",
			},
			"slot_base": SLOT_11,
			"entry_pc": int(entry_cpu["pc"]), "exit_pc": int(cpu["pc"]),
			"yield_callsite_pc": 0xA217, "yield_target_pc": 0xCB0F,
			"resume_pc_after_rts": 0xA21A,
			"entry_record": PackedByteArray(boundary["record"]),
			"entry_registers": entry_cpu, "entry_ram_image": entry_ram,
			"entry_stack_page": entry_stack,
			"call_frame_already_pushed": true,
			"pre_jsr_sp": int(callsite_registers["sp"]),
			"yield_callsite_registers": callsite_registers,
			"yield_callsite_stack_page": callsite_stack,
			"cb0f_entry_registers": cb0f_registers,
			"mapper": mapper, "initial_mapper": initial_mapper,
			"ram_image": gate_output_ram, "stack_page": stack,
			"ram_writes": ram_writes, "stack_writes": stack_writes,
			"stack_reads": stack_reads, "mapper_writes": mapper_writes,
			"source_reads": source_reads, "instruction_pcs": instruction_pcs,
			"ppu_bus_events": [],
			"apu_register_writes": [],
			"trace_state_used": false,
			"ppu_apu_effects_applied": false,
			"source_timing_modeled": false,
		}
	if int(cpu["a"]) != 0:
		return _unsupported("The `$A21A` queue-ready test returned an unsupported nonzero value without bit 7 set.")
	instruction_pcs.append(0xA21F)
	_set_a(cpu, 0x01)
	instruction_pcs.append(0xA221)
	_write_ram(ram, ram_writes, 0x0515, 0x01, 0xA221)
	instruction_pcs.append(0xA224)
	_set_y(cpu, 0x00)
	instruction_pcs.append(0xA226)
	var animation_stream_pointer := int(ram[0x0063]) | (int(ram[0x0064]) << 8)
	var animation_stream := PackedByteArray()
	var animation_stream_offset := 0
	var is_index2_stream := int(ram[0x05F3]) == 0x02 \
			and animation_stream_pointer >= 0xA2E8 and animation_stream_pointer <= 0xA2FA \
			and ((animation_stream_pointer - 0xA2E8) % 2) == 0
	if animation_stream_pointer == 0xA425:
		animation_stream = _sources[ANIMATION_STREAM_FILE]
	elif animation_stream_pointer >= 0xA2AE and animation_stream_pointer < 0xA2AE + _sources[ANIMATION_STREAM_ZERO_FILE].size():
		animation_stream = _sources[ANIMATION_STREAM_ZERO_FILE]
		animation_stream_offset = animation_stream_pointer - 0xA2AE
	elif animation_stream_pointer >= 0xA2CB and animation_stream_pointer < 0xA2CB + _sources[ANIMATION_STREAM_INDEX1_FILE].size():
		animation_stream = _sources[ANIMATION_STREAM_INDEX1_FILE]
		animation_stream_offset = animation_stream_pointer - 0xA2CB
	elif is_index2_stream:
		animation_stream = _sources[ANIMATION_STREAM_INDEX2_FILE]
		animation_stream_offset = animation_stream_pointer - 0xA2E8
	else:
		return _unsupported("The live animation pointer is outside the packaged `$A425`, index-zero, index-one, and index-two ROM streams.")
	if animation_stream_offset + 1 >= animation_stream.size():
		return _unsupported("The live animation stream does not contain a command and pointer-table index.")
	var command := int(animation_stream[animation_stream_offset])
	_set_a(cpu, command)
	_read_event(source_reads, 0xA226, animation_stream_pointer, command, "animation_command")
	instruction_pcs.append(0xA228)
	var terminal_pointer_redirects := 0
	while command == 0xFF:
		# Index zero terminates inactive at `$A2C8->$A2AE`; index one loops
		# its active worker from `$A2E5->$A2CB`; index two loops from `$A2FA->$A2E8`.
		var is_index_zero_terminal := animation_stream_pointer == 0xA2C8 \
			and animation_stream_offset == 0x1A and int(ram[0x05E3]) == 0x00
		var is_index_one_terminal := animation_stream_pointer == 0xA2E5 \
			and animation_stream_offset == 0x1A
		var is_index2_terminal := is_index2_stream and animation_stream_pointer == 0xA2FA \
			and animation_stream_offset == 0x12 and int(ram[0x05E3]) == 0x01
		if not (is_index_zero_terminal or is_index_one_terminal or is_index2_terminal) \
				or terminal_pointer_redirects != 0 \
				or animation_stream_offset + 2 >= animation_stream.size():
			return _unsupported("The `$A21A` terminal `$FF` redirect is outside the bounded index-zero, index-one, or active index-two ROM loop.")
		instruction_pcs.append(0xA22C)
		_set_y(cpu, 0x01)
		instruction_pcs.append(0xA22D)
		var redirected_pointer_low := int(animation_stream[animation_stream_offset + 1])
		_set_a(cpu, redirected_pointer_low)
		_set_x(cpu, redirected_pointer_low)
		_read_event(source_reads, 0xA22D, animation_stream_pointer + 1,
			redirected_pointer_low, "terminal_animation_pointer_low")
		instruction_pcs.append(0xA230)
		_set_y(cpu, 0x02)
		instruction_pcs.append(0xA231)
		var redirected_pointer_high := int(animation_stream[animation_stream_offset + 2])
		_set_a(cpu, redirected_pointer_high)
		_read_event(source_reads, 0xA231, animation_stream_pointer + 2,
			redirected_pointer_high, "terminal_animation_pointer_high")
		instruction_pcs.append(0xA233)
		_write_ram(ram, ram_writes, 0x0064, redirected_pointer_high, 0xA233)
		instruction_pcs.append(0xA235)
		_write_ram(ram, ram_writes, 0x0063, redirected_pointer_low, 0xA235)
		instruction_pcs.append(0xA237)
		_set_a(cpu, int(ram[0x05E3]))
		_read_event(source_reads, 0xA237, 0x05E3, int(ram[0x05E3]), "actor_worker_active_flag")
		if int(cpu["a"]) != 0:
			instruction_pcs.append(0xA23A)
			_read_event(source_reads, 0xA23A, 0xA23A, 0xD0, "active_actor_loop_branch_opcode")
			_read_event(source_reads, 0xA23A, 0xA23B, 0xE8, "active_actor_loop_branch_displacement")
		else:
			instruction_pcs.append(0xA23C)
			_write_ram(ram, ram_writes, 0x05F4, 0x00, 0xA23C)
		instruction_pcs.append(0xA23F)
		animation_stream_pointer = (redirected_pointer_high << 8) | redirected_pointer_low
		var stream_base := 0xA2E8 if is_index2_terminal else (0xA2CB if is_index_one_terminal else 0xA2AE)
		var expected_redirect := 0xA2E8 if is_index2_terminal else (0xA2CB if is_index_one_terminal else 0xA2AE)
		if animation_stream_pointer != expected_redirect:
			return _unsupported("The `$A21A` terminal pointer does not resolve to its ROM-selected animation stream.")
		if is_index2_terminal:
			animation_stream = _sources[ANIMATION_STREAM_INDEX2_FILE]
		elif is_index_one_terminal:
			animation_stream = _sources[ANIMATION_STREAM_INDEX1_FILE]
		else:
			animation_stream = _sources[ANIMATION_STREAM_ZERO_FILE]
		animation_stream_offset = animation_stream_pointer - stream_base
		_set_y(cpu, 0x00)
		instruction_pcs.append(0xA224)
		instruction_pcs.append(0xA226)
		command = int(animation_stream[animation_stream_offset])
		_set_a(cpu, command)
		_read_event(source_reads, 0xA226, animation_stream_pointer, command,
			"animation_command")
		instruction_pcs.append(0xA228)
		terminal_pointer_redirects += 1
	if command not in [0x05, 0xEF] and not (is_index2_stream and command == 0x04):
		return _unsupported("The live animation command is outside the verified `$05`, `$EF`, and index-two `$04` cases.")
	instruction_pcs.append(0xA242)
	_write_ram(ram, ram_writes, 0x05F5, command, 0xA242)
	instruction_pcs.append(0xA245)
	_set_y(cpu, 0x01)
	instruction_pcs.append(0xA246)
	var event_index := int(animation_stream[animation_stream_offset + 1])
	_set_a(cpu, event_index)
	_read_event(source_reads, 0xA246, animation_stream_pointer + 1, event_index, "animation_event_index")
	var index2_packet_event := is_index2_stream and command == 0x04 and event_index in [5, 6, 7]
	if (index2_packet_event and int(ram[0x05F3]) != 0x02) \
			or (not index2_packet_event and (event_index < 0 or event_index >= 5)) \
			or (command == 0x04 and not index2_packet_event) \
			or (command == 0xEF and event_index != 0):
		return _unsupported("The live animation packet index is outside the ROM rows supported by this executor.")
	instruction_pcs.append(0xA248)
	_set_a(cpu, (event_index << 1) & 0xFF)
	instruction_pcs.append(0xA249)
	_set_x(cpu, int(cpu["a"]))
	instruction_pcs.append(0xA24A)
	var packet_pointer_table: PackedByteArray = _sources[
		ANIMATION_INDEX2_PACKET_POINTER_TABLE_FILE if index2_packet_event \
		else ANIMATION_PACKET_POINTER_TABLE_FILE]
	var packet_pointer_offset := event_index * 2
	var packet_pointer_low := int(packet_pointer_table[packet_pointer_offset])
	_set_a(cpu, packet_pointer_low)
	_read_event(source_reads, 0xA24A, 0xA42A + packet_pointer_offset, packet_pointer_low, "animation_event_pointer_low")
	instruction_pcs.append(0xA24D)
	_write_ram(ram, ram_writes, 0x003A, packet_pointer_low, 0xA24D)
	instruction_pcs.append(0xA24F)
	var packet_pointer_high := int(packet_pointer_table[packet_pointer_offset + 1])
	_set_a(cpu, packet_pointer_high)
	_read_event(source_reads, 0xA24F, 0xA42B + packet_pointer_offset, packet_pointer_high, "animation_event_pointer_high")
	instruction_pcs.append(0xA252)
	_write_ram(ram, ram_writes, 0x003B, packet_pointer_high, 0xA252)
	_set_y(cpu, 0x00)
	_set_x(cpu, 0x00)
	var packet_pointer := (packet_pointer_high << 8) | packet_pointer_low
	var packet_source_file := ""
	match packet_pointer:
		0xA46A: packet_source_file = ANIMATION_PPU_PACKETS_FILE
		0xA48F: packet_source_file = ANIMATION_PPU_PACKETS_01_FILE
		0xA494: packet_source_file = ANIMATION_PPU_PACKETS_02_FILE
		0xA499: packet_source_file = ANIMATION_PPU_PACKETS_03_FILE
		0xA49E: packet_source_file = ANIMATION_PPU_PACKETS_04_FILE
		0xA4C3: packet_source_file = ANIMATION_PPU_PACKETS_05_FILE
		0xA4E8: packet_source_file = ANIMATION_PPU_PACKETS_06_FILE
		0xA4ED: packet_source_file = ANIMATION_PPU_PACKETS_07_FILE
		_: return _unsupported("The animation packet pointer does not resolve to a packaged ROM packet span.")
	var packet_bytes: PackedByteArray = _sources[packet_source_file]
	var stream_offset := 0
	var packet_offset := 0
	var packet_count := 0
	var parsed_packets: Array[Dictionary] = []
	while true:
		if stream_offset >= packet_bytes.size() or packet_count > 16:
			return _unsupported("The `$A46A` packet stream has no bounded zero-count terminator.")
		instruction_pcs.append(0xA258)
		var byte_count := int(packet_bytes[stream_offset])
		_set_y(cpu, stream_offset)
		_set_a(cpu, byte_count)
		_read_event(source_reads, 0xA258, packet_pointer + stream_offset, byte_count, "animation_packet_length")
		if byte_count == 0:
			instruction_pcs.append(0xA25A)
			break
		instruction_pcs.append(0xA25C)
		_write_ram(ram, ram_writes, 0x04A5 + packet_offset, byte_count, 0xA25C)
		_write_ram(ram, ram_writes, 0x003C, byte_count, 0xA25F)
		var destination_low := int(packet_bytes[stream_offset + 1])
		instruction_pcs.append(0xA262)
		_set_y(cpu, stream_offset + 1)
		_set_a(cpu, destination_low)
		_read_event(source_reads, 0xA262, packet_pointer + stream_offset + 1, destination_low, "animation_ppu_address_low")
		instruction_pcs.append(0xA264)
		_write_ram(ram, ram_writes, 0x04A6 + packet_offset, destination_low, 0xA264)
		var destination_high := int(packet_bytes[stream_offset + 2])
		instruction_pcs.append(0xA268)
		_set_y(cpu, stream_offset + 2)
		_set_a(cpu, destination_high)
		_read_event(source_reads, 0xA268, packet_pointer + stream_offset + 2, destination_high, "animation_ppu_address_high")
		instruction_pcs.append(0xA26A)
		_write_ram(ram, ram_writes, 0x04A7 + packet_offset, destination_high, 0xA26A)
		instruction_pcs.append(0xA26D)
		packet_offset += 3
		_set_x(cpu, packet_offset)
		var payload := PackedByteArray()
		for byte_index in byte_count:
			var payload_value := int(packet_bytes[stream_offset + 3 + byte_index])
			instruction_pcs.append(0xA271)
			_set_y(cpu, stream_offset + 3 + byte_index)
			_set_a(cpu, payload_value)
			_read_event(source_reads, 0xA271, packet_pointer + stream_offset + 3 + byte_index,
				payload_value, "animation_ppu_payload")
			_write_ram(ram, ram_writes, 0x04A5 + packet_offset, payload_value, 0xA273)
			payload.append(payload_value)
			packet_offset += 1
			_set_x(cpu, packet_offset)
		var left := byte_count
		while left > 0:
			left -= 1
			_write_ram(ram, ram_writes, 0x003C, left, 0xA278)
			_set_flag(cpu, P_N, (left & 0x80) != 0)
			_set_flag(cpu, P_Z, left == 0)
		instruction_pcs.append(0xA27C)
		stream_offset += 3 + byte_count
		packet_count += 1
		parsed_packets.append({
			"length": byte_count,
			"destination": (destination_high << 8) | destination_low,
			"payload": payload,
		})
	if stream_offset != packet_bytes.size() - 1 or packet_offset >= 0x70:
		return _unsupported("The selected ROM animation PPU packet stream has no exact bounded terminator.")
	instruction_pcs.append(0xA27E)
	_write_ram(ram, ram_writes, 0x04A5 + packet_offset, 0x00, 0xA27E)
	instruction_pcs.append(0xA281)
	_set_a(cpu, 0x80)
	instruction_pcs.append(0xA283)
	_write_ram(ram, ram_writes, 0x0515, 0x80, 0xA283)
	instruction_pcs.append(0xA286)
	_set_a(cpu, int(ram[0x0063]))
	_read_event(source_reads, 0xA286, 0x0063, int(ram[0x0063]), "animation_stream_pointer_low")
	instruction_pcs.append(0xA288)
	_set_flag(cpu, P_C, false)
	instruction_pcs.append(0xA289)
	var next_pointer_low := (int(cpu["a"]) + 2) & 0xFF
	_set_flag(cpu, P_C, int(cpu["a"]) + 2 > 0xFF)
	_set_a(cpu, next_pointer_low)
	instruction_pcs.append(0xA28B)
	_write_ram(ram, ram_writes, 0x0063, next_pointer_low, 0xA28B)
	if (int(cpu["p"]) & P_C) != 0:
		instruction_pcs.append(0xA28D)
		_write_ram(ram, ram_writes, 0x0064, (int(ram[0x0064]) + 1) & 0xFF, 0xA28F)
	instruction_pcs.append(0xA291)
	_rts(cpu, stack, stack_reads, 0xA291)
	if int(cpu["pc"]) != 0xCF84:
		return _unsupported("The animation-list RTS did not return to mapper wrapper `$CF84`.")
	# `$CF84-$CF8E` restores the original bank pair before returning to `$8050`.
	instruction_pcs.append(0xCF84)
	_set_a(cpu, 0x18)
	instruction_pcs.append(0xCF86)
	_write_ram(ram, ram_writes, 0x0024, 0x18, 0xCF86)
	instruction_pcs.append(0xCF88)
	_set_a(cpu, 0x19)
	instruction_pcs.append(0xCF8A)
	_write_ram(ram, ram_writes, 0x0025, 0x19, 0xCF8A)
	var mapper_helper: PackedByteArray = _sources["mapper_helper"]
	for offset in [0, 2, 3, 6, 9, 11, 13, 14, 15, 17, 18, 21, 23, 24, 27, 28]:
		instruction_pcs.append(0xCE2D + offset)
	var selector_low := int(ram[0x0022]) | 0x06
	_write_ram(ram, ram_writes, 0x0023, selector_low, 0xCE31)
	_set_mapper_pair_register(mapper, mapper_writes, selector_low, 6, 0xCE33, true)
	_read_event(source_reads, 0xCE36, 0x0024, int(ram[0x0024]), "mapper_bank_6_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0024]), 6, 0xCE38)
	var selector_high := int(ram[0x0022]) | 0x07
	_write_ram(ram, ram_writes, 0x0023, selector_high, 0xCE3F)
	_set_mapper_pair_register(mapper, mapper_writes, selector_high, 7, 0xCE41, true)
	_read_event(source_reads, 0xCE44, 0x0025, int(ram[0x0025]), "mapper_bank_7_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0025]), 7, 0xCE46)
	_rts(cpu, stack, stack_reads, 0xCE49)
	if int(cpu["pc"]) != 0x8050 or int(cpu["sp"]) != 0xCA \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19:
		return _unsupported("The mapper helper did not restore banks `$18/$19` and return to `$8050`.")
	instruction_pcs.append(0x8050)
	cpu["pc"] = 0x8045
	instruction_pcs.append(0x8045)
	_set_a(cpu, 0x01)
	cpu["pc"] = 0x8047
	if _sources["worker_prefix"].slice(0x45, 0x4A) != PackedByteArray([0xA9, 0x01, 0x20, 0x15, 0xC5]):
		return _unsupported("The `$8050->$8045->$8047` source loop differs from the shared bank-$18 bytes.")
	instruction_pcs.append(0x8047)
	var output_ram := ram.duplicate()
	for offset in STACK_SIZE:
		output_ram[0x0100 + offset] = stack[offset]
	var animation_source_span_hashes := {
		ANIMATION_COMMAND_LOOP_FILE: "c315087f3f361a05abbbc63748d1c890aea1a2be7f40fb325150cb71688f1cfd",
		ANIMATION_STREAM_FILE: "c80e57d27a62d8f8ae98f6976e64d0a1e4f9cebe78cf5b16e79ecd927b985da6",
		ANIMATION_STREAM_ZERO_FILE: "9016d1464cdeda45f92924cbb80750f4a5e448eba0733f4ecc903c39f19ca152",
		ANIMATION_STREAM_INDEX1_FILE: "c49f05054d80e56b0b67d6aa54fd8df627a141788bafe2ba462cc2dac3ce8275",
		ANIMATION_POINTER_FILE: "48dceebd8704067b3697888d1f847f69d77a5fbbcb8e57ac3a9a0b41205e47cf",
		ANIMATION_PACKET_POINTER_TABLE_FILE: "faf0f900066396fec637d1db3b62437835c010e10fb67f87d03e89496f877ff7",
		ANIMATION_PPU_PACKETS_FILE: "4fd878c7cc59ffec84362bfc6f973474f72c83087d302687958b844682b2d678",
		ANIMATION_PPU_PACKETS_01_FILE: "ddb3daefa3e57138841317c468338120ff1f0941a11955c3640f5d5828c7b34a",
		ANIMATION_PPU_PACKETS_02_FILE: "cd0bf13e4ccb0d5738e1f83917201a7bf355dd9f82716d3594e9752af37994f1",
		ANIMATION_PPU_PACKETS_03_FILE: "92de63c44c57852ef97b0a1aed56b897f4731d7c38c2b7a35a61f4eb3c7741ed",
		ANIMATION_PPU_PACKETS_04_FILE: "4cf2f13165526f20ed00ddf94286986b6c6afa2fed1977ac2378ba61948d31cf",
		"fixed_mapper_helper_CE2D_CE49.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
		"bank18_actor_worker_entry_8000_804A.bin": "2187af6881ea2f4e7eb16c0c5550bb24ead076be918d429d8ab63564ed8fd46c",
	}
	if is_index2_stream:
		animation_source_span_hashes[ANIMATION_STREAM_INDEX2_FILE] = \
			"424adf7357d292bb49f97104a0e091edb8e4705a81d0698984fbbcd94b13ab66"
		animation_source_span_hashes[ANIMATION_INDEX2_PACKET_POINTER_TABLE_FILE] = \
			"1e692b18504e8fad80b9172d657f448d147d9c1ed65ff05ea8b8bfb8409e4dc1"
		animation_source_span_hashes[ANIMATION_PPU_PACKETS_05_FILE] = \
			"f82521c259c81ec916a28e42ed2744a59cbb2abe8521081fd23c9d9690c28b93"
		animation_source_span_hashes[ANIMATION_PPU_PACKETS_06_FILE] = \
			"b07bc05cce10fd5c335a4d677dcd13fdb168227f64b358dd25b5eeca550fcf1e"
		animation_source_span_hashes[ANIMATION_PPU_PACKETS_07_FILE] = \
			"0630624ed694ebb370c1539d4da0be8778264c6a596ae6bcb697d26253252b00"
	return {
		"ok": true,
		"status": "slot11_f5_animation_queue_at_8047",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": animation_source_span_hashes,
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"yield_callsite_pc": 0x8047,
		"yield_target_pc": 0xCB0F,
		"resume_pc_after_rts": 0x804A,
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"call_frame_already_pushed": false,
		"pre_jsr_sp": int(cpu["sp"]),
		"yield_callsite_registers": cpu.duplicate(true),
		"yield_callsite_stack_page": stack.duplicate(),
		"mapper": mapper,
		"initial_mapper": initial_mapper,
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"mapper_writes": mapper_writes,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"secondary_ppu_packets": parsed_packets,
		"animation_stream_pointer": animation_stream_pointer,
		"animation_command": command,
		"animation_packet_index": event_index,
		"packet_stream_pointer": packet_pointer,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}
## Executes one ROM-owned nonzero animation wait. `$8053` decrements `$05E9`,
## `$A20C` decrements `$05F5`, and the worker returns to its `$8047` yield.
func execute_from_slot11_animation_countdown_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_animation_countdown_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 animation countdown boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var cpu := {
		"pc": int(boundary["pc"]), "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var mapper: Dictionary = boundary.get("mapper", {}).duplicate(true)
	var initial_mapper := mapper.duplicate(true)
	var initial_stream_pointer := int(ram[0x005F]) | (int(ram[0x0060]) << 8)
	var is_scenario2e_actor6d_9bfe_delay_tick: bool = initial_stream_pointer == 0x9BFE \
			and bool(valid.get("scenario2e_actor6d_9bfe_delay_tick", false))
	var is_scenario2e_actor6d_type5_packet_wait: bool = initial_stream_pointer == 0x9BFE \
			and bool(valid.get("scenario2e_actor6d_type5_packet_wait", false))
	var is_scenario1c_parameter58_dispatch_profile := initial_stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_stream_dispatch_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_stream_dispatch_worker_profile(ram, stack, boundary))
	var is_selector03_sequence := initial_stream_pointer in [0xA3BD, 0xA3C9]
	var is_scenario1c_parameter00_stream := initial_stream_pointer == 0x9400 \
			and int(ram[0x05EA]) == 0x00 \
			and _is_scenario1c_actor00_live_worker_profile(ram)
	var is_scenario1c_parameter58_initial_delay := initial_stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_live_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_live_worker_profile(ram, stack, boundary))
	var is_scenario1c_parameter58_countdown := initial_stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_countdown_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_countdown_worker_profile(ram, stack, boundary))
	var is_scenario1c_parameter58_post_packet_delay := initial_stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_post_packet_delay_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_post_packet_delay_worker_profile(ram, stack, boundary))
	var is_scenario1c_parameter58_followup_post_packet_delay := initial_stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_followup_post_packet_delay_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_followup_post_packet_delay_worker_profile(ram, stack, boundary))
	var is_parameter47_f2_delay_tick := initial_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x01 \
			and int(ram[0x05E5]) == 0x02 and int(ram[0x05E9]) == 0x01 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x01 \
			and int(stack[0xC7]) == 0x01 and int(stack[0xC8]) == 0x21 \
			and int(boundary.get("a", -1)) == 0x21 \
			and int(boundary.get("x", -1)) == 0x21 \
			and int(boundary.get("y", -1)) == 0x01
	var is_parameter47_f2_followup_delay_tick := initial_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
			and int(ram[0x05E5]) == 0x06 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 \
			and int(ram[0x05F3]) == 0x01 and int(ram[0x05F4]) == 0x01 \
			and int(ram[0x05F5]) == 0x04 and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x05 and int(stack[0xC8]) == 0x05 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x05
	var is_parameter47_f2_animation_countdown_tick := initial_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x00, 0x09, 0x0E, 0x02, 0x02, 0x01]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x02]) \
			and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x06 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A
	var is_parameter47_f2_text_terminal_command := initial_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x00, 0x09, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x01]) \
			and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x06 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A
	var is_a439_initial_delay := initial_stream_pointer == 0xA439 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x00 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(stack[0xC7]) == 0xEB and int(stack[0xC8]) == 0x39 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x39 \
			and int(boundary.get("x", -1)) == 0x39 \
			and int(boundary.get("y", -1)) == 0xEB
	var is_a439_delay_countdown := initial_stream_pointer == 0xA439 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x01 \
			and int(ram[0x05E5]) == 0x01 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(stack[0xC7]) == 0x00 and int(stack[0xC8]) == 0x39 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x39 \
			and int(boundary.get("x", -1)) == 0x39 \
			and int(boundary.get("y", -1)) == 0x00
	var is_a439_post_packet_delay := initial_stream_pointer == 0xA439 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
			and int(ram[0x05E5]) == 0x05 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x04 \
			and int(ram[0x0515]) == 0x00 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x05 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x04
	var is_a439_text_post_packet_delay := initial_stream_pointer == 0xA439 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0D and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x02 \
			and int(ram[0x0515]) == 0x00 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x06 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A
	var is_a439_text_packet_wait := initial_stream_pointer == 0xA439 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
			and int(ram[0x05E5]) == 0x05 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x03 \
			and int(ram[0x0515]) == 0x00 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x05 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x04
	var is_selector03_row02_terminal_command := initial_stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x19 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) == 0x00
	var is_a439_text_terminal_command := initial_stream_pointer == 0xA439 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0D and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x01 \
			and int(ram[0x0515]) == 0x00 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x06 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A
	var is_scenario1c_parameter58_followup_text_terminal_command := initial_stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_followup_text_terminal_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_followup_text_terminal_worker_profile(ram, stack, boundary))
	var is_selector03_terminal_inactive_countdown := initial_stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB2 and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x02
	var is_selector03_terminal_inactive_packet_countdown := initial_stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and ((int(ram[0x0063]) in [0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6] \
				and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
				and int(boundary.get("a", -1)) == 0x04 \
				and int(boundary.get("x", -1)) == 0x04 \
				and int(boundary.get("y", -1)) == 0x04) \
			or (int(ram[0x0063]) == 0xC8 and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
				and int(boundary.get("a", -1)) == 0x24 \
				and int(boundary.get("x", -1)) == 0x24 \
				and int(boundary.get("y", -1)) == 0x24))
	var is_selector03_terminal_inactive_gate := initial_stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB2 and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x02
	var is_a439_text_terminal_inactive_gate := initial_stream_pointer == 0xA439 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0E and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x06 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x02
	var is_scenario1c_parameter58_followup_text_terminal_inactive_gate := initial_stream_pointer == 0x9A62 \
			and int(ram[0x05EA]) == 0x58 \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x00]) \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x06 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x02
	var is_parameter47_f2_text_terminal_inactive_gate: bool = initial_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x00]) \
			and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x06 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x02
	# `$8053` overwrites entry A with `$05E3`; `$A215` then loads `$01` before the yield.
	var is_a439_inactive_zero_counter_gate := initial_stream_pointer == 0xA439 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0E and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(ram[0x0063]) in [0xB2, 0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6, 0xC8] \
			and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) in [0x02, 0x04]
	var is_a439_text_inactive_animation_countdown := initial_stream_pointer == 0xA439 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0E and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(ram[0x0063]) in [0xB2, 0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6, 0xC8] \
			and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04
	var is_scenario1c_parameter58_terminal_animation_countdown: bool = initial_stream_pointer == 0x9A62 \
			and int(ram[0x05EA]) == 0x58 \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F5) == PackedByteArray([0x00, 0x01]) \
			and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB2, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04 \
			or is_scenario1c_parameter58_phase29_cursor10_queue_busy_animation_boundary(boundary)
	var is_scenario1e_actor58_animation_countdown := \
			is_scenario1e_actor58_animation_countdown_boundary(boundary)
	var is_scenario1e_actor58_zero_counter_gate := int(ram[0x05F5]) == 0 \
			and is_scenario1e_actor58_animation_countdown_boundary(boundary, true)
	var is_scenario1e_actor58_inactive_zero_mode_resume := \
			is_scenario1e_actor58_inactive_zero_mode_resume_boundary(boundary)
	var is_scenario1c_parameter58_zero_counter_queue_busy_gate: bool = initial_stream_pointer == 0x9A62 \
			and is_scenario1c_parameter58_zero_counter_queue_busy_animation_boundary(boundary)
	var is_parameter47_f2_animation_script_countdown := initial_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F5) == PackedByteArray([0x01, 0x01]) \
			and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(ram[0x0063]) in [0xCD, 0xCF] and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04
	var is_parameter47_f2_post_packet_animation_countdown := initial_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F5) == PackedByteArray([0x01, 0x01]) \
			and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(ram[0x0063]) in [0xD1, 0xD3, 0xD5, 0xD7, 0xD9, 0xDB, 0xDD, 0xDF, 0xE1, 0xE3, 0xE5] and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04
	var is_parameter47_f2_inactive_zero_counter_gate := initial_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x00]) \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(ram[0x0063]) in [0xCD, 0xCF] and int(ram[0x0064]) == 0xA2 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04
	var is_parameter47_f2_post_packet_zero_counter_gate := initial_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x00]) \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(ram[0x0063]) in [0xD1, 0xD3, 0xD5, 0xD7, 0xD9, 0xDB, 0xDD, 0xDF, 0xE1, 0xE3, 0xE5] and int(ram[0x0064]) == 0xA2 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04
	var is_a439_inactive_zero_mode_resume := initial_stream_pointer == 0xA439 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0E and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x01 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(ram[0x0063]) == 0xBC and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04
	var is_scenario1c_f0_inactive_zero_mode_resume := initial_stream_pointer == 0x9400 \
			and int(ram[0x05EA]) == 0x00 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x02, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xD7, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x02, 0x21, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x21 \
			and int(boundary.get("x", -1)) == 0x21 \
			and int(boundary.get("y", -1)) == 0x02
	var is_selector03_terminal_inactive_packet_gate := initial_stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and ((int(ram[0x0063]) in [0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6] \
				and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
				and int(boundary.get("a", -1)) == 0x04 \
				and int(boundary.get("x", -1)) == 0x04 \
				and int(boundary.get("y", -1)) == 0x04) \
			or (int(ram[0x0063]) == 0xC8 and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
				and int(boundary.get("a", -1)) == 0x24 \
				and int(boundary.get("x", -1)) == 0x24 \
				and int(boundary.get("y", -1)) == 0x24))
	var is_selector03_animation_tail_idle := initial_stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
			and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x24
	var is_selector03_row02_animation_gate := initial_stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x19 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) == 0x00
	var is_selector03_followup_packet_wait := initial_stream_pointer == 0xA3C9 \
			and int(ram[0x05E4]) == 0x02 \
			and ((int(ram[0x05E5]) == 0x06 and int(ram[0x05E7]) == 0x01 \
				and int(ram[0x05F5]) == 0x03) \
				or (int(ram[0x05E5]) == 0x10 and int(ram[0x05E7]) == 0x02 \
				and int(ram[0x05F5]) == 0x01)) \
			and int(ram[0x05E6]) == 0x0E and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x0515]) == 0x00
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var callsite_registers: Dictionary = {}
	var callsite_stack := PackedByteArray()
	var terminal_sequence_completed := false

	# `$804A JSR $8053`; follow the traced worker branch and return to `$804D`.
	instruction_pcs.append(0x804A)
	_jsr(cpu, stack, stack_writes, 0x804A, 0x8053)
	instruction_pcs.append(0x8053)
	_set_a(cpu, int(ram[0x05E3]))
	_read_event(source_reads, 0x8053, 0x05E3, int(ram[0x05E3]), "worker_active_flag")
	if int(cpu["a"]) == 0 and (is_selector03_terminal_inactive_countdown \
			or is_selector03_terminal_inactive_gate \
			or is_a439_text_terminal_inactive_gate \
			or is_scenario1c_parameter58_followup_text_terminal_inactive_gate \
			or is_scenario1e_actor58_inactive_zero_mode_resume \
			or is_parameter47_f2_text_terminal_inactive_gate \
			or is_parameter47_f2_animation_script_countdown \
			or is_parameter47_f2_post_packet_animation_countdown \
			or is_scenario1c_parameter58_terminal_animation_countdown \
			or is_scenario1e_actor58_animation_countdown \
			or is_scenario1e_actor58_zero_counter_gate \
			or is_scenario1c_parameter58_zero_counter_queue_busy_gate \
			or is_parameter47_f2_inactive_zero_counter_gate \
			or is_parameter47_f2_post_packet_zero_counter_gate \
			or is_a439_inactive_zero_counter_gate \
			or is_a439_text_inactive_animation_countdown \
			or is_a439_inactive_zero_mode_resume \
			or is_scenario1c_f0_inactive_zero_mode_resume \
			or is_selector03_terminal_inactive_packet_countdown \
			or is_selector03_terminal_inactive_packet_gate \
			or is_selector03_animation_tail_idle):
		instruction_pcs.append(0x8056)
		instruction_pcs.append(0x8059)
		_rts(cpu, stack, stack_reads, 0x8059)
		terminal_sequence_completed = true
	elif int(cpu["a"]) != 1:
		return _unsupported("The animation countdown worker is not active at `$8053`.")
	if not terminal_sequence_completed:
		instruction_pcs.append(0x8056)
		instruction_pcs.append(0x8059)
		_set_a(cpu, int(ram[0x05E9]))
		_read_event(source_reads, 0x8059, 0x05E9, int(ram[0x05E9]), "actor_animation_delay")
		instruction_pcs.append(0x805C)
	if not terminal_sequence_completed and int(cpu["a"]) == 0:
		# `$8062` dispatches the current actor-stream handler; this bounded case
		# accepts only its ROM byte below `$F0`, which becomes the next delay.
		instruction_pcs.append(0x8062)
		_set_a(cpu, int(ram[0x05E4]))
		_read_event(source_reads, 0x8062, 0x05E4, int(ram[0x05E4]), "actor_stream_dispatch_index")
		_jsr(cpu, stack, stack_writes, 0x8065, 0xC509)
		var handler := _inline_dispatch(cpu, ram, stack, ram_writes,
			stack_writes, stack_reads, source_reads, 0x8065, 0x8068, instruction_pcs)
		if handler == 0x806E:
			instruction_pcs.append(0x806E)
			var stream_index := int(ram[0x05E5])
			_set_y(cpu, stream_index)
			_read_event(source_reads, 0x806E, 0x05E5, stream_index, "actor_stream_index")
			_write_ram(ram, ram_writes, 0x05E5, (stream_index + 1) & 0xFF, 0x8071)
			_read_event(source_reads, 0x8074, 0x005F, int(ram[0x005F]), "actor_stream_pointer_low")
			_read_event(source_reads, 0x8074, 0x0060, int(ram[0x0060]), "actor_stream_pointer_high")
			var stream_address := ((int(ram[0x0060]) << 8) | int(ram[0x005F])) + stream_index
			var stream_byte := _read_stream_byte(stream_address)
			if stream_byte < 0:
				return _unsupported("The actor-stream delay byte is outside the hash-checked ROM spans.")
			_read_event(source_reads, 0x8074, stream_address, stream_byte, "actor_stream_followup_delay")
			_set_a(cpu, stream_byte)
			instruction_pcs.append(0x8076)
			_compare_a(cpu, 0xF0)
			if stream_byte == 0xF0:
				var is_selector03_terminal_stream_end := is_selector03_row02_terminal_command \
						and stream_address == 0xA3E2 and stream_index == 0x19
				var is_a439_text_stream_end := is_a439_text_terminal_command \
						and stream_address == 0xA446 and stream_index == 0x0D
				var is_scenario1c_parameter58_followup_text_stream_end := \
						is_scenario1c_parameter58_followup_text_terminal_command \
						and stream_address == 0x9A6F and stream_index == 0x0D
				var is_parameter47_f2_text_stream_end := is_parameter47_f2_text_terminal_command \
					and stream_address == 0x9920 and stream_index == 0x09
				var is_scenario1c_parameter00_stream_end := is_scenario1c_parameter00_stream \
					and stream_address == 0x9401 and stream_index == 0x01 \
					and int(ram[0x05E5]) == 0x01 and int(ram[0x05EA]) == 0x00
				if not is_selector03_terminal_stream_end and not is_a439_text_stream_end \
					and not is_scenario1c_parameter58_followup_text_stream_end \
					and not is_parameter47_f2_text_stream_end \
					and not is_scenario1c_parameter00_stream_end:
					return _unsupported("The live `$F0` terminator is outside the verified selector-$03, A439, parameter-$47, or scenario-$1C parameter-$00 stream end.")
				# `$F0` dispatches to `$8098`: clear the active actor-stream flag,
				# discard the parser/worker JSR frames, and return to the `$804D` wrapper.
				instruction_pcs.append(0x8078)
				instruction_pcs.append(0x807A)
				_jsr(cpu, stack, stack_writes, 0x807A, 0x8087)
				instruction_pcs.append(0x8087)
				_set_a(cpu, stream_byte & 0x0F)
				instruction_pcs.append(0x8089)
				_jsr(cpu, stack, stack_writes, 0x8089, 0xC509)
				var terminal_handler := _inline_dispatch(cpu, ram, stack, ram_writes,
					stack_writes, stack_reads, source_reads, 0x8089, 0x808C, instruction_pcs)
				if terminal_handler != 0x8098:
					return _unsupported("The selector-$03 `$F0` command no longer dispatches through ROM handler `$8098`.")
				var terminal_handler_bytes: PackedByteArray = _sources[WORKER_FILE].slice(
					0x8098 - 0x804A, 0x80A0 - 0x804A)
				if terminal_handler_bytes != PackedByteArray([0xA9, 0x00, 0x8D, 0xE3, 0x05, 0x68, 0x68, 0x60]):
					return _unsupported("The ROM `$8098` actor-stream terminator bytes changed.")
				for terminal_offset in terminal_handler_bytes.size():
					var terminal_address := 0x8098 + terminal_offset
					_read_event(source_reads, terminal_address, terminal_address,
						int(terminal_handler_bytes[terminal_offset]), "selector03_terminal_handler_rom_byte")
				instruction_pcs.append(0x8098)
				_set_a(cpu, 0x00)
				instruction_pcs.append(0x809A)
				_write_ram(ram, ram_writes, 0x05E3, 0x00, 0x809A)
				instruction_pcs.append(0x809D)
				_set_a(cpu, _pop(cpu, stack, stack_reads, 0x809D))
				_set_nz(cpu, int(cpu["a"]))
				instruction_pcs.append(0x809E)
				_set_a(cpu, _pop(cpu, stack, stack_reads, 0x809E))
				_set_nz(cpu, int(cpu["a"]))
				instruction_pcs.append(0x809F)
				_rts(cpu, stack, stack_reads, 0x809F)
				var expected_terminal_x := 0x06 if is_a439_text_stream_end or is_scenario1c_parameter58_followup_text_stream_end or is_parameter47_f2_text_stream_end else 0x04
				if is_scenario1c_parameter00_stream_end:
					if int(cpu["pc"]) != 0x804D or int(cpu["sp"]) != 0xCA \
							or int(cpu["a"]) != 0x80 or int(cpu["y"]) != 0x02:
						return _unsupported("Scenario-$1C parameter-$00 `$F0` did not reproduce its verified ROM handler return state.")
				elif int(cpu["pc"]) != 0x804D or int(cpu["sp"]) != 0xCA \
						or int(cpu["a"]) != 0x80 or int(cpu["x"]) != expected_terminal_x \
						or int(cpu["y"]) != 0x02:
					return _unsupported("The ROM `$8098` terminator did not reproduce the FCEUX `$804D` return registers and stack.")
				terminal_sequence_completed = true
			if stream_byte >= 0xF0 and not terminal_sequence_completed:
				if stream_byte != 0xF4 or not is_selector03_sequence \
						or stream_address != 0xA3BD or stream_index != 0:
					return _unsupported("The live stream byte selects an unsupported `$F0+` handler table.")
				# The live selector-$03 stream begins with F4 03. Resolve its row
				# through the ROM's $811E handler and pointer table, then continue
				# the same source parser at $A3C9, where byte $01 is a delay.
				instruction_pcs.append(0x8078)
				instruction_pcs.append(0x807A)
				_jsr(cpu, stack, stack_writes, 0x807A, 0x8087)
				instruction_pcs.append(0x8087)
				_set_a(cpu, stream_byte & 0x0F)
				instruction_pcs.append(0x8089)
				_jsr(cpu, stack, stack_writes, 0x8089, 0xC509)
				var f4_handler := _inline_dispatch(cpu, ram, stack, ram_writes,
					stack_writes, stack_reads, source_reads, 0x8089, 0x808C, instruction_pcs)
				if f4_handler != 0x80CB:
					return _unsupported("ROM `$A3BD` F4 no longer resolves to the `$80CB` selector handler.")
				instruction_pcs.append(0x80CB)
				_set_y(cpu, int(ram[0x05E5]))
				var selector_address := initial_stream_pointer + int(cpu["y"])
				var selector := _read_stream_byte(selector_address)
				if selector != 0x03:
					return _unsupported("The live `$A3BD` sequence row no longer selects F4 selector `$03`.")
				_read_event(source_reads, 0x80CE, selector_address, selector, "F4_selector")
				_set_a(cpu, selector)
				instruction_pcs.append(0x80D0)
				_jsr(cpu, stack, stack_writes, 0x80D0, 0x80EA)
				instruction_pcs.append(0x80EA)
				_jsr(cpu, stack, stack_writes, 0x80EA, 0xC509)
				var row_handler := _inline_dispatch(cpu, ram, stack, ram_writes,
					stack_writes, stack_reads, source_reads, 0x80EA, 0x80ED, instruction_pcs)
				if row_handler != 0x811E:
					return _unsupported("F4 selector `$03` no longer dispatches through bank-$18 `$811E`.")
				instruction_pcs.append(0x811E)
				var selected_row := int(ram[0x0629])
				_read_event(source_reads, 0x811E, 0x0629, selected_row, "actor_sequence_row")
				_set_x(cpu, selected_row)
				instruction_pcs.append(0x8121)
				_rts(cpu, stack, stack_reads, 0x8121)
				if int(cpu["pc"]) != 0x80D3 or selected_row != 0:
					return _unsupported("The live sequence row does not resolve to the verified row-zero pointer.")
				instruction_pcs.append(0x80D3)
				_set_a(cpu, int(cpu["x"]))
				instruction_pcs.append(0x80D4)
				var row_offset := (int(cpu["a"]) << 1) & 0xFF
				_set_a(cpu, row_offset)
				_set_flag(cpu, P_C, true)
				instruction_pcs.append(0x80D6)
				_read_event(source_reads, 0x80D6, 0x05E5, int(ram[0x05E5]), "F4_pointer_row_index")
				var pointer_carry := 1 if (int(cpu["p"]) & P_C) != 0 else 0
				var pointer_offset := (row_offset + int(ram[0x05E5]) + pointer_carry) & 0xFF
				_set_y(cpu, pointer_offset)
				var pointer_table_address := initial_stream_pointer + pointer_offset
				var pointer_low := _read_stream_byte(pointer_table_address)
				var pointer_high := _read_stream_byte(pointer_table_address + 1)
				if pointer_low != 0xC9 or pointer_high != 0xA3:
					return _unsupported("The live `$0629=0` F4 selector no longer resolves to `$A3C9`.")
				instruction_pcs.append(0x80DA)
				_read_event(source_reads, 0x80DA, pointer_table_address, pointer_low, "F4_target_pointer_low")
				_set_a(cpu, pointer_low)
				instruction_pcs.append(0x80DC)
				_set_x(cpu, int(cpu["a"]))
				instruction_pcs.append(0x80DD)
				_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
				instruction_pcs.append(0x80DE)
				_read_event(source_reads, 0x80DE, pointer_table_address + 1, pointer_high, "F4_target_pointer_high")
				_set_a(cpu, pointer_high)
				instruction_pcs.append(0x80E0)
				_write_ram(ram, ram_writes, 0x005F, pointer_low, 0x80E0)
				instruction_pcs.append(0x80E2)
				_write_ram(ram, ram_writes, 0x0060, pointer_high, 0x80E2)
				instruction_pcs.append(0x80E6)
				_write_ram(ram, ram_writes, 0x05E5, 0, 0x80E6)
				instruction_pcs.append(0x80E9)
				_rts(cpu, stack, stack_reads, 0x80E9)
				if int(cpu["pc"]) != 0x807D:
					return _unsupported("The F4 selector handler did not return to the source parser at `$807D`.")
				instruction_pcs.append(0x807D)
				instruction_pcs.append(0x806E)
				_set_y(cpu, int(ram[0x05E5]))
				_read_event(source_reads, 0x806E, 0x05E5, int(ram[0x05E5]), "actor_stream_index")
				_write_ram(ram, ram_writes, 0x05E5, (int(ram[0x05E5]) + 1) & 0xFF, 0x8071)
				stream_index = int(cpu["y"])
				stream_address = 0xA3C9 + stream_index
				stream_byte = _read_stream_byte(stream_address)
				if stream_byte != 0x01:
					return _unsupported("The selector-$03 stream's first post-F4 byte is no longer `$01`.")
				_read_event(source_reads, 0x8074, stream_address, stream_byte, "actor_stream_followup_delay")
				_set_a(cpu, stream_byte)
				instruction_pcs.append(0x8076)
				_compare_a(cpu, 0xF0)
			if stream_byte >= 0xF0 and not terminal_sequence_completed:
				return _unsupported("The live actor-stream command did not resolve to a delay byte.")
			if not terminal_sequence_completed:
				instruction_pcs.append(0x8078)
				instruction_pcs.append(0x8080)
				_write_ram(ram, ram_writes, 0x05E9, stream_byte, 0x8080)
				instruction_pcs.append(0x8083)
				_write_ram(ram, ram_writes, 0x05E4, (int(ram[0x05E4]) + 1) & 0xFF, 0x8083)
				_set_nz(cpu, int(ram[0x05E4]))
				instruction_pcs.append(0x8086)
				_rts(cpu, stack, stack_reads, 0x8086)
		elif handler == 0x8218:
			var stream_index := int(ram[0x05E5])
			_set_y(cpu, stream_index)
			_read_event(source_reads, 0x8218, 0x05E5, stream_index, "actor_event_stream_index")
			var stream_address := (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) + stream_index
			var event_byte := _read_stream_byte(stream_address)
			if event_byte < 0:
				return _unsupported("The live `$8218` stream pointer is outside the verified source spans.")
			_read_event(source_reads, 0x8218, stream_address, event_byte, "actor_event_byte")
			_set_a(cpu, event_byte)
			instruction_pcs.append(0x8218)
			instruction_pcs.append(0x821B)
			instruction_pcs.append(0x821D)
			_compare_a(cpu, 0x90)
			instruction_pcs.append(0x821F)
			if (int(cpu["p"]) & P_C) != 0:
				return _unsupported("The `$821F` BCS path reaches `$822E->$C52D`; its live behavior is not integrated.")
			instruction_pcs.append(0x8221)
			_set_a(cpu, event_byte & 0x0F)
			_set_nz(cpu, int(cpu["a"]))
			instruction_pcs.append(0x8223)
			_write_ram(ram, ram_writes, 0x05F3, int(cpu["a"]), 0x8223)
			instruction_pcs.append(0x8226)
			_set_a(cpu, 0x80)
			instruction_pcs.append(0x8228)
			_write_ram(ram, ram_writes, 0x05F4, 0x80, 0x8228)
			instruction_pcs.append(0x8234)
			var is_selector03_type2_event := stream_address == 0xA3CA and event_byte == 0x20
			var is_a439_type1_event := stream_address == 0xA43A and event_byte == 0x10
			var is_scenario1c_parameter58_type1_event := initial_stream_pointer == 0x9A62 \
					and stream_address == 0x9A63 and event_byte == 0x10 \
					and is_scenario1c_parameter58_dispatch_profile
			var is_type1_event := is_a439_type1_event or is_scenario1c_parameter58_type1_event
			if not is_selector03_type2_event and not is_type1_event:
				return _unsupported(
					"Godot reaches `$8218->$8234` with `$%02X` from `$%04X`; this " % [event_byte, stream_address]
					+ "does not match the muted FCEUX event reads `$20` at `$A3CA` "
					+ "or type-$01 `$10` at `$A43A`/`$9A63`. Resolve stream-pointer and tick alignment "
					+ "before advancing this route.")
			# `$8218->$8234` decodes both recorded cases through the ROM lookup and
			# pointer tables: selector-$03 type 2 and type-$01 event payloads.
			instruction_pcs.append(0x8234)
			_set_y(cpu, stream_index)
			_read_event(source_reads, 0x8234, stream_address, event_byte, "actor_event_payload_command")
			_set_a(cpu, event_byte)
			var event_type := (int(cpu["a"]) >> 4) & 0x0F
			_set_x(cpu, event_type)
			var event_value := _read_actor_event_source_byte(0x86B8 + event_type)
			if event_type != (1 if is_type1_event else 2) or event_value != 0x0E:
				return _unsupported("The ROM event type lookup no longer maps the observed event type to `$0E`.")
			_read_event(source_reads, 0x823B, 0x86B8 + event_type, event_value, "actor_event_type_value")
			_set_a(cpu, event_value)
			_write_ram(ram, ram_writes, 0x05E6, event_value, 0x823E)
			_set_a(cpu, event_type)
			_set_a(cpu, int(cpu["a"]) << 1)
			_push(cpu, stack, stack_writes, int(cpu["a"]), 0x8241, "PHA")
			_set_x(cpu, int(cpu["a"]))
			var pointer_address := 0x8DC2 + int(cpu["x"])
			var payload_low := _read_actor_event_source_byte(pointer_address)
			var payload_high := _read_actor_event_source_byte(pointer_address + 1)
			var expected_payload_address := 0x8E37 if is_type1_event else 0x8E94
			if payload_low != (expected_payload_address & 0xFF) \
					or payload_high != (expected_payload_address >> 8):
				return _unsupported("ROM `$8DC4/$8DC6` event pointer no longer resolves to the recorded payload stream.")
			_read_event(source_reads, 0x8245, pointer_address, payload_low, "actor_event_payload_pointer_low")
			_write_ram(ram, ram_writes, 0x0061, payload_low, 0x8248)
			_read_event(source_reads, 0x824A, pointer_address + 1, payload_high, "actor_event_payload_pointer_high")
			_write_ram(ram, ram_writes, 0x0062, payload_high, 0x824D)
			var payload_address := (payload_high << 8) | payload_low
			var payload := PackedByteArray()
			var payload_source_file := ACTOR_EVENT_PAYLOAD_TYPE1_FILE \
					if is_type1_event else ACTOR_EVENT_PAYLOAD_TYPE2_FILE
			var payload_source: PackedByteArray = _sources[payload_source_file]
			_set_y(cpu, 0)
			for payload_index in 3:
				_set_y(cpu, payload_index)
				var payload_byte := _read_actor_event_source_byte(payload_address + payload_index)
				if payload_byte != int(payload_source[payload_index]):
					return _unsupported("The selected ROM event payload differs from its verified three-byte source span.")
				_read_event(source_reads, 0x8251 + payload_index * 4, payload_address + payload_index,
					payload_byte, "actor_event_payload_byte_%d" % payload_index)
				_set_a(cpu, payload_byte)
				if payload_index < 2:
					_push(cpu, stack, stack_writes, payload_byte,
						0x8251 + payload_index * 4, "PHA")
				else:
					_write_ram(ram, ram_writes, 0x05E7, payload_byte, 0x825B)
				payload.append(payload_byte)
			_set_y(cpu, 0x03)
			_set_a(cpu, 0x06)
			_write_ram(ram, ram_writes, 0x05E8, 0x06, 0x8261)
			_set_a(cpu, 0x01)
			instruction_pcs.append(0x8266)
			cpu["pc"] = 0x8266
			callsite_registers = cpu.duplicate(true)
			callsite_stack = stack.duplicate()
			_jsr(cpu, stack, stack_writes, 0x8266, 0xC515)
			instruction_pcs.append(0xC515)
			var yield_jump_opcode := int(_sources[YIELD_TRAMPOLINE_FILE][0])
			if yield_jump_opcode != 0x4C:
				return _unsupported("The fixed task-yield trampoline no longer jumps from `$C515`.")
			_read_event(source_reads, 0xC515, 0xC515, yield_jump_opcode, "task_yield_dispatch_opcode")
			cpu["pc"] = 0xCB0F
			instruction_pcs.append(0xCB0F)
			var event_yield := _waiter_yield_result(boundary, entry_cpu, entry_ram, entry_stack,
				cpu, mapper, ram, stack, ram_writes, stack_writes, stack_reads,
				source_reads, instruction_pcs, callsite_registers, callsite_stack,
				0x8266, 0x8269, "slot11_actor_event_payload_at_cb0f")
			var event_span_hashes := {
				ACTOR_EVENT_DISPATCH_FILE: "ad89d4999241da3618d8c3c06822986cb9f0ba561683e112c5ce71f2b5b05bfb",
				ACTOR_EVENT_TYPE_TABLE_FILE: "76fb4484e771b7e9628dbf321e34ef11d1f953a164db859398e5b54f7fa6fa99",
				ACTOR_EVENT_POINTER_TABLE_FILE: "772bad1ed64aa4e9543211333c2f1213f88cd418ec117a66b4367bae89a33ea8",
				ACTOR_EVENT_PAYLOAD_TYPE1_FILE: "6d591cefc508d55b2022f08972e0eb34b31fa14d33e2ba0aa4b7fcb9f5c1ba35",
				ACTOR_EVENT_PAYLOAD_TYPE2_FILE: "6d591cefc508d55b2022f08972e0eb34b31fa14d33e2ba0aa4b7fcb9f5c1ba35",
				YIELD_TRAMPOLINE_FILE: "86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e",
			}
			if is_scenario1c_parameter58_type1_event:
				event_span_hashes[PARAMETER58_STREAM_FILE] = "15779004184bd0d73ede7e28bb543f63a92f64cc67a99cc49a4f14ec66d60274"
			else:
				event_span_hashes[ACTOR_EVENT_STREAM_FILE] = "d1f080bd08e18fbce24895ef9d11887febc6961d23f9b48bd271f56c7442fd1c"
			event_yield["source_span_hashes"] = event_span_hashes
			event_yield["decoded_event"] = {
				"address": stream_address, "byte": event_byte, "type": event_type,
				"type_value": event_value, "payload_address": payload_address,
				"payload": payload, "wait_counter": int(ram[0x05E8]),
			}
			return event_yield
		elif handler == 0x82F2:
			var is_parameter47_f2_index1_packet_wait := initial_stream_pointer == 0x9917 \
					and int(ram[0x05EA]) == 0x47 \
					and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
					and int(ram[0x05E5]) == 0x03 and int(ram[0x05E6]) == 0x0E \
					and int(ram[0x05E7]) == 0x01 and int(ram[0x05E8]) == 0x02 \
					and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x01 \
					and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x05 \
					and int(ram[0x0515]) == 0x00 \
					and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
					and int(ram[0x0629]) == 0x00 \
					and int(stack[0xC7]) == 0x67 and int(stack[0xC8]) == 0xF2 \
					and int(stack[0xC9]) == 0x4C and int(stack[0xCA]) == 0x80 \
					and int(boundary.get("a", -1)) == 0x24 \
					and int(boundary.get("x", -1)) == 0x24 \
					and int(boundary.get("y", -1)) == 0x24
			var is_parameter47_f2_index2_packet_wait := initial_stream_pointer == 0x9917 \
					and int(ram[0x05EA]) == 0x47 \
					and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x02, 0x06, 0x0E, 0x02, 0x02, 0x00]) \
					and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x03]) \
					and int(ram[0x0515]) == 0x00 \
					and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
					and int(ram[0x0022]) == 0x00 and int(ram[0x0629]) == 0x00 \
					and int(stack[0xC7]) == 0x67 and int(stack[0xC8]) == 0xF2 \
					and int(stack[0xC9]) == 0x4C and int(stack[0xCA]) == 0x80 \
					and int(boundary.get("a", -1)) == 0x05 \
					and int(boundary.get("x", -1)) == 0x05 \
					and int(boundary.get("y", -1)) == 0x05
			var is_a439_packet_wait := initial_stream_pointer == 0xA439 \
					and int(ram[0x05E4]) == 2 and int(ram[0x05E5]) == 2 \
					and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 1 \
					and int(ram[0x05E8]) == 2 and int(ram[0x05E9]) == 0 \
					and int(ram[0x05F4]) == 1 and int(ram[0x05F5]) == 5
			var is_scenario1c_parameter58_packet_wait := bool(
				valid.get("scenario1c_parameter58_packet_wait", false)) \
				or bool(valid.get("scenario1c_parameter58_followup_packet_wait", false))
			var is_a439_text_packet_wait_handler := initial_stream_pointer == 0xA439 \
					and int(ram[0x05E4]) == 2 and int(ram[0x05E5]) == 5 \
					and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 2 \
					and int(ram[0x05E8]) == 2 and int(ram[0x05E9]) == 0 \
					and int(ram[0x05F3]) == 0 and int(ram[0x05F4]) == 1 \
					and int(ram[0x05F5]) == 3
			var first_packet_wait := initial_stream_pointer == 0xA3C9 \
					and int(ram[0x05E4]) == 2 and int(ram[0x05E5]) == 2 \
					and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 0 \
					and int(ram[0x05E8]) == 2 and int(ram[0x05E9]) == 0 \
					and int(ram[0x05F4]) == 1 and int(ram[0x05F5]) == 5
			if not (is_selector03_sequence or is_scenario2e_actor6d_type5_packet_wait \
					or is_parameter47_f2_index1_packet_wait \
					or is_parameter47_f2_index2_packet_wait \
					or is_a439_packet_wait or is_scenario1c_parameter58_packet_wait \
					or is_a439_text_packet_wait_handler) \
					or not (is_scenario2e_actor6d_type5_packet_wait or first_packet_wait \
					or is_parameter47_f2_index1_packet_wait \
					or is_parameter47_f2_index2_packet_wait \
					or is_a439_packet_wait or is_scenario1c_parameter58_packet_wait \
					or is_a439_text_packet_wait_handler \
					or is_selector03_followup_packet_wait):
				return _unsupported("The `$82F2` packet-wait state is unsupported: index1=%s index2=%s stream=$%04X EA=$%02X E3:E9=%s F3:F5=%s animation=$%04X selector=$%02X stack[C7:CB]=%s A/X/Y=$%02X/$%02X/$%02X." % [
					str(is_parameter47_f2_index1_packet_wait), str(is_parameter47_f2_index2_packet_wait), initial_stream_pointer, int(ram[0x05EA]),
					ram.slice(0x05E3, 0x05EA).hex_encode(), ram.slice(0x05F3, 0x05F6).hex_encode(),
					int(ram[0x0063]) | (int(ram[0x0064]) << 8), int(ram[0x0629]),
					stack.slice(0xC7, 0xCC).hex_encode(), int(boundary.get("a", -1)),
					int(boundary.get("x", -1)), int(boundary.get("y", -1))])
			# The ROM row-2 handler is `LDA #$01; JSR $C515`. The real saved JSR
			# resumes at `$82F7`; queue polling and packet construction after that
			# resume are a separate source transition.
			instruction_pcs.append(0x82F2)
			for offset in 5:
				var source_address := 0x82F2 + offset
				var source_byte := _read_bank18(source_address)
				if source_byte != int(_sources[ANIMATION_PACKET_WAIT_FILE][offset]):
					return _unsupported("ROM `$82F2` packet-wait byte changed at `$%04X`." % source_address)
				_read_event(source_reads, 0x82F2, source_address, source_byte,
					"actor_packet_wait_rom_byte")
			_set_a(cpu, 0x01)
			instruction_pcs.append(0x82F4)
			cpu["pc"] = 0x82F4
			callsite_registers = cpu.duplicate(true)
			callsite_stack = stack.duplicate()
			_jsr(cpu, stack, stack_writes, 0x82F4, 0xC515)
			instruction_pcs.append(0xC515)
			var yield_opcode := int(_sources[YIELD_TRAMPOLINE_FILE][0])
			if yield_opcode != 0x4C or int(cpu["sp"]) != 0xC6 \
					or int(stack[0xC7]) != 0xF6 or int(stack[0xC8]) != 0x82:
				return _unsupported("ROM `$82F4->$C515` did not preserve the traced `$82F7` continuation frame.")
			_read_event(source_reads, 0xC515, 0xC515, yield_opcode, "task_yield_dispatch_opcode")
			cpu["pc"] = 0xCB0F
			var packet_wait_yield := _waiter_yield_result(boundary, entry_cpu,
				entry_ram, entry_stack, cpu, mapper, ram, stack, ram_writes,
				stack_writes, stack_reads, source_reads, instruction_pcs,
				callsite_registers, callsite_stack, 0x82F4, 0x82F7,
				"slot11_actor_scenario2e_actor6d_type5_packet_wait_at_cb0f" \
					if is_scenario2e_actor6d_type5_packet_wait \
					else "slot11_actor_packet_wait_at_cb0f")
			packet_wait_yield["source_span_hashes"] = {
				WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
				ANIMATION_PACKET_WAIT_FILE: "66dd891f98da1e60546ec6ee4b58ef81d3c1c55a43af989117504566178c06d1",
				YIELD_TRAMPOLINE_FILE: "86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e",
				INLINE_DISPATCH_FILE: INLINE_DISPATCH_SHA256,
				TRAMPOLINE_FILE: TRAMPOLINE_SHA256,
			}
			if is_scenario2e_actor6d_type5_packet_wait:
				packet_wait_yield["source_span_hashes"][PARAMETER6D_STREAM_FILE] = \
					"0b787ded174d6496196c978f5b835c4e89c9858a8499617b02bacc5b3f7b7d1e"
			return packet_wait_yield
		else:
			return _unsupported("The live actor-stream dispatch selected unsupported handler `$%04X` for index `$%02X`." % [handler, int(ram[0x05E4])])
	elif not terminal_sequence_completed:
		instruction_pcs.append(0x805E)
		var next_delay := (int(ram[0x05E9]) - 1) & 0xFF
		_write_ram(ram, ram_writes, 0x05E9, next_delay, 0x805E)
		_set_nz(cpu, next_delay)
		instruction_pcs.append(0x8061)
		_rts(cpu, stack, stack_reads, 0x8061)
	if int(cpu["pc"]) != 0x804D or int(cpu["sp"]) != 0xCA:
		return _unsupported("The `$8053` countdown RTS did not return to `$804D`.")

	# `$804D->$C560->$CF72` selects `$1A/$1B`, then the ROM animation gate.
	instruction_pcs.append(0x804D)
	_jsr(cpu, stack, stack_writes, 0x804D, 0xC560)
	_read_event(source_reads, 0xC560, 0xC560, 0x4C, "fixed_call_stub_opcode")
	cpu["pc"] = 0xCF72
	instruction_pcs.append(0xCF72)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCF72, "PHA")
	instruction_pcs.append(0xCF73)
	_set_a(cpu, int(ram[0x0022]))
	_read_event(source_reads, 0xCF73, 0x0022, int(ram[0x0022]), "mapper_shadow")
	instruction_pcs.append(0xCF75)
	_set_a(cpu, 0x1A)
	instruction_pcs.append(0xCF77)
	_write_ram(ram, ram_writes, 0x0024, 0x1A, 0xCF77)
	instruction_pcs.append(0xCF79)
	_set_a(cpu, 0x1B)
	instruction_pcs.append(0xCF7B)
	_write_ram(ram, ram_writes, 0x0025, 0x1B, 0xCF7B)
	instruction_pcs.append(0xCF7D)
	_jsr(cpu, stack, stack_writes, 0xCF7D, 0xCE2D)
	_apply_animation_mapper_helper(ram, mapper, ram_writes, mapper_writes,
		source_reads, instruction_pcs)
	_rts(cpu, stack, stack_reads, 0xCE49)
	if int(cpu["pc"]) != 0xCF80:
		return _unsupported("The first `$CE2D` helper call did not return to `$CF80`.")
	instruction_pcs.append(0xCF80)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0xCF80))
	instruction_pcs.append(0xCF81)
	_jsr(cpu, stack, stack_writes, 0xCF81, 0x802A)
	instruction_pcs.append(0x802A)
	cpu["pc"] = 0xA1EB
	instruction_pcs.append(0xA1EB)
	_set_a(cpu, int(ram[0x05F4]))
	_read_event(source_reads, 0xA1EB, 0x05F4, int(ram[0x05F4]), "animation_gate_mode")
	if (is_selector03_sequence or is_scenario2e_actor6d_9bfe_delay_tick \
			or is_a439_initial_delay or is_a439_delay_countdown \
			or is_a439_post_packet_delay or is_a439_text_packet_wait \
			or is_a439_text_post_packet_delay or is_a439_inactive_zero_mode_resume \
			or is_scenario1e_actor58_inactive_zero_mode_resume \
			or is_scenario1c_f0_inactive_zero_mode_resume \
			or is_scenario1c_parameter58_initial_delay \
			or is_scenario1c_parameter58_countdown \
			or is_scenario1c_parameter58_followup_post_packet_delay) \
			and int(ram[0x05F4]) == 0:
		# ROM `$A1EB` returns immediately when the sequence animation mode is
		# zero; the wrapper then restores banks and reaches `$8047`.
		instruction_pcs.append(0xA1EE)
		instruction_pcs.append(0xA1F0)
		_rts(cpu, stack, stack_reads, 0xA1F0)
	else:
		if int(cpu["a"]) != 1:
			return _unsupported("The repeated animation gate is not in positive `$05F4` mode.")
		instruction_pcs.append(0xA1EE)
		instruction_pcs.append(0xA1F1)
		if (int(cpu["p"]) & P_N) != 0:
			return _unsupported("The animation gate takes the negative `$05F4` setup path.")
		instruction_pcs.append(0xA20C)
		_set_a(cpu, int(ram[0x05F5]))
		_read_event(source_reads, 0xA20C, 0x05F5, int(ram[0x05F5]), "animation_wait_counter")
		if int(cpu["a"]) == 0:
			if not is_selector03_row02_animation_gate and not is_selector03_terminal_inactive_gate \
					and not is_a439_text_terminal_inactive_gate \
						and not is_scenario1c_parameter58_followup_text_terminal_inactive_gate \
					and not is_parameter47_f2_text_terminal_inactive_gate \
					and not is_parameter47_f2_inactive_zero_counter_gate \
					and not is_parameter47_f2_post_packet_zero_counter_gate \
					and not is_a439_inactive_zero_counter_gate \
					and not is_selector03_terminal_inactive_packet_gate \
					and not is_scenario1c_parameter58_zero_counter_queue_busy_gate \
					and not is_scenario1e_actor58_zero_counter_gate:
				return _unsupported("The animation counter reached the `$A215` yield branch outside the traced selector-$03 row-$02 state.")
			instruction_pcs.append(0xA20F)
			instruction_pcs.append(0xA215)
			var gate_prefix: PackedByteArray = _sources[ANIMATION_GATE_FILE]
			var gate_offset := 0xA215 - 0xA1EB
			if gate_prefix.slice(gate_offset, gate_offset + 5) != PackedByteArray([0xA9, 0x01, 0x20, 0x15, 0xC5]):
				return _unsupported("The ROM `$A215->$A217` animation-gate yield bytes changed.")
			_read_event(source_reads, 0xA215, 0xA215, 0xA9, "animation_gate_yield_opcode")
			_read_event(source_reads, 0xA215, 0xA216, 0x01, "animation_gate_yield_value")
			_set_a(cpu, 0x01)
			cpu["pc"] = 0xA217
			instruction_pcs.append(0xA217)
			_read_event(source_reads, 0xA217, 0xA217, 0x20, "animation_gate_yield_jsr_opcode")
			_read_event(source_reads, 0xA217, 0xA218, 0x15, "animation_gate_yield_jsr_low")
			_read_event(source_reads, 0xA217, 0xA219, 0xC5, "animation_gate_yield_jsr_high")
			callsite_registers = cpu.duplicate(true)
			callsite_stack = stack.duplicate()
			_jsr(cpu, stack, stack_writes, 0xA217, 0xC515)
			if int(cpu["sp"]) != 0xC4 or int(stack[0xC5]) != 0x19 or int(stack[0xC6]) != 0xA2:
				return _unsupported("The `$A217->$C515` selector-$03 gate did not save the traced `$A21A` return frame.")
			var trampoline_opcode := int(_sources[YIELD_TRAMPOLINE_FILE][0])
			if trampoline_opcode != 0x4C:
				return _unsupported("The fixed `$C515` task trampoline is not a JMP.")
			_read_event(source_reads, 0xC515, 0xC515, trampoline_opcode, "task_yield_dispatch_opcode")
			cpu["pc"] = 0xCB0F
			instruction_pcs.append(0xCB0F)
			var cb0f_registers := cpu.duplicate(true)
			var gate_output_ram := ram.duplicate()
			for stack_offset in STACK_SIZE:
				gate_output_ram[0x0100 + stack_offset] = stack[stack_offset]
			return {
				"ok": true,
				"status": "slot11_actor_parameter47_f2_post_packet_zero_counter_gate_at_cb0f_from_a217" \
					if is_parameter47_f2_post_packet_zero_counter_gate \
					else "slot11_f5_animation_gate_at_cb0f_from_a217",
				"rom_sha256": ROM_SHA256,
				"source_manifest": MANIFEST_PATH,
				"source_span_hashes": {
					WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
					F4_SELECTOR03_TABLE_FILE: "1d5435b3ff8bf70f3978c927fcd1d49051ff7254a724f0b27aa2585fd3cc6de8",
					SEQUENCE_ROW_HANDLER_FILE: "e05d702a76bbdb1c18f36ac1523b9b7b5eb0bacd791953b61da2e1dd41fc75f6",
					STREAM_EVENT_DISPATCH_FILE: "a46488bd47acb67282e03aa63e4111b7efc1677dc8f10dc52e90a2d80ae7aa5c",
					STREAM_SHORT_EVENT_FILE: "7e59d0713a7eb14d55dcca569ff75b2e6fea37d394fa72531eabcfabe4c106be",
					STREAM_FOLLOWUP_FILE: "79be558cb1fe9bfbf950a23486ed0da89c1dc37e20daa52feed8f6a124225fe4",
					ACTOR_EVENT_STREAM_FILE: "d1f080bd08e18fbce24895ef9d11887febc6961d23f9b48bd271f56c7442fd1c",
					C560_STUB_FILE: "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc",
					CF72_WRAPPER_FILE: "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13",
					BANK1A_ENTRY_FILE: "d8ec35aefd2671a7a810a2fa342db297bfb35011862ec3b907aa09fced64da90",
					ANIMATION_GATE_FILE: "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618",
					"fixed_mapper_helper_CE2D_CE49.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
				},
				"slot_base": SLOT_11,
				"entry_pc": int(entry_cpu["pc"]), "exit_pc": int(cpu["pc"]),
				"yield_callsite_pc": 0xA217, "yield_target_pc": 0xCB0F,
				"resume_pc_after_rts": 0xA21A,
				"entry_record": PackedByteArray(boundary["record"]),
				"entry_registers": entry_cpu, "entry_ram_image": entry_ram,
				"entry_stack_page": entry_stack,
				"call_frame_already_pushed": true,
				"pre_jsr_sp": int(callsite_registers["sp"]),
				"yield_callsite_registers": callsite_registers,
				"yield_callsite_stack_page": callsite_stack,
				"cb0f_entry_registers": cb0f_registers,
				"mapper": mapper, "initial_mapper": initial_mapper,
				"ram_image": gate_output_ram, "stack_page": stack,
				"ram_writes": ram_writes, "stack_writes": stack_writes,
				"stack_reads": stack_reads, "mapper_writes": mapper_writes,
				"source_reads": source_reads, "instruction_pcs": instruction_pcs,
				"ppu_bus_events": [], "apu_register_writes": [],
				"trace_state_used": false, "ppu_apu_effects_applied": false,
				"source_timing_modeled": false,
			}
		instruction_pcs.append(0xA20F)
		instruction_pcs.append(0xA211)
		var next_animation_wait := (int(ram[0x05F5]) - 1) & 0xFF
		_write_ram(ram, ram_writes, 0x05F5, next_animation_wait, 0xA211)
		_set_nz(cpu, next_animation_wait)
		instruction_pcs.append(0xA214)
		_rts(cpu, stack, stack_reads, 0xA214)
	if int(cpu["pc"]) != 0xCF84:
		return _unsupported("The animation counter RTS did not return to `$CF84`.")

	# The wrapper restores `$18/$19` and its final mapper-helper RTS returns to `$804F`.
	instruction_pcs.append(0xCF84)
	_set_a(cpu, 0x18)
	instruction_pcs.append(0xCF86)
	_write_ram(ram, ram_writes, 0x0024, 0x18, 0xCF86)
	instruction_pcs.append(0xCF88)
	_set_a(cpu, 0x19)
	instruction_pcs.append(0xCF8A)
	_write_ram(ram, ram_writes, 0x0025, 0x19, 0xCF8A)
	_apply_animation_mapper_helper(ram, mapper, ram_writes, mapper_writes,
		source_reads, instruction_pcs)
	_rts(cpu, stack, stack_reads, 0xCE49)
	if int(cpu["pc"]) != 0x8050 or int(cpu["sp"]) != 0xCA \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19:
		return _unsupported("The wrapper did not restore `$18/$19` and return to `$8050`.")
	instruction_pcs.append(0x8050)
	cpu["pc"] = 0x8045
	instruction_pcs.append(0x8045)
	_set_a(cpu, 0x01)
	cpu["pc"] = 0x8047
	instruction_pcs.append(0x8047)
	var output_ram := ram.duplicate()
	for offset in STACK_SIZE:
		output_ram[0x0100 + offset] = stack[offset]
	return {
		"ok": true,
		"status": "slot11_actor_scenario1e_actor58_animation_countdown_at_8047" if is_scenario1e_actor58_animation_countdown \
			else "slot11_actor_scenario1e_actor58_inactive_zero_mode_resume_at_8047" if is_scenario1e_actor58_inactive_zero_mode_resume \
			else "slot11_actor_scenario1c_parameter58_terminal_animation_countdown_at_8047" if is_scenario1c_parameter58_terminal_animation_countdown \
			else "slot11_actor_scenario1c_parameter58_followup_text_terminal_at_8047" if is_scenario1c_parameter58_followup_text_terminal_command \
			else "slot11_actor_parameter47_f2_text_terminal_at_8047" if is_parameter47_f2_text_terminal_command \
			else "slot11_actor_scenario1c_f0_inactive_zero_mode_resume_at_8047" if is_scenario1c_f0_inactive_zero_mode_resume \
			else "slot11_actor_scenario1c_parameter58_followup_post_packet_delay_at_8047" if is_scenario1c_parameter58_followup_post_packet_delay \
			else "slot11_actor_scenario1c_parameter58_post_packet_delay_at_8047" if is_scenario1c_parameter58_post_packet_delay \
			else "slot11_actor_scenario1c_parameter58_countdown_at_8047" if is_scenario1c_parameter58_countdown \
			else "slot11_actor_scenario1c_parameter58_delay_at_8047" if is_scenario1c_parameter58_initial_delay \
			else "slot11_actor_scenario2e_actor6d_9bfe_delay_at_8047" \
			if is_scenario2e_actor6d_9bfe_delay_tick \
			else "slot11_actor_rom_stream_delay_at_8047" \
			if is_a439_initial_delay or is_a439_delay_countdown or is_a439_post_packet_delay \
					or is_a439_text_post_packet_delay or is_a439_text_terminal_command \
					or is_a439_inactive_zero_mode_resume \
			else "slot11_actor_parameter47_f2_followup_delay_tick_at_8047" if is_parameter47_f2_followup_delay_tick \
			else "slot11_actor_parameter47_f2_post_packet_animation_countdown_at_8047" if is_parameter47_f2_post_packet_animation_countdown \
			else "slot11_actor_parameter47_f2_animation_script_countdown_at_8047" if is_parameter47_f2_animation_script_countdown \
			else "slot11_actor_parameter47_f2_animation_countdown_at_8047" if is_parameter47_f2_animation_countdown_tick \
			else "slot11_actor_parameter47_f2_delay_tick_at_8047" if is_parameter47_f2_delay_tick \
			else "slot11_actor_sequence_selector03_delay_at_8047" if is_selector03_sequence \
			else "slot11_f5_animation_countdown_at_8047",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"source_span_hashes": {
			WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
			PARAMETER58_STREAM_FILE: "15779004184bd0d73ede7e28bb543f63a92f64cc67a99cc49a4f14ec66d60274",
			F4_SELECTOR03_TABLE_FILE: "1d5435b3ff8bf70f3978c927fcd1d49051ff7254a724f0b27aa2585fd3cc6de8",
			SEQUENCE_ROW_HANDLER_FILE: "e05d702a76bbdb1c18f36ac1523b9b7b5eb0bacd791953b61da2e1dd41fc75f6",
			STREAM_EVENT_DISPATCH_FILE: "a46488bd47acb67282e03aa63e4111b7efc1677dc8f10dc52e90a2d80ae7aa5c",
			STREAM_SHORT_EVENT_FILE: "7e59d0713a7eb14d55dcca569ff75b2e6fea37d394fa72531eabcfabe4c106be",
			STREAM_FOLLOWUP_FILE: "79be558cb1fe9bfbf950a23486ed0da89c1dc37e20daa52feed8f6a124225fe4",
			ACTOR_EVENT_STREAM_FILE: "d1f080bd08e18fbce24895ef9d11887febc6961d23f9b48bd271f56c7442fd1c",
			ACTOR_EVENT_STREAM_TEXT_FILE: "8368859c91cb9632996f9674b98d47b90d23e5e58f4a084fb972e82d57eaab70",
			C560_STUB_FILE: "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc",
			CF72_WRAPPER_FILE: "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13",
			BANK1A_ENTRY_FILE: "d8ec35aefd2671a7a810a2fa342db297bfb35011862ec3b907aa09fced64da90",
			ANIMATION_GATE_FILE: "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618",
			"fixed_mapper_helper_CE2D_CE49.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
		},
		"slot_base": SLOT_11,
		"entry_pc": int(entry_cpu["pc"]),
		"exit_pc": int(cpu["pc"]),
		"yield_callsite_pc": 0x8047,
		"yield_target_pc": 0xCB0F,
		"resume_pc_after_rts": 0x804A,
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"call_frame_already_pushed": false,
		"pre_jsr_sp": int(cpu["sp"]),
		"yield_callsite_registers": cpu.duplicate(true),
		"yield_callsite_stack_page": stack.duplicate(),
		"mapper": mapper,
		"initial_mapper": initial_mapper,
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"mapper_writes": mapper_writes,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"trace_state_used": false,
		"ppu_apu_effects_applied": false,
		"source_timing_modeled": false,
	}


func _run_match_index_selector(cpu: Dictionary, ram: PackedByteArray,
		source_reads: Array[Dictionary], instruction_pcs: Array[int]) -> int:
	# ROM `$8122-$8130`: X starts at zero and advances only while `$0026`
	# exceeds the indexed threshold byte. The match-zero trace uses the first row.
	instruction_pcs.append(0x8122)
	_set_x(cpu, 0)
	var match_index := int(ram[0x0026])
	instruction_pcs.append(0x8124)
	_read_event(source_reads, 0x8124, 0x0026, match_index, "match_index")
	_set_a(cpu, match_index)
	for row in 7:
		var threshold := int(_sources[SELECTOR_FILE][15 + row])
		instruction_pcs.append(0x8126)
		_read_event(source_reads, 0x8126, 0x8131 + row, threshold, "match_index_threshold")
		_compare_a(cpu, threshold)
		instruction_pcs.append(0x8129)
		if match_index < threshold:
			return int(cpu["x"])
		instruction_pcs.append(0x812B)
		if match_index == threshold:
			return int(cpu["x"])
		_set_x(cpu, (int(cpu["x"]) + 1) & 0xFF)
	return int(cpu["x"])


func _inline_dispatch(cpu: Dictionary, ram: PackedByteArray,
		stack: PackedByteArray, ram_writes: Array[Dictionary],
		stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		source_reads: Array[Dictionary], call_pc: int, table_base: int,
		instruction_pcs: Array[int]) -> int:
	# The callsite's JSR $C509 has already pushed its return word.
	instruction_pcs.append(0xCB99)
	var prior_a := int(cpu["a"]) & 0xFF
	_set_flag(cpu, P_C, (prior_a & 0x80) != 0)
	_set_a(cpu, (prior_a << 1) & 0xFF)
	_set_y(cpu, int(cpu["a"]))
	var return_low := _pop(cpu, stack, stack_reads, 0xCB9B)
	_write_ram(ram, ram_writes, 0x0036, return_low, 0xCB9C)
	var return_high := _pop(cpu, stack, stack_reads, 0xCB9E)
	_write_ram(ram, ram_writes, 0x0037, return_high, 0xCBA0)
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_index := int(cpu["y"])
	var vector_low := _read_bank18(table_base + vector_index - 1)
	if vector_low < 0:
		return -1
	_read_event(source_reads, 0xCBA2, table_base + vector_index - 1, vector_low, "inline_vector_low")
	_set_a(cpu, vector_low)
	_push(cpu, stack, stack_writes, int(cpu["a"]), 0xCBA2, "PHA")
	_set_y(cpu, (int(cpu["y"]) + 1) & 0xFF)
	var vector_high := _read_bank18(table_base + int(cpu["y"]) - 1)
	if vector_high < 0:
		return -1
	_read_event(source_reads, 0xCBA6, table_base + int(cpu["y"]) - 1, vector_high, "inline_vector_high")
	_set_a(cpu, vector_high)
	_write_ram(ram, ram_writes, 0x0037, int(cpu["a"]), 0xCBA8)
	_set_a(cpu, _pop(cpu, stack, stack_reads, 0xCBAA))
	_write_ram(ram, ram_writes, 0x0036, int(cpu["a"]), 0xCBAB)
	var target := int(ram[0x0036]) | (int(ram[0x0037]) << 8)
	if target not in [0x806E, 0x8098, 0x80B5, 0x80CB, 0x8106, 0x810E, 0x811E, 0x8122, 0x81FD, 0x8218, 0x82F2]:
		return -1
	cpu["pc"] = target
	return target


func _validate_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x804A \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not the live dispatched slot-$11 `$804A` continuation."}
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or int(ram[0x0000]) != SLOT_11:
		return {"ok": false, "reason": "The live slot-$11 scheduler record or restored RAM/stack is unsupported."}
	var stream_pointer := int(ram[0x005F]) | (int(ram[0x0060]) << 8)
	var parameter47_boundary := stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and int(stack[0xC7]) == 0x8F and int(stack[0xC8]) == 0x17 \
			and int(boundary.get("a", -1)) == 0x17 \
			and int(boundary.get("x", -1)) == 0x17 \
			and int(boundary.get("y", -1)) == 0x8F
	# PASS's animation-index-$01 stream is a sequence of `$05,index` pairs at
	# `$A2CB-$A2E4`, followed by the `$A2E5` loop marker. During each F5 wait,
	# the cursor points to the next pair/marker while `$9917` and the return frame stay live.
	var parameter47_f2_post_packet_animation_countdown: bool = stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and int(ram[0x05F3]) == 0x01 and int(ram[0x05F4]) == 0x01 \
			and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0063]) in [0xD1, 0xD3, 0xD5, 0xD7, 0xD9, 0xDB, 0xDD, 0xDF, 0xE1, 0xE3, 0xE5] and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04
	# The PASS callback-$1F source seed installs actor parameter `$00` at
	# `$9400`; this is the resulting first live worker dispatch, after the
	# `$30->$2F` scenario wait tick. Pin its RAM, animation, stack, and registers.
	var scenario1c_parameter00_boundary: bool = stream_pointer == 0x9400 \
			and int(ram[0x05EA]) == 0x00 \
			and _is_scenario1c_actor00_live_worker_profile(ram) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x00, 0x0E, 0x02, 0x02, 0x00, 0x00]) \
			and ram.slice(0x05F4, 0x05F6) == PackedByteArray([0x00, 0x01]) \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(ram[0x0063]) == 0xD7 and int(ram[0x0064]) == 0xA2 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x01, 0x00, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x00 \
			and int(boundary.get("x", -1)) == 0x00 \
			and int(boundary.get("y", -1)) == 0x01
	var scenario1c_callback63_parameter58_boundary := stream_pointer == 0x9A62 \
			and (_is_scenario1c_callback63_parameter58_live_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_countdown_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_stream_dispatch_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_post_packet_delay_worker_profile(ram, stack, boundary))
	var scenario2e_callback36_map2f_parameter6d_boundary: bool = stream_pointer == 0x9BE3 \
			and int(ram[0x05EA]) == 0x6D \
			and (_is_scenario2e_callback36_map2f_actor6d_live_worker_profile(ram, stack, boundary) \
			or _is_scenario2e_callback36_map2f_actor6d_f2_waiter_entry_profile(ram, stack, boundary))
	var parameter73_boundary := stream_pointer == 0x9F42 \
			and int(stack[0xC7]) == 0xE7 and int(stack[0xC8]) == 0x42 \
			and int(boundary.get("a", -1)) == 0x42 \
			and int(boundary.get("x", -1)) == 0x42 \
			and int(boundary.get("y", -1)) == 0xE7
	var selector03_boundary := stream_pointer == 0xA3BD \
			and int(stack[0xC7]) == 0xE9 and int(stack[0xC8]) == 0xBD \
			and int(boundary.get("a", -1)) == 0xBD \
			and int(boundary.get("x", -1)) == 0xBD \
			and int(boundary.get("y", -1)) == 0xE9
	var selector03_event_boundary := stream_pointer == 0xA3C9 \
			and int(stack[0xC7]) == 0x00 and int(stack[0xC8]) == 0xC9 \
			and int(boundary.get("a", -1)) == 0xC9 \
			and int(boundary.get("x", -1)) == 0xC9 \
			and int(boundary.get("y", -1)) == 0x00
	var a439_initial_delay_entry := stream_pointer == 0xA439 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x00 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0xEB and int(stack[0xC8]) == 0x39 \
			and int(boundary.get("a", -1)) == 0x39 \
			and int(boundary.get("x", -1)) == 0x39 \
			and int(boundary.get("y", -1)) == 0xEB
	var a439_post_packet_delay_entry := stream_pointer == 0xA439 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
			and int(ram[0x05E5]) == 0x05 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x04 \
			and int(ram[0x0515]) == 0x00 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x05 \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x04
	var a439_text_packet_wait_entry := stream_pointer == 0xA439 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
			and int(ram[0x05E5]) == 0x05 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x03 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x05 \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x04
	var a439_text_post_packet_delay_entry := stream_pointer == 0xA439 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0D and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x02 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x06 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A
	var a439_text_terminal_entry := stream_pointer == 0xA439 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0D and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x01 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x06 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A
	var selector03_terminal_inactive_gate := stream_pointer == 0xA3C9 \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x02 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB2 and int(ram[0x0064]) == 0xA2
	var a439_text_terminal_inactive_gate := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x06 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x02 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0E and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB2 and int(ram[0x0064]) == 0xA2
	var scenario1c_parameter58_followup_text_terminal_inactive_gate: bool = stream_pointer == 0x9A62 \
			and int(ram[0x05EA]) == 0x58 \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x00]) \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x02, 0x06, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x02
	var selector03_terminal_inactive_packet_gate := stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) == 0x00 \
			and ((int(ram[0x0063]) in [0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6] \
				and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
				and int(boundary.get("a", -1)) == 0x04 \
				and int(boundary.get("x", -1)) == 0x04 \
				and int(boundary.get("y", -1)) == 0x04) \
			or (int(ram[0x0063]) == 0xC8 and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
				and int(boundary.get("a", -1)) == 0x24 \
				and int(boundary.get("x", -1)) == 0x24 \
				and int(boundary.get("y", -1)) == 0x24))
	var selector03_animation_tail_idle := stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
			and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x24
	var selector03_terminal_inactive_packet_countdown := stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and ((int(ram[0x0063]) in [0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6] \
				and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
				and int(boundary.get("a", -1)) == 0x04 \
				and int(boundary.get("x", -1)) == 0x04 \
				and int(boundary.get("y", -1)) == 0x04) \
			or (int(ram[0x0063]) == 0xC8 and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
				and int(boundary.get("a", -1)) == 0x24 \
				and int(boundary.get("x", -1)) == 0x24 \
				and int(boundary.get("y", -1)) == 0x24))
	if int(stack[0xC9]) != 0x49 or int(stack[0xCA]) != 0x80 \
				or not (parameter47_boundary or scenario1c_parameter00_boundary \
				or scenario1c_callback63_parameter58_boundary \
				or scenario2e_callback36_map2f_parameter6d_boundary \
				or parameter73_boundary or selector03_boundary or selector03_event_boundary \
				or a439_initial_delay_entry or a439_post_packet_delay_entry \
				or a439_text_packet_wait_entry \
				or a439_text_post_packet_delay_entry \
				or a439_text_terminal_entry \
				or scenario1c_parameter58_followup_text_terminal_inactive_gate \
				or is_scenario1e_actor58_inactive_zero_mode_resume_boundary(boundary) \
				or parameter47_f2_post_packet_animation_countdown \
				or selector03_terminal_inactive_gate \
				or selector03_terminal_inactive_packet_gate or selector03_animation_tail_idle \
				or selector03_terminal_inactive_packet_countdown):
		var record_hex := (record as PackedByteArray).hex_encode() if record is PackedByteArray else "invalid"
		var animation_pointer := int(ram[0x0063]) | (int(ram[0x0064]) << 8)
		return {"ok": false, "reason": "The slot-$11 continuation does not match a verified saved context: record=%s stream=$%04X animation=$%04X A/X/Y=$%02X/$%02X/$%02X stack[C7:CB]=%s RAM[E3:EB]=%s F4/F5=%s queue=$%02X row=$%02X." % [
			record_hex, stream_pointer, animation_pointer,
			int(boundary.get("a", -1)), int(boundary.get("x", -1)),
			int(boundary.get("y", -1)), stack.slice(0xC7, 0xCB).hex_encode(),
			(ram as PackedByteArray).slice(0x05E3, 0x05EB).hex_encode(),
			(ram as PackedByteArray).slice(0x05F4, 0x05F6).hex_encode(),
			int((ram as PackedByteArray)[0x0515]), int((ram as PackedByteArray)[0x0629])]}
	for stack_offset in STACK_SIZE:
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return {"ok": false, "reason": "The scheduler RAM image and stack-page snapshot disagree at `$%02X`." % stack_offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The scheduler boundary omits a valid CPU status value and known-bit mask."}
	return {"ok": true}


## Identifies the repeated scenario-$2E actor-$6D `$F2` waiter signature. The
## scheduler calls this on the saved `$CB0F` boundary; the waiter executor calls
## it again after dispatch restores the `$CC53` CPU context.
func is_scenario2e_callback36_map2f_actor6d_f2_waiter_resume_candidate(
		boundary: Dictionary) -> bool:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC1, 0x18, 0x19]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE:
		return false
	var wait_count := int(stack[0xC6])
	var initial_count_registers := wait_count == 0x06 \
			and int(boundary.get("x", -1)) == 0xE3 and int(boundary.get("y", -1)) == 0x06 \
			and int(boundary.get("a", -1)) in [0x01, 0xE3]
	var packet_count_registers := wait_count >= 0 and wait_count < 0x06 \
			and int(boundary.get("x", -1)) == 0x4F and int(boundary.get("y", -1)) == 0x00 \
			and int(boundary.get("a", -1)) in [0x01, 0x4F]
	var saved_boundary := int(boundary.get("phase", -1)) == 3 \
			and int(boundary.get("pc", -1)) == 0xCB0F \
			and int(boundary.get("sp", -1)) == 0xC1 \
			and int(boundary.get("pending_resume", -1)) == 2
	var dispatched_boundary := int(boundary.get("phase", -1)) == 2 \
			and int(boundary.get("pc", -1)) == 0xCC53 \
			and int(boundary.get("sp", -1)) == 0xC5 \
			and int(boundary.get("active_task_slot", -1)) == SLOT_11
	return (saved_boundary or dispatched_boundary) \
		and int(boundary.get("ready_delay", -1)) == 0 \
		and int(stack[0xC2]) == int(boundary.get("y", -1)) \
		and int(stack[0xC3]) == int(boundary.get("x", -1)) \
		and int(ram[0x0519]) == 0x70 + wait_count \
		and ram.slice(0x0516, 0x0517) == PackedByteArray([0x01]) \
		and ram.slice(0x0518, 0x051D) == PackedByteArray([0x2E, 0x70 + wait_count, 0xE8, 0x9B, 0x00]) \
		and int(ram[0x0522]) == 0x00 and int(ram[0x052B]) == 0x00 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x78, 0x36, 0x02, 0x3C, 0x4A, 0x8B, 0x6D, 0x00]) \
		and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x005D, 0x0061) == PackedByteArray([0x53, 0xB7, 0xE3, 0x9B]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x01, 0x01, 0x2F, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
		and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x6D]) \
		and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
		and ram.slice(0x0063, 0x0065) == PackedByteArray([0xBA, 0xA2]) \
		and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
		and int(ram[0x0629]) == 0x00 \
		and stack.slice(0xC4, 0xC9) == PackedByteArray([0x52, 0xCC, wait_count, 0x7C, 0x80]) \
		and stack.slice(0xC9, 0xCB) == PackedByteArray([0x4C, 0x80]) \
		and (initial_count_registers or packet_count_registers)


func _validate_waiter_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0xCC53 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not a live scheduler-dispatched slot-$11 `$CC53` waiter continuation."}
	if not record is PackedByteArray \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or int(ram[0x0000]) != SLOT_11:
		return {"ok": false, "reason": "The live slot-$11 `$CC53` record, return frame, or stack-resident packet count is unsupported."}
	var f2_wait_counter := int(stack[0xC6]) if stack is PackedByteArray and stack.size() == STACK_SIZE else -1
	var f2_initial_count_profile := f2_wait_counter == 0x06 \
		and int(boundary.get("x", -1)) == 0x17 and int(boundary.get("y", -1)) == 0x06
	var f2_packet_count_profile := f2_wait_counter >= 0 and f2_wait_counter < 0x06 \
		and int(boundary.get("x", -1)) == 0x4F and int(boundary.get("y", -1)) == 0x00
	var parameter47_f2_waiter: bool = record == PackedByteArray([0x00, 0xC1, 0x18, 0x19]) \
		and int(boundary.get("sp", -1)) == 0xC5 \
		and int(ram[0x05EA]) == 0x47 \
		and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9917 \
		and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
		and int(ram[0x05E5]) == 0x01 \
		and int(stack[0xC4]) == 0x52 and int(stack[0xC5]) == 0xCC \
		and int(stack[0xC7]) == 0x7C and int(stack[0xC8]) == 0x80 \
		and (f2_initial_count_profile or f2_packet_count_profile)
	var scenario1c_wait_count := int(stack[0xC6])
	var scenario1c_wait_registers := \
		(scenario1c_wait_count == 0x06 \
			and int(boundary.get("a", -1)) == 0x00 \
			and int(boundary.get("x", -1)) == 0x00 \
			and int(boundary.get("y", -1)) == 0x06) \
		or (scenario1c_wait_count >= 0 and scenario1c_wait_count < 0x06 \
			and int(boundary.get("a", -1)) == 0x4F \
			and int(boundary.get("x", -1)) == 0x4F \
			and int(boundary.get("y", -1)) == 0x00)
	var scenario1c_parameter00_f2_waiter: bool = record == PackedByteArray([0x00, 0xC1, 0x18, 0x19]) \
		and int(boundary.get("sp", -1)) == 0xC5 \
		and int(ram[0x05EA]) == 0x00 \
		and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9400 \
		and ram.slice(0x003A, 0x003B) == PackedByteArray([0x06]) \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x4F, 0xBB]) \
		and scenario1c_wait_count >= 0 and scenario1c_wait_count <= 0x06 \
		and int(ram[0x0515]) == 0x00 \
		and int(ram[0x0519]) == 0x28 + scenario1c_wait_count \
		and ram.slice(0x0516, 0x0519) == PackedByteArray([0x01, 0x40, 0x1C]) \
		and ram.slice(0x051A, 0x051D) == PackedByteArray([0xE8, 0x9B, 0x00]) \
		and ram.slice(0x0522, 0x052B) == PackedByteArray([0x02, 0x30, 0x1F, 0x02, 0x3C, 0x4A, 0x4C, 0x00, 0x40]) \
		and int(ram[0x0539]) == 0x00 \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x40, 0xA0, 0x00, 0x00, 0x01, 0x52, 0xA0, 0x80, 0x00, 0x02, 0x80, 0x01]) \
		and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x00]) \
		and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
		and stack.slice(0xC4, 0xC6) == PackedByteArray([0x52, 0xCC]) \
		and int(stack[0xC6]) == scenario1c_wait_count \
		and stack.slice(0xC7, 0xC9) == PackedByteArray([0x7C, 0x80]) \
		and scenario1c_wait_registers
	var scenario2e_callback36_map2f_parameter6d_f2_waiter: bool = \
		is_scenario2e_callback36_map2f_actor6d_f2_waiter_resume_candidate(boundary)
	var standard_waiter: bool = record == PackedByteArray([0x00, 0xBF, 0x18, 0x19]) \
		and int(boundary.get("sp", -1)) == 0xC3 \
		and int(stack[0xC2]) == 0x52 and int(stack[0xC3]) == 0xCC \
		and int(stack[0xC4]) >= 0 and int(stack[0xC4]) <= 0x06 \
		and ((int(boundary.get("x", -1)) == 0x52 and int(boundary.get("y", -1)) == 0x0C) \
			or (int(boundary.get("x", -1)) == 0x4F and int(boundary.get("y", -1)) == 0x00))
	if not parameter47_f2_waiter and not scenario1c_parameter00_f2_waiter \
			and not scenario2e_callback36_map2f_parameter6d_f2_waiter and not standard_waiter:
		return {"ok": false, "reason": "The live `$CC53` record, ROM-specific return frame, or X/Y register signature is unsupported."}
	for stack_offset in STACK_SIZE:
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return {"ok": false, "reason": "The `$CC53` RAM and stack snapshots disagree at `$%02X`." % stack_offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The `$CC53` boundary omits a valid CPU status value and known-bit mask."}
	return {"ok": true}


func _validate_waiter_tail_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0xCCA3 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not a live scheduler-dispatched slot-$11 `$CCA3` counter-tail continuation."}
	if not record is PackedByteArray \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or int(ram[0x0000]) != SLOT_11:
		return {"ok": false, "reason": "The live `$CCA3` record, outer actor return frame, or saved X/Y is unsupported."}
	var parameter47_f2_tail: bool = record == PackedByteArray([0x00, 0xC2, 0x18, 0x19]) \
		and int(boundary.get("sp", -1)) == 0xC6 \
		and int(ram[0x05EA]) == 0x47 \
		and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9917 \
		and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
		and int(ram[0x05E5]) == 0x01 \
		and int(stack[0xC4]) == 0x4F \
		and int(stack[0xC5]) == 0xA2 and int(stack[0xC6]) == 0xCC \
		and int(stack[0xC7]) == 0x7C and int(stack[0xC8]) == 0x80 \
		and int(boundary.get("x", -1)) == 0x4F \
		and int(boundary.get("y", -1)) == 0x00
	var scenario1c_parameter00_f2_tail: bool = record == PackedByteArray([0x00, 0xC2, 0x18, 0x19]) \
		and int(boundary.get("sp", -1)) == 0xC6 \
		and int(ram[0x05EA]) == 0x00 \
		and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9400 \
		and ram.slice(0x0515, 0x051A) == PackedByteArray([0x00, 0x61, 0x40, 0x1C, 0x27]) \
		and int(ram[0x05D1]) == 0x80 and int(ram[0x05D2]) == 0x01 \
		and ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x18, 0x08, 0x22]) \
		and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x00]) \
		and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
		and stack.slice(0xC4, 0xC9) == PackedByteArray([0x4F, 0xA2, 0xCC, 0x7C, 0x80]) \
		and int(boundary.get("a", -1)) == 0x4F \
		and int(boundary.get("x", -1)) == 0x4F \
		and int(boundary.get("y", -1)) == 0x00
	var scenario2e_actor6d_f2_tail: bool = record == PackedByteArray([0x00, 0xC2, 0x18, 0x19]) \
		and int(boundary.get("sp", -1)) == 0xC6 \
		and int(ram[0x05EA]) == 0x6D \
		and (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9BE3 \
		and ram.slice(0x0515, 0x051A) == PackedByteArray([0x00, 0x01, 0x00, 0x2E, 0x6F]) \
		and ram.slice(0x0522, 0x052B) == PackedByteArray([0x00, 0x78, 0x36, 0x02, 0x3C, 0x4A, 0x8B, 0x6D, 0x00]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([0x24, 0xC0, 0x00, 0x01, 0x01, 0x2F, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
		and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x6D]) \
		and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
		and int(ram[0x0063]) == 0xBA and int(ram[0x0064]) == 0xA2 \
		and ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x18, 0x08, 0x22]) \
		and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
		and int(ram[0x0629]) == 0x00 \
		and stack.slice(0xC4, 0xC9) == PackedByteArray([0x4F, 0xA2, 0xCC, 0x7C, 0x80]) \
		and stack.slice(0xC9, 0xCB) == PackedByteArray([0x4C, 0x80]) \
		and int(boundary.get("a", -1)) == 0x4F \
		and int(boundary.get("x", -1)) == 0x4F \
		and int(boundary.get("y", -1)) == 0x00
	var standard_tail: bool = record == PackedByteArray([0x00, 0xC0, 0x18, 0x19]) \
		and int(boundary.get("sp", -1)) == 0xC4 \
		and int(stack[0xC3]) == 0xA2 and int(stack[0xC4]) == 0xCC \
		and int(stack[0xC5]) == 0xFF and int(stack[0xC6]) == 0x81 \
		and int(boundary.get("x", -1)) == 0x4F and int(boundary.get("y", -1)) == 0x00
	if not parameter47_f2_tail and not scenario1c_parameter00_f2_tail \
			and not scenario2e_actor6d_f2_tail and not standard_tail:
		return {"ok": false, "reason": "The live `$CCA3` record, ROM-specific return frame, or X/Y signature is unsupported."}
	for stack_offset in STACK_SIZE:
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return {"ok": false, "reason": "The `$CCA3` RAM and stack snapshots disagree at `$%02X`." % stack_offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The `$CCA3` boundary omits valid CPU status and known-bit values."}
	return {"ok": true}


func _validate_final_packet_return_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0xCCD1 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not a live scheduler-dispatched slot-$11 `$CCD1` final-packet return."}
	if not record is PackedByteArray \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or int(ram[0x0000]) != SLOT_11:
		return {"ok": false, "reason": "The live `$CCD1` RAM, stack, or slot signature is unsupported."}
	var parameter47_f2: bool = record == PackedByteArray([0x00, 0xC2, 0x18, 0x19]) \
			and int(boundary.get("sp", -1)) == 0xC6 \
			and int(stack[0xC4]) == 0x21 and int(stack[0xC5]) == 0xD0 \
			and int(stack[0xC6]) == 0xCC \
			and int(stack[0xC7]) == 0x7C and int(stack[0xC8]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x21 \
			and int(boundary.get("x", -1)) == 0x21 \
			and int(boundary.get("y", -1)) == 0x00 \
			and int(ram[0x005F]) == 0x17 and int(ram[0x0060]) == 0x99 \
			and int(ram[0x05EA]) == 0x47 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x01 and int(ram[0x05F4]) == 0x00
	var scenario1c_parameter00_f2: bool = record == PackedByteArray([0x00, 0xC2, 0x18, 0x19]) \
			and int(boundary.get("sp", -1)) == 0xC6 \
			and int(stack[0xC4]) == 0x21 and int(stack[0xC5]) == 0xD0 \
			and int(stack[0xC6]) == 0xCC \
			and int(stack[0xC7]) == 0x7C and int(stack[0xC8]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x21 \
			and int(boundary.get("x", -1)) == 0x21 \
			and int(boundary.get("y", -1)) == 0x00 \
			and int(ram[0x005F]) == 0x00 and int(ram[0x0060]) == 0x94 \
			and int(ram[0x05EA]) == 0x00 \
			and ram.slice(0x0515, 0x051A) == PackedByteArray([0x00, 0x61, 0x40, 0x1C, 0x26]) \
			and ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x20, 0xE0, 0x23]) \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x01 and int(ram[0x05F4]) == 0x00
	var scenario2e_actor6d_f2: bool = record == PackedByteArray([0x00, 0xC2, 0x18, 0x19]) \
			and int(boundary.get("sp", -1)) == 0xC6 \
			and stack.slice(0xC3, 0xCB) == PackedByteArray([0x00, 0x21, 0xD0, 0xCC, 0x7C, 0x80, 0x4C, 0x80]) \
			and int(boundary.get("a", -1)) == 0x21 \
			and int(boundary.get("x", -1)) == 0x21 \
			and int(boundary.get("y", -1)) == 0x00 \
			and int(ram[0x005F]) == 0xE3 and int(ram[0x0060]) == 0x9B \
			and int(ram[0x05EA]) == 0x6D \
			and ram.slice(0x0515, 0x051D) == PackedByteArray([0x00, 0x01, 0x00, 0x2E, 0x6E, 0xE8, 0x9B, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x01, 0x0E, 0x02, 0x02, 0x00, 0x6D]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
			and ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x20, 0xE0, 0x23]) \
			and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0
	var standard_f5: bool = record == PackedByteArray([0x00, 0xC0, 0x18, 0x19]) \
			and int(boundary.get("sp", -1)) == 0xC4 \
			and int(stack[0xC3]) == 0xD0 and int(stack[0xC4]) == 0xCC \
			and int(stack[0xC5]) == 0xFF and int(stack[0xC6]) == 0x81 \
			and int(stack[0xC7]) == 0x7C and int(stack[0xC8]) == 0x80 \
			and int(stack[0xC9]) == 0x4C and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("x", -1)) == 0x21 \
			and int(boundary.get("y", -1)) == 0x00 \
			and int(ram[0x005F]) == 0x52 and int(ram[0x0060]) == 0x9F \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x01
	if not parameter47_f2 and not scenario1c_parameter00_f2 \
			and not scenario2e_actor6d_f2 and not standard_f5:
		return {"ok": false, "reason": "The live `$CCD1` record, nested RTS frames, actor stream, or register signature is unsupported: " \
				+ "record=%s SP=%02X stack[C4:CB]=%s A/X/Y=%02X/%02X/%02X ptr=%04X actor=%02X " \
				+ "E3/E4/E5/F4=%02X/%02X/%02X/%02X." % [
			record.hex_encode(), int(boundary.get("sp", -1)), stack.slice(0xC4, 0xCB).hex_encode(),
			int(boundary.get("a", -1)), int(boundary.get("x", -1)), int(boundary.get("y", -1)),
			int(ram[0x0060]) << 8 | int(ram[0x005F]), int(ram[0x05EA]),
			int(ram[0x05E3]), int(ram[0x05E4]), int(ram[0x05E5]), int(ram[0x05F4]) ]}
	for offset in STACK_SIZE:
		if int(ram[0x0100 + offset]) != int(stack[offset]):
			return {"ok": false, "reason": "The `$CCD1` RAM and stack snapshots disagree at `$%02X`." % offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The `$CCD1` boundary omits valid CPU status and known-bit values."}
	return {"ok": true, "parameter47_f2": parameter47_f2,
		"scenario1c_parameter00_f2": scenario1c_parameter00_f2,
		"scenario2e_actor6d_f2": scenario2e_actor6d_f2}


func _validate_f5_animation_gate_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	var is_event_queue_animation: bool = record is PackedByteArray \
			and record == PackedByteArray([0x00, 0xC1, 0x18, 0x19])
	var is_parameter47_f2_delay: bool = record is PackedByteArray \
			and record in [PackedByteArray([0x00, 0xC2, 0x18, 0x19]),
				PackedByteArray([0x00, 0xC6, 0x18, 0x19])] \
			and ram is PackedByteArray and ram.size() == RAM_SIZE \
			and int(ram[0x005F]) == 0x17 and int(ram[0x0060]) == 0x99 \
			and int(ram[0x05EA]) == 0x47 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x01 \
			and int(ram[0x05E5]) == 0x02 \
			and ((record == PackedByteArray([0x00, 0xC2, 0x18, 0x19]) \
				and int(ram[0x05E9]) == 0x01) \
				or (record == PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
				and int(ram[0x05E9]) == 0x00)) \
			and int(ram[0x05F4]) == 0x00 \
			and int(boundary.get("a", -1)) == 0x01 \
			and int(boundary.get("x", -1)) == 0x21 \
			and int(boundary.get("y", -1)) == 0x01
	var is_scenario2e_actor6d_f4_delay: bool = record is PackedByteArray \
			and record == PackedByteArray([0x00, 0xC2, 0x18, 0x19]) \
			and ram is PackedByteArray and ram.size() == RAM_SIZE \
			and int(boundary.get("sp", -1)) == 0xCA \
			and int(ram[0x005F]) == 0xFE and int(ram[0x0060]) == 0x9B \
			and int(ram[0x05EA]) == 0x6D \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x01, 0x6D]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
			and int(ram[0x05F4]) == 0x00 \
			and int(boundary.get("a", -1)) == 0x01 \
			and int(boundary.get("x", -1)) == 0xFE \
			and int(boundary.get("y", -1)) == 0x00
	var has_scenario1c_ram_stack_shapes: bool = ram is PackedByteArray and ram.size() == RAM_SIZE \
		and stack is PackedByteArray and stack.size() == STACK_SIZE
	var is_scenario1c_f0_zero_mode: bool = has_scenario1c_ram_stack_shapes \
		and record is PackedByteArray \
		and record == PackedByteArray([0x00, 0xC2, 0x18, 0x19]) \
		and int(boundary.get("sp", -1)) == 0xCA \
		and int(stack[0xC7]) == 0x7C and int(stack[0xC8]) == 0x80 \
		and int(stack[0xC9]) == 0x4C and int(stack[0xCA]) == 0x80 \
		and int(boundary.get("a", -1)) == 0x80 \
		and int(boundary.get("x", -1)) == 0x21 \
		and int(boundary.get("y", -1)) == 0x02 \
		and int(ram[0x005F]) == 0x00 and int(ram[0x0060]) == 0x94 \
		and int(ram[0x05EA]) == 0x00 \
		and ram.slice(0x0515, 0x051A) == PackedByteArray([0x00, 0x61, 0x40, 0x1C, 0x26]) \
		and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x02, 0x0E, 0x02, 0x02, 0x00]) \
		and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
		and ram.slice(0x0063, 0x0065) == PackedByteArray([0xD7, 0xA2]) \
		and int(ram[0x0022]) == 0x00 and int(ram[0x0515]) == 0x00
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x804D \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not the live slot-$11 `$804D` F5 continuation."}
	if not record is PackedByteArray \
			or (not is_event_queue_animation and not is_parameter47_f2_delay \
				and not is_scenario2e_actor6d_f4_delay \
				and not is_scenario1c_f0_zero_mode \
				and record != PackedByteArray([0x00, 0xC0, 0x18, 0x19])) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or not mapper is Dictionary \
			or int(ram[0x0000]) != SLOT_11:
		var debug_ram: PackedByteArray = ram if ram is PackedByteArray else PackedByteArray()
		var debug_stack: PackedByteArray = stack if stack is PackedByteArray else PackedByteArray()
		return {"ok": false, "reason": "The live slot-$11 animation gate has an unsupported task/RAM/stack snapshot: record=%s sizes=%d/%d PC/SP=$%04X/$%02X stream=$%04X E3:E9=%s F3:F5=%s A/X/Y=$%02X/$%02X/$%02X stack[C7:CB]=%s." % [
			str(record), debug_ram.size(), debug_stack.size(),
			int(boundary.get("pc", -1)), int(boundary.get("sp", -1)),
			(int(debug_ram[0x005F]) | (int(debug_ram[0x0060]) << 8)) if debug_ram.size() == RAM_SIZE else -1,
			debug_ram.slice(0x05E3, 0x05EA).hex_encode() if debug_ram.size() == RAM_SIZE else "invalid",
			debug_ram.slice(0x05F3, 0x05F6).hex_encode() if debug_ram.size() == RAM_SIZE else "invalid",
			int(boundary.get("a", -1)), int(boundary.get("x", -1)), int(boundary.get("y", -1)),
			debug_stack.slice(0xC7, 0xCC).hex_encode() if debug_stack.size() == STACK_SIZE else "invalid",
		]}
	if is_event_queue_animation:
		# `$F4=$80` takes the ROM setup branch, which selects a pointer-table row
		# and clears `$F5` before `$A20F`. Some other observed gate profiles use
		# the positive-counter decrement branch; this scenario-$1C case is not
		# treated as a frame delay or adjusted to match a captured count.
		var f2_stream_pointer := int(ram[0x005F]) | (int(ram[0x0060]) << 8)
		var is_parameter47_f2_event := f2_stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 and int(ram[0x05E3]) == 0x01 \
			and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 0x01 \
			and int(ram[0x05E8]) == 0x02 and int(ram[0x05E9]) == 0x00
		var is_scenario1c_parameter58_type1_event: bool = f2_stream_pointer == 0x9A62 \
			and int(ram[0x05EA]) == 0x58 \
			and ram.slice(0x05E3, 0x05EA) \
				== PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x80, 0x01]) \
			and ram.slice(0x0061, 0x0063) == PackedByteArray([0x37, 0x8E]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0xAC, 0x02, 0x4C, 0x80])
		var is_scenario2e_actor6d_type1_event: bool = f2_stream_pointer == 0x9BFE \
			and int(ram[0x05EA]) == 0x6D \
			and ram.slice(0x05E3, 0x05EB) \
				== PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x6D]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x02, 0x80, 0x01]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xBA, 0xA2]) \
			and int(boundary.get("a", -1)) == 0x02 \
			and int(boundary.get("x", -1)) == 0x0A \
			and int(boundary.get("y", -1)) == 0x56
		var is_type1_event := not is_parameter47_f2_event \
			and not is_scenario2e_actor6d_type1_event \
			and int(ram[0x05E7]) == 0x01
		var expected_x := 0x0A if is_parameter47_f2_event or is_scenario2e_actor6d_type1_event else 0x02 if is_type1_event else 0x04
		var expected_y := 0x56 if is_parameter47_f2_event or is_scenario2e_actor6d_type1_event else 0x5D if is_type1_event else 0x62
		var expected_stream_low := 0x17 if is_parameter47_f2_event else 0xFE if is_scenario2e_actor6d_type1_event else 0x62 if is_scenario1c_parameter58_type1_event else 0x39 if is_type1_event else 0xC9
		var expected_stream_high := 0x99 if is_parameter47_f2_event else 0x9B if is_scenario2e_actor6d_type1_event else 0x9A if is_scenario1c_parameter58_type1_event else 0xA4 if is_type1_event else 0xA3
		var expected_event_type := 0x01 if is_type1_event or is_parameter47_f2_event or is_scenario2e_actor6d_type1_event else 0x00
		var expected_event_row := 0x03 if is_parameter47_f2_event else 0x02
		var expected_animation_index := 0x01 if is_parameter47_f2_event else 0x02 if is_scenario2e_actor6d_type1_event else 0x00
		if int(boundary.get("a", -1)) != 0x02 or int(boundary.get("x", -1)) != expected_x \
				or int(boundary.get("y", -1)) != expected_y \
				or int(ram[0x005F]) != expected_stream_low \
				or int(ram[0x0060]) != expected_stream_high \
				or int(ram[0x05E4]) != 0x02 or int(ram[0x05E5]) != expected_event_row \
				or int(ram[0x05E6]) != 0x0E or int(ram[0x05E7]) != expected_event_type \
				or int(ram[0x05E8]) != 0x02 or int(ram[0x05E9]) != 0x00 \
				or int(ram[0x05F3]) != expected_animation_index \
				or int(ram[0x05F4]) != 0x80 or int(ram[0x05F5]) <= 0 \
				or (is_parameter47_f2_event and int(ram[0x05EA]) != 0x47):
			return {"ok": false, "reason": "Type-$%02X gate input differs: A/X/Y=%02X/%02X/%02X stream=%02X%02X counters=%02X/%02X event=%02X/%02X/%02X delay=%02X anim=%02X/%02X/%02X." % [
				0x05 if is_parameter47_f2_event else 0x58 if is_scenario1c_parameter58_type1_event else 0x01 if is_type1_event else 0x02,
				int(boundary.get("a", -1)), int(boundary.get("x", -1)), int(boundary.get("y", -1)),
				int(ram[0x0060]), int(ram[0x005F]),
				int(ram[0x05E4]), int(ram[0x05E5]),
				int(ram[0x05E6]), int(ram[0x05E7]), int(ram[0x05E8]),
				int(ram[0x05E9]), int(ram[0x05F3]), int(ram[0x05F4]), int(ram[0x05F5])]}
	elif is_parameter47_f2_delay:
		if int(stack[0xC9]) != 0x4C or int(stack[0xCA]) != 0x80:
			return {"ok": false, "reason": "The F2 `$01` delay continuation lost its actor-worker return context."}
	elif is_scenario2e_actor6d_f4_delay:
		if int(stack[0xC9]) != 0x4C or int(stack[0xCA]) != 0x80:
			return {"ok": false, "reason": "Actor-$6D F4 delay continuation lost its parser return frame."}
	elif is_scenario1c_f0_zero_mode:
		if int(stack[0xC7]) != 0x7C or int(stack[0xC8]) != 0x80 \
				or int(stack[0xC9]) != 0x4C or int(stack[0xCA]) != 0x80:
			return {"ok": false, "reason": "The scenario-$1C `$F0` zero-mode continuation lost its actor-worker return context."}
	else:
		if int(stack[0xC7]) != 0x7C or int(stack[0xC8]) != 0x80 \
				or int(stack[0xC9]) != 0x4C or int(stack[0xCA]) != 0x80 \
				or int(boundary.get("a", -1)) != 0x80 \
				or int(boundary.get("x", -1)) != 0x21 \
				or int(boundary.get("y", -1)) != 0x01 \
				or int(ram[0x005F]) != 0x52 or int(ram[0x0060]) != 0x9F \
				or int(ram[0x05E3]) != 0x01 or int(ram[0x05E4]) != 0x00 \
				or int(ram[0x05E5]) != 0x02 or int(ram[0x05E9]) != 0x02 \
				or int(ram[0x05F3]) != 0x0D or int(ram[0x05F4]) != 0x80:
			return {"ok": false, "reason": "The live F5 stream, actor animation mode, return frames, or saved CPU state is unsupported."}
	var registers_variant: Variant = mapper.get("bank_registers", {})
	if not registers_variant is Dictionary \
			or int(registers_variant.get(6, registers_variant.get("6", -1))) != 0x18 \
			or int(registers_variant.get(7, registers_variant.get("7", -1))) != 0x19 \
			or int(mapper.get("select", -1)) not in [6, 7]:
		return {"ok": false, "reason": "The `$804D` mapper snapshot omits the current MMC3 registers 6/7."}
	for offset in STACK_SIZE:
		if int(ram[0x0100 + offset]) != int(stack[offset]):
			return {"ok": false, "reason": "The `$804D` RAM and stack snapshots disagree at `$%02X`." % offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The `$804D` boundary omits valid CPU status and known-bit values."}
	return {"ok": true, "parameter47_f2_delay": is_parameter47_f2_delay,
		"scenario2e_actor6d_f4_delay": is_scenario2e_actor6d_f4_delay,
		"scenario1c_f0_zero_mode": is_scenario1c_f0_zero_mode}


func _validate_a21a_animation_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0xA21A \
			or int(boundary.get("sp", -1)) != 0xC6 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x1A \
			or int(boundary.get("bank_high", -1)) != 0x1B:
		return {"ok": false, "reason": "Input is not the dispatched slot-$11 `$A21A` animation continuation."}
	var animation_index := -1
	var animation_pointer := -1
	if ram is PackedByteArray and ram.size() == RAM_SIZE:
		animation_index = int(ram[0x05F3])
		animation_pointer = int(ram[0x0063]) | (int(ram[0x0064]) << 8)
	var index_zero_stream := animation_index == 0 \
			and animation_pointer >= 0xA2AE and animation_pointer <= 0xA2C8 \
			and ((animation_pointer - 0xA2AE) % 2) == 0
	var index_one_stream := animation_index == 1 \
			and animation_pointer >= 0xA2CB and animation_pointer <= 0xA2E5 \
			and ((animation_pointer - 0xA2CB) % 2) == 0
	var index_two_stream := animation_index == 2 \
			and animation_pointer >= 0xA2E8 and animation_pointer <= 0xA2FA \
			and ((animation_pointer - 0xA2E8) % 2) == 0
	var index_0d_stream := animation_index == 0x0D and animation_pointer == 0xA425
	var scenario1c_parameter58_zero_counter_queue_busy := \
			is_scenario1c_parameter58_zero_counter_queue_busy_animation_boundary(boundary)
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC2, 0x1A, 0x1B]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or not mapper is Dictionary \
			or int(ram[0x0000]) != SLOT_11 \
			or (not scenario1c_parameter58_zero_counter_queue_busy \
				and stack.slice(0xC7, 0xCB) != PackedByteArray([0x83, 0xCF, 0x4F, 0x80])) \
			or not (index_zero_stream or index_one_stream or index_two_stream or index_0d_stream) \
			or int(ram[0x05F4]) != 0x01 \
			or int(ram[0x05F5]) != 0x00 \
			or (int(ram[0x0022]) & 0xF8) != 0:
		return {"ok": false, "reason": "The `$A21A` animation index/pointer, empty queue gate, mapper shadow, or saved stack is outside a ROM-backed case: record=%s A/X/Y=%02X/%02X/%02X index=%02X ptr=$%04X f4/f5=%02X/%02X q=%02X mapper22=%02X stack=%s." % [
			record.hex_encode() if record is PackedByteArray else str(record),
			int(boundary.get("a", -1)), int(boundary.get("x", -1)), int(boundary.get("y", -1)),
			animation_index, animation_pointer,
			int(ram[0x05F4]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x05F5]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x0515]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			int(ram[0x0022]) if ram is PackedByteArray and ram.size() == RAM_SIZE else -1,
			stack.slice(0xC2, 0xCB).hex_encode() if stack is PackedByteArray and stack.size() == STACK_SIZE else "invalid",
		]}
	var registers_variant: Variant = mapper.get("bank_registers", {})
	if not registers_variant is Dictionary \
			or int(registers_variant.get(6, registers_variant.get("6", -1))) != 0x1A \
			or int(registers_variant.get(7, registers_variant.get("7", -1))) != 0x1B \
			or int(mapper.get("select", -1)) not in [6, 7]:
		return {"ok": false, "reason": "The `$A21A` mapper snapshot omits the live MMC3 `$1A/$1B` pair."}
	for offset in STACK_SIZE:
		if int(ram[0x0100 + offset]) != int(stack[offset]):
			return {"ok": false, "reason": "The `$A21A` RAM and stack snapshots disagree at `$%02X`." % offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The `$A21A` boundary omits valid CPU status values."}
	return {"ok": true}


func _is_scenario2e_actor6d_type5_packet_wait_boundary(boundary: Dictionary) -> bool:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	if not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or not mapper is Dictionary:
		return false
	var registers: Dictionary = mapper.get("bank_registers", {})
	if not registers is Dictionary:
		return false
	var relevant_status_mask := P_N | P_Z | P_C
	var status := int(boundary.get("p", -1))
	var status_known_mask := int(boundary.get("p_known_mask", -1))
	if (status_known_mask & relevant_status_mask) != relevant_status_mask \
			or (status & relevant_status_mask) != 0:
		return false
	var expected_ppu_registers := PackedByteArray([0x3C, 0x4A, 0x20, 0x21, 0x00, 0x00])
	for register_index in expected_ppu_registers.size():
		var register_key := str(register_index)
		if registers.has(register_index) or registers.has(register_key):
			if int(registers.get(register_index, registers.get(register_key, -1))) \
					!= int(expected_ppu_registers[register_index]):
				return false
	return (int(ram[0x005F]) | (int(ram[0x0060]) << 8)) == 0x9BFE \
			and ram.slice(0x0515, 0x051D) == PackedByteArray([0x00, 0x01, 0x00, 0x2E, 0x64, 0xE8, 0x9B, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x6D]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x02, 0x01, 0x04]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xEA, 0xA2]) \
			and ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x04, 0xC8, 0x22]) \
			and int(ram[0x0000]) == SLOT_11 \
			and int(ram[0x0022]) == 0x00 and int(ram[0x0629]) == 0x00 \
			and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x24 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x24, 0x24, 0x49, 0x80]) \
			and ram.slice(0x01C7, 0x01CB) == PackedByteArray([0x24, 0x24, 0x49, 0x80]) \
			and int(mapper.get("select", -1)) == 0x07 \
			and int(mapper.get("bank_low", -1)) == 0x18 \
			and int(mapper.get("bank_high", -1)) == 0x19 \
			and int(registers.get(6, registers.get("6", -1))) == 0x18 \
			and int(registers.get(7, registers.get("7", -1))) == 0x19


func _validate_animation_countdown_boundary(boundary: Dictionary) -> Dictionary:
	var record: Variant = boundary.get("record", PackedByteArray())
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x804A \
			or int(boundary.get("sp", -1)) != 0xCA \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not the dispatched slot-$11 animation continuation at `$804A`."}
	if not record is PackedByteArray or record != PackedByteArray([0x00, 0xC6, 0x18, 0x19]) \
			or not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or not mapper is Dictionary or int(ram[0x0000]) != SLOT_11:
		return {"ok": false, "reason": "The slot-$11 `$804A` context omits its live record, RAM, stack, or mapper state."}
	if is_scenario1e_actor58_inactive_zero_mode_resume_boundary(boundary):
		return {"ok": true}
	if is_scenario1e_actor58_animation_countdown_boundary(boundary, true):
		return {"ok": true}
	var stream_pointer := int(ram[0x005F]) | (int(ram[0x0060]) << 8)
	var scenario2e_actor6d_9bfe_delay_tick: bool = stream_pointer == 0x9BFE \
			and int(ram[0x05EA]) == 0x6D \
			and ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x00, 0x2E, 0x6D, 0xE8, 0x9B, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x01, 0x01, 0x0E, 0x02, 0x02, 0x01, 0x6D]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xBA, 0xA2]) \
			and ram.slice(0x04A5, 0x04A8) == PackedByteArray([0x20, 0xE0, 0x23]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x00, 0xFE, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0xFE \
			and int(boundary.get("x", -1)) == 0xFE \
			and int(boundary.get("y", -1)) == 0x00
	if _is_scenario2e_actor6d_type5_packet_wait_boundary(boundary):
		return {"ok": true, "scenario2e_actor6d_type5_packet_wait": true}
	var standard_countdown := stream_pointer == 0x9F52 \
			and int(stack[0xC7]) == (int(boundary.get("y", -1)) & 0xFF) \
			and int(stack[0xC8]) == 0x24 \
			and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) in [0x24, 0x02, 0x03] \
			and int(ram[0x05E4]) in [0x00, 0x01] \
			and int(ram[0x05E5]) == (0x02 if int(ram[0x05E4]) == 0 else 0x03) \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) > 0
	var scenario1c_parameter58_initial_delay_tick := stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_live_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_live_worker_profile(ram, stack, boundary))
	var scenario1c_parameter58_countdown_tick := stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_countdown_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_countdown_worker_profile(ram, stack, boundary))
	var scenario1c_parameter58_stream_dispatch_tick := stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_stream_dispatch_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_stream_dispatch_worker_profile(ram, stack, boundary))
	var scenario1c_parameter58_post_packet_delay_tick := stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_post_packet_delay_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_post_packet_delay_worker_profile(ram, stack, boundary))
	var scenario1c_parameter58_followup_post_packet_delay_tick := stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_followup_post_packet_delay_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_followup_post_packet_delay_worker_profile(ram, stack, boundary))
	var selector03_start := stream_pointer == 0xA3BD \
			and int(stack[0xC7]) == 0xE9 and int(stack[0xC8]) == 0xBD \
			and int(boundary.get("a", -1)) == 0xBD \
			and int(boundary.get("x", -1)) == 0xBD \
			and int(boundary.get("y", -1)) == 0xE9 \
			and int(ram[0x05E4]) == 0 and int(ram[0x05E5]) == 0 \
			and int(ram[0x05E9]) == 0 and int(ram[0x05F4]) == 0
	var selector03_delay_tick := stream_pointer == 0xA3C9 \
			and int(stack[0xC7]) == 0 and int(stack[0xC8]) == 0xC9 \
			and int(boundary.get("a", -1)) == 0xC9 \
			and int(boundary.get("x", -1)) == 0xC9 \
			and int(boundary.get("y", -1)) == 0 \
			and int(ram[0x05E4]) == 1 and int(ram[0x05E5]) == 1 \
			and int(ram[0x05E9]) in [0, 1] and int(ram[0x05F4]) == 0
	var a439_initial_delay_tick := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0xEB and int(stack[0xC8]) == 0x39 \
			and int(boundary.get("a", -1)) == 0x39 \
			and int(boundary.get("x", -1)) == 0x39 \
			and int(boundary.get("y", -1)) == 0xEB \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x00 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2
	var a439_delay_countdown_tick := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x00 and int(stack[0xC8]) == 0x39 \
			and int(boundary.get("a", -1)) == 0x39 \
			and int(boundary.get("x", -1)) == 0x39 \
			and int(boundary.get("y", -1)) == 0x00 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x01 \
			and int(ram[0x05E5]) == 0x01 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2
	var a439_post_packet_delay_tick := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x05 \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x04 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
			and int(ram[0x05E5]) == 0x05 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x04 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2
	var a439_text_post_packet_delay_tick := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x06 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0D and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x02 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2
	var a439_event_dispatch_tick := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x00 and int(stack[0xC8]) == 0x39 \
			and int(boundary.get("a", -1)) == 0x39 \
			and int(boundary.get("x", -1)) == 0x39 \
			and int(boundary.get("y", -1)) == 0x00 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x01 \
			and int(ram[0x05E5]) == 0x01 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2
	var parameter47_f2_delay_tick := stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x01 \
			and int(ram[0x05E5]) == 0x02 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x01 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xBC and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x01 and int(stack[0xC8]) == 0x21 \
			and int(boundary.get("a", -1)) == 0x21 \
			and int(boundary.get("x", -1)) == 0x21 \
			and int(boundary.get("y", -1)) == 0x01
	var parameter47_f2_followup_delay_tick := stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
			and int(ram[0x05E5]) == 0x06 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 \
			and int(ram[0x05F3]) == 0x01 and int(ram[0x05F4]) == 0x01 \
			and int(ram[0x05F5]) == 0x04 and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x05 and int(stack[0xC8]) == 0x05 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x05
	var parameter47_f2_animation_countdown_tick: bool = stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x00, 0x09, 0x0E, 0x02, 0x02, 0x01]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x02]) \
			and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x06 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A
	var parameter47_f2_text_terminal_command: bool = stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x00, 0x09, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x01]) \
			and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x06 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A
	var parameter47_f2_type5_event := stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x01 \
			and int(ram[0x05E5]) == 0x02 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 \
			and int(ram[0x05F3]) == 0x00 and int(ram[0x05F4]) == 0x00 \
			and int(ram[0x05F5]) == 0x01 and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xBC and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0022]) == 0x00 \
			and int(stack[0xC7]) == 0x01 and int(stack[0xC8]) == 0x21 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x21 \
			and int(boundary.get("x", -1)) == 0x21 \
			and int(boundary.get("y", -1)) == 0x01
	var parameter47_f2_index1_packet_wait := stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
			and int(ram[0x05E5]) == 0x03 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x01 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x01 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
					and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x24
	var selector03_packet_wait := stream_pointer == 0xA3C9 \
			and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
			and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x24 \
			and int(ram[0x05E4]) == 2 and int(ram[0x05E5]) == 2 \
			and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 0 \
			and int(ram[0x05E8]) == 2 and int(ram[0x05E9]) == 0 \
			and int(ram[0x05F4]) == 1 and int(ram[0x05F5]) == 5 \
			and int(ram[0x0515]) == 0
	var a439_packet_wait := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
			and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x24 \
			and int(ram[0x05E3]) == 1 and int(ram[0x05E4]) == 2 \
			and int(ram[0x05E5]) == 2 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 1 and int(ram[0x05E8]) == 2 \
			and int(ram[0x05E9]) == 0 and int(ram[0x05F3]) == 0 \
			and int(ram[0x05F4]) == 1 and int(ram[0x05F5]) == 5 \
			and int(ram[0x0515]) == 0 and int(ram[0x0063]) == 0xB0 \
			and int(ram[0x0064]) == 0xA2
	var scenario1c_parameter58_packet_wait: bool = stream_pointer == 0x9A62 \
			and int(ram[0x05EA]) == 0x58 \
			and ram.slice(0x05E3, 0x05EB) \
				== PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x05]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0063]) == 0xB0 \
			and int(ram[0x0064]) == 0xA2 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x24, 0x24, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x24
	var scenario1c_parameter58_followup_packet_wait: bool = \
			_is_scenario1c_parameter58_followup_packet_wait_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_followup_packet_wait_profile(ram, stack, boundary)
	var a439_text_packet_wait := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x05 \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x04 \
			and int(ram[0x05E3]) == 1 and int(ram[0x05E4]) == 2 \
			and int(ram[0x05E5]) == 5 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 2 and int(ram[0x05E8]) == 2 \
			and int(ram[0x05E9]) == 0 and int(ram[0x05F3]) == 0 \
			and int(ram[0x05F4]) == 1 and int(ram[0x05F5]) == 3 \
			and int(ram[0x0515]) == 0 and int(ram[0x0063]) == 0xB0 \
			and int(ram[0x0064]) == 0xA2
	var selector03_post_packet_countdown := stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
			and ((int(ram[0x05E5]) == 0x06 and int(ram[0x05E7]) == 0x01 \
				and int(ram[0x05F5]) == 0x04 \
				and int(stack[0xC7]) == 0x05 and int(stack[0xC8]) == 0x05 \
				and int(boundary.get("a", -1)) == 0x05 \
				and int(boundary.get("x", -1)) == 0x05 \
				and int(boundary.get("y", -1)) == 0x05) \
				or (int(ram[0x05E5]) == 0x10 and int(ram[0x05E7]) == 0x02 \
				and int(ram[0x05F5]) == 0x02 \
				and int(stack[0xC7]) == 0x0F and int(stack[0xC8]) == 0x07 \
				and int(boundary.get("a", -1)) == 0x07 \
				and int(boundary.get("x", -1)) == 0x07 \
				and int(boundary.get("y", -1)) == 0x0F)) \
			and int(ram[0x05E6]) == 0x0E and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 \
			and int(ram[0x0515]) == 0x00
	var selector03_followup_packet_wait := stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x02 \
			and ((int(ram[0x05E5]) == 0x06 and int(ram[0x05E7]) == 0x01 \
				and int(ram[0x05F5]) == 0x03 \
				and int(stack[0xC7]) == 0x05 and int(stack[0xC8]) == 0x05 \
				and int(boundary.get("a", -1)) == 0x05 \
				and int(boundary.get("x", -1)) == 0x05 \
				and int(boundary.get("y", -1)) == 0x05) \
				or (int(ram[0x05E5]) == 0x10 and int(ram[0x05E7]) == 0x02 \
				and int(ram[0x05F5]) == 0x01 \
				and int(stack[0xC7]) == 0x0F and int(stack[0xC8]) == 0x07 \
				and int(boundary.get("a", -1)) == 0x07 \
				and int(boundary.get("x", -1)) == 0x07 \
				and int(boundary.get("y", -1)) == 0x0F)) \
			and int(ram[0x05E6]) == 0x0E and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 \
			and int(ram[0x0515]) == 0x00
	var selector03_row02_animation_gate := stream_pointer == 0xA3C9 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x07 \
			and int(boundary.get("a", -1)) == 0x07 \
			and int(boundary.get("x", -1)) == 0x07 \
			and int(boundary.get("y", -1)) == 0x3A \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x19 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x01 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) == 0x00
	var selector03_row02_terminal_command := stream_pointer == 0xA3C9 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04 \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x19 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) == 0x00
	var a439_text_terminal_command := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x3A and int(stack[0xC8]) == 0x06 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x3A \
			and int(ram[0x05E3]) == 0x01 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0D and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x01 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2
	var scenario1c_parameter58_followup_text_terminal_command := stream_pointer == 0x9A62 \
			and (_is_scenario1c_parameter58_followup_text_terminal_worker_profile(ram, stack, boundary) \
			or _is_scenario1c_callback63_parameter58_followup_text_terminal_worker_profile(ram, stack, boundary))
	var scenario1c_parameter58_followup_text_terminal_inactive_gate: bool = stream_pointer == 0x9A62 \
			and int(ram[0x05EA]) == 0x58 \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x00]) \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB0, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x02, 0x06, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x02
	var selector03_terminal_inactive_countdown := stream_pointer == 0xA3C9 \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x02 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(ram[0x0063]) == 0xB2 and int(ram[0x0064]) == 0xA2
	var selector03_terminal_inactive_packet_countdown := stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and ((int(ram[0x0063]) in [0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6] \
				and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
				and int(boundary.get("a", -1)) == 0x04 \
				and int(boundary.get("x", -1)) == 0x04 \
				and int(boundary.get("y", -1)) == 0x04) \
			or (int(ram[0x0063]) == 0xC8 and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
				and int(boundary.get("a", -1)) == 0x24 \
				and int(boundary.get("x", -1)) == 0x24 \
				and int(boundary.get("y", -1)) == 0x24))
	var selector03_terminal_inactive_gate := stream_pointer == 0xA3C9 \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x02 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB2 and int(ram[0x0064]) == 0xA2
	var selector03_terminal_inactive_packet_gate := stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and ((int(ram[0x0063]) in [0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6] \
				and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
				and int(boundary.get("a", -1)) == 0x04 \
				and int(boundary.get("x", -1)) == 0x04 \
				and int(boundary.get("y", -1)) == 0x04) \
			or (int(ram[0x0063]) == 0xC8 and int(ram[0x0064]) == 0xA2 \
				and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
				and int(boundary.get("a", -1)) == 0x24 \
				and int(boundary.get("x", -1)) == 0x24 \
				and int(boundary.get("y", -1)) == 0x24))
	var selector03_animation_tail_idle := stream_pointer == 0xA3C9 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x1A and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x05 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x24 and int(stack[0xC8]) == 0x24 \
			and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x24
	var parameter47_f2_index2_packet_wait: bool = stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x02, 0x06, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x03]) \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0022]) == 0x00 and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x05 and int(stack[0xC8]) == 0x05 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x05
	var a439_text_terminal_inactive_gate := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x06 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x02 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0E and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) == 0x00 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2
	var parameter47_f2_text_terminal_inactive_gate: bool = stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x00]) \
			and int(ram[0x0063]) == 0xCD and int(ram[0x0064]) == 0xA2 \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(stack[0xC7]) == 0x02 and int(stack[0xC8]) == 0x06 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x06 \
			and int(boundary.get("x", -1)) == 0x06 \
			and int(boundary.get("y", -1)) == 0x02
	var parameter47_f2_inactive_zero_counter_gate: bool = stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x00]) \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(ram[0x0063]) in [0xCD, 0xCF, 0xD1, 0xD3, 0xD5, 0xD7, 0xD9, 0xDB, 0xDD, 0xDF, 0xE1, 0xE3, 0xE5] and int(ram[0x0064]) == 0xA2 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04
	var parameter47_f2_post_packet_zero_counter_gate: bool = parameter47_f2_inactive_zero_counter_gate \
			and int(ram[0x0063]) in [0xD1, 0xD3, 0xD5, 0xD7, 0xD9, 0xDB, 0xDD, 0xDF, 0xE1, 0xE3, 0xE5]
	var a439_inactive_zero_counter_gate := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) in [0x02, 0x04] \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0E and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) == 0x00 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(ram[0x0063]) in [0xB2, 0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6, 0xC8] \
			and int(ram[0x0064]) == 0xA2
	var a439_animation_pointer := int(ram[0x0063]) in [0xB2, 0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6, 0xC8] \
			and int(ram[0x0064]) == 0xA2
	var a439_text_inactive_animation_countdown := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0E and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x01 and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and a439_animation_pointer
	var scenario1c_parameter58_terminal_animation_countdown: bool = stream_pointer == 0x9A62 \
			and int(ram[0x05EA]) == 0x58 \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x00, 0x00, 0x0E, 0x0E, 0x02, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F5) == PackedByteArray([0x00, 0x01]) \
			and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xB2, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04 \
			or is_scenario1c_parameter58_phase29_cursor10_queue_busy_animation_boundary(boundary)
	var scenario1c_parameter58_zero_counter_queue_busy_gate: bool = stream_pointer == 0x9A62 \
			and is_scenario1c_parameter58_zero_counter_queue_busy_animation_boundary(boundary)
	var parameter47_f2_animation_script_countdown: bool = stream_pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x0A, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F5) == PackedByteArray([0x01, 0x01]) \
			and int(ram[0x05F5]) in [1, 2, 3, 4, 5] \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and int(ram[0x0063]) in [0xCD, 0xCF, 0xD1, 0xD3, 0xD5, 0xD7, 0xD9, 0xDB, 0xDD, 0xDF, 0xE1, 0xE3, 0xE5] and int(ram[0x0064]) == 0xA2 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04
	var parameter47_f2_post_packet_animation_countdown: bool = parameter47_f2_animation_script_countdown \
			and int(ram[0x0063]) in [0xD1, 0xD3, 0xD5, 0xD7, 0xD9, 0xDB, 0xDD, 0xDF, 0xE1, 0xE3, 0xE5]
	var a439_inactive_zero_mode_resume := stream_pointer == 0xA439 \
			and int(stack[0xC7]) == 0x04 and int(stack[0xC8]) == 0x04 \
			and int(stack[0xC9]) == 0x49 and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x04 \
			and int(boundary.get("x", -1)) == 0x04 \
			and int(boundary.get("y", -1)) == 0x04 \
			and int(ram[0x05E3]) == 0x00 and int(ram[0x05E4]) == 0x00 \
			and int(ram[0x05E5]) == 0x0E and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 0x02 and int(ram[0x05E8]) == 0x02 \
			and int(ram[0x05E9]) == 0x00 and int(ram[0x05F3]) == 0x00 \
			and int(ram[0x05F4]) == 0x00 and int(ram[0x05F5]) == 0x01 \
			and int(ram[0x0515]) in [0x00, 0x80] \
			and int(ram[0x0063]) == 0xBC and int(ram[0x0064]) == 0xA2
	var scenario1c_f0_inactive_zero_mode_resume: bool = stream_pointer == 0x9400 \
			and int(ram[0x05EA]) == 0x00 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x00, 0x00, 0x02, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x00, 0x01]) \
			and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
			and int(ram[0x0629]) == 0x00 \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xD7, 0xA2]) \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0x02, 0x21, 0x49, 0x80]) \
			and int(boundary.get("a", -1)) == 0x21 \
			and int(boundary.get("x", -1)) == 0x21 \
			and int(boundary.get("y", -1)) == 0x02
	var standard_animation_pointer := int(ram[0x0063]) == 0x27 and int(ram[0x0064]) == 0xA4
	var packet_wait_animation_pointer := int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2
	var sequence_animation_pointer := int(ram[0x0063]) == 0xB2 and int(ram[0x0064]) == 0xA2
	if not standard_countdown and not selector03_start and not selector03_delay_tick \
			and not scenario2e_actor6d_9bfe_delay_tick \
			and not scenario1c_parameter58_initial_delay_tick \
			and not scenario1c_parameter58_countdown_tick \
			and not scenario1c_parameter58_stream_dispatch_tick \
			and not scenario1c_parameter58_packet_wait \
			and not scenario1c_parameter58_followup_packet_wait \
			and not parameter47_f2_delay_tick and not parameter47_f2_followup_delay_tick \
			and not parameter47_f2_animation_countdown_tick \
			and not parameter47_f2_text_terminal_command \
			and not parameter47_f2_type5_event and not parameter47_f2_index1_packet_wait \
			and not parameter47_f2_index2_packet_wait \
			and not a439_initial_delay_tick and not a439_delay_countdown_tick \
			and not a439_post_packet_delay_tick and not scenario1c_parameter58_post_packet_delay_tick \
			and not scenario1c_parameter58_followup_post_packet_delay_tick \
			and not a439_text_post_packet_delay_tick \
			and not a439_event_dispatch_tick \
			and not selector03_packet_wait and not a439_packet_wait and not a439_text_packet_wait \
			and not selector03_post_packet_countdown \
			and not selector03_followup_packet_wait and not selector03_row02_animation_gate \
			and not selector03_row02_terminal_command and not a439_text_terminal_command \
			and not scenario1c_parameter58_followup_text_terminal_command \
			and not scenario1c_parameter58_followup_text_terminal_inactive_gate \
			and not scenario1c_parameter58_terminal_animation_countdown \
			and not scenario1c_parameter58_zero_counter_queue_busy_gate \
			and not selector03_terminal_inactive_countdown \
			and not selector03_terminal_inactive_packet_countdown \
			and not selector03_terminal_inactive_gate \
			and not a439_text_terminal_inactive_gate \
			and not parameter47_f2_text_terminal_inactive_gate \
			and not parameter47_f2_inactive_zero_counter_gate \
			and not a439_inactive_zero_counter_gate \
			and not a439_text_inactive_animation_countdown \
			and not parameter47_f2_animation_script_countdown \
			and not a439_inactive_zero_mode_resume \
			and not scenario1c_f0_inactive_zero_mode_resume \
			and not selector03_terminal_inactive_packet_gate \
			and not selector03_animation_tail_idle \
			or int(stack[0xC9]) != 0x49 or int(stack[0xCA]) != 0x80 \
			or (not selector03_packet_wait and not a439_packet_wait and not a439_text_packet_wait \
				and not selector03_post_packet_countdown \
				and not selector03_followup_packet_wait \
				and not selector03_row02_animation_gate and not selector03_row02_terminal_command \
				and not a439_text_terminal_command \
				and not scenario1c_parameter58_followup_text_terminal_command \
				and not scenario1c_parameter58_followup_text_terminal_inactive_gate \
				and not scenario1c_parameter58_terminal_animation_countdown \
				and not parameter47_f2_text_terminal_inactive_gate \
				and not selector03_terminal_inactive_countdown \
				and not selector03_terminal_inactive_packet_countdown \
				and not selector03_terminal_inactive_gate \
				and not a439_text_terminal_inactive_gate \
				and not a439_inactive_zero_counter_gate \
				and not parameter47_f2_inactive_zero_counter_gate \
				and not a439_text_inactive_animation_countdown \
				and not parameter47_f2_animation_script_countdown \
				and not a439_inactive_zero_mode_resume \
				and not scenario1c_f0_inactive_zero_mode_resume \
				and not selector03_terminal_inactive_packet_gate \
				and not selector03_animation_tail_idle and not a439_initial_delay_tick \
				and not a439_delay_countdown_tick and not a439_post_packet_delay_tick \
				and not scenario1c_parameter58_post_packet_delay_tick \
				and not scenario1c_parameter58_followup_post_packet_delay_tick \
				and not a439_text_post_packet_delay_tick \
				and not a439_event_dispatch_tick and not parameter47_f2_delay_tick \
				and not parameter47_f2_followup_delay_tick \
				and not parameter47_f2_animation_countdown_tick \
				and not parameter47_f2_text_terminal_command \
				and not parameter47_f2_type5_event and not parameter47_f2_index1_packet_wait \
				and not parameter47_f2_index2_packet_wait \
				and not scenario1c_parameter58_initial_delay_tick \
				and not scenario1c_parameter58_countdown_tick \
				and not scenario1c_parameter58_stream_dispatch_tick \
				and not scenario1c_parameter58_packet_wait \
				and not scenario1c_parameter58_followup_packet_wait \
				and not scenario1c_parameter58_zero_counter_queue_busy_gate \
				and not scenario2e_actor6d_9bfe_delay_tick \
				and not standard_animation_pointer) \
			or ((selector03_packet_wait or a439_packet_wait or scenario1c_parameter58_packet_wait \
				or scenario1c_parameter58_followup_packet_wait \
				or a439_text_packet_wait or selector03_post_packet_countdown \
				or selector03_followup_packet_wait or selector03_row02_animation_gate) \
				and not packet_wait_animation_pointer) \
			or ((selector03_row02_terminal_command or selector03_terminal_inactive_countdown \
				or selector03_terminal_inactive_gate) \
				and not sequence_animation_pointer) \
			or (a439_text_terminal_inactive_gate and not packet_wait_animation_pointer) \
			or (scenario1c_parameter58_followup_text_terminal_inactive_gate \
				and not packet_wait_animation_pointer) \
			or (scenario1c_parameter58_terminal_animation_countdown \
				and not sequence_animation_pointer) \
			or (scenario1c_parameter58_zero_counter_queue_busy_gate \
				and not sequence_animation_pointer) \
			or (parameter47_f2_text_terminal_inactive_gate \
				and (int(ram[0x0063]) != 0xCD or int(ram[0x0064]) != 0xA2)) \
			or (a439_text_inactive_animation_countdown and not a439_animation_pointer) \
			or ((a439_text_terminal_command or scenario1c_parameter58_followup_text_terminal_command) \
				and not packet_wait_animation_pointer) \
			or (selector03_terminal_inactive_packet_countdown \
				and not (int(ram[0x0063]) in [0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6, 0xC8] and int(ram[0x0064]) == 0xA2)) \
			or (selector03_terminal_inactive_packet_gate \
				and not (int(ram[0x0063]) in [0xB4, 0xB6, 0xB8, 0xBA, 0xBC, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6, 0xC8] and int(ram[0x0064]) == 0xA2)) \
			or (int(ram[0x05E3]) != 0x01 and not selector03_terminal_inactive_countdown \
				and not selector03_terminal_inactive_packet_countdown \
				and not selector03_terminal_inactive_gate \
				and not scenario1c_parameter58_followup_text_terminal_inactive_gate \
				and not scenario1c_parameter58_terminal_animation_countdown \
				and not scenario1c_parameter58_zero_counter_queue_busy_gate \
				and not a439_text_terminal_inactive_gate \
				and not parameter47_f2_text_terminal_inactive_gate \
				and not parameter47_f2_inactive_zero_counter_gate \
				and not a439_inactive_zero_counter_gate \
				and not a439_text_inactive_animation_countdown \
				and not parameter47_f2_animation_script_countdown \
				and not a439_inactive_zero_mode_resume \
				and not scenario1c_f0_inactive_zero_mode_resume \
				and not selector03_terminal_inactive_packet_gate \
				and not selector03_animation_tail_idle) \
			or (not selector03_packet_wait and not a439_packet_wait and not a439_text_packet_wait \
				and not selector03_post_packet_countdown \
				and not selector03_followup_packet_wait \
				and not selector03_row02_animation_gate \
				and not selector03_row02_terminal_command and not a439_text_terminal_command \
				and not scenario1c_parameter58_followup_text_terminal_command \
				and not scenario1c_parameter58_followup_text_terminal_inactive_gate \
				and not scenario1c_parameter58_terminal_animation_countdown \
					and not scenario1c_parameter58_zero_counter_queue_busy_gate \
				and not selector03_terminal_inactive_countdown \
				and not selector03_terminal_inactive_packet_countdown \
				and not selector03_terminal_inactive_gate \
				and not a439_text_terminal_inactive_gate \
				and not parameter47_f2_text_terminal_inactive_gate \
				and not a439_inactive_zero_counter_gate \
				and not a439_text_inactive_animation_countdown \
				and not a439_inactive_zero_mode_resume \
				and not selector03_terminal_inactive_packet_gate \
				and not selector03_animation_tail_idle and not a439_initial_delay_tick \
				and not a439_delay_countdown_tick and not a439_post_packet_delay_tick \
				and not scenario1c_parameter58_post_packet_delay_tick \
				and not scenario1c_parameter58_followup_post_packet_delay_tick \
				and not a439_text_post_packet_delay_tick \
				and not a439_event_dispatch_tick and not parameter47_f2_delay_tick \
				and not parameter47_f2_followup_delay_tick \
				and not parameter47_f2_animation_countdown_tick \
				and not parameter47_f2_text_terminal_command \
				and not parameter47_f2_inactive_zero_counter_gate \
				and not parameter47_f2_animation_script_countdown \
				and not parameter47_f2_type5_event and not parameter47_f2_index1_packet_wait \
				and not parameter47_f2_index2_packet_wait \
				and not scenario1c_f0_inactive_zero_mode_resume \
				and not scenario1c_parameter58_initial_delay_tick \
				and not scenario1c_parameter58_countdown_tick \
				and not scenario1c_parameter58_stream_dispatch_tick \
				and not scenario1c_parameter58_packet_wait \
				and not scenario1c_parameter58_followup_packet_wait \
				and not scenario2e_actor6d_9bfe_delay_tick \
				and int(ram[0x05F3]) != 0x0D) \
			or ((selector03_packet_wait or a439_packet_wait or scenario1c_parameter58_packet_wait \
				or scenario1c_parameter58_followup_packet_wait \
				or a439_text_packet_wait or selector03_post_packet_countdown \
				or selector03_followup_packet_wait or selector03_row02_animation_gate \
				or selector03_row02_terminal_command or a439_text_terminal_command \
				or scenario1c_parameter58_followup_text_terminal_command \
				or selector03_terminal_inactive_countdown \
				or selector03_terminal_inactive_packet_countdown \
				or selector03_terminal_inactive_gate or a439_text_terminal_inactive_gate \
				or a439_inactive_zero_counter_gate \
				or a439_text_inactive_animation_countdown \
				or a439_inactive_zero_mode_resume \
				or selector03_terminal_inactive_packet_gate) \
				and int(ram[0x05F3]) != 0x00) \
			or (int(ram[0x05F5]) == 0 and not selector03_row02_animation_gate \
				and not selector03_terminal_inactive_gate \
				and not scenario1c_parameter58_followup_text_terminal_command \
				and not scenario1c_parameter58_followup_text_terminal_inactive_gate \
				and not a439_text_terminal_inactive_gate \
				and not parameter47_f2_text_terminal_inactive_gate \
				and not parameter47_f2_inactive_zero_counter_gate \
				and not a439_inactive_zero_counter_gate \
				and not selector03_terminal_inactive_packet_gate \
				and not scenario1c_parameter58_zero_counter_queue_busy_gate) \
			or (int(ram[0x0515]) != 0x00 and not (int(ram[0x0515]) == 0x80 \
				and (selector03_terminal_inactive_packet_countdown \
				or selector03_terminal_inactive_packet_gate \
				or a439_inactive_zero_counter_gate \
				or a439_text_inactive_animation_countdown \
				or parameter47_f2_animation_script_countdown \
				or a439_inactive_zero_mode_resume \
				or scenario1c_parameter58_terminal_animation_countdown \
					or scenario1c_parameter58_zero_counter_queue_busy_gate \
				or selector03_animation_tail_idle))) \
			or (int(ram[0x0022]) & 0xF8) != 0:
		var recognized_states := PackedStringArray()
		var recognized_state_checks: Dictionary = {
			"standard_countdown": standard_countdown,
			"selector03_start": selector03_start,
			"selector03_delay_tick": selector03_delay_tick,
			"a439_initial_delay_tick": a439_initial_delay_tick,
			"a439_delay_countdown_tick": a439_delay_countdown_tick,
			"a439_post_packet_delay": a439_post_packet_delay_tick,
			"scenario1c_parameter58_post_packet_delay": scenario1c_parameter58_post_packet_delay_tick,
			"scenario1c_parameter58_followup_post_packet_delay": scenario1c_parameter58_followup_post_packet_delay_tick,
			"a439_text_post_packet_delay": a439_text_post_packet_delay_tick,
			"a439_event_dispatch_tick": a439_event_dispatch_tick,
			"parameter47_f2_delay_tick": parameter47_f2_delay_tick,
			"parameter47_f2_followup_delay_tick": parameter47_f2_followup_delay_tick,
			"parameter47_f2_animation_countdown_tick": parameter47_f2_animation_countdown_tick,
			"parameter47_f2_text_terminal_command": parameter47_f2_text_terminal_command,
			"parameter47_f2_type5_event": parameter47_f2_type5_event,
			"parameter47_f2_index1_packet_wait": parameter47_f2_index1_packet_wait,
			"parameter47_f2_index2_packet_wait": parameter47_f2_index2_packet_wait,
			"selector03_packet_wait": selector03_packet_wait,
			"a439_packet_wait": a439_packet_wait,
			"a439_text_packet_wait": a439_text_packet_wait,
			"selector03_post_packet_countdown": selector03_post_packet_countdown,
			"selector03_followup_packet_wait": selector03_followup_packet_wait,
			"selector03_row02_animation_gate": selector03_row02_animation_gate,
			"selector03_row02_terminal_command": selector03_row02_terminal_command,
			"a439_text_terminal_command": a439_text_terminal_command,
			"scenario1c_parameter58_followup_text_terminal_command": scenario1c_parameter58_followup_text_terminal_command,
			"scenario1c_parameter58_followup_text_terminal_inactive_gate": scenario1c_parameter58_followup_text_terminal_inactive_gate,
			"scenario1c_parameter58_terminal_animation_countdown": scenario1c_parameter58_terminal_animation_countdown,
			"scenario1c_parameter58_zero_counter_queue_busy_gate": scenario1c_parameter58_zero_counter_queue_busy_gate,
			"selector03_terminal_inactive_countdown": selector03_terminal_inactive_countdown,
			"selector03_terminal_inactive_packet_countdown": selector03_terminal_inactive_packet_countdown,
			"selector03_terminal_inactive_gate": selector03_terminal_inactive_gate,
			"a439_text_terminal_inactive_gate": a439_text_terminal_inactive_gate,
			"parameter47_f2_text_terminal_inactive_gate": parameter47_f2_text_terminal_inactive_gate,
			"parameter47_f2_inactive_zero_counter_gate": parameter47_f2_inactive_zero_counter_gate,
			"parameter47_f2_post_packet_zero_counter_gate": parameter47_f2_post_packet_zero_counter_gate,
			"a439_inactive_zero_counter_gate": a439_inactive_zero_counter_gate,
			"a439_text_inactive_animation_countdown": a439_text_inactive_animation_countdown,
			"parameter47_f2_animation_script_countdown": parameter47_f2_animation_script_countdown,
			"parameter47_f2_post_packet_animation_countdown": parameter47_f2_post_packet_animation_countdown,
			"a439_inactive_zero_mode_resume": a439_inactive_zero_mode_resume,
			"scenario1c_f0_inactive_zero_mode_resume": scenario1c_f0_inactive_zero_mode_resume,
			"scenario1c_parameter58_initial_delay_tick": scenario1c_parameter58_initial_delay_tick,
			"scenario1c_parameter58_countdown_tick": scenario1c_parameter58_countdown_tick,
			"scenario1c_parameter58_stream_dispatch_tick": scenario1c_parameter58_stream_dispatch_tick,
			"scenario1c_parameter58_post_packet_delay_tick": scenario1c_parameter58_post_packet_delay_tick,
			"scenario1c_parameter58_followup_post_packet_delay_tick": scenario1c_parameter58_followup_post_packet_delay_tick,
			"scenario1c_parameter58_packet_wait": scenario1c_parameter58_packet_wait,
			"scenario1c_parameter58_followup_packet_wait": scenario1c_parameter58_followup_packet_wait,
			"selector03_terminal_inactive_packet_gate": selector03_terminal_inactive_packet_gate,
			"selector03_animation_tail_idle": selector03_animation_tail_idle,
		}
		for state_name: String in recognized_state_checks:
			if bool(recognized_state_checks[state_name]):
				recognized_states.append(state_name)
		return {"ok": false, "reason": "The `$804A` actor tick is outside verified state: stream=$%04X animation=$%04X E3:E9=%s F4:F5=%s queue=$%02X `$0022`=$%02X stack[C7:CB]=%s A/X/Y=$%02X/$%02X/$%02X P=$%02X/%02X record=%s callback63_terminal=%s scenario=%s callback=%s map=%s actor=%s gate=%s recognized=%s." % [
			stream_pointer, int(ram[0x0063]) | (int(ram[0x0064]) << 8),
			ram.slice(0x05E3, 0x05EA).hex_encode(), ram.slice(0x05F4, 0x05F6).hex_encode(),
			int(ram[0x0515]), int(ram[0x0022]), stack.slice(0xC7, 0xCB).hex_encode(),
			int(boundary.get("a", -1)), int(boundary.get("x", -1)), int(boundary.get("y", -1)),
			int(boundary.get("p", -1)), int(boundary.get("p_known_mask", -1)),
			(PackedByteArray(boundary.get("record", PackedByteArray()))).hex_encode(),
			str(_is_scenario1c_callback63_parameter58_followup_text_terminal_worker_profile(ram, stack, boundary)),
			ram.slice(0x0516, 0x051D).hex_encode(), ram.slice(0x0522, 0x052B).hex_encode(),
			ram.slice(0x05C7, 0x05D3).hex_encode(), ram.slice(0x05E3, 0x05EB).hex_encode(),
			ram.slice(0x05F3, 0x05F6).hex_encode(),
			", ".join(recognized_states)]}
	var registers_variant: Variant = mapper.get("bank_registers", {})
	if not registers_variant is Dictionary \
			or int(registers_variant.get(6, registers_variant.get("6", -1))) != 0x18 \
			or int(registers_variant.get(7, registers_variant.get("7", -1))) != 0x19 \
			or int(mapper.get("select", -1)) not in [6, 7]:
		return {"ok": false, "reason": "The animation countdown boundary omits the live MMC3 `$18/$19` pair."}
	for offset in STACK_SIZE:
		if int(ram[0x0100 + offset]) != int(stack[offset]):
			return {"ok": false, "reason": "The `$804A` RAM and stack snapshots disagree at `$%02X`." % offset}
	if not boundary.has("p") or not boundary.has("p_known_mask") \
			or int(boundary.get("p", -1)) < 0 or int(boundary.get("p", -1)) > 0xFF \
			or int(boundary.get("p_known_mask", -1)) < 0 \
			or int(boundary.get("p_known_mask", -1)) > 0xFF:
		return {"ok": false, "reason": "The animation countdown boundary omits valid CPU status values."}
	return {"ok": true,
		"scenario1c_parameter58_packet_wait": scenario1c_parameter58_packet_wait,
		"scenario1c_parameter58_followup_packet_wait": scenario1c_parameter58_followup_packet_wait,
		"scenario2e_actor6d_9bfe_delay_tick": scenario2e_actor6d_9bfe_delay_tick,
		"parameter47_f2_animation_countdown_tick": parameter47_f2_animation_countdown_tick,
		"parameter47_f2_text_terminal_command": parameter47_f2_text_terminal_command,
		"parameter47_f2_text_terminal_inactive_gate": parameter47_f2_text_terminal_inactive_gate,
		"parameter47_f2_inactive_zero_counter_gate": parameter47_f2_inactive_zero_counter_gate,
		"parameter47_f2_post_packet_zero_counter_gate": parameter47_f2_post_packet_zero_counter_gate,
		"parameter47_f2_post_packet_animation_countdown": parameter47_f2_post_packet_animation_countdown}


## Resumes the row-$02 packet builder at `$82F7` and follows its source path to
## the next `$8047->$C515` yield. This CPU subset is limited to the ROM bytes
## and opcodes used by this traced continuation.
func execute_from_slot11_packet_wait_resume_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var valid := _validate_slot11_packet_resume_boundary(boundary)
	if not bool(valid.get("ok", false)):
		return _reject(String(valid.get("reason", "Unsupported slot-$11 packet resume boundary.")))
	var ram: PackedByteArray = boundary["ram_image"].duplicate()
	var stack: PackedByteArray = boundary["stack_page"].duplicate()
	var mapper: Dictionary = boundary["mapper"].duplicate(true)
	var cpu := {
		"pc": 0x82F7, "sp": int(boundary["sp"]),
		"a": int(boundary["a"]) & 0xFF, "x": int(boundary["x"]) & 0xFF,
		"y": int(boundary["y"]) & 0xFF, "p": int(boundary["p"]) & 0xFF,
		"p_known_mask": int(boundary["p_known_mask"]) & 0xFF,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var initial_mapper := mapper.duplicate(true)
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var mapper_writes: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var stack_status_known_masks: Dictionary = {}
	var steps := 0
	while steps < 2048:
		var pc := int(cpu["pc"])
		if pc == 0x8047 and int(mapper.get("bank_low", -1)) == 0x18:
			var callsite_registers := cpu.duplicate(true)
			var callsite_stack := stack.duplicate()
			_jsr(cpu, stack, stack_writes, pc, 0xC515)
			var trampoline_opcode := _read_packet_resume_rom_byte(0xC515, mapper)
			if trampoline_opcode != 0x4C:
				return _unsupported("ROM `$8047->$C515` no longer reaches the checked task trampoline.")
			_read_event(source_reads, 0xC515, 0xC515, trampoline_opcode, "task_yield_dispatch_opcode")
			cpu["pc"] = 0xCB0F
			instruction_pcs.append(0xC515)
			var result := _waiter_yield_result(boundary, entry_cpu, entry_ram,
				entry_stack, cpu, mapper, ram, stack, ram_writes, stack_writes,
				stack_reads, source_reads, instruction_pcs, callsite_registers,
				callsite_stack, 0x8047, 0x804A, "slot11_actor_packet_resume_at_cb0f")
			var actor6d_stream_read := _packet_resume_reads_actor6d_stream(source_reads)
			result["source_span_hashes"] = _slot11_packet_resume_source_hashes(actor6d_stream_read)
			if actor6d_stream_read:
				result["actor_parameter"] = 0x6D
				result["actor_parameter_manifest"] = PARAMETER6D_MANIFEST_PATH
			result["initial_mapper"] = initial_mapper
			result["mapper_writes"] = mapper_writes
			var actor_text_rom_addresses := _packet_resume_text_stream_addresses(source_reads)
			result["decoded_packet"] = {
				"ppu_queue_flag": int(ram[0x0515]),
				"ppu_packet_header": ram.slice(0x04A5, 0x04B9),
				"actor_text_bytes": ram.slice(0x04B9, 0x04BF),
				"actor_text_rom_address": int(actor_text_rom_addresses[0]) if not actor_text_rom_addresses.is_empty() else -1,
				"actor_text_rom_addresses": actor_text_rom_addresses,
				"actor_text_pointer_resolved": not actor_text_rom_addresses.is_empty(),
			}
			return result
		instruction_pcs.append(pc)
		var opcode := _packet_resume_fetch_byte(cpu, mapper, source_reads, pc)
		if opcode < 0:
			return _unsupported("Packet-resume ROM fetch is outside verified spans at `$%04X`." % pc)
		steps += 1
		var address := 0
		var operand := 0
		var value := 0
		match opcode:
			0x09, 0x29, 0x69, 0xA0, 0xA2, 0xA9, 0xC0, 0xC9, 0xE0, 0xE9:
				operand = _packet_resume_fetch_byte(cpu, mapper, source_reads, pc)
				if operand < 0: return _unsupported("Packet-resume immediate is unavailable at `$%04X`." % pc)
				match opcode:
					0x09: _set_a(cpu, int(cpu["a"]) | operand)
					0x29: _set_a(cpu, int(cpu["a"]) & operand)
					0x69:
						if (int(cpu["p_known_mask"]) & P_C) == 0:
							return _unsupported("Packet-resume ADC at `$%04X` consumes unknown carry." % pc)
						_actor_event_arithmetic(cpu, operand, false)
					0xA0: _set_y(cpu, operand)
					0xA2: _set_x(cpu, operand)
					0xA9: _set_a(cpu, operand)
					0xC0: _packet_resume_compare(cpu, int(cpu["y"]), operand)
					0xC9: _compare_a(cpu, operand)
					0xE0: _packet_resume_compare(cpu, int(cpu["x"]), operand)
					0xE9:
						if (int(cpu["p_known_mask"]) & P_C) == 0:
							return _unsupported("Packet-resume SBC at `$%04X` consumes unknown carry." % pc)
						_actor_event_arithmetic(cpu, operand, true)
					_: pass
			0x10, 0x90, 0xB0, 0xD0, 0xF0:
				operand = _packet_resume_fetch_byte(cpu, mapper, source_reads, pc)
				if operand < 0: return _unsupported("Packet-resume branch byte is unavailable at `$%04X`." % pc)
				var branch_flag := P_N if opcode == 0x10 else P_C if opcode in [0x90, 0xB0] else P_Z
				if (int(cpu["p_known_mask"]) & branch_flag) == 0:
					return _unsupported("Packet-resume branch at `$%04X` consumes an unknown status flag `$%02X`." % [pc, branch_flag])
				var p := int(cpu["p"])
				var take := (opcode == 0x10 and (p & P_N) == 0) \
					or (opcode == 0x90 and (p & P_C) == 0) \
					or (opcode == 0xB0 and (p & P_C) != 0) \
					or (opcode == 0xD0 and (p & P_Z) == 0) \
					or (opcode == 0xF0 and (p & P_Z) != 0)
				if take:
					cpu["pc"] = (int(cpu["pc"]) + (operand if operand < 0x80 else operand - 0x100)) & 0xFFFF
			0x18, 0x38:
				_set_flag(cpu, P_C, opcode == 0x38)
			0x0A:
				value = int(cpu["a"])
				_set_flag(cpu, P_C, (value & 0x80) != 0)
				_set_a(cpu, value << 1)
			0x20:
				address = _packet_resume_fetch_word(cpu, mapper, source_reads, pc)
				if address < 0: return _unsupported("Packet-resume JSR target is unavailable at `$%04X`." % pc)
				var jsr_stack_sp := int(cpu["sp"]) & 0xFF
				_jsr(cpu, stack, stack_writes, pc, address)
				stack_status_known_masks.erase(0x0100 | jsr_stack_sp)
				stack_status_known_masks.erase(0x0100 | ((jsr_stack_sp - 1) & 0xFF))
				_sync_packet_resume_stack_ram(ram, stack)
			0x4C:
				address = _packet_resume_fetch_word(cpu, mapper, source_reads, pc)
				if address < 0: return _unsupported("Packet-resume JMP target is unavailable at `$%04X`." % pc)
				cpu["pc"] = address
			0x6C:
				address = _packet_resume_fetch_word(cpu, mapper, source_reads, pc)
				if address < 0: return _unsupported("Packet-resume indirect JMP pointer is unavailable at `$%04X`." % pc)
				var target_low := _packet_resume_read_memory(address, ram, mapper, source_reads, pc)
				var target_high_address := (address & 0xFF00) | ((address + 1) & 0x00FF)
				var target_high := _packet_resume_read_memory(target_high_address, ram, mapper, source_reads, pc)
				if target_low < 0 or target_high < 0: return _unsupported("Packet-resume dispatch pointer is not ROM-backed.")
				cpu["pc"] = target_low | (target_high << 8)
			0x48:
				var pha_stack_address := 0x0100 | (int(cpu["sp"]) & 0xFF)
				_push(cpu, stack, stack_writes, int(cpu["a"]), pc, "PHA")
				stack_status_known_masks.erase(pha_stack_address)
				_sync_packet_resume_stack_ram(ram, stack)
			0x08:
				var php_stack_address := 0x0100 | (int(cpu["sp"]) & 0xFF)
				_push(cpu, stack, stack_writes, int(cpu["p"]) | P_B | P_U, pc, "PHP")
				stack_status_known_masks[php_stack_address] = (int(cpu["p_known_mask"]) | P_B | P_U) & 0xFF
				_sync_packet_resume_stack_ram(ram, stack)
			0x60:
				var rts_stack_sp := int(cpu["sp"]) & 0xFF
				_rts(cpu, stack, stack_reads, pc)
				stack_status_known_masks.erase(0x0100 | ((rts_stack_sp + 1) & 0xFF))
				stack_status_known_masks.erase(0x0100 | ((rts_stack_sp + 2) & 0xFF))
				_sync_packet_resume_stack_ram(ram, stack)
			0x68:
				var pla_stack_address := 0x0100 | ((int(cpu["sp"]) + 1) & 0xFF)
				_set_a(cpu, _pop(cpu, stack, stack_reads, pc))
				stack_status_known_masks.erase(pla_stack_address)
				_sync_packet_resume_stack_ram(ram, stack)
			0x28:
				var plp_stack_address := 0x0100 | ((int(cpu["sp"]) + 1) & 0xFF)
				var status_known_mask := int(stack_status_known_masks.get(plp_stack_address, 0))
				var restored_status := _stack_pop_raw(cpu, stack, stack_reads, pc)
				stack_status_known_masks.erase(plp_stack_address)
				cpu["p"] = (restored_status | P_U) & ~P_B & 0xFF
				cpu["p_known_mask"] = (status_known_mask | P_U) & ~P_B & 0xFF
				_sync_packet_resume_stack_ram(ram, stack)
			0x84, 0x85, 0x86, 0x8D, 0x99, 0x9D:
				if opcode in [0x84, 0x85, 0x86]:
					address = _packet_resume_fetch_byte(cpu, mapper, source_reads, pc)
				else:
					address = _packet_resume_fetch_word(cpu, mapper, source_reads, pc)
				if address < 0: return _unsupported("Packet-resume store address is unavailable at `$%04X`." % pc)
				if opcode == 0x9D: address = (address + int(cpu["x"])) & 0xFFFF
				elif opcode == 0x99: address = (address + int(cpu["y"])) & 0xFFFF
				value = int(cpu["a"]) if opcode in [0x85, 0x8D, 0x9D] else int(cpu["x"]) if opcode == 0x86 else int(cpu["y"])
				if not _packet_resume_write_memory(address, value, pc, ram, stack,
						stack_status_known_masks, mapper, ram_writes, mapper_writes):
					return _unsupported("Packet-resume store targets unsupported address `$%04X` at `$%04X`." % [address, pc])
			0x8A: _set_a(cpu, int(cpu["x"]))
			0x98: _set_a(cpu, int(cpu["y"]))
			0xA4, 0xA5, 0xA6:
				address = _packet_resume_fetch_byte(cpu, mapper, source_reads, pc)
				value = _packet_resume_read_memory(address, ram, mapper, source_reads, pc)
				if address < 0 or value < 0: return _unsupported("Packet-resume zero-page read failed at `$%04X`." % pc)
				if opcode == 0xA4: _set_y(cpu, value)
				elif opcode == 0xA6: _set_x(cpu, value)
				else: _set_a(cpu, value)
			0xA8: _set_y(cpu, int(cpu["a"]))
			0xAA: _set_x(cpu, int(cpu["a"]))
			0xAC, 0xAD, 0xAE, 0xCD, 0xEE, 0xCE:
				address = _packet_resume_fetch_word(cpu, mapper, source_reads, pc)
				if address < 0: return _unsupported("Packet-resume absolute address is unavailable at `$%04X`." % pc)
				if opcode in [0xEE, 0xCE]:
					value = _packet_resume_read_memory(address, ram, mapper, source_reads, pc)
					if value < 0 or not _packet_resume_write_memory(address,
						value + (1 if opcode == 0xEE else -1), pc, ram, stack,
						stack_status_known_masks, mapper, ram_writes, mapper_writes):
						return _unsupported("Packet-resume increment/decrement target is unsupported at `$%04X`." % pc)
					_set_nz(cpu, value + (1 if opcode == 0xEE else -1))
				else:
					value = _packet_resume_read_memory(address, ram, mapper, source_reads, pc)
					if value < 0: return _unsupported("Packet-resume absolute read is unavailable at `$%04X`." % pc)
					if opcode == 0xAC: _set_y(cpu, value)
					elif opcode == 0xAE: _set_x(cpu, value)
					elif opcode == 0xCD: _compare_a(cpu, value)
					else: _set_a(cpu, value)
			0x2C:
				address = _packet_resume_fetch_word(cpu, mapper, source_reads, pc)
				value = _packet_resume_read_memory(address, ram, mapper, source_reads, pc)
				if address < 0 or value < 0: return _unsupported("Packet-resume BIT operand is unavailable at `$%04X`." % pc)
				_set_flag(cpu, P_N, (value & 0x80) != 0)
				_set_flag(cpu, P_V, (value & 0x40) != 0)
				_set_flag(cpu, P_Z, (int(cpu["a"]) & value) == 0)
			0xB1:
				operand = _packet_resume_fetch_byte(cpu, mapper, source_reads, pc)
				if operand < 0: return _unsupported("Packet-resume indirect-Y pointer is unavailable at `$%04X`." % pc)
				address = ((int(ram[operand]) | (int(ram[(operand + 1) & 0xFF]) << 8)) + int(cpu["y"])) & 0xFFFF
				value = _packet_resume_read_memory(address, ram, mapper, source_reads, pc)
				if value < 0:
					var indirect_pointer := int(ram[operand]) | (int(ram[(operand + 1) & 0xFF]) << 8)
					return _unsupported("Packet-resume indirect-Y data is outside ROM spans at `$%04X`: operand=$%02X pointer=$%04X Y=$%02X address=$%04X banks=$%02X/$%02X." % [
						pc, operand, indirect_pointer, int(cpu["y"]), address,
						int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1))])
				_set_a(cpu, value)
			0xB9, 0xBD, 0xDD:
				address = _packet_resume_fetch_word(cpu, mapper, source_reads, pc)
				if address < 0: return _unsupported("Packet-resume indexed address is unavailable at `$%04X`." % pc)
				var indexed_base := address
				var index_register := int(cpu["y"]) if opcode == 0xB9 else int(cpu["x"])
				address = (address + index_register) & 0xFFFF
				value = _packet_resume_read_memory(address, ram, mapper, source_reads, pc)
				if value < 0: return _unsupported("Packet-resume indexed read is outside ROM spans at `$%04X`: base=$%04X index=$%02X address=$%04X banks=$%02X/$%02X." % [
					pc, indexed_base, index_register, address,
					int(mapper.get("bank_low", -1)), int(mapper.get("bank_high", -1))])
				if opcode == 0xDD: _packet_resume_compare(cpu, int(cpu["x"]), value)
				else: _set_a(cpu, value)
			0x88: _set_y(cpu, int(cpu["y"]) - 1)
			0xC8: _set_y(cpu, int(cpu["y"]) + 1)
			0xE8: _set_x(cpu, int(cpu["x"]) + 1)
			0xE6:
				address = _packet_resume_fetch_byte(cpu, mapper, source_reads, pc)
				value = _packet_resume_read_memory(address, ram, mapper, source_reads, pc)
				if address < 0 or value < 0 or not _packet_resume_write_memory(address,
						value + 1, pc, ram, stack, stack_status_known_masks,
						mapper, ram_writes, mapper_writes):
					return _unsupported("Packet-resume zero-page increment is unsupported at `$%04X`." % pc)
				_set_nz(cpu, value + 1)
			_:
				return _unsupported("Unmodeled packet-resume opcode `$%02X` at `$%04X`." % [opcode, pc])
	return _unsupported("ROM packet resume exceeded 2,048 instructions at `$%04X` without reaching `$8047`: A/X/Y=$%02X/$%02X/$%02X E3:E9=%s F3:F5=%s $0515=$%02X ptr=$%04X queue=%s zp30-3D=%s buffer_05E8_05F5=%s indirect=$%04X recent=%s stack=%s." % [
		int(cpu["pc"]), int(cpu["a"]), int(cpu["x"]), int(cpu["y"]),
		ram.slice(0x05E3, 0x05EA).hex_encode(), ram.slice(0x05F3, 0x05F6).hex_encode(),
		int(ram[0x0515]), int(ram[0x005F]) | (int(ram[0x0060]) << 8),
		ram.slice(0x04A5, 0x04BF).hex_encode(), ram.slice(0x0030, 0x003E).hex_encode(),
		ram.slice(0x05E8, 0x05F6).hex_encode(),
		int(ram[0x0030]) | (int(ram[0x0031]) << 8),
		str(instruction_pcs.slice(max(0, instruction_pcs.size() - 16))), stack.slice(0xC4, 0xCC).hex_encode()])


func _validate_slot11_packet_resume_boundary(boundary: Dictionary) -> Dictionary:
	var ram: Variant = boundary.get("ram_image", PackedByteArray())
	var stack: Variant = boundary.get("stack_page", PackedByteArray())
	var record: Variant = boundary.get("record", PackedByteArray())
	var mapper: Variant = boundary.get("mapper", {})
	if String(boundary.get("rom_sha256", "")) != ROM_SHA256 \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("phase", -1)) != 2 \
			or int(boundary.get("pending_resume", -1)) != 0 \
			or int(boundary.get("ready_delay", -1)) != 0 \
			or int(boundary.get("pc", -1)) != 0x82F7 \
			or int(boundary.get("sp", -1)) != 0xC8 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(boundary.get("bank_low", -1)) != 0x18 \
			or int(boundary.get("bank_high", -1)) != 0x19:
		return {"ok": false, "reason": "Input is not the dispatched slot-$11 `$82F7` continuation."}
	if not ram is PackedByteArray or ram.size() != RAM_SIZE \
			or not stack is PackedByteArray or stack.size() != STACK_SIZE \
			or not record is PackedByteArray or record != PackedByteArray([0x00, 0xC4, 0x18, 0x19]) \
			or not mapper is Dictionary or int(ram[0x0000]) != SLOT_11:
		return {"ok": false, "reason": "The `$82F7` task omits the expected live RAM, stack, record, or mapper."}
	var pointer := int(ram[0x005F]) | (int(ram[0x0060]) << 8)
	var first_packet_resume := pointer == 0xA3C9 \
			and int(ram[0x05E4]) == 2 and int(ram[0x05E5]) == 2 \
			and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 0 \
			and int(ram[0x05E8]) == 2 and int(ram[0x05E9]) == 0 \
			and int(ram[0x05F3]) == 0 and int(ram[0x05F4]) == 1 \
			and int(ram[0x05F5]) == 5
	var a439_packet_resume := pointer == 0xA439 \
			and int(ram[0x05E4]) == 2 and int(ram[0x05E5]) == 2 \
			and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 1 \
			and int(ram[0x05E8]) == 2 and int(ram[0x05E9]) == 0 \
			and int(ram[0x05F3]) == 0 and int(ram[0x05F4]) == 1 \
			and int(ram[0x05F5]) == 5
	var a439_text_packet_resume := pointer == 0xA439 \
			and int(ram[0x05E3]) == 1 and int(ram[0x05E4]) == 2 \
			and int(ram[0x05E5]) == 5 and int(ram[0x05E6]) == 0x0E \
			and int(ram[0x05E7]) == 2 and int(ram[0x05E8]) == 2 \
			and int(ram[0x05E9]) == 0 and int(ram[0x05F3]) == 0 \
			and int(ram[0x05F4]) == 1 and int(ram[0x05F5]) == 3 \
			and int(ram[0x0515]) == 0 and int(ram[0x0063]) == 0xB0 \
			and int(ram[0x0064]) == 0xA2
	var followup_packet_resume := pointer == 0xA3C9 \
			and int(ram[0x05E4]) == 2 and int(ram[0x05E5]) == 6 \
			and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 1 \
			and int(ram[0x05E8]) == 2 and int(ram[0x05E9]) == 0 \
			and int(ram[0x05F3]) == 0 and int(ram[0x05F4]) == 1 \
			and int(ram[0x05F5]) == 3
	var row02_packet_resume := pointer == 0xA3C9 \
			and int(ram[0x05E4]) == 2 and int(ram[0x05E5]) == 0x10 \
			and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 2 \
			and int(ram[0x05E8]) == 2 and int(ram[0x05E9]) == 0 \
			and int(ram[0x05F3]) == 0 and int(ram[0x05F4]) == 1 \
			and int(ram[0x05F5]) == 1
	var parameter47_index1_packet_resume: bool = pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x02, 0x03, 0x0E, 0x01, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x05]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0063]) == 0xCD \
			and int(ram[0x0064]) == 0xA2 and int(ram[0x0629]) == 0 \
			and int(stack[0xC7]) == 0xF6 and int(stack[0xC8]) == 0x82 \
			and int(stack[0xC9]) == 0x4C and int(stack[0xCA]) == 0x80
	var parameter47_index2_packet_resume: bool = pointer == 0x9917 \
			and int(ram[0x05EA]) == 0x47 \
			and ram.slice(0x05E3, 0x05EA) == PackedByteArray([0x01, 0x02, 0x06, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x01, 0x01, 0x03]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0063]) == 0xCD \
			and int(ram[0x0064]) == 0xA2 and int(ram[0x0629]) == 0 \
			and int(ram[0x0022]) == 0 \
			and int(stack[0xC7]) == 0xF6 and int(stack[0xC8]) == 0x82 \
			and int(stack[0xC9]) == 0x4C and int(stack[0xCA]) == 0x80 \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x06
	var scenario1c_parameter58_packet_resume: bool = pointer == 0x9A62 \
			and int(ram[0x05EA]) == 0x58 \
			and ram.slice(0x05E3, 0x05EB) \
				== PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x58]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x05]) \
			and int(ram[0x0515]) == 0 \
			and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0xF6, 0x82, 0x4C, 0x80]) \
			and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x06
	var scenario1c_parameter58_followup_packet_resume: bool = pointer == 0x9A62 \
			and int(ram[0x05EA]) == 0x58 \
			and ram.slice(0x05E3, 0x05EA) \
				== PackedByteArray([0x01, 0x02, 0x05, 0x0E, 0x02, 0x02, 0x00]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x01, 0x03]) \
			and int(ram[0x0515]) == 0 and int(ram[0x0022]) == 0 and int(ram[0x0629]) == 0 \
			and int(ram[0x0063]) == 0xB0 and int(ram[0x0064]) == 0xA2 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0xF6, 0x82, 0x4C, 0x80]) \
			and int(boundary.get("a", -1)) == 0x05 \
			and int(boundary.get("x", -1)) == 0x05 \
			and int(boundary.get("y", -1)) == 0x06
	var scenario2e_actor6d_type5_packet_resume: bool = pointer == 0x9BFE \
			and ram.slice(0x0515, 0x051D) == PackedByteArray([0x00, 0x01, 0x00, 0x2E, 0x63, 0xE8, 0x9B, 0x00]) \
			and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x02, 0x02, 0x0E, 0x01, 0x02, 0x00, 0x6D]) \
			and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x02, 0x01, 0x04]) \
			and ram.slice(0x0063, 0x0065) == PackedByteArray([0xEA, 0xA2]) \
			and int(ram[0x0022]) == 0x00 and int(ram[0x0629]) == 0x00 \
			and stack.slice(0xC7, 0xCB) == PackedByteArray([0xF6, 0x82, 0x4C, 0x80]) \
			and int(boundary.get("a", -1)) == 0x24 \
			and int(boundary.get("x", -1)) == 0x24 \
			and int(boundary.get("y", -1)) == 0x06 \
			and (int(boundary.get("p_known_mask", -1)) & (P_N | P_Z | P_C)) \
				== (P_N | P_Z | P_C) \
			and (int(boundary.get("p", -1)) & (P_N | P_Z | P_C)) == 0
	if (not first_packet_resume and not a439_packet_resume \
			and not followup_packet_resume and not row02_packet_resume \
			and not a439_text_packet_resume and not parameter47_index1_packet_resume \
			and not parameter47_index2_packet_resume and not scenario1c_parameter58_packet_resume \
			and not scenario1c_parameter58_followup_packet_resume \
			and not scenario2e_actor6d_type5_packet_resume) \
			or int(ram[0x05E3]) != 1 or int(ram[0x0515]) != 0 \
			or int(stack[0xC7]) != 0xF6 or int(stack[0xC8]) != 0x82 \
			or (int(ram[0x0022]) & 0xF8) != 0 \
			or ((scenario1c_parameter58_packet_resume or scenario1c_parameter58_followup_packet_resume) \
				and (int(ram[0x0022]) != 0 or int(ram[0x0629]) != 0)):
		return {"ok": false, "reason": "The live `$82F7` continuation is outside the pinned packet profile: " + JSON.stringify({
			"record": record.hex_encode(), "pc": int(boundary.get("pc", -1)),
			"pointer": "%04X" % pointer, "EA": int(ram[0x05EA]),
			"E3_EA": ram.slice(0x05E3, 0x05EB).hex_encode(),
			"F3_F5": ram.slice(0x05F3, 0x05F6).hex_encode(),
			"queue": int(ram[0x0515]), "animation": "%04X" % (int(ram[0x0063]) | (int(ram[0x0064]) << 8)),
			"0022": int(ram[0x0022]), "0629": int(ram[0x0629]),
			"stack_C7_CA": stack.slice(0xC7, 0xCB).hex_encode(),
			"A_X_Y": [int(boundary.get("a", -1)), int(boundary.get("x", -1)), int(boundary.get("y", -1))],
			"packet_profile": parameter47_index2_packet_resume,
			"scenario1c_parameter58_packet_resume": scenario1c_parameter58_packet_resume,
		})}
	for offset in STACK_SIZE:
		if int(ram[0x0100 + offset]) != int(stack[offset]):
			return {"ok": false, "reason": "The `$82F7` RAM and stack snapshots differ at `$%02X`." % offset}
	var registers_variant: Variant = mapper.get("bank_registers", {})
	if not registers_variant is Dictionary \
			or int(registers_variant.get(6, registers_variant.get("6", -1))) != 0x18 \
			or int(registers_variant.get(7, registers_variant.get("7", -1))) != 0x19 \
			or int(mapper.get("select", -1)) not in [6, 7]:
		return {"ok": false, "reason": "The `$82F7` mapper state omits live MMC3 banks `$18/$19`."}
	for key: String in ["a", "x", "y", "p", "p_known_mask"]:
		if not boundary.has(key) or int(boundary[key]) < 0 or int(boundary[key]) > 0xFF:
			return {"ok": false, "reason": "The `$82F7` boundary omits a valid CPU register %s." % key}
	return {"ok": true}


func _packet_resume_fetch_byte(cpu: Dictionary, mapper: Dictionary,
		source_reads: Array[Dictionary], pc: int) -> int:
	var address := int(cpu["pc"]) & 0xFFFF
	var value := _read_packet_resume_rom_byte(address, mapper)
	if value >= 0:
		_read_event(source_reads, pc, address, value, "actor_packet_resume_rom_byte")
	cpu["pc"] = (address + 1) & 0xFFFF
	return value


func _packet_resume_fetch_word(cpu: Dictionary, mapper: Dictionary,
		source_reads: Array[Dictionary], pc: int) -> int:
	var low := _packet_resume_fetch_byte(cpu, mapper, source_reads, pc)
	var high := _packet_resume_fetch_byte(cpu, mapper, source_reads, pc)
	if low < 0 or high < 0: return -1
	return low | (high << 8)


func _packet_resume_read_memory(address: int, ram: PackedByteArray, mapper: Dictionary,
		source_reads: Array[Dictionary], pc: int) -> int:
	if address >= 0 and address < 0x2000:
		var ram_address := address & 0x07FF
		var value := int(ram[ram_address])
		_read_event(source_reads, pc, ram_address, value, "actor_packet_resume_ram_read")
		return value
	var source_value := _read_packet_resume_rom_byte(address, mapper)
	if source_value >= 0:
		_read_event(source_reads, pc, address, source_value, "actor_packet_resume_rom_data")
	return source_value


func _packet_resume_write_memory(address: int, value: int, pc: int,
		ram: PackedByteArray, stack: PackedByteArray, stack_status_known_masks: Dictionary,
		mapper: Dictionary, ram_writes: Array[Dictionary], mapper_writes: Array[Dictionary]) -> bool:
	if address >= 0 and address < 0x2000:
		var ram_address := address & 0x07FF
		_write_ram(ram, ram_writes, ram_address, value, pc)
		if ram_address >= 0x0100 and ram_address < 0x0200:
			stack[ram_address & 0xFF] = value & 0xFF
			stack_status_known_masks.erase(ram_address)
		return true
	if address == 0x8000:
		var selected := value & 0x07
		mapper["select"] = selected
		mapper_writes.append({"pc": pc, "address": address, "value": value & 0xFF, "select": selected})
		return true
	if address == 0x8001:
		var selected := int(mapper.get("select", -1))
		if selected not in [6, 7]: return false
		_set_mapper_pair_register(mapper, mapper_writes, value, selected, pc)
		return true
	return false


func _sync_packet_resume_stack_ram(ram: PackedByteArray, stack: PackedByteArray) -> void:
	for stack_offset in STACK_SIZE:
		ram[0x0100 + stack_offset] = stack[stack_offset]


func _packet_resume_compare(cpu: Dictionary, left: int, right: int) -> void:
	var difference := (left - right) & 0xFF
	_set_flag(cpu, P_C, left >= right)
	_set_nz(cpu, difference)


func _slot11_packet_resume_source_hashes(include_parameter6d_stream: bool) -> Dictionary:
	var hashes := {
		ACTOR_PACKET_RESUME_FILE: "978aad12034e7113bb0366808145d6408b5a70098274e6a00c241bae2d8d6a12",
		ACTOR_PACKET_RESUME_CONTINUATION_FILE: "86db4642e0a3aaa45796069b995d22a4093f8036227c82ae81e28c47f19410e5",
		PARAMETER47_INDEX1_PACKET_LOOKUP_FILE: "456db556cef5802457e8666bf34d2d83fc8d713565f385eadeec8e7fe8d9e3fd",
		PARAMETER47_ACTOR_TEXT_POINTER_FILE: "4e48ab6b84301af8b8fa92c04373b79b5d6f0f37d207c775c98fbce001ff67fe",
		RECORD_POINTER_TABLE_FILE: "5b9f6e3ab4a8858805b9d8c94d306e9313d319bd7cf52398dff269c374ecd60e",
		RECORD_POINTER_TABLE_FULL_FILE: "69928f23546876b56ef0e1c47913e5bcf8b34d2aaab39f521916e8e028cf0dba",
		ACTOR_PACKET_ROW_ADDRESS_FILE: "d96e385a2efac7078c2039c2cba7be185bf570689d4d3c11642b71b53ddc07fe",
		PARAMETER58_STREAM_FILE: "15779004184bd0d73ede7e28bb543f63a92f64cc67a99cc49a4f14ec66d60274",
		ACTOR_EVENT_STREAM_CONTINUATION_FILE: "98722e2ebed8ed3d3652e11e4181f0dccc1ce7d192d8f1db370af8ec4a4e174a",
		ACTOR_EVENT_STREAM_TEXT_FILE: "8368859c91cb9632996f9674b98d47b90d23e5e58f4a084fb972e82d57eaab70",
		"fixed_record_pointer_vector_C50C_C50F.bin": "71f4bb6ccdc5573bcfceef2422fe8636bc1dd1068675da3d860282d577e78b44",
		"fixed_record_pointer_resolver_CD7C_CD89.bin": "8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24",
		TEXT_POINTER_LOOKUP_FILE: "f9dc5864adabc5db33189a020b140fc4ecaad375427c97fe23b3be1b65771b92",
		TEXT_POINTER_76_FILE: "7b0ede93dd7a46b4084c470accbde1cd0c3e79f11de2acda14789c756bc1bc1d",
		ACTOR_TEXT_76_FILE: "43d56de68e6197feddf34fcb5ebf127fbd8efb3c00b8fde7232e136a9056bdea",
		TEXT_POINTER_TABLE_FILE: "a9f5fe1065b10b827ed01b3e5785bd7e588d634d39775d8cff0c0b871b90c8bf",
		TEXT_STREAM_E6_FILE: "b14618dbd1ace58f36d2aa7d0e046d9155d3a14c78ae50e6fa537077096690e9",
		TEXT_STREAM_F9A4_FILE: "f2a75ea55767154b617239e02a7f6f68140df718904be878818f48fe98d23009",
		TEXT_STREAM_F53A_FILE: "f51cba1dfe206478670952db060ddbbf73e7cbb46ff8ca93ccf52c9004582c17",
		PLAYER_NAME_POINTER_08_FILE: "e12533f65374f184d86d85fc4af8d5caf3adc82ce0e3c807aa59156ec9f4fde8",
		PLAYER_NAME_STREAM_08_FILE: "b3a3a5e4da898b911055f80b1915e7c52adaef2f592d0be88895d0e6762d890a",
		"fixed_text_helper_vector_C524_C527.bin": "ec16977c3bfaa36e30d39a6e50ef3a1478d7c5a122f029c905be8413dc0a3b2f",
		"fixed_text_token_converter_CBC2_CBF1.bin": "840a83b978d52de7009769a5ef383299928a7af77f34d3e639d5393bef43d129",
		"fixed_team_name_dispatch_C53C_C53F.bin": "6419d5a470082bb95466023cfc1b7b935f42415f3a318be99c4c612ea9bfd9e5",
		"fixed_dispatch_C509_C50C.bin": INLINE_DISPATCH_SHA256,
		"fixed_branch_table_dispatch_CB99_CBAF.bin": TRAMPOLINE_SHA256,
		C560_STUB_FILE: "170b3801f4df2a5789a9ef9fbdc6c389c58afdad9c58a94d3c7fad8e6563ccbc",
		CF72_WRAPPER_FILE: "8ef4c31ce9f19ea12db252480ab5342a4429e37c3f81148bdde0286ad03b3c13",
		"fixed_mapper_helper_CE2D_CE49.bin": "6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c",
		ANIMATION_GATE_FILE: "7cf2b10130708c5b0a722741eb60d27e732672730c7bbfb515dd1f9a17122618",
		ANIMATION_INDEX_TABLE_FILE: "ad3e81a3ca712cd37059bd8e8eaa52468f09e6ba17b32100b53e39a5e3dfdef6",
		YIELD_TRAMPOLINE_FILE: "86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e",
	}
	if include_parameter6d_stream:
		hashes[PARAMETER6D_STREAM_FILE] = \
			"0b787ded174d6496196c978f5b835c4e89c9858a8499617b02bacc5b3f7b7d1e"
	return hashes


func _packet_resume_reads_actor6d_stream(source_reads: Array[Dictionary]) -> bool:
	for read: Dictionary in source_reads:
		var address := int(read.get("address", -1))
		if address >= 0x9BE3 and address <= 0x9C70:
			return true
	return false


func _packet_resume_text_stream_addresses(source_reads: Array[Dictionary]) -> Array[int]:
	var addresses: Array[int] = []
	for read: Dictionary in source_reads:
		if String(read.get("kind", "")) != "actor_packet_resume_rom_data":
			continue
		var address := int(read.get("address", -1))
		var stream_start := 0
		if address >= 0xF776 and address < 0xF77C: stream_start = 0xF776
		elif address >= 0xF52B and address < 0xF530: stream_start = 0xF52B
		elif address >= 0xFAB0 and address < 0xFAB4: stream_start = 0xFAB0
		elif address >= 0xF9A4 and address < 0xF9A8: stream_start = 0xF9A4
		elif address >= 0xF53A and address < 0xF53F: stream_start = 0xF53A
		if stream_start != 0 and not addresses.has(stream_start):
			addresses.append(stream_start)
	return addresses


## Continues a ROM-backed actor event from the scheduler-restored `$8269` wait poll.
## The bounded source interpreter runs ROM instructions until the next `$8266`
## task yield or the event routine's return to its `$804D` caller.
func execute_from_slot11_actor_event_wait_boundary(boundary: Dictionary) -> Dictionary:
	error_message = ""
	if not _configured:
		return _reject("Configure hash-checked slot-$11 ROM source spans first.")
	var ram_variant: Variant = boundary.get("ram_image", PackedByteArray())
	var stack_variant: Variant = boundary.get("stack_page", PackedByteArray())
	var record_variant: Variant = boundary.get("record", PackedByteArray())
	var mapper_variant: Variant = boundary.get("mapper", {})
	if not ram_variant is PackedByteArray or not stack_variant is PackedByteArray \
			or not record_variant is PackedByteArray or not mapper_variant is Dictionary:
		return _reject("The event wait boundary omits RAM, stack, task record, or mapper state.")
	var ram: PackedByteArray = ram_variant.duplicate()
	var stack: PackedByteArray = stack_variant.duplicate()
	var record: PackedByteArray = record_variant
	var mapper: Dictionary = mapper_variant.duplicate(true)
	var start_a := int(boundary.get("a", -1))
	var start_x := int(boundary.get("x", -1))
	var start_y := int(boundary.get("y", -1))
	var start_p := int(boundary.get("p", -1))
	var start_known := int(boundary.get("p_known_mask", -1))
	var payload_pointer := int(ram[0x0061]) | (int(ram[0x0062]) << 8) if ram.size() == RAM_SIZE else -1
	var f2_expected_queue_stack := PackedByteArray([0x68, 0x82, 0x22, 0x2C, 0x0A, 0x4C, 0x80])
	if ram.size() == RAM_SIZE:
		# `$82DB` advances the PPU destination by two `$20` rows per completed
		# packet. Same-ROM type-2 traces show `$C7` advancing `$2C->$6C->$AC`;
		# preserve the carry into `$C6` when the 16-bit PPU address wraps.
		var f2_next_ppu_address := (0x222C \
			+ ((6 - int(ram[0x05E8])) * 0x40)) & 0xFFFF
		f2_expected_queue_stack[2] = (f2_next_ppu_address >> 8) & 0xFF
		f2_expected_queue_stack[3] = f2_next_ppu_address & 0xFF
	var f2_type5_profile := ram.size() == RAM_SIZE \
		and int(ram[0x005F]) == 0x17 and int(ram[0x0060]) == 0x99 \
		and payload_pointer == 0x8FBF \
		and int(ram[0x05EA]) == 0x47 \
		and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 0x14 \
		and int(ram[0x05E8]) in [1, 2, 3, 4, 5, 6] \
		and int(ram[0x05F3]) == 0x01 and int(ram[0x05F4]) == 0x80 \
		and int(ram[0x05F5]) == 0x01 \
		and stack.size() == STACK_SIZE \
		and stack.slice(0xC4, 0xCB) == f2_expected_queue_stack
	var scenario2e_actor6d_type5_profile := ram.size() == RAM_SIZE \
		and int(ram[0x005F]) == 0xFE and int(ram[0x0060]) == 0x9B \
		and payload_pointer == 0x8FBF \
		and int(ram[0x05EA]) == 0x6D \
		and int(ram[0x05E6]) == 0x0E and int(ram[0x05E7]) == 0x14 \
		and int(ram[0x05E8]) in [1, 2, 3, 4, 5, 6] and int(ram[0x05E9]) == 0x00 \
		and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x02, 0x80, 0x01]) \
		and int(ram[0x0515]) == 0x00 \
		and stack.size() == STACK_SIZE \
		and stack.slice(0xC4, 0xCB) == f2_expected_queue_stack
	var type02_payload_profile := payload_pointer in [0x8E37, 0x8E94]
	if ram.size() != RAM_SIZE or stack.size() != STACK_SIZE \
			or record != PackedByteArray([0x00, 0xC1, 0x18, 0x19]) \
			or int(boundary.get("slot_base", -1)) != SLOT_11 \
			or int(boundary.get("pc", -1)) != 0x8269 or int(boundary.get("sp", -1)) != 0xC5 \
			or int(boundary.get("active_task_slot", -1)) != SLOT_11 \
			or int(mapper.get("bank_low", -1)) != 0x18 \
			or int(mapper.get("bank_high", -1)) != 0x19 \
			or int(ram[0x05E6]) != 0x0E or int(ram[0x05E7]) != 0x14 \
			or int(ram[0x05E8]) not in [1, 2, 3, 4, 5, 6] \
			or (not type02_payload_profile and not f2_type5_profile \
				and not scenario2e_actor6d_type5_profile) \
			or int(ram[0x0515]) not in [0x00, 0x80] \
			or start_a < 0 or start_a > 0xFF or start_x < 0 or start_x > 0xFF \
			or start_y < 0 or start_y > 0xFF or start_p < 0 or start_p > 0xFF \
			or start_known < 0 or start_known > 0xFF:
		return _reject("The live task is outside the verified type-$02 or F2 type-$05 event wait at `$8269`: " \
			+ JSON.stringify({"record": record.hex_encode(), "pc": boundary.get("pc", -1),
				"sp": boundary.get("sp", -1), "payload": payload_pointer,
				"e6_e9": [ram[0x05E6], ram[0x05E7], ram[0x05E8], ram[0x05E9]],
				"flags": [ram[0x05F3], ram[0x05F4], ram[0x05F5], ram[0x0515]],
				"stream_y": [ram[0x005F], ram[0x0060], start_y],
				"stack_c4_cb": stack.slice(0xC4, 0xCB).hex_encode(),
				"registers": [start_a, start_x, start_y],
				"mapper": [mapper.get("bank_low", -1), mapper.get("bank_high", -1)]}))
	for stack_offset in STACK_SIZE:
		if int(ram[0x0100 + stack_offset]) != int(stack[stack_offset]):
			return _reject("The event wait RAM and physical stack snapshots differ at `$%02X`." % stack_offset)
	var cpu := {
		"pc": 0x8269, "sp": 0xC5, "a": start_a, "x": start_x, "y": start_y,
		"p": start_p, "p_known_mask": start_known,
	}
	var entry_cpu := cpu.duplicate(true)
	var entry_ram := ram.duplicate()
	var entry_stack := stack.duplicate()
	var ram_writes: Array[Dictionary] = []
	var stack_writes: Array[Dictionary] = []
	var stack_reads: Array[Dictionary] = []
	var source_reads: Array[Dictionary] = []
	var instruction_pcs: Array[int] = []
	var steps := 0
	while steps < 4096:
		var pc := int(cpu["pc"])
		if pc == 0x8266:
			var callsite_registers := cpu.duplicate(true)
			var callsite_stack := stack.duplicate()
			_jsr(cpu, stack, stack_writes, 0x8266, 0xC515)
			_read_event(source_reads, 0xC515, 0xC515, 0x4C, "task_yield_dispatch_opcode")
			cpu["pc"] = 0xCB0F
			instruction_pcs.append(0xC515)
			var yield_result := _waiter_yield_result(boundary, entry_cpu, entry_ram,
				entry_stack, cpu, mapper, ram, stack, ram_writes, stack_writes,
				stack_reads, source_reads, instruction_pcs, callsite_registers,
				callsite_stack, 0x8266, 0x8269, "slot11_actor_event_queue_at_cb0f")
			yield_result["source_span_hashes"] = _actor_event_wait_source_hashes(
				payload_pointer == 0x8FBF, scenario2e_actor6d_type5_profile)
			var decoded_event_queue := {
				"entry_flag_0515": int(entry_ram[0x0515]),
				"ready_flag_after_build": int(ram[0x0515]),
				"remaining_packet_count": int(ram[0x05E8]),
				"source_pointer": int(ram[0x0061]) | (int(ram[0x0062]) << 8),
				"stream_index_y": int(cpu["y"]),
				"packet_buffer": ram.slice(0x04A5, 0x04C0),
			}
			if scenario2e_actor6d_type5_profile:
				decoded_event_queue["actor_parameter"] = 0x6D
				decoded_event_queue["event_stream_pointer"] = 0x9BFE
				decoded_event_queue["type5_payload_source"] = 0x8FBF
			yield_result["decoded_event_queue"] = decoded_event_queue
			return yield_result
		var instruction_pc := pc
		instruction_pcs.append(instruction_pc)
		var opcode := _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
		if opcode < 0:
			return _unsupported("Event source fetch at `$%04X` is outside packaged ROM spans." % instruction_pc)
		steps += 1
		var operand := 0
		var address := 0
		var value := 0
		match opcode:
			0xAD: # LDA absolute
				address = _actor_event_fetch_word(cpu, instruction_pc, source_reads)
				value = _actor_event_read_memory(address, ram, instruction_pc, source_reads)
				if value < 0: return _unsupported("Event LDA at `$%04X` reads an unsupported address." % instruction_pc)
				_set_a(cpu, value)
			0xD0, 0xF0, 0x10, 0x90: # BNE, BEQ, BPL, BCC
				operand = _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
				if operand < 0: return _unsupported("Event branch operand is unavailable at `$%04X`." % instruction_pc)
				var take_branch := (opcode == 0xD0 and (int(cpu["p"]) & P_Z) == 0) \
					or (opcode == 0xF0 and (int(cpu["p"]) & P_Z) != 0) \
					or (opcode == 0x10 and (int(cpu["p"]) & P_N) == 0) \
					or (opcode == 0x90 and (int(cpu["p"]) & P_C) == 0)
				if take_branch:
					cpu["pc"] = (int(cpu["pc"]) + (operand if operand < 0x80 else operand - 0x100)) & 0xFFFF
			0xA9: # LDA immediate
				value = _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
				if value < 0: return _unsupported("Event immediate byte is unavailable at `$%04X`." % instruction_pc)
				_set_a(cpu, value)
			0xA2: # LDX immediate
				value = _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
				if value < 0: return _unsupported("Event LDX operand is unavailable at `$%04X`." % instruction_pc)
				_set_x(cpu, value)
			0x85, 0x8D, 0x9D: # STA zero-page, absolute, absolute-X
				if opcode == 0x85:
					address = _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
				else:
					address = _actor_event_fetch_word(cpu, instruction_pc, source_reads)
				if opcode == 0x9D: address = (address + int(cpu["x"])) & 0xFFFF
				if address < 0 or address >= RAM_SIZE:
					return _unsupported("Event STA at `$%04X` targets non-RAM `$%04X`." % [instruction_pc, address])
				_write_ram(ram, ram_writes, address, int(cpu["a"]), instruction_pc)
			0xBD: # LDA absolute-X
				address = (_actor_event_fetch_word(cpu, instruction_pc, source_reads) + int(cpu["x"])) & 0xFFFF
				value = _actor_event_read_memory(address, ram, instruction_pc, source_reads)
				if value < 0: return _unsupported("Event indexed LDA at `$%04X` reads an unsupported address." % instruction_pc)
				_set_a(cpu, value)
			0x68: # PLA
				_set_a(cpu, _pop(cpu, stack, stack_reads, instruction_pc))
			0x18, 0x38: # CLC, SEC
				_set_flag(cpu, P_C, opcode == 0x38)
			0x69, 0xE9: # ADC/SBC immediate
				value = _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
				if value < 0: return _unsupported("Event arithmetic operand is unavailable at `$%04X`." % instruction_pc)
				_actor_event_arithmetic(cpu, value, opcode == 0xE9)
			0xED: # SBC absolute
				address = _actor_event_fetch_word(cpu, instruction_pc, source_reads)
				value = _actor_event_read_memory(address, ram, instruction_pc, source_reads)
				if value < 0: return _unsupported("Event SBC at `$%04X` reads an unsupported address." % instruction_pc)
				_actor_event_arithmetic(cpu, value, true)
			0x48: # PHA
				_push(cpu, stack, stack_writes, int(cpu["a"]), instruction_pc, "PHA")
			0xE8, 0xC8: # INX, INY
				if opcode == 0xE8: _set_x(cpu, int(cpu["x"]) + 1)
				else: _set_y(cpu, int(cpu["y"]) + 1)
			0xB1: # LDA (zero-page),Y
				operand = _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
				if operand < 0: return _unsupported("Event indirect-Y operand is unavailable at `$%04X`." % instruction_pc)
				address = ((int(ram[operand]) | (int(ram[(operand + 1) & 0xFF]) << 8)) + int(cpu["y"])) & 0xFFFF
				value = _actor_event_read_memory(address, ram, instruction_pc, source_reads)
				if value < 0: return _unsupported("Event indirect-Y read at `$%04X` is outside packaged spans." % instruction_pc)
				_set_a(cpu, value)
			0x29: # AND immediate
				value = _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
				if value < 0: return _unsupported("Event AND operand is unavailable at `$%04X`." % instruction_pc)
				_set_a(cpu, int(cpu["a"]) & value)
			0xC6: # DEC zero-page
				address = _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
				if address < 0: return _unsupported("Event DEC operand is unavailable at `$%04X`." % instruction_pc)
				value = (int(ram[address]) - 1) & 0xFF
				_write_ram(ram, ram_writes, address, value, instruction_pc)
				_set_nz(cpu, value)
			0xCE, 0xEE: # DEC/INC absolute
				address = _actor_event_fetch_word(cpu, instruction_pc, source_reads)
				if address < 0 or address >= RAM_SIZE:
					return _unsupported("Event INC/DEC at `$%04X` targets unsupported RAM." % instruction_pc)
				value = (int(ram[address]) + (1 if opcode == 0xEE else -1)) & 0xFF
				_write_ram(ram, ram_writes, address, value, instruction_pc)
				_set_nz(cpu, value)
			0x8A: # TXA
				_set_a(cpu, int(cpu["x"]))
			0xCD: # CMP absolute
				address = _actor_event_fetch_word(cpu, instruction_pc, source_reads)
				value = _actor_event_read_memory(address, ram, instruction_pc, source_reads)
				if value < 0: return _unsupported("Event CMP at `$%04X` reads an unsupported address." % instruction_pc)
				_compare_a(cpu, value)
			0xAA: # TAX
				_set_x(cpu, int(cpu["a"]))
			0x60: # RTS
				_rts(cpu, stack, stack_reads, instruction_pc)
				if int(cpu["pc"]) == 0x804D:
					return _actor_event_return_result(boundary, entry_cpu, entry_ram,
						entry_stack, cpu, mapper, ram, stack, ram_writes, stack_writes,
						stack_reads, source_reads, instruction_pcs)
				if int(cpu["pc"]) != 0x8231:
					return _unsupported("The event queue source RTS returned to unexpected `$%04X`; only nested `$8231` and caller `$804D` returns are modeled." % int(cpu["pc"]))
			_:
				return _unsupported("Unmodeled opcode `$%02X` at actor-event PC `$%04X`." % [opcode, instruction_pc])
	return _unsupported("The ROM actor-event wait exceeded its bounded instruction count.")


func _actor_event_fetch_byte(cpu: Dictionary, instruction_pc: int,
		source_reads: Array[Dictionary]) -> int:
	var address := int(cpu["pc"]) & 0xFFFF
	var value := _read_actor_event_source_byte(address)
	if value >= 0:
		_read_event(source_reads, instruction_pc, address, value, "actor_event_rom_byte")
	cpu["pc"] = (address + 1) & 0xFFFF
	return value


func _actor_event_fetch_word(cpu: Dictionary, instruction_pc: int,
		source_reads: Array[Dictionary]) -> int:
	var low := _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
	var high := _actor_event_fetch_byte(cpu, instruction_pc, source_reads)
	if low < 0 or high < 0: return -1
	return low | (high << 8)


func _actor_event_read_memory(address: int, ram: PackedByteArray,
		instruction_pc: int, source_reads: Array[Dictionary]) -> int:
	if address >= 0 and address < RAM_SIZE:
		var value := int(ram[address])
		_read_event(source_reads, instruction_pc, address, value, "actor_event_ram_read")
		return value
	var source_value := _read_actor_event_source_byte(address)
	if source_value >= 0:
		_read_event(source_reads, instruction_pc, address, source_value, "actor_event_rom_data")
	return source_value


func _actor_event_arithmetic(cpu: Dictionary, operand: int, subtract: bool) -> void:
	var before := int(cpu["a"]) & 0xFF
	var carry_in := 1 if (int(cpu["p"]) & P_C) != 0 else 0
	var wide_result := before - operand - (1 - carry_in) if subtract \
		else before + operand + carry_in
	var result := wide_result & 0xFF
	_set_flag(cpu, P_C, wide_result >= 0 if subtract else wide_result > 0xFF)
	var overflow := ((before ^ result) & (before ^ operand) & 0x80) != 0 if subtract \
		else ((~(before ^ operand)) & (before ^ result) & 0x80) != 0
	_set_flag(cpu, P_V, overflow)
	_set_a(cpu, result)


func _actor_event_wait_source_hashes(include_type5: bool = false,
		include_parameter6d_stream: bool = false) -> Dictionary:
	var hashes := {
		ACTOR_EVENT_DISPATCH_FILE: "ad89d4999241da3618d8c3c06822986cb9f0ba561683e112c5ce71f2b5b05bfb",
		ACTOR_EVENT_QUEUE_CONSUMER_FILE: "2bfbf1443a6faaddd4fb0c06ddbf7936dd2370cde55c52477571c0df58a03a2a",
		ACTOR_EVENT_PAYLOAD_STREAM_FILE: "d07ed3b8e8583cc18718d8f5534cf8eda338ed192ae2285216c8f9793649d375",
		ACTOR_EVENT_PAYLOAD_STREAM_TYPE1_FILE: "375de5d8bd3612c321f2748c1235adbea1816467c44979b920decc1e49ec30de",
		ACTOR_EVENT_NEXT_STATE_TABLE_FILE: "ad93181c969ca4595a83c4837a6fa7c83bb2f8904590a6b018957de6237890ca",
		YIELD_TRAMPOLINE_FILE: "86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e",
	}
	if include_type5:
		hashes[ACTOR_EVENT_PAYLOAD_STREAM_TYPE5_FILE] = \
			"48b367fb4e65f7bc3507a96b4b160e02407755e5810f81a51072a7693cee37dd"
	if include_parameter6d_stream:
		hashes[PARAMETER6D_STREAM_FILE] = \
			"0b787ded174d6496196c978f5b835c4e89c9858a8499617b02bacc5b3f7b7d1e"
	return hashes


func _actor_event_return_result(boundary: Dictionary, entry_cpu: Dictionary,
		entry_ram: PackedByteArray, entry_stack: PackedByteArray, cpu: Dictionary,
		mapper: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		ram_writes: Array[Dictionary], stack_writes: Array[Dictionary],
		stack_reads: Array[Dictionary], source_reads: Array[Dictionary],
		instruction_pcs: Array[int]) -> Dictionary:
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	var payload_pointer := int(entry_ram[0x0061]) | (int(entry_ram[0x0062]) << 8)
	var is_scenario2e_actor6d_type5 := int(entry_ram[0x005F]) == 0xFE \
		and int(entry_ram[0x0060]) == 0x9B and int(entry_ram[0x05EA]) == 0x6D
	return {
		"ok": true, "status": "slot11_actor_event_queue_returned_to_804d",
		"rom_sha256": ROM_SHA256, "source_manifest": MANIFEST_PATH,
		"slot_base": SLOT_11, "entry_pc": int(boundary["pc"]), "exit_pc": 0x804D,
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu, "entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack, "exit_registers": cpu.duplicate(true),
		"mapper": mapper.duplicate(true), "ram_image": output_ram,
		"stack_page": stack.duplicate(), "ram_writes": ram_writes,
		"stack_writes": stack_writes, "stack_reads": stack_reads,
		"source_reads": source_reads, "instruction_pcs": instruction_pcs,
		"source_span_hashes": _actor_event_wait_source_hashes(
			payload_pointer == 0x8FBF or is_scenario2e_actor6d_type5,
			is_scenario2e_actor6d_type5),
		"ppu_bus_events": [], "apu_register_writes": [],
		"ppu_apu_effects_applied": false, "trace_state_used": false,
		"source_timing_modeled": false,
	}


func _waiter_yield_result(boundary: Dictionary, entry_cpu: Dictionary,
		entry_ram: PackedByteArray, entry_stack: PackedByteArray, cpu: Dictionary,
		mapper: Dictionary, ram: PackedByteArray, stack: PackedByteArray,
		ram_writes: Array[Dictionary], stack_writes: Array[Dictionary],
		stack_reads: Array[Dictionary], source_reads: Array[Dictionary],
		instruction_pcs: Array[int], callsite_registers: Dictionary,
		callsite_stack: PackedByteArray, callsite_pc: int = 0xCC50,
		resume_pc: int = 0xCC53,
		result_status: String = "slot11_actor_waiter_at_cb0f_from_cc53") -> Dictionary:
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": result_status,
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"slot_base": SLOT_11,
		"entry_pc": int(boundary["pc"]),
		"exit_pc": 0xCB0F,
		"yield_callsite_pc": callsite_pc,
		"yield_target_pc": 0xCB0F,
		"resume_pc_after_rts": resume_pc,
		"entry_record": PackedByteArray(boundary["record"]),
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"call_frame_already_pushed": true,
		"yield_callsite_registers": callsite_registers.duplicate(true),
		"yield_callsite_stack_page": callsite_stack.duplicate(),
		"cb0f_entry_registers": cpu.duplicate(true),
		"mapper": mapper.duplicate(true),
		"ram_image": output_ram,
		"stack_page": stack.duplicate(),
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"source_span_hashes": {
			WAITER_FILE: "dce4d011f0e612ea074e546e43c28c5395220f2af924a49aee4b35c2491775e3",
			PACKET_BUILDER_FILE: "681bf402c35efba946da16d63cb53787bf50ed5ba87261929c10d19906b66d0c",
			COUNTER_TAIL_FILE: "28ae864c35cf13601f8cb93f4bc13f0cadcd64b9d401fff6f0bef8e2b656bee0",
		},
		"scheduler_save_contract": {
			"slot_base": SLOT_11, "delay_in_a": int(callsite_registers["a"]),
			"callsite_pc": callsite_pc, "target_pc": 0xCB0F,
			"resume_pc": resume_pc, "call_frame_already_pushed": true,
			"pre_jsr_sp": int(callsite_registers["sp"]),
			"cb0f_entry_sp": int(cpu["sp"]),
			"rom_cb0f_push_order": ["X", "Y"],
			"expected_saved_sp_after_cb0f_pushes": (int(callsite_registers["sp"]) - 4) & 0xFF,
			"mapper_low_high": PackedByteArray([0x18, 0x19]),
		},
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"source_timing_modeled": false,
	}


func _result(boundary: Dictionary, entry_cpu: Dictionary, entry_ram: PackedByteArray,
		entry_stack: PackedByteArray, cpu: Dictionary, mapper: Dictionary,
		ram: PackedByteArray, stack: PackedByteArray, ram_writes: Array[Dictionary],
		stack_writes: Array[Dictionary], stack_reads: Array[Dictionary],
		source_reads: Array[Dictionary], instruction_pcs: Array[int],
		callsite_registers: Dictionary, callsite_stack: PackedByteArray) -> Dictionary:
	var output_ram := ram.duplicate()
	for stack_offset in STACK_SIZE:
		output_ram[0x0100 + stack_offset] = stack[stack_offset]
	return {
		"ok": true,
		"status": "slot11_actor_worker_at_cb0f_from_cc50",
		"rom_sha256": ROM_SHA256,
		"source_manifest": MANIFEST_PATH,
		"entry_pc": 0x804A,
		"exit_pc": 0xCB0F,
		"yield_callsite_pc": 0xCC50,
		"yield_target_pc": 0xCB0F,
		"resume_pc_after_rts": 0xCC53,
		"slot_base": SLOT_11,
		"entry_record": PackedByteArray(boundary["record"]),
		"source_span_hashes": {
			WORKER_FILE: "9c07722c85a0670f8986a7e7a680bc205a587881383fd84276e520806f465c6e",
			STREAM_FILE: "907c3653f2e64fa9d27a0a14a7dd38e404f0f1c05a97c0367be24e587f5ebadf",
			SELECTOR_FILE: "f4acc27853404adda00ba3dcee5f5f4ecdb2939a5d026a6d8f459261497d35b0",
			F5_HANDLER_FILE: "9ae06ade354ced65b80ae98704cd748b28b3fb80829dae0172ce09859fa37405",
			C52D_FILE: "eb93189d38ebaea8201970900e5b276a27c54c6fa2001a705945cb1d5172f371",
			WAITER_FILE: "dce4d011f0e612ea074e546e43c28c5395220f2af924a49aee4b35c2491775e3",
			"inline_dispatch": INLINE_DISPATCH_SHA256,
			"trampoline": TRAMPOLINE_SHA256,
		},
		"entry_registers": entry_cpu,
		"entry_ram_image": entry_ram,
		"entry_stack_page": entry_stack,
		"registers": cpu.duplicate(true),
		"yield_callsite_registers": callsite_registers.duplicate(true),
		"yield_callsite_stack_page": callsite_stack.duplicate(),
		"call_frame_already_pushed": true,
		"cb0f_entry_registers": cpu.duplicate(true),
		"mapper": mapper.duplicate(true),
		"ram_image": output_ram,
		"stack_page": stack,
		"ram_writes": ram_writes,
		"stack_writes": stack_writes,
		"stack_reads": stack_reads,
		"source_reads": source_reads,
		"instruction_pcs": instruction_pcs,
		"resolved_f4_target": 0x9F52,
		"resolved_f5_handler": 0x81FD,
		"scheduler_save_contract": {
			"slot_base": SLOT_11, "delay_in_a": 0x01,
			"callsite_pc": 0xCC50, "target_pc": 0xCB0F,
			"resume_pc": 0xCC53, "call_frame_already_pushed": true,
			"pre_jsr_sp": int(callsite_registers["sp"]),
			"cb0f_entry_sp": int(cpu["sp"]),
			"rom_cb0f_push_order": ["X", "Y"],
			"expected_saved_sp_after_cb0f_pushes": 0xBF,
			"mapper_low_high": PackedByteArray([0x18, 0x19]),
		},
		"ppu_bus_events": [],
		"apu_register_writes": [],
		"ppu_apu_effects_applied": false,
		"trace_state_used": false,
		"source_timing_modeled": false,
	}


func _load_parameter6d_sources() -> bool:
	var manifest_file := FileAccess.open(PARAMETER6D_MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Actor-$6D source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Actor-$6D source manifest is malformed.")
	var manifest: Dictionary = parsed
	var source_rom: Dictionary = manifest.get("source_rom", {})
	var actor: Dictionary = manifest.get("actor_parameter", {})
	if String(manifest.get("schema", "")) != "ct2-slot11-actor-parameter-6d-source-v1" \
			or String(source_rom.get("sha256", "")) != ROM_SHA256 \
			or String(actor.get("actor_parameter", "")) != "$6D" \
			or _manifest_hex(actor.get("entry_cpu_address", "0x0")) != 0x92FA \
			or String(actor.get("pointer_bytes_hex", "")).replace(" ", "").to_upper() != "E39B" \
			or _manifest_hex(actor.get("target_cpu_address", "0x0")) != 0x9BE3 \
			or _manifest_hex(actor.get("next_pointer_entry_cpu_address", "0x0")) != 0x92FC \
			or String(actor.get("next_pointer_bytes_hex", "")).replace(" ", "").to_upper() != "719C" \
			or _manifest_hex(actor.get("next_target_cpu_address", "0x0")) != 0x9C71:
		return _fail("Actor-$6D manifest provenance or pointer-table bounds differ from the verified ROM source.")
	var spans_by_file: Dictionary = {}
	for span_variant: Variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			spans_by_file[String(span.get("file", ""))] = span
	var expected_spans := {
		PARAMETER6D_POINTER_FILE: [0x92FA, 0x03130A, 2,
			"0aebdd98608aa88311ca8ab9bedd486c26160ed4a842df5297fd8572eb568bf4"],
		PARAMETER6D_STREAM_FILE: [0x9BE3, 0x031BF3, 142,
			"0b787ded174d6496196c978f5b835c4e89c9858a8499617b02bacc5b3f7b7d1e"],
	}
	for file_variant: Variant in expected_spans:
		var file_name := String(file_variant)
		var spec: Array = expected_spans[file_name]
		var span: Dictionary = spans_by_file.get(file_name, {})
		var path := PARAMETER6D_ROOT + file_name
		if span.is_empty() \
				or _manifest_hex(span.get("cpu_start", "0x0")) != int(spec[0]) \
				or _manifest_hex(span.get("file_offset", "0x0")) != int(spec[1]) \
				or int(span.get("length_bytes", -1)) != int(spec[2]) \
				or String(span.get("sha256", "")) != String(spec[3]) \
				or not FileAccess.file_exists(path):
			return _fail("Actor-$6D manifest mapping or source artifact differs for %s." % file_name)
		var source := FileAccess.get_file_as_bytes(path)
		if source.size() != int(spec[2]) or _sha256(source) != String(spec[3]) \
				or String(span.get("bytes_hex", "")).replace(" ", "").to_lower() != source.hex_encode():
			return _fail("Actor-$6D ROM-derived bytes failed validation for %s." % file_name)
		_sources[file_name] = source
	return true


func _load_animation_index2_sources() -> bool:
	var manifest_file := FileAccess.open(ANIMATION_INDEX2_MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return _fail("Animation-index-$02 source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Animation-index-$02 source manifest is malformed.")
	var manifest: Dictionary = parsed
	var layout: Dictionary = manifest.get("rom_layout", {})
	if int(manifest.get("schema_version", -1)) != 1 \
			or String(manifest.get("rom_sha256", "")) != ROM_SHA256 \
			or String(layout.get("format", "")) != "iNES" \
			or int(layout.get("mapper", -1)) != 4 \
			or int(layout.get("prg_size_bytes", -1)) != 262144 \
			or String(layout.get("cpu_window", "")) != "0xA000-0xBFFF" \
			or String(layout.get("prg_8k_bank", "")) != "0x1B":
		return _fail("Animation-index-$02 manifest provenance or bank mapping differs from the verified ROM source.")
	var spans_by_file: Dictionary = {}
	for span_variant: Variant in manifest.get("spans", []):
		if span_variant is Dictionary:
			var span: Dictionary = span_variant
			spans_by_file[String(span.get("file", ""))] = span
	var expected_spans := {
		ANIMATION_STREAM_INDEX2_FILE: [0xA2E8, 0xA2FC, 0x0362F8, 21,
			"424adf7357d292bb49f97104a0e091edb8e4705a81d0698984fbbcd94b13ab66"],
		ANIMATION_INDEX2_PACKET_POINTER_TABLE_FILE: [0xA42A, 0xA439, 0x03643A, 16,
			"1e692b18504e8fad80b9172d657f448d147d9c1ed65ff05ea8b8bfb8409e4dc1"],
		ANIMATION_PPU_PACKETS_05_FILE: [0xA4C3, 0xA4E7, 0x0364D3, 37,
			"f82521c259c81ec916a28e42ed2744a59cbb2abe8521081fd23c9d9690c28b93"],
		ANIMATION_PPU_PACKETS_06_FILE: [0xA4E8, 0xA4EC, 0x0364F8, 5,
			"b07bc05cce10fd5c335a4d677dcd13fdb168227f64b358dd25b5eeca550fcf1e"],
		ANIMATION_PPU_PACKETS_07_FILE: [0xA4ED, 0xA4F1, 0x0364FD, 5,
			"0630624ed694ebb370c1539d4da0be8778264c6a596ae6bcb697d26253252b00"],
	}
	for file_variant: Variant in expected_spans:
		var file_name := String(file_variant)
		var spec: Array = expected_spans[file_name]
		var span: Dictionary = spans_by_file.get(file_name, {})
		var path := ANIMATION_INDEX2_ROOT + file_name
		if span.is_empty() \
				or String(span.get("bank", "")) != "bank1b" \
				or _manifest_hex(span.get("cpu_start", "0x0")) != int(spec[0]) \
				or _manifest_hex(span.get("cpu_end_inclusive", "0x0")) != int(spec[1]) \
				or _manifest_hex(span.get("file_offset", "0x0")) != int(spec[2]) \
				or int(span.get("length", -1)) != int(spec[3]) \
				or String(span.get("sha256", "")) != String(spec[4]) \
				or not FileAccess.file_exists(path):
			return _fail("Animation-index-$02 manifest mapping or source artifact differs for %s." % file_name)
		var source := FileAccess.get_file_as_bytes(path)
		if source.size() != int(spec[3]) or _sha256(source) != String(spec[4]) \
				or String(span.get("bytes_hex", "")).replace(" ", "").to_lower() != source.hex_encode():
			return _fail("Animation-index-$02 ROM-derived bytes failed validation for %s." % file_name)
		_sources[file_name] = source
	return true


func _expect(file_name: String, cpu_address: int, expected: Array[int]) -> bool:
	if not _sources.has(file_name):
		return false
	var base := _source_base(file_name)
	var source: PackedByteArray = _sources[file_name]
	var offset := cpu_address - base
	if offset < 0 or offset + expected.size() > source.size():
		return false
	for index: int in expected.size():
		if int(source[offset + index]) != expected[index]:
			return false
	return true


func _source_base(file_name: String) -> int:
	match file_name:
		WORKER_FILE: return 0x804A
		STREAM_EVENT_DISPATCH_FILE: return 0x8218
		ACTOR_EVENT_DISPATCH_FILE: return 0x8218
		ACTOR_EVENT_QUEUE_CONSUMER_FILE: return 0x8273
		ACTOR_EVENT_NEXT_STATE_TABLE_FILE: return 0x86C8
		ACTOR_EVENT_TYPE5_LOOKUP_FILE: return 0x86BD
		ACTOR_EVENT_POINTER_TYPE5_FILE: return 0x8DCC
		ACTOR_EVENT_PAYLOAD_STREAM_FILE: return 0x8E94
		ACTOR_EVENT_PAYLOAD_STREAM_TYPE1_FILE: return 0x8E37
		ACTOR_EVENT_PAYLOAD_STREAM_TYPE5_FILE: return 0x8FBF
		ACTOR_PACKET_RESUME_FILE: return 0x82F7
		ACTOR_PACKET_RESUME_CONTINUATION_FILE: return 0x8653
		RECORD_POINTER_TABLE_FILE: return 0xCD89
		ACTOR_PACKET_ROW_ADDRESS_FILE: return 0x86E8
		TEXT_POINTER_LOOKUP_FILE: return 0xF30F
		PARAMETER47_ACTOR_TEXT_POINTER_FILE: return 0xF329
		TEXT_POINTER_76_FILE: return 0xF415
		ACTOR_TEXT_76_FILE: return 0xF776
		STREAM_SHORT_EVENT_FILE: return 0x81D1
		STREAM_FILE: return 0x9F42
		STREAM_FOLLOWUP_FILE: return 0x9F54
		PARAMETER47_STREAM_FILE: return 0x9917
		PARAMETER00_STREAM_FILE: return 0x9400
		PARAMETER58_STREAM_FILE: return 0x9A62
		PARAMETER6D_POINTER_FILE: return 0x92FA
		PARAMETER6D_STREAM_FILE: return 0x9BE3
		RECORD_POINTER_TABLE_FULL_FILE: return 0xCD89
		TEXT_STREAM_F53A_FILE: return 0xF53A
		SEQUENCE_ROW_HANDLER_FILE: return 0x811E
		F4_SELECTOR03_TABLE_FILE: return 0xA3BD
		"inline_dispatch": return 0xC509
		ACTOR_EVENT_STREAM_FILE: return 0xA3C9
		ACTOR_EVENT_STREAM_TEXT_FILE: return 0xA43D
		SELECTOR_FILE: return 0x8122
		F5_HANDLER_FILE: return 0x81FD
		C52D_FILE: return 0xC52D
		WAITER_FILE: return 0xCC46
		PACKET_BUILDER_FILE: return 0xCC53
		COUNTER_TAIL_FILE: return 0xCC9E
		F5_TAIL_FILE: return 0x8200
		C560_STUB_FILE: return 0xC560
		CF72_WRAPPER_FILE: return 0xCF72
		BANK1A_ENTRY_FILE: return 0x802A
		ANIMATION_GATE_FILE: return 0xA1EB
		ANIMATION_INDEX_FILE: return 0xA2AC
		ANIMATION_INDEX_TABLE_FILE: return 0xA292
		ANIMATION_COMMAND_LOOP_FILE: return 0xA21A
		ANIMATION_STREAM_FILE: return 0xA425
		ANIMATION_STREAM_ZERO_FILE: return 0xA2AE
		ANIMATION_STREAM_INDEX1_FILE: return 0xA2CB
		ANIMATION_STREAM_INDEX2_FILE: return 0xA2E8
		ANIMATION_POINTER_FILE: return 0xA42A
		ANIMATION_PACKET_POINTER_TABLE_FILE: return 0xA42A
		ANIMATION_INDEX2_PACKET_POINTER_TABLE_FILE: return 0xA42A
		ANIMATION_PACKET_WAIT_FILE: return 0x82F2
		ANIMATION_PPU_PACKETS_FILE: return 0xA46A
		ANIMATION_PPU_PACKETS_01_FILE: return 0xA48F
		ANIMATION_PPU_PACKETS_02_FILE: return 0xA494
		ANIMATION_PPU_PACKETS_03_FILE: return 0xA499
		ANIMATION_PPU_PACKETS_04_FILE: return 0xA49E
		ANIMATION_PPU_PACKETS_05_FILE: return 0xA4C3
		ANIMATION_PPU_PACKETS_06_FILE: return 0xA4E8
		ANIMATION_PPU_PACKETS_07_FILE: return 0xA4ED
	return -1


func _read_bank18(address: int) -> int:
	var worker_prefix: PackedByteArray = _sources.get("worker_prefix", PackedByteArray())
	if address >= 0x8000 and address < 0x8000 + worker_prefix.size():
		return int(worker_prefix[address - 0x8000])
	if address >= 0x9BE3 and address < 0x9BE3 + _sources[PARAMETER6D_STREAM_FILE].size():
		return int(_sources[PARAMETER6D_STREAM_FILE][address - 0x9BE3])
	if address >= 0x9917 and address < 0x9917 + _sources[PARAMETER47_STREAM_FILE].size():
		return int(_sources[PARAMETER47_STREAM_FILE][address - 0x9917])
	if address >= 0x9A62 and address < 0x9A62 + _sources[PARAMETER58_STREAM_FILE].size():
		return int(_sources[PARAMETER58_STREAM_FILE][address - 0x9A62])
	if address >= 0x804A and address < 0x804A + _sources[WORKER_FILE].size():
		return int(_sources[WORKER_FILE][address - 0x804A])
	if address >= 0x82F2 and address < 0x82F2 + _sources[ANIMATION_PACKET_WAIT_FILE].size():
		return int(_sources[ANIMATION_PACKET_WAIT_FILE][address - 0x82F2])
	if address >= 0x82F7 and address < 0x82F7 + _sources[ACTOR_PACKET_RESUME_FILE].size():
		return int(_sources[ACTOR_PACKET_RESUME_FILE][address - 0x82F7])
	if address >= 0x8653 and address < 0x8653 + _sources[ACTOR_PACKET_RESUME_CONTINUATION_FILE].size():
		return int(_sources[ACTOR_PACKET_RESUME_CONTINUATION_FILE][address - 0x8653])
	if address >= 0x875A and address < 0x875A + _sources[PARAMETER47_INDEX1_PACKET_LOOKUP_FILE].size():
		return int(_sources[PARAMETER47_INDEX1_PACKET_LOOKUP_FILE][address - 0x875A])
	if address >= 0x86E8 and address < 0x86E8 + _sources[ACTOR_PACKET_ROW_ADDRESS_FILE].size():
		return int(_sources[ACTOR_PACKET_ROW_ADDRESS_FILE][address - 0x86E8])
	if address >= 0x8122 and address < 0x8122 + _sources[SELECTOR_FILE].size():
		return int(_sources[SELECTOR_FILE][address - 0x8122])
	if address >= 0x811E and address < 0x811E + _sources[SEQUENCE_ROW_HANDLER_FILE].size():
		return int(_sources[SEQUENCE_ROW_HANDLER_FILE][address - 0x811E])
	if address >= 0x81FD and address < 0x81FD + _sources[F5_HANDLER_FILE].size():
		return int(_sources[F5_HANDLER_FILE][address - 0x81FD])
	return -1


func _read_packet_resume_rom_byte(address: int, mapper: Dictionary) -> int:
	if address >= 0x8000 and address < 0xA000:
		match int(mapper.get("bank_low", -1)):
			0x18: return _read_bank18(address)
			0x1A:
				if address >= 0x802A and address < 0x802A + _sources[BANK1A_ENTRY_FILE].size():
					return int(_sources[BANK1A_ENTRY_FILE][address - 0x802A])
			_: return -1
	if address >= 0xA000 and address < 0xC000:
		match int(mapper.get("bank_high", -1)):
			0x19: return _read_stream_byte(address)
			0x1B:
				for source_spec: Array in [
					[ANIMATION_GATE_FILE, 0xA1EB],
					[ANIMATION_INDEX_TABLE_FILE, 0xA292],
					[ANIMATION_STREAM_ZERO_FILE, 0xA2AE],
					[ANIMATION_STREAM_INDEX1_FILE, 0xA2CB],
					[ANIMATION_STREAM_INDEX2_FILE, 0xA2E8],
					[ANIMATION_INDEX2_PACKET_POINTER_TABLE_FILE, 0xA42A],
					[ANIMATION_PPU_PACKETS_05_FILE, 0xA4C3],
					[ANIMATION_PPU_PACKETS_06_FILE, 0xA4E8],
					[ANIMATION_PPU_PACKETS_07_FILE, 0xA4ED],
				]:
					var source: PackedByteArray = _sources[String(source_spec[0])]
					var offset := address - int(source_spec[1])
					if offset >= 0 and offset < source.size():
						return int(source[offset])
			_: return -1
	if address >= 0xC000 and address < 0xE000:
		for source_spec: Array in [
			["inline_dispatch", 0xC509],
			["record_pointer_vector", 0xC50C],
			[YIELD_TRAMPOLINE_FILE, 0xC515],
			["text_helper_vector", 0xC524],
			["text_pointer_vector", 0xC53C],
			[C560_STUB_FILE, 0xC560],
			["record_pointer_resolver", 0xCD7C],
			[RECORD_POINTER_TABLE_FILE, 0xCD89],
			[RECORD_POINTER_TABLE_FULL_FILE, 0xCD89],
			["mapper_helper", 0xCE2D],
			[CF72_WRAPPER_FILE, 0xCF72],
			["trampoline", 0xCB99],
			["text_token_converter", 0xCBC2],
		]:
			var source: PackedByteArray = _sources[String(source_spec[0])]
			var offset := address - int(source_spec[1])
			if offset >= 0 and offset < source.size():
				return int(source[offset])
		return -1
	if address >= 0xE000:
		for source_spec: Array in [
			[TEXT_POINTER_LOOKUP_FILE, 0xF30F],
			[PARAMETER47_ACTOR_TEXT_POINTER_FILE, 0xF329],
			[TEXT_POINTER_TABLE_FILE, 0xF329],
			[TEXT_STREAM_E6_FILE, 0xFAB0],
			[TEXT_STREAM_F9A4_FILE, 0xF9A4],
			[TEXT_STREAM_F53A_FILE, 0xF53A],
			[TEXT_POINTER_76_FILE, 0xF415],
			[ACTOR_TEXT_76_FILE, 0xF776],
			[PLAYER_NAME_POINTER_08_FILE, 0xF339],
			[PLAYER_NAME_STREAM_08_FILE, 0xF52B],
		]:
			var source: PackedByteArray = _sources[String(source_spec[0])]
			var offset := address - int(source_spec[1])
			if offset >= 0 and offset < source.size():
				return int(source[offset])
	return -1


func _read_stream_byte(address: int) -> int:
	var parameter6d_offset := address - 0x9BE3
	var parameter6d_stream: PackedByteArray = _sources[PARAMETER6D_STREAM_FILE]
	if parameter6d_offset >= 0 and parameter6d_offset < parameter6d_stream.size():
		return int(parameter6d_stream[parameter6d_offset])
	var parameter58_offset := address - 0x9A62
	var parameter58_stream: PackedByteArray = _sources[PARAMETER58_STREAM_FILE]
	if parameter58_offset >= 0 and parameter58_offset < parameter58_stream.size():
		return int(parameter58_stream[parameter58_offset])
	var parameter00_offset := address - 0x9400
	var parameter00_stream: PackedByteArray = _sources[PARAMETER00_STREAM_FILE]
	if parameter00_offset >= 0 and parameter00_offset < parameter00_stream.size():
		return int(parameter00_stream[parameter00_offset])
	var parameter47_offset := address - 0x9917
	var parameter47_stream: PackedByteArray = _sources[PARAMETER47_STREAM_FILE]
	if parameter47_offset >= 0 and parameter47_offset < parameter47_stream.size():
		return int(parameter47_stream[parameter47_offset])
	var selector03_offset := address - 0xA3BD
	var selector03_table: PackedByteArray = _sources[F4_SELECTOR03_TABLE_FILE]
	if selector03_offset >= 0 and selector03_offset < selector03_table.size():
		return int(selector03_table[selector03_offset])
	var offset := address - 0x9F42
	var stream: PackedByteArray = _sources[STREAM_FILE]
	if offset >= 0 and offset < stream.size():
		return int(stream[offset])
	var followup_offset := address - 0x9F54
	var followup: PackedByteArray = _sources[STREAM_FOLLOWUP_FILE]
	if followup_offset >= 0 and followup_offset < followup.size():
		return int(followup[followup_offset])
	var actor_event_offset := address - 0xA3C9
	var actor_event: PackedByteArray = _sources[ACTOR_EVENT_STREAM_FILE]
	if actor_event_offset >= 0 and actor_event_offset < actor_event.size():
		return int(actor_event[actor_event_offset])
	var actor_event_continuation: PackedByteArray = _sources[ACTOR_EVENT_STREAM_CONTINUATION_FILE]
	var actor_event_continuation_offset := address - 0xA43C
	if actor_event_continuation_offset >= 0 and actor_event_continuation_offset < actor_event_continuation.size():
		return int(actor_event_continuation[actor_event_continuation_offset])
	var actor_event_text: PackedByteArray = _sources[ACTOR_EVENT_STREAM_TEXT_FILE]
	var actor_event_text_offset := address - 0xA43D
	if actor_event_text_offset >= 0 and actor_event_text_offset < actor_event_text.size():
		return int(actor_event_text[actor_event_text_offset])
	return -1


func _is_scenario1c_actor00_seed_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x01, 0x40, 0x1C, 0x30]) \
		and int(ram[0x051B]) == 0x9B \
		and int(ram[0x0522]) == 0x02 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x30, 0x1F, 0x02, 0x3C, 0x4A, 0x4C, 0x00, 0x40]) \
		and ram.slice(0x05C7, 0x05D2) == PackedByteArray([
			0x40, 0xA0, 0x00, 0x00, 0x01, 0x52, 0xA0, 0x80, 0x00, 0x02, 0x80]) \
		and int(ram[0x05D2]) == 0x01 \
		and int(ram[0x05CE]) == 0x80


## The live slot-$11 worker starts on the frame after the seed's first root
## countdown tick: `$ED5B` has changed `$0519` from `$30` to `$2F`. Keep the
## parameter-$00 F2 stream admission tied to that exact source state.
func _is_scenario1c_actor00_live_worker_profile(ram: PackedByteArray) -> bool:
	return ram.size() == RAM_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x01, 0x40, 0x1C, 0x2F]) \
		and int(ram[0x003A]) == 0x06 \
		and int(ram[0x051B]) == 0x9B \
		and int(ram[0x0522]) == 0x02 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x30, 0x1F, 0x02, 0x3C, 0x4A, 0x4C, 0x00, 0x40]) \
		and ram.slice(0x005D, 0x005F) == PackedByteArray([0x4F, 0xBB]) \
		and int(ram[0x0539]) == 0x00 \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x40, 0xA0, 0x00, 0x00, 0x01, 0x52, 0xA0, 0x80, 0x00, 0x02, 0x80, 0x01])


## PASS frame 9476's slot-$11 dispatch state: scenario `$2E`, callback `$36`,
## map `$2F`, actor `$6D`, pointer `$9BE3`, and the recorded CPU/stack context.
## This admits the captured live task profile only; no trace RAM is used as a seed.
func _is_scenario2e_callback36_map2f_actor6d_live_worker_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary) -> bool:
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
		and ram.slice(0x0516, 0x051A) == PackedByteArray([0x01, 0x00, 0x2E, 0x78]) \
		and ram.slice(0x051A, 0x051D) == PackedByteArray([0xE8, 0x9B, 0x00]) \
		and int(ram[0x0522]) == 0x00 \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([
			0x78, 0x36, 0x02, 0x3C, 0x4A, 0x8B, 0x6D, 0x00]) \
		and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x005D, 0x0061) == PackedByteArray([0x53, 0xB7, 0xE3, 0x9B]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x01, 0x01, 0x2F, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
		and ram.slice(0x05E3, 0x05EB) == PackedByteArray([
			0x01, 0x00, 0x00, 0x0E, 0x02, 0x02, 0x00, 0x6D]) \
		and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
		and ram.slice(0x0063, 0x0065) == PackedByteArray([0xBA, 0xA2]) \
		and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
		and int(ram[0x0629]) == 0x00 \
		and stack.slice(0xC7, 0xCB) == PackedByteArray([0x04, 0x04, 0x49, 0x80]) \
		and int(boundary.get("a", -1)) == 0x01 \
		and int(boundary.get("x", -1)) == 0xE3 \
		and int(boundary.get("y", -1)) == 0xDB \
		and int(boundary.get("p", -1)) == 0x30


## Frame-9477's repeated FCEUX trace captures the next live `$804A` entry after
## the scenario counter advances from `$78` to `$77`. It is the same `$9BE3`
## `$F2` waiter route, with the scheduler-restored stack/register signature.
func _is_scenario2e_callback36_map2f_actor6d_f2_waiter_entry_profile(
		ram: PackedByteArray, stack: PackedByteArray, boundary: Dictionary) -> bool:
	return ram.size() == RAM_SIZE and stack.size() == STACK_SIZE \
		and ram.slice(0x0516, 0x051D) == PackedByteArray([0x01, 0x00, 0x2E, 0x77, 0xE8, 0x9B, 0x00]) \
		and ram.slice(0x0523, 0x052B) == PackedByteArray([0x78, 0x36, 0x02, 0x3C, 0x4A, 0x8B, 0x6D, 0x00]) \
		and int(ram[0x003A]) == 0x06 \
		and ram.slice(0x005D, 0x0061) == PackedByteArray([0x53, 0xB7, 0xE3, 0x9B]) \
		and ram.slice(0x05C7, 0x05D3) == PackedByteArray([
			0x24, 0xC0, 0x00, 0x01, 0x01, 0x2F, 0x80, 0xA0, 0x00, 0x02, 0x00, 0x00]) \
		and ram.slice(0x05E3, 0x05EB) == PackedByteArray([0x01, 0x00, 0x00, 0x0E, 0x02, 0x02, 0x00, 0x6D]) \
		and ram.slice(0x05F3, 0x05F6) == PackedByteArray([0x00, 0x00, 0x01]) \
		and ram.slice(0x0063, 0x0065) == PackedByteArray([0xBA, 0xA2]) \
		and int(ram[0x0515]) == 0x00 and int(ram[0x0022]) == 0x00 \
		and int(ram[0x0629]) == 0x00 \
		and stack.slice(0xC7, 0xCB) == PackedByteArray([0xDB, 0xE3, 0x49, 0x80]) \
		and int(boundary.get("a", -1)) == 0xE3 \
		and int(boundary.get("x", -1)) == 0xE3 \
		and int(boundary.get("y", -1)) == 0xDB


func _read_actor_event_source_byte(address: int) -> int:
	for source_spec: Array in [
		[ACTOR_EVENT_DISPATCH_FILE, 0x8218],
		[ACTOR_EVENT_QUEUE_CONSUMER_FILE, 0x8273],
		[ACTOR_EVENT_NEXT_STATE_TABLE_FILE, 0x86C8],
		[ACTOR_EVENT_PAYLOAD_STREAM_TYPE1_FILE, 0x8E37],
		[ACTOR_EVENT_PAYLOAD_STREAM_FILE, 0x8E94],
		[ACTOR_EVENT_PAYLOAD_STREAM_TYPE5_FILE, 0x8FBF],
	]:
		var source_bytes: PackedByteArray = _sources[String(source_spec[0])]
		var source_offset := address - int(source_spec[1])
		if source_offset >= 0 and source_offset < source_bytes.size():
			return int(source_bytes[source_offset])
	for source_spec: Array in [
		[ACTOR_EVENT_TYPE_TABLE_FILE, 0x86B8],
		[ACTOR_EVENT_POINTER_TABLE_FILE, 0x8DC4],
		[ACTOR_EVENT_TYPE5_LOOKUP_FILE, 0x86BD],
		[ACTOR_EVENT_POINTER_TYPE5_FILE, 0x8DCC],
		[ACTOR_EVENT_PAYLOAD_TYPE1_FILE, 0x8E37],
		[ACTOR_EVENT_PAYLOAD_TYPE2_FILE, 0x8E94],
	]:
		var bytes: PackedByteArray = _sources[String(source_spec[0])]
		var offset := address - int(source_spec[1])
		if offset >= 0 and offset < bytes.size():
			return int(bytes[offset])
	return -1


func _jsr(cpu: Dictionary, stack: PackedByteArray,
		stack_writes: Array[Dictionary], pc: int, target: int) -> void:
	var return_word := (pc + 2) & 0xFFFF
	_push(cpu, stack, stack_writes, (return_word >> 8) & 0xFF, pc, "JSR_high")
	_push(cpu, stack, stack_writes, return_word & 0xFF, pc, "JSR_low")
	cpu["pc"] = target


func _rts(cpu: Dictionary, stack: PackedByteArray, stack_reads: Array[Dictionary], pc: int) -> void:
	var low := _stack_pop_raw(cpu, stack, stack_reads, pc)
	var high := _stack_pop_raw(cpu, stack, stack_reads, pc)
	cpu["pc"] = (((high << 8) | low) + 1) & 0xFFFF


func _push(cpu: Dictionary, stack: PackedByteArray,
		stack_writes: Array[Dictionary], value: int, pc: int, kind: String) -> void:
	var sp := int(cpu["sp"]) & 0xFF
	var byte_value := value & 0xFF
	stack[sp] = byte_value
	stack_writes.append({"pc": pc, "address": 0x0100 | sp, "value": byte_value, "kind": kind})
	cpu["sp"] = (sp - 1) & 0xFF


func _pop(cpu: Dictionary, stack: PackedByteArray, stack_reads: Array[Dictionary], pc: int) -> int:
	var value := _stack_pop_raw(cpu, stack, stack_reads, pc)
	_set_a(cpu, value)
	return value


func _stack_pop_raw(cpu: Dictionary, stack: PackedByteArray,
		stack_reads: Array[Dictionary], pc: int) -> int:
	var sp := (int(cpu["sp"]) + 1) & 0xFF
	cpu["sp"] = sp
	var value := int(stack[sp])
	stack_reads.append({"pc": pc, "address": 0x0100 | sp, "value": value})
	return value


func _write_ram(ram: PackedByteArray, writes: Array[Dictionary], address: int, value: int, pc: int) -> void:
	var byte_value := value & 0xFF
	ram[address] = byte_value
	writes.append({"pc": pc, "address": address, "value": byte_value})


func _set_mapper_pair_register(mapper: Dictionary, writes: Array[Dictionary],
		value: int, bank_register: int, pc: int, select_write: bool = false) -> void:
	var byte_value := value & 0xFF
	if select_write:
		mapper["select"] = bank_register
		writes.append({"pc": pc, "address": 0x8000, "value": byte_value,
			"select": bank_register})
		return
	var registers_variant: Variant = mapper.get("bank_registers", {})
	var registers: Dictionary = registers_variant.duplicate(true) if registers_variant is Dictionary else {}
	var selected := int(mapper.get("select", -1))
	if bank_register not in [6, 7] or selected != bank_register:
		return
	registers[bank_register] = byte_value
	mapper["bank_registers"] = registers
	mapper["bank_low"] = int(registers.get(6, registers.get("6", -1)))
	mapper["bank_high"] = int(registers.get(7, registers.get("7", -1)))
	writes.append({"pc": pc, "address": 0x8001, "value": byte_value,
		"select": bank_register})


func _read_event(events: Array[Dictionary], pc: int, address: int, value: int, kind: String) -> void:
	events.append({"pc": pc, "address": address, "value": value & 0xFF, "kind": kind})


func _apply_animation_mapper_helper(ram: PackedByteArray, mapper: Dictionary,
		ram_writes: Array[Dictionary], mapper_writes: Array[Dictionary],
		source_reads: Array[Dictionary], instruction_pcs: Array[int]) -> void:
	for offset in [0, 2, 3, 6, 9, 11, 13, 14, 15, 17, 18, 21, 23, 24, 27, 28]:
		instruction_pcs.append(0xCE2D + offset)
	var selector_low := int(ram[0x0022]) | 0x06
	_write_ram(ram, ram_writes, 0x0023, selector_low, 0xCE31)
	_set_mapper_pair_register(mapper, mapper_writes, selector_low, 6, 0xCE33, true)
	_read_event(source_reads, 0xCE36, 0x0024, int(ram[0x0024]), "mapper_bank_6_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0024]), 6, 0xCE38)
	var selector_high := int(ram[0x0022]) | 0x07
	_write_ram(ram, ram_writes, 0x0023, selector_high, 0xCE3F)
	_set_mapper_pair_register(mapper, mapper_writes, selector_high, 7, 0xCE41, true)
	_read_event(source_reads, 0xCE44, 0x0025, int(ram[0x0025]), "mapper_bank_7_value")
	_set_mapper_pair_register(mapper, mapper_writes, int(ram[0x0025]), 7, 0xCE46)


func _set_a(cpu: Dictionary, value: int) -> void:
	cpu["a"] = value & 0xFF
	_set_nz(cpu, int(cpu["a"]))


func _set_x(cpu: Dictionary, value: int) -> void:
	cpu["x"] = value & 0xFF
	_set_nz(cpu, int(cpu["x"]))


func _set_y(cpu: Dictionary, value: int) -> void:
	cpu["y"] = value & 0xFF
	_set_nz(cpu, int(cpu["y"]))


func _set_nz(cpu: Dictionary, value: int) -> void:
	var p := int(cpu["p"]) & ~(P_N | P_Z)
	if (value & 0x80) != 0:
		p |= P_N
	if (value & 0xFF) == 0:
		p |= P_Z
	cpu["p"] = p
	cpu["p_known_mask"] = int(cpu["p_known_mask"]) | P_N | P_Z


func _set_flag(cpu: Dictionary, flag: int, enabled: bool) -> void:
	var p := int(cpu["p"])
	if enabled:
		p |= flag
	else:
		p &= ~flag
	cpu["p"] = p & 0xFF
	cpu["p_known_mask"] = int(cpu["p_known_mask"]) | flag


func _manifest_hex(value: Variant) -> int:
	var text := String(value).to_lower()
	if text.begins_with("0x"):
		text = text.substr(2)
	return text.hex_to_int()


func _compare_a(cpu: Dictionary, value: int) -> void:
	var before := int(cpu["a"]) & 0xFF
	var difference := (before - (value & 0xFF)) & 0xFF
	_set_flag(cpu, P_C, before >= (value & 0xFF))
	_set_nz(cpu, difference)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _reject(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "rejected_boundary", "error": reason, "source_manifest": MANIFEST_PATH}


func _unsupported(reason: String) -> Dictionary:
	error_message = reason
	return {"ok": false, "status": "unsupported_live_branch", "error": reason, "source_manifest": MANIFEST_PATH}


func _fail(reason: String) -> bool:
	error_message = reason
	return false
