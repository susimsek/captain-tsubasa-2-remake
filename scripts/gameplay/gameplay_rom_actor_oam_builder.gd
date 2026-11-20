extends RefCounted
class_name GameplayRomActorOamBuilder
## Interprets the supplied game's bank-$16 actor sprite streams.
##
## Inputs are live actor records, shared sprite selector/mirror/scroll state,
## the ROM Y clip window, and the caller's current 256-byte OAM shadow. This
## builder never reads the NES ROM file, endpoint snapshots, screenshots, or
## captured OAM. It returns updated OAM bytes for a caller-owned renderer.

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const MANIFEST_PATH := "res://reference/rom_extract/gameplay/actor_oam/manifest.json"

const EXPECTED_SEGMENTS := {
	"sprite_engine_8000_8185": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_sprite_engine_8000_8185.bin",
		"cpu_start": 0x8000,
		"length": 0x186,
		"sha256": "4c8913c90c578a7924f74b8a94b91ff5ac4b059c7c9e7304d3f48a7ae67f9894",
	},
	"sprite_offsets_81d2_8239": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_sprite_offsets_81d2_8239.bin",
		"cpu_start": 0x81D2,
		"length": 0x68,
		"sha256": "7cbf389d7e51e0b550b95a5a11cbb6840320c95e3a25215f4553c2b15b06214d",
	},
	"sprite_descriptor_pointers_8280_842b": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_sprite_descriptor_pointers_8280_842b.bin",
		"cpu_start": 0x8280,
		"length": 0x1AC,
		"sha256": "1940d28401f83302f9dd3fbeb8660e2bbf9f522aae8fbc97b70215975e1f704c",
	},
	"live_e6_descriptor_ca_terminator_bd45": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_live_e6_descriptor_CA_terminator_BD45.bin",
		"cpu_start": 0xBD45,
		"length": 1,
		"sha256": "68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4",
	},
	"live_e6_descriptor_ca_stream_bdd5_bde1": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_live_e6_descriptor_CA_stream_BDD5_BDE1.bin",
		"cpu_start": 0xBDD5,
		"length": 0x0D,
		"sha256": "98dcd0980d3a3bd0a4552309d3ea10cda3d9ec9d9c2662e445ad065a1c0721ef",
	},
	"animation66_descriptor_pointer_9e_83bc_83bd": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_pointer_9E_83BC_83BD.bin",
		"cpu_start": 0x83BC,
		"length": 0x02,
		"sha256": "5f0d984a52ca41b0b88a47636c86c81e2d5bf002916ceb931161478d1c1580d7",
	},
	"animation66_descriptor_pointer_9f_83be_83bf": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_pointer_9F_83BE_83BF.bin",
		"cpu_start": 0x83BE,
		"length": 0x02,
		"sha256": "db0a25a871aa2a0a6dd4b7edaa5c37cbb7be827d7e4adefe5b320facdc3250a0",
	},
	"first_command_sprite_streams_842c_8979": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_first_command_sprite_streams_842c_8979.bin",
		"cpu_start": 0x842C,
		"length": 0x54E,
		"sha256": "90caefd89c50a5696347adba35d47b1b428829c4983051da11226f6bab1f1fa7",
	},
	"descriptor_0b_0e_streams_897a_89bb": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_0B_0E_streams_897A_89BB.bin",
		"cpu_start": 0x897A,
		"length": 0x42,
		"sha256": "df7ca04d4e372766834155b3b777178e48b33f985dc02c8bde7342572e87e05e",
	},
	"slot11_actor_descriptors_0f_12_streams_89bc_8b73": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_slot11_actor_descriptors_0F_12_streams_89BC_8B73.bin",
		"cpu_start": 0x89BC,
		"length": 0x1B8,
		"sha256": "c36945bc33a00c0d97521178b289d1df3d1ffec935c17332d9692aa753243aba",
	},
	"route_actor_descriptor_14_stream_8b81_8d0b": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_route_actor_descriptor_14_stream_8B81_8D0B.bin",
		"cpu_start": 0x8B81,
		"length": 0x18B,
		"sha256": "fd84af09b6b5affba9b03a60fb3d7174190b094769028b0cadc380e8c8b6329d",
	},
	"route_actor_descriptor_18_stream_8d45_8d51": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_route_actor_descriptor_18_stream_8D45_8D51.bin",
		"cpu_start": 0x8D45,
		"length": 0x0D,
		"sha256": "5188d6fcec3a2f29067dd566617a9d0b40a75734d8db3bba06008690ec05970b",
	},
	"route_actor_descriptor_15_stream_8d0c_8d1a": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_route_actor_descriptor_15_stream_8D0C_8D1A.bin",
		"cpu_start": 0x8D0C,
		"length": 0x0F,
		"sha256": "a1d2ad69c82b5ffda5057d4cef159c0cf66ef96b821f7df3eab73ff6586c161e",
	},
	"route_actor_descriptor_16_stream_8d1b_8d2f": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_route_actor_descriptor_16_stream_8D1B_8D2F.bin",
		"cpu_start": 0x8D1B,
		"length": 0x15,
		"sha256": "1aa769bf4812c0873416852f7338830e7064dd31bc118c0dc0992e3d9b85cbac",
	},
	"route_actor_descriptor_1d_stream_8f56_8f62": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_route_actor_descriptor_1D_stream_8F56_8F62.bin",
		"cpu_start": 0x8F56,
		"length": 0x0D,
		"sha256": "5188d6fcec3a2f29067dd566617a9d0b40a75734d8db3bba06008690ec05970b",
	},
	"animation66_descriptor9e_prefix_b21e_b231": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_animation66_descriptor9E_prefix_B21E_B231.bin",
		"cpu_start": 0xB21E,
		"length": 0x13,
		"sha256": "20658f483aa243208c4293c944ca62b7df37c8a4c9f08ad59e7c638d214fe529",
	},
	"animation66_descriptor9e_selector08_pointer_b23b_b23c": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_animation66_descriptor9E_selector08_pointer_B23B_B23C.bin",
		"cpu_start": 0xB23B,
		"length": 0x02,
		"sha256": "f2a7a8a2081d23a7d258d84005783f728480e15cda342d84b09ddbdcab0e2d06",
	},
	"animation66_descriptor9e_selector02_b287_b292": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_animation66_descriptor9E_selector02_B287_B292.bin",
		"cpu_start": 0xB287,
		"length": 0x0B,
		"sha256": "8b85041ed826e82d268002846c8daf0cbc8adcb3883d84c9fe743a3ba7faa949",
	},
	"animation66_descriptor9e_jump_b24b_b276": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_animation66_descriptor9E_jump_B24B_B276.bin",
		"cpu_start": 0xB24B,
		"length": 0x2B,
		"sha256": "3d112fc60542fc3e0ca0133daeb36aed191260e2789e2cdbbb089a11608cb153",
	},
	"animation66_descriptor9f_prefix_b2cc_b2d8": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_animation66_descriptor9F_prefix_B2CC_B2D8.bin",
		"cpu_start": 0xB2CC,
		"length": 0x0D,
		"sha256": "daa91c5bca7b2a85323cbd62f9e794551fbafc643a06b6e45dad32104e0b1cb5",
	},
	"early_actor_descriptor_pointers_83f0_83f5": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_early_actor_descriptor_pointers_83f0_83f5.bin",
		"cpu_start": 0x83F0,
		"length": 0x06,
		"sha256": "c657102f38fc6bb3b6fdf8231ab95316f8eee01c64c9af2bda3a344876340b4f",
	},
	"early_actor_descriptor_pointer_b7_83ee_83ef": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_early_actor_descriptor_pointer_B7_83EE_83EF.bin",
		"cpu_start": 0x83EE,
		"length": 0x02,
		"sha256": "afabfea077b7afe3d9a8e653724631361d30835b71a1afc37b5a3fe80b2b248b",
	},
	"early_actor_descriptor_b7_bae0_bb20": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_early_actor_descriptor_B7_BAE0_BB20.bin",
		"cpu_start": 0xBAE0,
		"length": 0x41,
		"sha256": "61836c0206e6179b672698701893e3d36b3bf53e76e95305cf014d5cb4487bfb",
	},
	"early_actor_descriptor_b8_bb21_bb61": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_early_actor_descriptor_B8_BB21_BB61.bin",
		"cpu_start": 0xBB21,
		"length": 0x41,
		"sha256": "7e9cdcd5dbe2e732c0bdb4ba4a05328a26b36ce447d336702eaffdf46888b7dc",
	},
	"early_actor_descriptor_b9_bb62_bb6c": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_early_actor_descriptor_B9_BB62_BB6C.bin",
		"cpu_start": 0xBB62,
		"length": 0x0B,
		"sha256": "f8c2fe9650548e50d75b37eaca01d2a5e924e5f858718e6f0933cb816ebc615a",
	},
	"early_actor_descriptor_ba_bb6d_bb7b": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_early_actor_descriptor_BA_BB6D_BB7B.bin",
		"cpu_start": 0xBB6D,
		"length": 0x0F,
		"sha256": "40b0a4a2fd857fff6c29536666d2d2104acb9bf7ad2ce092eacd95aa62785803",
	},
	"descriptor_pointer_7d_837a_837b": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_pointer_7D_837A_837B.bin",
		"cpu_start": 0x837A,
		"length": 0x02,
		"sha256": "b7b1ecb9d926330e513a811f607f99a1e816ef15e53f5858d5a3f9b19bcedf6b",
	},
	"descriptor_7d_stream_aa83_aa87": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_7D_stream_AA83_AA87.bin",
		"cpu_start": 0xAA83,
		"length": 0x05,
		"sha256": "5698d4f4aecc18c443fe9be8e9c27953e8ac5251ec44616c2a8971b701b8c2cd",
	},
	"descriptor_pointer_table_73_7b_8366_8377": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_pointer_table_73_7B_8366_8377.bin",
		"cpu_start": 0x8366,
		"length": 0x12,
		"sha256": "db62c9e9f16ca1a78a20aa499718d2aee9a3f7cae58539984a61c7fedd8e3128",
	},
	"descriptor_pointer_72_8364_8365": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_pointer_72_8364_8365.bin",
		"cpu_start": 0x8364,
		"length": 0x02,
		"sha256": "de297b9c72e5464d967c50ce76caf063f8e5c0d721ecf6ccaaa38ad0b1de51a0",
	},
	"descriptor_pointer_71_8362_8363": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_pointer_71_8362_8363.bin",
		"cpu_start": 0x8362,
		"length": 0x02,
		"sha256": "9dbaf7f61f7ec28d54ff6d009469b02d2daa29f5eac7b252e091c1eecdebdc65",
	},
	"descriptor_71_stream_a96f_a9b1": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_71_stream_A96F_A9B1.bin",
		"cpu_start": 0xA96F,
		"length": 0x43,
		"sha256": "7a547dc3bd179b7e2e7be99eb738d3cb846101155fc8ff8ffea5f5073d6c42dd",
	},
	"descriptor_72_stream_a9b2_a9e0": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_72_stream_A9B2_A9E0.bin",
		"cpu_start": 0xA9B2,
		"length": 0x2F,
		"sha256": "928bfc93ce91f484187af5c155aceb0672981e511302e59b467182b565a4bfad",
	},
	"descriptor_streams_73_79_a9e1_aa6b": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_streams_73_79_A9E1_AA6B.bin",
		"cpu_start": 0xA9E1,
		"length": 0x8B,
		"sha256": "8869d3b755c62985c1bfd13d7ba96eaa9e2a284a86f36f9db239d69e3d54646d",
	},
	"descriptor_7b_stream_aa79_aa7d": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_7B_stream_AA79_AA7D.bin",
		"cpu_start": 0xAA79,
		"length": 0x05,
		"sha256": "7587a8c312ad6e9c359f9e8ed346ac5a2f5a28acd0e95bc3219a7744f750f94b",
	},
	"descriptor_7a_stream_aa6c_aa78": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_7A_stream_AA6C_AA78.bin",
		"cpu_start": 0xAA6C,
		"length": 0x0D,
		"sha256": "4d0eb09bed201ddb2071b13984c0b7a282e6b46c6bc2fb481195756f66873252",
	},
	"descriptor_pointer_7c_8378_8379": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_pointer_7C_8378_8379.bin",
		"cpu_start": 0x8378,
		"length": 0x02,
		"sha256": "2a45b832143bb6fb3c1e4dc972162aa805360c5939638d2d6944059039e1216d",
	},
	"descriptor_7c_stream_aa7e_aa82": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_7C_stream_AA7E_AA82.bin",
		"cpu_start": 0xAA7E,
		"length": 0x05,
		"sha256": "35888b80712ca2fc4f6a5f3c4fb2aee974d470088e79baed5c620d0fecac0bf8",
	},
	"descriptor_cf_streams_be2d_bed5": {
		"path": "reference/rom_extract/gameplay/actor_oam/bank16_descriptor_CF_streams_BE2D_BED5.bin",
		"cpu_start": 0xBE2D,
		"length": 0xA9,
		"sha256": "d205d9daf9c83a96186113abbb1ee4c6e6dab1e7f300cfc151224308fe656138",
	},
}

