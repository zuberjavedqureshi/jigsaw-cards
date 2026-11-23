# Technical Feasibility & Architecture Review

| Field | Value |
| --- | --- |
| Review date | 2026-11-23 |
| Baseline | `main` at merge of PR #1 (`a4a551b`) |
| Scope | Feasibility of confirmed requirements; Q-009, Q-010, Q-013, Q-014, Q-015; TD-01 to TD-08; risks; spikes |
| Status | **Analysis and recommendations only.** Nothing in this document approves a decision, closes an open question or changes product scope. |

## 0. How to Read This Review

- **Feasibility ratings:** **Feasible**, **Feasible with constraints** or **Needs investigation**.
- **Recommendations** are technical proposals. They become decisions only through an approved ADR, or through product-owner approval for product questions.
- **Evidence** is cited inline: package data from the pub.dev API, Flutter toolchain source, and a combinatorial analysis of 4×4 tilings (§6.1). Claims that rely on platform behaviour not verified here are marked **(verify in spike)**.

### 0.1 Ecosystem snapshot (pub.dev, retrieved 2026-11-23)

| Package | Latest | Published | Notes |
| --- | --- | --- | --- |
| Flutter (stable) | 3.50.1 | 2026-11-20 | Dart 3.14.0 |
| `flame` | 1.38.2 | 2026-08-27 | Requires Flutter ≥ 3.41, Dart ≥ 3.11 |
| `flame_audio` | 2.12.2 | 2026-07-19 | Built on `audioplayers` ^6.2 |
| `flutter_riverpod` | 3.5.0 | 2026-11-06 | Riverpod 3.x major line |
| `riverpod_generator` | 4.0.10 | 2026-11-06 | Optional code generation (TD-05) |
| `flame_riverpod` | 5.5.5 | 2026-07-19 | Flame-maintained bridge; depends on Riverpod ^3.0.3 and Flame ^1.38 |
| `rive` | 0.14.11 | 2026-08-03 | Still 0.x; depends on the native `rive_native` runtime |
| `flame_rive` | 1.11.2 | 2026-07-19 | Rive inside Flame; depends on `rive` ^0.14.6 |
| `flame_test` | 2.3.1 | 2026-08-26 | Flame component testing |
| `drift` | 2.35.4 | 2026-11-08 | SQLite ORM with migrations; uses code generation |
| `sembast` | 3.10.1 | 2026-11-09 | Pure-Dart document store |
| `hive_ce` | 2.24.0 | 2026-11-19 | Community fork of Hive |
| `hive` | 2.2.3 | **2022-06-30** | Unmaintained, pre-Dart-3 SDK constraint. **Exclude.** |
| `isar` | 3.1.0+1 | **2023-04-25** | Unmaintained, pre-Dart-3 SDK constraint. **Exclude.** |
| `shared_preferences` | 2.5.6 | 2026-10-05 | Key-value store |
| `path_provider` | 2.1.6 | 2026-06-15 | App documents directory |

Flutter Android defaults, from `flutter_tools` `FlutterExtension.kt` on `stable`: **minSdk 24 (Android 7.0), targetSdk 36, compileSdk 36.**

All confirmed stack choices (Flame, flame_audio, Riverpod) have current, compatible releases on the same Flutter/Dart baseline. No blocking version conflict was found.

---

## 1. Executive Summary

1. **The confirmed product is technically feasible** on Flutter + Flame + Riverpod. No confirmed requirement is infeasible.
2. **Three areas need investigation before implementation:**
   - Rive character reveal (GP-10, VI-03): native runtime, APK size and performance.
   - Tray layout on portrait phones (GP-03): the 4×4 pieces do not fit beside the board at full scale.
   - Drag-and-snap feel (GP-04, GP-05).
