# Post-PASS Scenario `$1C` Source Audit

## ROM identity and extraction

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- iNES mapper 4 / MMC3; 16 PRG 16-KiB units, represented as 32 8-KiB banks.
- Bank `$10` scenario window: CPU `$8000-$BFFF`, file base `0x020010`.
- Fixed bank `$1E`: CPU `$C000-$DFFF`; fixed bank `$1F`: CPU `$E000-$FFFF`.
- Extractor: `python3 tools/gameplay/extract_pass_scenario_1c_sources.py`; verify existing files with `python3 tools/gameplay/extract_pass_scenario_1c_sources.py --check`.

The scenario pointer table starts at CPU `$89BF`, file `0x0209CF`, with two-byte little-endian entries. ID `$1C` is at table CPU `$89F7`, file `0x020A07`, and contains `E3 9B`, resolving to `$9BE3`. Scanning all 256 entries for the next greater valid bank-$10 pointer finds ID `$24` at table CPU `$8A07`, file `0x020A17`, containing `F2 9B`, resolving to `$9BF2`. Therefore scenario `$1C` is 15 bytes at file offset `0x021BF3`, exclusive end `$9BF2`; its SHA-256 is `68d8512ef76afc90deee499c53952f8cf27d4c4473749a571ef1ed9deca132e2`.

The boundary owner is **ID `$24`**, not ID `$36`; ID `$36` points to `$B7E4`. The manifest and extractor verify the full table-derived boundary rather than relying on scenario-ID ordering.

## Source path into the scenario

The already extracted bank-$1E caller at `$DE6C-$DE95` establishes the following static sequence:

1. `$DE76` commits the selected holder and calls `$E6EC` to copy holder coordinates.
2. `$CE2D` maps the bank shadows `$1A/$1B`; `$801E` in bank `$1A` jumps to `$8B4A`.
3. `$8B4A` calls `$8B9C`. The helper returns carry set only when Y from `$0637` is in `[$60,$A0)` and X from `$0635` is outside `[$50,$B0)`. `$8B4A` returns early when carry is clear.
4. `$8B4A` calls fixed vector `$C624`; its first vector jumps to `$DCDF`. That target initializes `$044E` to `1 + ($00E2 & 1)` only when `$044E` is zero, otherwise it returns without changing the value.
5. The setup calls bank-$1A `$87E1`, then passes `$0A` through vector `$C609` (first target bank-$1F `$E4D7`). It passes `$2F` through vector `$C54E` (first target `$CBB0`), which queues scenario `$2F`; later it calls `$8E86` and fixed vector `$C600` (first target `$D565`). The `$0621` branch then jumps to `$8298` when equal to 1, otherwise `$8978`.
6. Returning to the `$DE6C` caller, it loads scenario ID `$1C` and calls `$CBB0`, then resets the stack and jumps to `$E0DF`.

This proves the static caller and direct dispatch edges. The route-specific behavior after the `$8298/$8978` branch and the point at which scenario `$1C` begins execution are not established by this extraction alone.

## Scenario bytes and decoded dispatch edges

The pointer-bounded root stream is:

```text
FD 00 FA 3E 9F F3 84 02 04 F2 9E B4 F2 B6 B4
```

- `$FD $00` uses bank-$10 `$885D->$886A->$8877`. The handler reads holder `$0441`, resolves its record through `$C50C->$CD7C`, and calls the `$C536` vector for the value calculation involving `$0638`. The final result depends on live holder/record state, so the byte stream alone does not determine it.
- `$FA $3E $9F` enters the bank-$10 nested target `$9F3E`. Existing sources `$881A-$8836` and `$80F6-$8104` show the saved caller pointer and target load.
- `$F3 $84` is decoded through `$8105->$816E->$C509->$CB99->$8259`. `$816E` masks `$84` to selector `$04`; `$8259` (`AE 4E 04 F0 01 CA 60`) returns X=0 when `$044E` is 0 or 1, X=1 when `$044E` is 2, and otherwise returns `$044E-1`.
- Because the original selector has its high bit set, `$8105` takes the high-bit branch. With the reader cursor at root offset +6, that branch computes a byte location at offset `+7+X`, reads the skip length there, advances the source pointer by that value, and resets `$3A` to zero. Thus X=0 reads `$02` at `$9BEA` and resumes at `$9BEC` (`F2 9E B4`); X=1 reads `$04` at `$9BEB` and resumes at `$9BEF` (`F2 B6 B4`).
- The preceding `$C624->$DCDF` call initializes `$044E` to `1 + ($00E2 & 1)` only when `$044E` was zero; a nonzero incoming value is preserved. The normal two branches therefore follow when `$044E` was freshly zero, while an arbitrary pre-existing value is a remaining context dependency.
- `$F2` at `$80F4` reads the next two bytes as a little-endian pointer, updates `$5D/$5E`, and clears `$3A`. Its selected root targets are `$B49E` and `$B4B6`. Each begins with one F9 word, one four-byte record, and an FB byte: `$B49E` has `F9 1D 2C 3C 01 78 58 FB`; `$B4B6` has `F9 11 2C 38 63 7A 58 FB`.

### Nested `$FA` target bounds

The nested target is a dispatch wrapper, not one contiguous executable script. Its exact inline wrapper is `$9F3E-$9F53` (exclusive end `$9F54`):