const OAM_BYTES_REQUIRED := 64 * 4
const MAX_STREAM_STEPS := 4096

var last_error := ""

var _segments: Dictionary = {}
var _loaded := false


## Build OAM writes for active actor records in ROM draw order.
##
## Each actor dictionary has `record_bytes: PackedByteArray` containing the
## live 21-byte actor record. `record_address` is optional diagnostic metadata.
## `initial_oam` is the caller's current 256-byte shadow; out-of-range X sprites
## update only the source-defined hidden Y byte and preserve other bytes.
func build_oam(
		actor_records: Array,
		sprite_selector: int,
		mirror_mode: int,
		scroll_x: int,
		clip_y_min: int,
		clip_y_max: int,
		initial_oam: PackedByteArray,
		start_oam_byte_index: int = 0
) -> Dictionary:
	last_error = ""
	if not _ensure_source_resources():
		return _failure_result()
	if initial_oam.size() != OAM_BYTES_REQUIRED:
		return _fail_result("Actor OAM builder requires the caller's 256-byte OAM shadow.")
	if start_oam_byte_index < 0 or start_oam_byte_index > OAM_BYTES_REQUIRED \
			or start_oam_byte_index % 4 != 0:
		return _fail_result("Initial OAM byte index must be an aligned value from 0 through 256.")
	if sprite_selector < 0 or sprite_selector > 0xFF \
			or mirror_mode < 0 or mirror_mode > 0xFF \
			or scroll_x < 0 or scroll_x > 0xFF \
			or clip_y_min < 0 or clip_y_min > 0xFF \
			or clip_y_max < 0 or clip_y_max > 0xFF:
		return _fail_result("Shared sprite selector, mirror, scroll, and Y clip values must be bytes.")

	var output_oam := initial_oam.duplicate()
	var cursor := start_oam_byte_index
	var total_sprites_written := 0
	var actor_results: Array[Dictionary] = []
	for actor_variant in actor_records:
		if not actor_variant is Dictionary:
			return _fail_result("Actor draw list contains a non-dictionary entry.")
		var actor: Dictionary = actor_variant
		var record_variant: Variant = actor.get("record_bytes", null)
		if not record_variant is PackedByteArray or (record_variant as PackedByteArray).size() != 21:
			return _fail_result("Each actor needs exactly 21 live record bytes.")
		var record_bytes: PackedByteArray = record_variant
		var actor_result := _draw_actor(record_bytes, sprite_selector, mirror_mode,
			scroll_x, clip_y_min, clip_y_max, output_oam, cursor)
		if not bool(actor_result.get("ok", false)):
			return _fail_result("Actor %s: %s" % [str(actor.get("record_address", "?")), str(actor_result.get("error", "decode failed"))])
		actor_result["actor_address"] = str(actor.get("record_address", "?"))
		output_oam = actor_result["oam_bytes"]
		cursor = int(actor_result["next_oam_byte_index"])
		total_sprites_written += int(actor_result["sprites_written"])
		actor_result.erase("oam_bytes")
		actor_results.append(actor_result)

	return {
		"ok": true,
		"oam_bytes": output_oam,
		"next_oam_byte_index": cursor,
		"sprites_written": total_sprites_written,
		"actors": actor_results,
		"error": "",
	}