3. **Rectangular partition generation (PS-08) is low risk.** A 4×4 board has exactly **70,878** rectangle tilings, which can be enumerated in milliseconds. A constrained, seeded or enumerate-and-choose approach is straightforward. The product constraints (allowed piece sizes and piece count) remain open (Q-009).
4. **Recommended persistence for the prototype:** a **single versioned JSON document with atomic writes**, behind a repository interface. This needs no database dependency. Revisit if requirements grow (TD-01, Q-014).
5. **Recommended project shape:** a Dart **pub workspace** with `app/` and `packages/puzzle_domain/`. The domain package has no Flutter dependency, so the domain/rendering boundary is enforced by the dependency graph (TD-04).
6. **Platform watch item:** apps targeting API 36 may have portrait locking ignored on large screens. The layout must remain usable in a non-portrait window **(verify in spike)**.
7. **Seven spikes** are proposed (§8). The highest priority are the hybrid shell, the Rive reveal, and drag/snap with tray layout.

---

## 2. Requirement Feasibility

### 2.1 Platform and architecture

| Req | Requirement | Rating | Notes |
| --- | --- | --- | --- |
| §13 | Android first | Feasible | Flutter default minSdk 24 / targetSdk 36 (§6.3) |
| §13 | Portrait orientation | Feasible with constraints | Lock with `SystemChrome.setPreferredOrientations` and the manifest. On large screens, API 36 targeting may ignore orientation restrictions **(verify in spike)**. Layout must degrade gracefully, e.g. a centred portrait column (§5, R-07) |
| §13 | Flutter + Flame hybrid | Feasible | `GameWidget` embedded in a Flutter screen; Flutter overlays for HUD, preview and reveal |
| §13 | Riverpod | Feasible | Riverpod 3.x is current. Bridge options in TD-03 |
| PS-03 | Independent pure-Dart puzzle domain | Feasible | Enforced by a separate package with no Flutter/Flame dependency (TD-04) |
| §13 | flame_audio | Feasible with constraints | Latency and lifecycle handling need checking (GP-12) |
| VI-03, §13 | Rive (subject to validation) | **Needs investigation** | See Q-015 and spike S-02 |
| PR-01 | Local-first persistence | Feasible | TD-01 recommendation |
| §13 | Firebase when justified | Feasible / not needed for prototype | Any future SDK choice depends on target audience (Q-001) and store family-policy implications |

### 2.2 Prototype gameplay (GP-01 to GP-13)

| Req | Rating | Recommended approach and notes |
| --- | --- | --- |
| GP-01 4×4 logical board | Feasible | Logical grid in the domain; pixel layout computed from available size |
| GP-02 Mixed rectangular pieces | Feasible | One puzzle texture; each piece draws a sub-rectangle (Flame `Sprite` with `srcPosition`/`srcSize`). No pre-sliced image files needed |
| GP-03 Tray below board | **Needs investigation** | Space analysis (§2.4): the tray cannot hold all 16 cells' worth of pieces at board scale. Needs scaling, scrolling or paging. The behaviour is open (Q-011) |
| GP-04 Drag from tray onto board | Feasible with constraints | Flame `DragCallbacks`. Handle single-pointer drag (ignore extra pointers), raise the dragged piece's priority, and make touch targets large enough (§2.4) |
| GP-05 Automatic magnetic snapping | Feasible with constraints | Simple geometry; the risk is *feel*. Snap threshold and animation timing must be configurable and tuned on devices (S-03) |
| GP-06 *(Proposed)* Incorrect placement returns to previous position | Feasible | Animate back with a Flame `MoveToEffect`. Product behaviour remains open (Q-010) |
| GP-07 No rotation | Feasible | No work required |
| GP-08 Optional reference preview | Feasible | Flutter overlay or Flame component. Interaction is open (Q-008) |
| GP-09 Completion detection | Feasible | Pure domain check; O(pieces) |
| GP-10 Character/card reveal | **Needs investigation** | Depends on Rive validation (Q-015, S-02). A Flutter overlay is recommended over in-scene Flame rendering (§4.4) |
| GP-11 Coin reward animation | Feasible | Flame effects/particles or Flutter animation; no extra dependency needed |
| GP-12 Sound effects | Feasible with constraints | Use pre-loaded short SFX through `flame_audio` low-latency pools. Measure latency on low-end Android and pause/resume with the app lifecycle (S-05) |
| GP-13 Automatic saving | Feasible with constraints | Save on every accepted placement, not only on pause: Android can kill a backgrounded process without further callbacks. Use atomic writes (TD-01) |