- `$9F3E: F3 10` dispatches to `$836E`. The complete helper at `$836E-$837B` starts X at zero, compares `$043B` with 1, and returns X=0 when equal. Otherwise it calls `$8677`, increments X, and returns; that path depends on `$8677`'s result. The five inline pointers at `$9F40-$9F49` are `$9F4A`, then `$BB4B` four times.
- If that selector chooses `$9F4A`, `$9F4A: F3 1E` dispatches to `$8401`. It returns X=`$043C & $7F`; for nonzero input, `$8211` also sets bit `$04` in `$0516`. The four inline pointers at `$9F4C-$9F53` are `$BB4B`, `$B502`, `$B54F`, and `$BB50`.
- Therefore the `$BB4B` child is selected when the outer helper returns index 1–4, or when it returns index 0 and `$043C & $7F` is zero at the inner selector. The exact child `$BB4B-$BB4F` is `30 1F 4C 00 FB` (file offset `0x023B5B`, SHA-256 `d39d9c4feecbd6f52b00d87bc8402f8a265fd173fb392b2066bcd08c2b9dce4c`): one event record followed by local `$FB`. `$FB` restores the saved nested-call cursor to root `$9BE8`, where the next opcode is `$F3 $84`. This five-byte extraction is bounded to the nested child and does not establish the resulting field worker or screen output.
- The wrapper, complete outer helper, and `$BB4B` child are extracted and hash-pinned. No retained same-input FCEUX RAM checkpoint establishes `$043B/$043C` at this branch, so the exact child selected in FCEUX is not claimed. The 64-byte `$9F3E` file is only context and is not mislabeled as a complete script.
- The `$9F3E`, `$B49E`, and `$B4B6` artifacts are labeled context prefixes. They are not asserted to be complete scripts or complete worker inputs.

## Scenario reader and worker dependencies

The dependency hashes are recorded and checked in `manifest.json`. The existing source chain establishes:

- `$CBB0-$CBC1` stores the queued scenario ID at `$0518` and yields through the normal task scheduler.
- `$EC08-$EC33` maps bank `$10` and calls its `$8000` reader entry.
- `$8000-$803E` resolves `$0518` through the pointer table at `$89BF`; the scenario reader starts at `$803F`.
- `$80A9-$80CE` indexes the `$F0-$FF` opcode-handler table. The `$F3` path calls fixed `$C509->$CB99` and selects from the inline table at `$816E`.
- `$FA` saves/restores the caller stream through the existing `$881A`/`$80F6` path; `$FB` returns to that saved stream or takes the reader's underflow terminator.
- `$8097-$80A8` is the existing scenario record/task setup prefix. Its presence does not prove that the scenario `$1C` selectors create a particular task or screen event.

## Live route evidence and Godot gap

- In the FCEUX trace `reference/diagnostics/pass_receiver_waiter_boundaries_20261118_222457_utc/events.csv`, `$044E=$02` appears at frame 9155 during the preceding actor-init/map-worker events and remains `$02` at frame 9248, when slot `$09` enters the scenario `$1C` root at `$EB8B` and bank-$10 reader. This is consistent with the decoded `$F3 $84` selector choosing X=1 and target `$B4B6`, but the trace does **not** directly capture an `$F2` operand or a source pointer equal to `$B4B6`.
- The same FCEUX run's `scenario0523_writes.csv`, sequence 3, records frame 9191 at bank-$10 `$8052`: slot `$09` changes `$0523` from `$30` to `$38`. That value matches the first field of the four-byte event record in the manifest-pinned `$B4B6` stream (`F9 11 2C 38 63 7A 58 FB`); frame-9248 reader/return events retain `$0523=$38`. Repeated passes in this trace directory normalize identically for `$0523` writes (4 rows), `$0519` writes (117), `$0518` writes (1), and `$EC94` reads (2).
- In the latest independent Godot ordinary-input rerun, slot-$09 source-worker context has `$044E=$01` and `$00E2=$00` across frames 9187–9191; `$0523` remains `$30` at Godot frame 9191. These are separate runs, and their frame labels are not treated as same-input or cycle-aligned comparisons.
- The implementation now admits both live `$044E` branches, and the `$B4B6` consumer has focused checks. The remaining discrepancy is upstream selector-state generation: `$0444 & 3` and, when `$044E` is zero, `$00E2 & 1` as consumed through `$DCDF`. Route integration, exact timer parity, and completion through frame 9600 remain unverified.

No direct `$B4B6` pointer capture or complete-route parity is claimed.

## Confirmed versus unresolved

**Confirmed from ROM bytes:** ROM identity, mapper/bank offsets, the `$1C` pointer and exclusive boundary, the 15 root bytes, direct `$8B4A/$8B9C` source, `$C624->$DCDF`, the exact `$F3 $84` skip/branch arithmetic and its `$B49E/$B4B6` roots for X=0/1, the two `$9F3E` dispatch tables, the conditional `$836E` selector helper, the bounded `$BB4B` event-plus-return child, `$F2` pointer replacement, `$FA` nested-target load, and the existing scenario-reader entry chain.

**Still unresolved:** which `$9F3E` branch same-input FCEUX selects because the post-PASS `$043B/$043C` RAM checkpoint is not retained; the non-`$BB4B` child paths `$B502/$B54F/$BB50`; any pre-existing `$044E` value outside the fresh 1/2 case; complete execution of the `$8298/$8978` field branch and worker continuation; the observable screen/audio result and its timing. This package does not operate FCEUX, seed Godot state from emulator captures, or verify live Godot route integration. It makes no visual, timing, or audio parity claim.