func _draw_actor(
		record_bytes: PackedByteArray,
		sprite_selector: int,
		mirror_mode: int,
		scroll_x: int,
		clip_y_min: int,
		clip_y_max: int,
		initial_oam: PackedByteArray,
		start_index: int
) -> Dictionary:
	var descriptor := int(record_bytes[0x12])
	var descriptor_pointer := _read_cpu_u16(0x8280 + descriptor * 2)
	if descriptor_pointer < 0:
		return {"ok": false, "error": last_error}
	var flag := int(record_bytes[0])
	var sprite_flip := ((flag & 0x60) << 1) ^ mirror_mode
	var x_origin := (((flag & 1) << 8) | int(record_bytes[8])) - 0x80 - scroll_x
	if (mirror_mode & 0x40) != 0:
		x_origin = 0x100 - x_origin
	x_origin &= 0xFFFF
	if (sprite_flip & 0x40) != 0:
		x_origin = (x_origin - 8) & 0xFFFF
	var movement_x := _signed_byte(int(record_bytes[0x13]))
	if ((flag ^ mirror_mode) & 0x40) != 0:
		movement_x = -movement_x
	x_origin = (x_origin + movement_x) & 0xFFFF

	var y_bias := 0x88 if (sprite_flip & 0x80) != 0 else 0x80
	var y_origin := (((flag >> 1) & 1) << 8) + int(record_bytes[12]) - y_bias
	y_origin = (y_origin + _signed_byte(int(record_bytes[0x14]))) & 0xFFFF

	var pointer := descriptor_pointer
	var stream_offset := 0
	var output_oam := initial_oam.duplicate()
	var oam_index := start_index
	var sprite_count := 0
	var run_count := 0
	var source_stream_roots: Array[int] = [descriptor_pointer]
	var visited: Dictionary = {}
	var steps := 0
	var run_log: Array[Dictionary] = []

	while steps < MAX_STREAM_STEPS:
		steps += 1
		var visit_key := "%04X:%04X" % [pointer, stream_offset]
		if visited.has(visit_key):
			return {"ok": false, "error": "sprite stream loop at $%s" % visit_key}
		visited[visit_key] = true
		var control := _read_cpu_byte(pointer + stream_offset)
		if control < 0:
			return {"ok": false, "error": last_error}
		var opcode := control & 0x07
		match opcode:
			1:
				return {
					"ok": true,
					"descriptor": descriptor,
					"descriptor_pointer": descriptor_pointer,
					"selected_stream_roots": source_stream_roots,
					"sprite_flip": sprite_flip,
					"base_x": x_origin,
					"base_y": y_origin,
					"run_count": run_count,
					"sprites_written": sprite_count,
					"start_oam_byte_index": start_index,
					"next_oam_byte_index": oam_index,
					"run_log": run_log,
					"oam_bytes": output_oam,
				}
			2:
				var jump_target := _read_cpu_u16(pointer + stream_offset + 1)
				if jump_target < 0:
					return {"ok": false, "error": last_error}
				pointer = jump_target
				stream_offset = 0
				source_stream_roots.append(pointer)
			3:
				var normalized_selector := sprite_selector - 0x0C if sprite_selector >= 0x0C else sprite_selector
				if normalized_selector < 0 or normalized_selector >= 12:
					return {"ok": false, "error": "selector $%02X is outside the source branch table" % sprite_selector}
				var table_address := pointer + stream_offset + 1 + normalized_selector * 2
				var branch_target := _read_cpu_u16(table_address)
				if branch_target < 0:
					return {"ok": false, "error": last_error}
				pointer = branch_target
				stream_offset = 0
				source_stream_roots.append(pointer)
			0:
				var count_minus_one := (control & 0x38) >> 3
				var count := count_minus_one + 1
				var y_index := _read_cpu_byte(pointer + stream_offset + 1)
				if y_index < 0:
					return {"ok": false, "error": last_error}
				if y_index >= 0x28:
					return {"ok": false, "error": "Y-offset index $%02X is out of range" % y_index}
				var y_offset := _signed_byte(_read_cpu_byte(0x81D2 + y_index))
				if (sprite_flip & 0x80) != 0:
					y_offset = -y_offset
				var y16 := (y_origin + y_offset) & 0xFFFF
				var screen_y := y16 & 0xFF
				var run_is_clipped := (y16 >> 8) != 0 or screen_y < clip_y_min or screen_y >= clip_y_max
				var run_record_address := pointer + stream_offset
				stream_offset += 2
				run_count += 1
				run_log.append({
					"source_address": run_record_address,
					"control": control,
					"count": count,
					"y_index": y_index,
					"y": screen_y,
					"clipped": run_is_clipped,
				})
				if run_is_clipped:
					stream_offset += count * 2
					continue
				for _sprite_index in count:
					var x_attribute_code := _read_cpu_byte(pointer + stream_offset)
					var tile_id := _read_cpu_byte(pointer + stream_offset + 1)
					if x_attribute_code < 0 or tile_id < 0:
						return {"ok": false, "error": last_error}
					var x_offset_index := x_attribute_code >> 2
					var x_offset := _signed_byte(_read_cpu_byte(0x81FA + x_offset_index))
					if (sprite_flip & 0x40) != 0:
						x_offset = -x_offset
					var x16 := (x_origin + x_offset) & 0xFFFF
					if oam_index + 4 > OAM_BYTES_REQUIRED:
						return {"ok": false, "error": "sprite stream exceeds the 64-entry OAM shadow"}
					if (x16 >> 8) != 0:
						# The source hides only Y and leaves the OAM cursor in place.
						output_oam[oam_index] = 0xF8
					else:
						output_oam[oam_index] = screen_y
						output_oam[oam_index + 1] = tile_id
						output_oam[oam_index + 2] = (x_attribute_code & 0x03) | sprite_flip
						output_oam[oam_index + 3] = x16 & 0xFF
						oam_index += 4
						sprite_count += 1
					stream_offset += 2
			_:
				return {"ok": false, "error": "unsupported sprite opcode %d at $%04X" % [opcode, pointer + stream_offset]}

	return {"ok": false, "error": "sprite stream exceeded %d parser steps" % MAX_STREAM_STEPS}