### 2.3 Product systems

| Req | Rating | Notes |
| --- | --- | --- |
| PS-04/05 Two separate puzzle styles | Feasible | Rectangular style now. The irregular style is feasible in Flame later (path clipping, Bézier tabs) but out of scope |
| PS-06/07 Mixed pieces, grid occupancy | Feasible | Occupancy derived from piece locations (PUZZLE_ENGINE §6) |
| PS-08 Rectangular partition generation | Feasible | §6.1. The algorithm is a technical choice (TD-02); the constraints are a product/design choice (Q-009) |
| PS-13 to PS-17 Shared session, configuration, interaction, completion, rewards | Feasible with constraints | Keep the shared contracts minimal and derived from the rectangular implementation. Do not build abstractions for the irregular style ahead of approval (Development Rules 7 and 9) |
| PS-18 Separate geometry and rendering | Feasible | Natural with per-style Flame components and domain geometry modules |
| CC-01 to CC-07 Card acquisition | Feasible | Application-layer logic over the domain's completion result. Make rewards idempotent: record "reward granted" atomically with progress |
| CC-02 Rarity | Feasible | Data field only, until tiers are defined (Q-007) |
| RW-01/02/04/05 Rewards | Feasible | As above. Progression rewards are undefined (Q-020), so they cannot be implemented yet |
| WP-01 World-based progression | Feasible | Configuration-driven. WP-02/03 remain proposed |
| DL-01 to DL-03 Data-driven levels | Feasible with constraints | Bundled JSON configuration validated at load. Constraint: illustration count and resolution drive APK/AAB size (R-08) |
| PR-01 to PR-03 Persistence | Feasible | TD-01 |
| MC-01/MC-02 Mascot and discovery | Feasible | Depends on art and Rive outcome |
| VI-01 to VI-05 Visual identity | Feasible | Art-pipeline dependency rather than a technical risk |

### 2.4 Layout analysis (GP-03, GP-04)

Assumptions: a typical portrait phone 360 dp wide, 16 dp side margins, so the board is about 328 dp square and a cell is about 82 dp.

- **Touch targets:** a 1×1 piece at board scale is about 82 dp, comfortably above Android's 48 dp minimum. At 0.6× tray scale it is about 49 dp, at the limit.
- **Tray space:** the pieces' total area always equals the board area (16 cells). On a 20:9 phone (about 800 dp tall), the space below the board after status bar, HUD and margins is roughly 0.9× the board height. On a 16:9 phone (about 640 dp tall) it is roughly 0.5×. With spacing between pieces, **the full set cannot fit at board scale on either aspect ratio.**
- **Implication:** the tray needs a smaller piece scale (e.g. 0.6 to 0.75×, enlarging on pick-up), scrolling or paging. This is a product/UX choice (Q-011) and is validated in S-03. Layout must be computed from available size (Development Rule 6).

---

## 3. Recommended Technical Approach

### 3.1 Layering (consistent with ARCHITECTURE_OVERVIEW)

```
app/ (Flutter)
  screens, overlays (HUD, preview, reveal, rewards)
  Riverpod: session notifier, progress, collection, coins, settings
  repositories (persistence behind interfaces)
  game/ (Flame): board, tray, piece components, effects, audio triggers
        │ intents (pick up / drop at candidate origin)
        ▼
packages/puzzle_domain/ (pure Dart)
  configuration + validation, partition generation,
  grid occupancy, placement rules, completion, snapshot (de)serialisation
```

### 3.2 Key principles

