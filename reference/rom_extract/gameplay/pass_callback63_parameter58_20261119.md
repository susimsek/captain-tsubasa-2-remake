# PASS Route: Callback and Animation Boundary (2026-11-19)

## Scope and provenance

This note records the frame 9235–9252 PASS-route trace around the callback handler and animation cursor. The trace metadata identifies ROM SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, FCEUX 2.7.0, NTSC, NewPPU, muted audio, and two replays from the same in-memory frame-9042 checkpoint. The exact traces are [`events.csv`](../../../diagnostics/pass_receiver_waiter_boundaries_20261119_015349_utc/events.csv) and [`events_repeat.csv`](../../../diagnostics/pass_receiver_waiter_boundaries_20261119_015349_utc/events_repeat.csv); run details are in [`metadata.txt`](../../../diagnostics/pass_receiver_waiter_boundaries_20261119_015349_utc/metadata.txt).

The two event files have 343 normalized matching rows each across frames 9235–9252. In frame 9235, the `$8327_callback_handler` snapshot has `$005F/$0060=$9A62` and `$0063/$0064=$A2D7`. By the frame-9244 snapshots, the first pointer remains `$9A62` and the animation cursor is `$A2B0`. These are observed RAM values; the snapshots alone do not establish when either pointer was written.

## Frame 9244 snapshots

| Hook snapshot | Cycle from frame start | PC / task slot / SP | `$05E9` | `$05F5` | `$005F/$0060` | `$0063/$0064` | Scenario `$0516–$0519` |
|---|---:|---|---:|---:|---|---|---|
| Before: `EB9E_scenario_return` | 13017 | `$EB9E` / `$09` / `$7A` | `$01` | `$04` | `$9A62` | `$A2B0` | `01 40 1C 2B` |
| After: `C515_nmi_wait` | 13775 | `$C515` / `$11` / `$C8` | `$00` | `$03` | `$9A62` | `$A2B0` | `01 40 1C 2B` |

The repeat trace records the same hook states and cycle positions. The snapshots therefore bracket `$05E9: $01→$00` and `$05F5: $04→$03` during frame 9244, with both pointers unchanged at the sampled hooks. They do not pinpoint the instruction or exact write cycle that changed either counter.

## Frames 9245–9248: packet wait and text queue

### Trace observations

The `C515_nmi_wait` snapshots in [`events.csv`](../../../diagnostics/pass_receiver_waiter_boundaries_20261119_015349_utc/events.csv) record this follow-up countdown:

| Source frame | FCEUX hook cycle from frame start | `$05E9` | `$05F5` |
|---:|---:|---:|---:|
| 9245 | 12877 | `$00` | `$03` |
| 9246 | 14149 | `$00` | `$02` |
| 9247 | 13688 | `$00` | `$01` |
| 9248 | 13367 | `$00` | `$00` |

At frame 9248, the later `$8327_callback_handler` snapshot (cycle 17887) records `$05E7=$02`, `$005F/$0060=$9A62`, `$0063/$0064=$8E37`, and RAM queue bytes `$04A5-$04A7 = 0E F0 22` and `$04B6-$04BF = 0E 10 23 61 6C 69 79 6F 72 21`. The repeat file has matching snapshots. The bytes at `$04B9-$04BF` spell `aliyor!` in the observed RAM snapshot.

### ROM-source interpretation

The bank-$18 source span [`bank18_actor_packet_resume_82f7_8652.bin`](slot11_actor_worker_resume_wait/bank18_actor_packet_resume_82f7_8652.bin), recorded in the [manifest](slot11_actor_worker_resume_wait/manifest.json), begins at `$82F7` with `LDA $0515; BNE $82F2`; if the wait flag is clear, it sets `$0515` to `$01` before its packet/row writer. Its row lookup uses `$05E7`; the bank-$18 row table [`bank18_actor_packet_row_address_86e8_86ed.bin`](slot11_actor_worker_resume_wait/bank18_actor_packet_row_address_86e8_86ed.bin) maps index `$02` to `$22F0`. The writer adds `$20` for the next row, consistent with the observed `$2310` address bytes. The manifest's parameter-`$58` stream span [`bank18_actor_stream_parameter58_9A62_9A6F.bin`](slot11_actor_worker_resume_wait/bank18_actor_stream_parameter58_9A62_9A6F.bin) contains the prefix `$01 $10 $E4 $FC $08`, the text bytes for `aliyor!`, and the stream tail `$FC $F0`. This source data is consistent with row `$02` and the staged RAM queue bytes observed at frame 9248.

The distinction is important: the logged `$8327_callback_handler` executes in PRG bank `$0C`, while the `$82F7` span is bank `$18` code in the same switchable CPU window. The `$8327` snapshot is not a direct instruction trace of bank-$18 `$82F7`; the latter's wait and row behavior comes from ROM-source decoding, correlated with the sampled RAM states.

The `$FC,$F0` stream tail is established by ROM bytes only. At the sampled frame-9248 callback, `$005F/$0060` is still `$9A62`; the trace does not establish that the stream advanced through either byte. Likewise, the event snapshots show staged queue bytes, but do not prove the precise enqueue/dequeue or PPU-write operation that produced them.

### Limits

The trace records PPU-RAM hashes at hooks, not PPU bus writes or a rendered-frame comparison, so this evidence does not establish that `aliyor!` was visibly drawn or identify its exact rendering cycle. Audio was muted and these files contain no APU register/sequence capture, so they support no audio-parity claim. The listed cycle values are FCEUX hook positions within an emulated frame; they do not establish physical NES cycle timing or the exact instruction cycle of a RAM write.

## ROM mapping

The source manifest is [`slot11_actor_worker_resume_wait/manifest.json`](slot11_actor_worker_resume_wait/manifest.json). Its bank-$1B span [`bank1b_actor_animation_stream_00_A2AE_A2CA.bin`](slot11_actor_worker_resume_wait/bank1b_actor_animation_stream_00_A2AE_A2CA.bin) maps CPU `$A2AE` to file offset `$0362BE` and begins `05 00 05 01 ...`; thus the command pair at `$A2B0` is `$05,$01`. The bank-$1B pointer table [`bank1b_actor_animation_packet_pointer_table_A42A_A433.bin`](slot11_actor_worker_resume_wait/bank1b_actor_animation_packet_pointer_table_A42A_A433.bin) contains little-endian pointer `$A48F` at index `$01`. The selected packet span [`bank1b_actor_animation_packets_01_A48F_A493.bin`](slot11_actor_worker_resume_wait/bank1b_actor_animation_packets_01_A48F_A493.bin) is `01 EA 22 DA 00`.

The `$9A62` stream pointer is also ROM-backed: [`bank18_actor_stream_parameter58_9A62_9A6F.bin`](slot11_actor_worker_resume_wait/bank18_actor_stream_parameter58_9A62_9A6F.bin) is the bank-$18 parameter-`$58` span at CPU `$9A62` (file offset `$031A72`), with bytes `01 10 E4 FC 08 61 6C 69 79 6F 72 21 FC F0`.

## Interpretation and limits

The ROM data resolves command `$05,$01` at `$A2B0` to the packet at `$A48F`; the paired trace snapshots are consistent with the expected countdown values `$05E9:1→0` and `$05F5:4→3`. This supports the boundary mapping, but does not by itself prove that this packet caused a particular queue operation. Queue signatures are state fingerprints only: they do not establish packet enqueue/dequeue causality. The hook snapshots bracket state changes but do not identify the write instruction or cycle, and these FCEUX observations are not physical NES timing evidence.