func _ensure_source_resources() -> bool:
	if _loaded:
		return true
	last_error = ""
	_segments.clear()
	var manifest_bytes := FileAccess.get_file_as_bytes(MANIFEST_PATH)
	if manifest_bytes.is_empty():
		return _fail("Actor OAM source manifest is missing.")
	var manifest_variant: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not manifest_variant is Dictionary:
		return _fail("Actor OAM source manifest is not a JSON object.")
	var manifest: Dictionary = manifest_variant
	if str(manifest.get("source_rom_sha256", "")) != SOURCE_ROM_SHA256 \
			or manifest.get("runtime_rom_dependency", true) != false \
			or manifest.get("capture_or_screenshot_bytes_included", true) != false:
		return _fail("Actor OAM source manifest has an unexpected ROM identity or provenance flag.")
	var raw_segments: Array = manifest.get("segments", [])
	if raw_segments.size() != EXPECTED_SEGMENTS.size():
		return _fail("Actor OAM source manifest has the wrong segment count.")
	for segment_name in EXPECTED_SEGMENTS:
		var expected: Dictionary = EXPECTED_SEGMENTS[segment_name]
		var found: Dictionary = {}
		for raw_variant in raw_segments:
			if raw_variant is Dictionary and str(raw_variant.get("name", "")) == str(segment_name):
				found = raw_variant
				break
		if found.is_empty():
			return _fail("Actor OAM source manifest is missing segment %s." % str(segment_name))
		if str(found.get("path", "")) != str(expected["path"]) \
				or _hex_value(found.get("cpu_start", "")) != int(expected["cpu_start"]) \
				or int(found.get("length_bytes", -1)) != int(expected["length"]) \
				or str(found.get("sha256", "")) != str(expected["sha256"]):
			return _fail("Actor OAM source segment metadata differs for %s." % str(segment_name))
		var source_path := "res://" + str(found["path"])
		var source_bytes := FileAccess.get_file_as_bytes(source_path)
		if source_bytes.size() != int(expected["length"]) \
				or _sha256(source_bytes) != str(expected["sha256"]):
			return _fail("Actor OAM source bytes failed integrity validation for %s." % str(segment_name))
		_segments[segment_name] = {
			"cpu_start": int(expected["cpu_start"]),
			"bytes": source_bytes,
		}
	_loaded = true
	return true