- **Single source of truth:** puzzle state lives in the domain, is held by a Riverpod notifier and is rendered by Flame. Flame never decides rules.
- **Pixels stay out of the domain:** Flame converts drop positions to candidate grid origins; the domain validates.
- **Rewards are applied in the application layer**, once, from the domain's completion result, through the shared reward integration (PS-17).
- **Persist the generated layout** in the session snapshot (§6.1). Do not rely on regenerating from a seed.

---

## 4. Recommendations for Pending Technical Decisions (TD-01 to TD-08)

All remain **Pending** until an ADR is approved.

### TD-01 Local database / storage

| Option | Assessment |
| --- | --- |
| **Versioned JSON document + atomic file write** (`path_provider`) | **Recommended for prototype.** Data is small (progress, card IDs, coins, settings, one session snapshot: a few KB). Minimal dependency, trivially versioned, easy to inspect and test. Write to a temp file, then rename for atomic replacement |
| `sembast` | Good alternative if multiple documents or queries are needed; pure Dart, maintained |
| `drift` (SQLite) | Strong migrations and querying, but adds code generation and native SQLite. Justified only if relational or query needs appear |
| `hive_ce` | Maintained fork; adequate, but adds a dependency without a clear need |
| `shared_preferences` | Fine for settings only; not suitable for the session snapshot |
| `hive`, `isar` | **Excluded**: unmaintained since 2022/2023, with pre-Dart-3 SDK constraints |

**Recommendation:** use a JSON document store behind a repository interface for the prototype, with a `schemaVersion` and migration hook. Validate crash safety in S-06. Re-evaluate before MVP if cloud save (Firebase) or larger data appear.

### TD-02 Rectangular partition generation algorithm

**Recommendation:** use **enumerate-and-select** or **constrained random splitting with rejection**, both feasible at runtime for 4×4 (§6.1). Pick a layout with a seeded generator, then **persist the resulting layout** in configuration (if generated at build time) or in the session snapshot (if generated at runtime). Unit-test that every output satisfies the tiling invariant and the configured constraints. Decide once Q-009's product constraints are known.

### TD-03 Flame ↔ Riverpod bridge

| Option | Assessment |
| --- | --- |
| Manual bridge: pass a small interface (intent callbacks plus a state listener) into the `FlameGame` | **Recommended default.** No dependency; the bridge surface is small (one game, a handful of signals) |
| `flame_riverpod` 5.5.5 (Flame-maintained) | Acceptable if components need to watch several providers. Low risk because it is first-party and version-aligned with Flame 1.38 / Riverpod 3 |

**Recommendation:** start with the manual bridge in S-01, and adopt `flame_riverpod` only if the spike shows real friction (Development Rule 1).

### TD-04 Repository layout

**Recommendation:** a Dart **pub workspace** (supported natively since Dart 3.6; no Melos required):

```
pubspec.yaml            (workspace root)
app/                    Flutter application
packages/puzzle_domain/ Pure Dart package (no Flutter dependency)
```

This matches the proposal in ARCHITECTURE_OVERVIEW §4 and enforces QG-02 through the dependency graph.

### TD-05 Riverpod code generation

**Recommendation:** **no code generation initially.** Write providers by hand. The provider count is small, and `riverpod_generator` adds `build_runner` to every change cycle. Revisit if the provider count or boilerplate grows. Avoid relying on Riverpod features marked experimental.

### TD-06 Minimum Android version / target devices

See Q-013 (§5).

### TD-07 Flutter / Flame version pinning

**Recommendation:**

- Pin the Flutter SDK version in the repository, e.g. a documented version file or FVM config. This is a developer tool, not an app dependency.
- Set the `environment` constraints in each `pubspec.yaml`, and commit `pubspec.lock` for the app.
- Upgrade Flutter, Flame and Riverpod deliberately in dedicated PRs.
- Current constraints: Flame needs Flutter ≥ 3.41; Riverpod 3.5 needs Dart ^3.12. Flutter 3.50.1 / Dart 3.14 satisfies both.

### TD-08 CI setup

**Recommendation:** once code exists, use GitHub Actions on pull requests:

- `dart format --set-exit-if-changed`
- `flutter analyze`
- `dart test` (domain)
- `flutter test` (app)

An optional debug APK build can come later. No secrets are required. The workflow is added in its own PR at the start of implementation, not now.

---

## 5. Open Technical Questions — Proposed Resolutions

None are closed by this review. Each needs explicit approval.

### Q-009 Rectangular partition generation

**Evidence (§6.1):**

- A 4×4 board has **70,878** rectangle tilings (matches OEIS A116694).
- 68,480 of them are guillotine-cuttable.
- Limiting pieces to at most 2×2 leaves **15,623**.
- Exhaustive enumeration took about 0.2 s in unoptimised CPython; Dart AOT is expected to be faster **(verify in spike)**.

**Technical recommendation:**

- Enumerate valid layouts, filter them by the configured constraints, and choose one with a seeded generator.
- Persist the chosen layout; Dart's `Random` sequence is not documented as stable across SDK versions.
- Runtime generation is cheap. Build-time generation gives designers review control. Both are feasible, and the choice can be made per puzzle in configuration.

**Needs product/design input (still open):**

- Allowed piece sizes (e.g. max 2×2? are 1×3 and 1×4 allowed?).
- Piece-count range.
- Whether hand-authored layouts are also supported.

For reference, with pieces capped at 2×2, 8 to 12 pieces covers 13,932 distinct layouts, so variety is ample.

### Q-010 Placement rule

**Technical analysis:**

- **Strict rule** (accept only the correct origin):
  - Simplest and fully deterministic.
  - Occupancy conflicts cannot arise, because correct positions tile the board.
  - Completion equals "all pieces placed".
  - Aligns with proposed GP-06.
  - Snapping reduces to "within threshold of the correct origin".
- **Free rule:** needs overlap handling, swapping or displacement, and a separate correctness check. This is more UI and state complexity.
- **Edge case for both:** identical-size pieces with visually indistinguishable regions (e.g. plain sky) can feel unfair under the strict rule. Mitigate through content guidelines, or generation constraints that avoid such pieces.

**Technical recommendation:** the strict rule, with correctly placed pieces locked, for the prototype. This is the simplest implementation that validates GP-04 to GP-06. **The product decision remains open** (Q-010 owner: Product/Tech), including the precise incorrect-drop behaviour.

### Q-013 Minimum Android version and target devices

**Evidence:** Flutter's default minSdk is 24 (Android 7.0) and targetSdk is 36.

**Technical recommendation:**

- `minSdk 24`, the Flutter default, unless S-02 shows that `rive_native` requires higher.
- `targetSdk` at the latest stable level; confirm Google Play's current target-API requirement at submission time.
- Proposed device test matrix:
  - One low-end device: about 2 to 3 GB RAM, 60 Hz, a recent Android Go-class or budget device.
  - One mid-range device.
  - One high-refresh-rate device (90/120 Hz).
  - One large-screen or foldable emulator at API 36.
- Proposed performance target, to be approved: no dropped frames during drag on mid-range hardware, measured in profile mode with Flutter DevTools.

**Still open:** the audience and market decision (Q-001) may raise the device floor or change the matrix.

### Q-014 Local persistence technology

**Recommendation:** see TD-01: a versioned JSON document with atomic writes for the prototype. Acceptance is in S-06.

### Q-015 Rive fallback

**Context:**

- `rive` 0.14.11 is still 0.x and now runs on the native `rive_native` runtime. That adds native libraries per ABI (APK size) and API churn risk.
- `flame_rive` 1.11.2 exists for in-scene use.

**Recommended evaluation order:**

1. Validate Rive in a **Flutter overlay** for the reveal (S-02).
2. If Rive fails the acceptance criteria, fall back to **sprite-sheet animation rendered by Flame** (`SpriteAnimation`). This needs no new dependency and gives the art team a known pipeline.
3. Lottie or pre-rendered video are further options, but each adds a dependency or a size cost. They should be considered only if 1 and 2 fail.

**Decision deferred** to S-02 results and product/art approval.

---