func _read_cpu_byte(address: int) -> int:
	for segment_variant in _segments.values():
		var segment: Dictionary = segment_variant
		var start := int(segment["cpu_start"])
		var bytes: PackedByteArray = segment["bytes"]
		if address >= start and address < start + bytes.size():
			return int(bytes[address - start])
	last_error = "CPU address $%04X is outside the preserved actor OAM spans." % address
	return -1


func _read_cpu_u16(address: int) -> int:
	var low := _read_cpu_byte(address)
	var high := _read_cpu_byte(address + 1)
	if low < 0 or high < 0:
		return -1
	return low | (high << 8)


func _signed_byte(value: int) -> int:
	return value - 0x100 if (value & 0x80) != 0 else value


func _hex_value(value: Variant) -> int:
	var normalized := str(value).to_lower().trim_prefix("0x")
	return normalized.hex_to_int()


func _sha256(bytes: PackedByteArray) -> String:
	if bytes.is_empty():
		return ""
	var hasher := HashingContext.new()
	if hasher.start(HashingContext.HASH_SHA256) != OK or hasher.update(bytes) != OK:
		return ""
	return hasher.finish().hex_encode()


func _fail(message: String) -> bool:
	last_error = message
	return false


func _failure_result() -> Dictionary:
	return {"ok": false, "error": last_error, "oam_bytes": PackedByteArray(), "next_oam_byte_index": -1}


func _fail_result(message: String) -> Dictionary:
	last_error = message
	return _failure_result()