## 6. Supporting Analysis

### 6.1 4×4 rectangle tilings

Exhaustive enumeration with a throwaway analysis script (not committed):

| Constraint | Tilings |
| --- | --- |
| Any rectangles | 70,878 |
| Guillotine-cuttable only | 68,480 |
| Max piece 2×2 | 15,623 |
| Max 2×2, 6–10 pieces, not all 1×1 | 7,501 |
| Max 2×2, 8–12 pieces, not all 1×1 | 13,932 |

Piece-count distribution with max 2×2:

| Pieces | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Tilings | 1 | 12 | 70 | 306 | 998 | 2,345 | 3,782 | 4,082 | 2,725 | 1,053 | 224 | 24 | 1 |

Conclusion: the space is small enough for exhaustive, constraint-filtered selection. Note that guillotine-only splitting (recursive cuts) would exclude 2,398 valid layouts, such as pinwheel arrangements. Whether that matters is a design choice.

### 6.2 Memory and asset sizing (estimates)

- A 1440×1440 RGBA puzzle texture is about 8 MB of GPU memory. That is acceptable, with one active puzzle at a time.
- Bundled illustrations dominate install size as content grows. Plan for Android App Bundle delivery, and review Play Asset Delivery before MVP content volume is set (R-08).

### 6.3 Toolchain baseline

Flutter 3.50.1 stable, Dart 3.14.0. Defaults: minSdk 24, targetSdk/compileSdk 36, NDK 28.2. All selected packages declare compatible SDK constraints.

---

## 7. Risks, Trade-offs and Dependencies

| ID | Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- | --- |
| R-01 | Rive runtime (0.x, native) fails performance, size or integration criteria | Medium | High: affects the core reveal | S-02 early; sprite-sheet fallback (Q-015) |
| R-02 | Drag/snap feel is not satisfying on low-end devices | Medium | High: core experience | S-03 with configurable thresholds; profile-mode measurement |
| R-03 | Tray cannot present pieces comfortably on short screens | High | Medium | Scaled tray or scroll/paging (Q-011); S-03 |
| R-04 | SFX latency or overlap issues on Android | Medium | Medium | Pre-loaded low-latency pools; S-05 |
| R-05 | Save corruption or lost progress on process death | Low | High | Save per placement, atomic writes, idempotent rewards; S-06 |
| R-06 | Premature abstraction for the future irregular style slows the prototype | Medium | Medium | Shared contracts limited to PS-13 to PS-17; Development Rules 7 and 9 |
| R-07 | API 36 large-screen behaviour overrides portrait lock | Medium | Low–Medium | Responsive centred layout; S-07 |
| R-08 | Asset volume inflates install size | Medium | Medium | Texture sizing guidelines; App Bundle; Asset Delivery review before MVP |
| R-09 | Dependency churn (Flame requires recent Flutter; Riverpod 3 changes) | Medium | Low | TD-07 pinning; deliberate upgrade PRs |
| R-10 | Indistinguishable pieces feel unfair under the strict rule | Medium | Low–Medium | Content guidelines or generation constraints (Q-009, Q-010) |
| R-11 | Unresolved product decisions (Q-001, Q-002, Q-007, Q-011, Q-020) block MVP design | High | Medium | Not blocking the prototype except Q-009, Q-010 and Q-011 |

**Dependencies on product decisions:**

- **Prototype:** Q-009 (constraints), Q-010 (placement rule), Q-011 (tray).
- **MVP:** Q-001, Q-002, Q-007, Q-020.

---

## 8. Proposed Technical Spikes (prioritised)

Spikes are time-boxed experiments on `spike/*` branches. Their code is throwaway and is not merged as production code without review. Each spike ends with a short findings note and, where a decision results, an ADR.

| Priority | Spike | Objective | Acceptance criteria (proposed) | Resolves |
| --- | --- | --- | --- | --- |
| 1 | **S-01 Hybrid shell** | Flutter screen embedding a `GameWidget`, Riverpod state, a Flutter overlay, and app lifecycle hooks | Riverpod state change reflected in Flame, and a Flame intent updates the notifier. Overlay shows and hides over the game. Pause/resume events received. A domain-placeholder package imports neither Flutter nor Flame. Manual vs `flame_riverpod` bridge compared | TD-03, TD-04, TD-05 |
| 2 | **S-02 Rive reveal** | Play a representative Rive character in a Flutter overlay (and optionally via `flame_rive`) | Smooth playback in profile mode on the low-end device. Release APK/AAB size increase measured and reported. Load-to-first-frame time measured. minSdk requirement of `rive_native` confirmed. Go/no-go recommendation with fallback assessment | Q-015, R-01, Q-013 input |
| 3 | **S-03 Drag, snap and tray** | 4×4 board with mixed pieces from one texture; drag from tray, snap, return | No dropped frames during drag on mid-range hardware in profile mode. Snap threshold and timings configurable. Tray variants (scaled, scrolling, paged) on 16:9 and 20:9 at 360 dp width. Informal usability check with a few testers | GP-03 to GP-06 feasibility, Q-011 input, Q-010 input, R-02, R-03 |
| 4 | **S-04 Partition generation** | Pure-Dart enumeration/selection under candidate constraints | Every output satisfies the tiling invariant (property tests). Generation time measured on the low-end device. Deterministic with a fixed seed within one SDK version. Candidate layouts rendered for design review | TD-02, Q-009 input |
| 5 | **S-05 Audio** | Short SFX through `flame_audio` pools | Perceived pick-up and snap latency acceptable on the low-end device. Rapid repeated snaps play without dropouts. Audio pauses on background and resumes correctly | GP-12, R-04 |
| 6 | **S-06 Persistence** | JSON document store with atomic writes behind a repository interface (compared against `sembast` if useful) | No corruption across repeated forced kills during writes. Per-placement save time measured on the low-end device. Schema version and migration path demonstrated. Session restore exact | TD-01, Q-014, R-05 |
| 7 | **S-07 Screen and orientation** | Layout and orientation on phone sizes, a tablet and a foldable at API 36 | Portrait layout usable at all tested sizes. Behaviour when the orientation lock is ignored documented. No hardcoded coordinates | Q-013 input, R-07 |

S-04 and S-06 are pure Dart or low-risk and can run in parallel with S-01 to S-03.

---

## 9. Documentation Inconsistencies Found

| # | Location | Issue | Suggested action |
| --- | --- | --- | --- |
| D-01 | GAMEPLAY §1 "Dragging and snapping" step 1 | Says pieces can be dragged "from the board". If correctly placed pieces lock (open in Q-010), board-to-board moves never happen | Leave until Q-010 is decided, then align |
| D-02 | DATA_MODELS `PuzzleSessionSnapshot.layout` | "Saved if it cannot be reproduced exactly": Dart `Random` is not guaranteed stable across SDK versions, so reproduction from a seed is fragile | Recommend always persisting the layout (TD-02); update when the ADR is approved |
| D-03 | TESTING_STRATEGY §2 | Reward-rule tests (application layer) are listed under "Puzzle Domain — Required Coverage" | Move to an application-layer section when the testing strategy is next revised |
| D-04 | ADR_INDEX "Planned ADRs" | Lists TD-01 to TD-04 and Rive only; TD-05 to TD-08 are missing | Updated in this change |
| D-05 | IMPLEMENTATION_STATUS | Did not reflect that the feasibility review had been performed | Updated in this change |

No contradictions with confirmed product decisions were found.

---

## 10. Next Steps (proposed)

1. Product owner reviews this document.
2. Decide which spikes to run and in what order; the recommended order is in §8.
3. Product input on Q-009 constraints, Q-010 and Q-011, which are needed to finish S-03 and S-04.
4. Write ADRs for TD-01 to TD-05 after their spikes; TD-06 to TD-08 can be decided without spikes.
5. Only then create the Flutter project structure (TD-04) and start the puzzle domain (Roadmap Phase 2).
