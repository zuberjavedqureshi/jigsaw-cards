# Technical Feasibility & Architecture Review

| Field | Value |
| --- | --- |
| Review date | 2026-11-23 |
| Baseline | `main` at merge of PR #1 (`a4a551b`) |
| Scope | Feasibility of confirmed requirements; Q-009, Q-010, Q-013, Q-014, Q-015; TD-01 to TD-08; risks; spikes |
| Status | **Analysis and recommendations only.** Nothing in this document approves a decision, closes an open question or changes product scope. |

> **Status update (2026-11-23, after merge):** the product owner has resolved **Q-009** (piece generation), **Q-010** (placement) and **Q-011** (tray). See PRD PS-19 to PS-24, GP-06 and GP-14 to GP-19, and [OPEN_QUESTIONS](../../planning/OPEN_QUESTIONS.md). The analysis below is kept as written, with resolution notes added where it referred to those questions. TD-01 to TD-08 remain **Pending**, and no spike has been approved. *(Status as of 2026-11-23; superseded for TD-03, TD-04, TD-05 and S-01 by the note below.)*
>
> **Status update (2026-11-24):** following S-01, the product owner confirmed **TD-03** (manual bridge, [ADR-0001](../decisions/ADR-0001-flame-riverpod-manual-bridge.md)), **TD-04** (pub workspace with enforced boundary, [ADR-0002](../decisions/ADR-0002-pub-workspace-and-domain-boundary.md)) and **TD-05** (no code generation, [ADR-0003](../decisions/ADR-0003-handwritten-riverpod-providers.md)). The other decisions remain Pending. S-01's Android device validation is still outstanding.

## 0. How to Read This Review

- **Feasibility ratings:** **Feasible**, **Feasible with constraints** or **Needs investigation**.
- **Recommendations** are technical proposals. They become decisions only through an approved ADR, or through product-owner approval for product questions.
- **Evidence** is cited inline: package data from the pub.dev API, Flutter toolchain source, Android developer documentation (§6.4) and a combinatorial analysis of 4×4 tilings (§6.1). Claims not verified against an authoritative source are marked **(unverified)** and assigned to a spike.
- **Acceptance criteria** in §8 are tagged **[Measure & report]** (record the result; no pass threshold), **[Check]** (pass/fail by inspection or test), **[Target — proposed]** (a numeric threshold that requires approval before it can be used to pass or fail a spike) or **[Observation]** (recorded for information; explicitly not a pass/fail gate). No benchmark results exist yet; every number in a target is a proposal, not a measurement.

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

Flutter Android defaults, from `flutter_tools` `FlutterExtension.kt` on `stable`: **minSdk 24 (Android 7.0), targetSdk 36, compileSdk 36.** These are the values a new Flutter project starts with. **They are not product decisions**; the minimum and target Android versions remain open (Q-013, TD-06).

All confirmed stack choices (Flame, flame_audio, Riverpod) have current, compatible releases on the same Flutter/Dart baseline. No blocking version conflict was found.

---

## 1. Executive Summary

1. **The confirmed product is technically feasible** on Flutter + Flame + Riverpod. No confirmed requirement is infeasible.
2. **Three areas need investigation before implementation:**
   - Rive character reveal (GP-10, VI-03): native runtime, APK size and performance.
   - Tray layout on portrait phones (GP-03): the 4×4 pieces do not fit beside the board at full scale.
   - Drag-and-snap feel (GP-04, GP-05).
3. **Rectangular partition generation (PS-08) appears low risk.** A 4×4 board has exactly **70,878** rectangle tilings. Exhaustive enumeration took about **182 ms in an unoptimised Python script on a desktop-class container**, not on a phone. That suggests the search space is small, but **Dart performance on a low-end Android device has not been measured** and must be measured in S-04. A constrained, seeded or enumerate-and-choose approach is straightforward. The product constraints were approved on 2026-11-23 (Q-009: pieces 1×1 to 2×2, 8–12 pieces, seeded, layout persisted).
4. **Recommended persistence for the prototype:** a **single versioned JSON document with atomic writes**, behind a repository interface. This needs no database dependency. Revisit if requirements grow (TD-01, Q-014).
5. **Recommended project shape:** a Dart **pub workspace** with `app/` and `packages/puzzle_domain/`. The domain package has no Flutter dependency, so the domain/rendering boundary is enforced by the dependency graph (TD-04).
6. **Platform watch item:** Android documentation confirms that for apps targeting API 36, orientation restrictions are ignored on displays with smallest width ≥ 600 dp (tablets, unfolded foldables), with an exemption for apps declared as games via `android:appCategory` (§6.4). Phones under 600 dp are not affected. How this applies to Jigsaw Cards is unverified on devices and is assigned to S-07.
7. **Seven spikes** are proposed (§8). The highest priority are the hybrid shell, the Rive reveal, and drag/snap with tray layout.

---

## 2. Requirement Feasibility

### 2.1 Platform and architecture

| Req | Requirement | Rating | Notes |
| --- | --- | --- | --- |
| §13 | Android first | Feasible | Flutter project defaults are minSdk 24 / targetSdk 36 (§6.3); the actual values are not yet decided (Q-013) |
| §13 | Portrait orientation | Feasible with constraints | Lock with `SystemChrome.setPreferredOrientations` and the manifest. On phones (< 600 dp smallest width) the lock applies normally. On large screens, apps targeting API 36 have orientation restrictions ignored unless an exemption applies (§6.4). Device behaviour unverified; layout must degrade gracefully, e.g. a centred portrait column (R-07, S-07) |
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
| GP-03 Tray below board | **Needs investigation** | Space analysis (§2.4): the tray cannot hold all 16 cells' worth of pieces at board scale. *Resolved by Q-011:* a two-row, horizontally scrollable tray, with pieces enlarging to board scale on pick-up (GP-16 to GP-19). Touch-target comfort and layout across phone sizes still need validation in S-03 |
| GP-04 Drag from tray onto board | Feasible with constraints | Flame `DragCallbacks`. Handle single-pointer drag (ignore extra pointers), raise the dragged piece's priority, and make touch targets large enough (§2.4) |
| GP-05 Automatic magnetic snapping | Feasible with constraints | Simple geometry; the risk is *feel*. Snap threshold and animation timing must be configurable and tuned on devices (S-03) |
| GP-06 Incorrect drop animates back to previous position | Feasible | Animate back with a Flame `MoveToEffect`. *Confirmed by Q-010*, together with the strict rule and permanent locking (GP-14, GP-15) |
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
| PS-08 Rectangular partition generation | Feasible | §6.1. The algorithm is a technical choice (TD-02). The product constraints were approved via Q-009 (PS-19 to PS-24) |
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
- **Implication:** the tray needs a smaller piece scale (e.g. 0.6 to 0.75×, enlarging on pick-up), scrolling or paging. *Resolved by Q-011:* two rows, horizontal scrolling, enlargement to board scale on pick-up. The tray piece scale itself is not specified by the decision and is set during S-03 within the "comfortable touch targets" requirement (GP-17). Layout must be computed from available size (Development Rule 6).

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

TD-03, TD-04 and TD-05 were confirmed on 2026-11-24 (ADR-0001 to ADR-0003; see the notes in each subsection). The others remain **Pending** until an ADR is approved. The recommendation text below is kept as originally written.

### TD-01 Local database / storage

| Option | Assessment |
| --- | --- |
| **Versioned JSON document + atomic file write** (`path_provider`) | **Recommended for prototype.** Data is small (progress, card IDs, coins, settings, one session snapshot: a few KB). Minimal dependency, trivially versioned, easy to inspect and test. Write to a temp file, then rename for atomic replacement |
| `sembast` | Good alternative if multiple documents or queries are needed; pure Dart, maintained |
| `drift` (SQLite) | Strong migrations and querying, but adds code generation and native SQLite. Justified only if relational or query needs appear |
| `hive_ce` | Maintained fork; adequate, but adds a dependency without a clear need |
| `shared_preferences` | Fine for settings only; not suitable for the session snapshot |
| `hive`, `isar` | **Excluded**: unmaintained since 2022/2023, with pre-Dart-3 SDK constraints |

**Recommendation:** use a JSON document store behind a repository interface for the prototype, with a `schemaVersion` and migration hook. Validate crash safety in S-06. The recovery policy for a missing or invalid save (e.g. last-known-good backup vs defined default state) is a separate choice that requires explicit approval. Re-evaluate before MVP if cloud save (Firebase) or larger data appear.

### TD-02 Rectangular partition generation algorithm

**Recommendation:** use **enumerate-and-select** or **constrained random splitting with rejection**. Both appear practical for 4×4 given the size of the search space (§6.1), but runtime cost in Dart on a low-end Android device is unmeasured. If S-04 shows runtime generation is too slow, generate at content-build time instead. Pick a layout with a seeded generator, then **persist the resulting layout** in configuration (if generated at build time) or in the session snapshot (if generated at runtime). Unit-test that every output satisfies the tiling invariant and the configured constraints. *Update 2026-11-23:* Q-009's product constraints are now approved (PS-19 to PS-24), and seeding and layout persistence are product requirements. The algorithm choice remains pending.

### TD-03 Flame ↔ Riverpod bridge

> **Confirmed 2026-11-24** by the product owner: [ADR-0001](../decisions/ADR-0001-flame-riverpod-manual-bridge.md). The original recommendation follows.

| Option | Assessment |
| --- | --- |
| Manual bridge: pass a small interface (intent callbacks plus a state listener) into the `FlameGame` | **Recommended default.** No dependency; the bridge surface is small (one game, a handful of signals) |
| `flame_riverpod` 5.5.5 (Flame-maintained) | Acceptable if components need to watch several providers. Low risk because it is first-party and version-aligned with Flame 1.38 / Riverpod 3 |

**Recommendation:** start with the manual bridge in S-01, and adopt `flame_riverpod` only if the spike shows real friction (Development Rule 1).

### TD-04 Repository layout

> **Confirmed 2026-11-24** by the product owner: [ADR-0002](../decisions/ADR-0002-pub-workspace-and-domain-boundary.md). The original recommendation follows.

**Recommendation:** a Dart **pub workspace** (supported natively since Dart 3.6; no Melos required):

```
pubspec.yaml            (workspace root)
app/                    Flutter application
packages/puzzle_domain/ Pure Dart package (no Flutter dependency)
```

This matches the proposal in ARCHITECTURE_OVERVIEW §4 and enforces QG-02 through the dependency graph.

### TD-05 Riverpod code generation

> **Confirmed 2026-11-24** by the product owner: [ADR-0003](../decisions/ADR-0003-handwritten-riverpod-providers.md). The original recommendation follows.

**Recommendation:** **no code generation initially.** Write providers by hand. The provider count is small, and `riverpod_generator` adds `build_runner` to every change cycle. Revisit if the provider count or boilerplate grows. Avoid relying on Riverpod features marked experimental.

### TD-06 Minimum Android version / target devices

See Q-013 (§5). Flutter's defaults are a starting point, not a decision.

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

> **Resolved 2026-11-23** by the product owner: pieces 1×1, 1×2, 2×1, 2×2; every generated prototype layout must contain between 8 and 12 pieces, inclusive; seeded generation; layout persisted; hand-authored layouts not required for the prototype (PRD PS-19 to PS-24). By the analysis in §6.1, these constraints admit **13,932** distinct 4×4 layouts. The algorithm remains a technical decision (TD-02). The analysis below is the original pre-decision text.

**Evidence (§6.1):**

- A 4×4 board has **70,878** rectangle tilings (matches OEIS A116694).
- 68,480 of them are guillotine-cuttable.
- Limiting pieces to at most 2×2 leaves **15,623**.
- Exhaustive enumeration took about 182 ms with an unoptimised Python 3.13 script on the review container (a desktop-class Linux environment, not a mobile device). This shows only that the search space is small. **It is not a prediction of Dart performance on Android**, which must be measured on the low-end test device in S-04.

**Technical recommendation:**

- Enumerate valid layouts, filter them by the configured constraints, and choose one with a seeded generator.
- Persist the chosen layout; Dart's `Random` sequence is not documented as stable across SDK versions.
- Runtime generation appears practical, subject to S-04 measurement. Build-time generation gives designers review control and has no runtime cost. The choice could be made per puzzle in configuration.

**Needs product/design input** (*resolved 2026-11-23, see the note above*):

- Allowed piece sizes (e.g. max 2×2? are 1×3 and 1×4 allowed?).
- Piece-count range.
- Whether hand-authored layouts are also supported.

For reference, with pieces capped at 2×2, 8 to 12 pieces covers 13,932 distinct layouts, so variety is ample.

### Q-010 Placement rule

> **Resolved 2026-11-23** by the product owner: strict rule (only the correct position accepts a piece), permanent locking (no moving or swapping), and incorrect drops animate back to the previous position (PRD GP-06, GP-14, GP-15). The analysis below is the original pre-decision text.

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

**Evidence:** Flutter's project defaults are minSdk 24 (Android 7.0) and targetSdk 36. These defaults are not product decisions.

**Technical recommendation (not a decision):**

- Start from `minSdk 24`, the Flutter default, unless S-02 shows that `rive_native` requires higher or Q-001 changes the device floor.
- `targetSdk` at the latest stable level; confirm Google Play's current target-API requirement at submission time. Targeting API 36 brings the large-screen orientation behaviour in §6.4.
- Proposed device test matrix:
  - One low-end device: about 2 to 3 GB RAM, 60 Hz, a recent Android Go-class or budget device.
  - One mid-range device.
  - One high-refresh-rate device (90/120 Hz).
  - One large-screen or foldable emulator at API 36.
- Performance is measured with the protocol in §8.1. The proposed frame-time targets there require approval.

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

Measurement environment: Python 3.13, unoptimised script, on the review container (desktop-class Linux, not a mobile device); full enumeration took about 182 ms. This is not an estimate of Dart or on-device performance, which S-04 measures.

Conclusion: the search space is small enough that exhaustive, constraint-filtered selection is a reasonable candidate, subject to S-04 measurement. Note that guillotine-only splitting (recursive cuts) would exclude 2,398 valid layouts, such as pinwheel arrangements. Whether that matters is a design choice.

### 6.2 Memory and asset sizing (estimates)

- A 1440×1440 RGBA puzzle texture is about 8 MB of GPU memory. That is acceptable, with one active puzzle at a time.
- Bundled illustrations dominate install size as content grows. Plan for Android App Bundle delivery, and review Play Asset Delivery before MVP content volume is set (R-08).

### 6.3 Toolchain baseline

Flutter 3.50.1 stable, Dart 3.14.0. Project defaults: minSdk 24, targetSdk/compileSdk 36, NDK 28.2. These are defaults, not decisions (Q-013, TD-06). All selected packages declare compatible SDK constraints.

### 6.4 Android 16 (API 36) large-screen orientation behaviour

**Verified against Android developer documentation** (retrieved 2026-11-23):

- [Behavior changes: apps targeting Android 16 or higher](https://developer.android.com/about/versions/16/behavior-changes-16), page last updated 2026-10-28.
- [`<application>` manifest element](https://developer.android.com/guide/topics/manifest/application-element), page last updated 2026-08-21.

What the documentation states:

| Point | Documented behaviour |
| --- | --- |
| Scope | Apps targeting Android 16 (API 36) |
| Change | Orientation, resizability and aspect-ratio restrictions no longer apply on displays with smallest width ≥ 600 dp. Apps fill the display window regardless of the preferred orientation, without pillarboxing |
| Exceptions | Games, based on the `android:appCategory` flag; users who opt in to the app's default behaviour in the device's aspect-ratio settings; screens smaller than sw600dp |
| Temporary opt-out | Manifest property `android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY` at activity or application level |
| Future | The opt-out will not apply to apps targeting API 37 |
| `appCategory` | Valid values include `game`; categories are also used to group apps when summarising battery, network or disk usage |

**Implications for Jigsaw Cards:**

- Phones (< 600 dp smallest width) are unaffected: the portrait lock applies.
- On tablets and unfolded foldables, the portrait lock would be ignored unless the game exemption or a user setting applies.
- Declaring `android:appCategory="game"` is a candidate technical option. It is **not a decision**.

**Unverified (assigned to S-07):**

- Actual behaviour on an API 36 large-screen emulator or device, with and without `appCategory="game"`.
- Whether the game exemption continues for apps targeting API 37. The documentation states only that the opt-out property ends; it does not say whether the game exemption continues.
- Interaction with Flutter's `SystemChrome.setPreferredOrientations`.

**Recommendation:** whatever the exemption outcome, build the layout to stay usable in a non-portrait or resizable window (centred portrait column). That keeps the design correct if exemptions change.

---

## 7. Risks, Trade-offs and Dependencies

| ID | Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- | --- |
| R-01 | Rive runtime (0.x, native) fails performance, size or integration criteria | Medium | High: affects the core reveal | S-02 early; sprite-sheet fallback (Q-015) |
| R-02 | Drag/snap feel is not satisfying on low-end devices | Medium | High: core experience | S-03 with configurable thresholds; profile-mode measurement |
| R-03 | Tray cannot present pieces comfortably on short screens | High | Medium | Two-row scrollable tray with enlargement on pick-up, approved via Q-011; validate touch targets and layout in S-03 |
| R-04 | SFX latency or overlap issues on Android | Medium | Medium | Pre-loaded low-latency pools; S-05 |
| R-05 | Save corruption, lost progress or inconsistent reward state on process death or device interruption | Low | High | Save per placement; atomic write-and-replace (recommended, not decided); recovery policy to be approved (S-06 alternatives); single document so progress, cards, coins and reward-granted state are written together; staged-termination tests in S-06. Power loss cannot be fully reproduced in testing |
| R-06 | Premature abstraction for the future irregular style slows the prototype | Medium | Medium | Shared contracts limited to PS-13 to PS-17; Development Rules 7 and 9 |
| R-07 | On large screens (≥ 600 dp), API 36 targeting ignores the portrait lock unless an exemption applies (documented, §6.4); device behaviour unverified | Medium | Low–Medium | Responsive centred layout; evaluate the `appCategory="game"` exemption; verify in S-07 |
| R-08 | Asset volume inflates install size | Medium | Medium | Texture sizing guidelines; App Bundle; Asset Delivery review before MVP |
| R-09 | Dependency churn (Flame requires recent Flutter; Riverpod 3 changes) | Medium | Low | TD-07 pinning; deliberate upgrade PRs |
| R-10 | Indistinguishable pieces feel unfair under the strict rule (now confirmed, GP-14) | Medium | Low–Medium | Content guidelines or generation constraints within PS-20/PS-21 |
| R-11 | Unresolved product decisions (Q-001, Q-002, Q-007, Q-020) block MVP design | High | Medium | Q-009, Q-010 and Q-011, the prototype blockers, were resolved 2026-11-23 |

**Dependencies on product decisions:**

- **Prototype:** Q-009, Q-010 and Q-011 were resolved 2026-11-23.
- **MVP:** Q-001, Q-002, Q-007, Q-020.

---

## 8. Proposed Technical Spikes (prioritised)

Spikes are time-boxed experiments on `spike/*` branches. Their code is throwaway and is not merged as production code without review. Each spike ends with a short findings note and, where a decision results, an ADR. **No spike is approved or started by this document.**

| Priority | Spike | Objective | Informs |
| --- | --- | --- | --- |
| 1 | **S-01 Hybrid shell** | Flutter screen embedding a `GameWidget`, Riverpod state, a Flutter overlay and app lifecycle hooks | TD-03, TD-04, TD-05 |
| 2 | **S-02 Rive reveal** | Play a representative Rive character in a Flutter overlay (optionally via `flame_rive`) | Q-015, R-01, Q-013 input |
| 3 | **S-03 Drag, snap and tray** | 4×4 board with mixed pieces from one texture; two-row scrollable tray, drag, snap and lock, return | GP-03 to GP-06, GP-14 to GP-19, R-02, R-03 |
| 4 | **S-04 Partition generation** | Pure-Dart seeded generation under the approved constraints (PS-19 to PS-24) | TD-02 |
| 5 | **S-05 Audio** | Short SFX through `flame_audio` pools | GP-12, R-04 |
| 6 | **S-06 Persistence** | JSON document store with atomic write-and-replace behind a repository interface (compared against `sembast` if useful) | TD-01, Q-014, R-05 |
| 7 | **S-07 Screen and orientation** | Layout and orientation on phones, a tablet and a foldable at API 36 | Q-013 input, R-07, §6.4 |

S-04 and S-06 are pure Dart or low-risk and can run in parallel with S-01 to S-03.

### 8.1 Performance measurement protocol (applies to S-01, S-02, S-03, S-05, S-06)

**Build and tooling**

- **Profile mode** builds only; debug-mode timings are not valid.
- Collect per-frame build and raster times with Flutter's `FrameTiming` data, via DevTools or `SchedulerBinding.addTimingsCallback`.

**Recording conditions** for each run:

- Device model, Android version, RAM and display refresh rate.
- Battery level and charging state; battery saver off.
- Thermal state: cold start, or after a 5-minute warm-up.
- Other apps closed.

**Scenario:** a defined, repeatable interaction script per spike (e.g. a 30-second scripted drag sequence). Run at least 3 times and report each run.

**Frame budgets**

| Display | Budget |
| --- | --- |
| 60 Hz | 16.7 ms |
| 90 Hz | 11.1 ms |
| 120 Hz | 8.3 ms |

A **missed frame** is one whose build or raster time exceeds the budget for the device's active refresh rate.

**Report for each scenario:**

- Build- and raster-time distribution (p50, p90, p99, max).
- Total frames.
- Missed-frame count and percentage.

**Proposed frame-time targets** (**[Target — proposed]**, require approval):

| Device | Refresh rate | Proposed target |
| --- | --- | --- |
| Mid-range | 60 Hz | ≤ 1% missed frames during the scenario; p99 build and raster each ≤ 16.7 ms |
| Low-end | 60 Hz | ≤ 5% missed frames during the scenario |
| High-refresh device | 120 Hz | **[Measure & report]** only, against the 8.3 ms budget. No pass threshold until the product owner decides whether high-refresh smoothness is a goal |

### 8.2 Acceptance criteria per spike

**S-01 Hybrid shell**

- **[Check]** A Riverpod state change is reflected in the Flame scene, and a Flame intent updates the Riverpod notifier.
- **[Check]** A Flutter overlay shows and hides over the game.
- **[Check]** App pause and resume events are received.
- **[Check]** A placeholder domain package imports neither Flutter nor Flame, and the build fails if it tries to.
- **[Measure & report]** Frame timing (§8.1) for an idle scene and an overlay toggle on the mid-range device.
- **[Measure & report]** Comparison of the manual bridge and `flame_riverpod`: lines of glue code and any limitations found.

**S-02 Rive reveal**

- **[Measure & report]** Frame timing (§8.1) during the reveal animation on the low-end and mid-range devices.
- **[Target — proposed]** During the reveal, frame-time targets as in §8.1.
- **[Measure & report]** Release AAB and per-ABI APK size increase from adding `rive`. A size budget must be set by the product owner before this can be pass/fail.
- **[Measure & report]** Time from reveal trigger to the first rendered animation frame, and the memory increase during playback.
- **[Check]** `rive_native`'s minimum Android API is confirmed from its manifest/documentation and compared with the Q-013 recommendation.
- **[Check]** Findings note gives a go/no-go recommendation, with the fallback assessment (Q-015).

**S-03 Drag, snap and tray**

- **[Measure & report]** Frame timing (§8.1) for a scripted drag-and-drop sequence on all three device classes.
- **[Target — proposed]** Frame-time targets as in §8.1 on the mid-range and low-end devices.
- **[Measure & report]** Touch-to-visual response: time from pointer-down to the piece visibly lifting, from a screen recording or pointer and frame timestamps.
- **[Check]** Snap threshold, snap duration and return animation are configuration values, not hardcoded.
- **[Check]** The approved two-row, horizontally scrollable tray (GP-16) renders without overlap or clipping on 16:9 and 20:9 layouts at 360 dp width.
- **[Check]** A picked-up piece enlarges to board scale (GP-18). An incorrect drop animates back to its tray position (GP-06). A correctly placed piece locks and cannot be picked up again (GP-15).
- **[Measure & report]** Tray piece touch-target sizes at each tested screen size.
- **[Target — proposed]** Tray touch targets ≥ 48 dp, Android's minimum touch-target guideline. GP-17 requires "comfortable touch targets" but no number has been approved.
- **[Measure & report]** Informal usability observations from a small group of testers. These are observations, not acceptance gates.

**S-04 Partition generation**

- **[Check]** Property tests: every generated layout satisfies the tiling invariant, uses only 1×1, 1×2, 2×1 and 2×2 pieces, and contains between 8 and 12 pieces, inclusive (PS-20, PS-21).
- **[Check]** With a fixed seed and the same SDK version, output is identical across runs.
- **[Measure & report]** Generation time in Dart (AOT, profile/release) on the low-end test device: p50, p95 and max over at least 100 generations, under the approved constraints.
- **[Target — proposed]** Layout generation completes within 100 ms p95 on the low-end device; otherwise recommend build-time generation.
- **[Check]** The persisted layout restores identically (PS-23), without relying on regenerating from the seed.
- **[Check]** A sample of generated layouts is rendered for design review.

**S-05 Audio**

- **[Measure & report]** Touch-to-sound latency for pick-up and snap SFX on the low-end and mid-range devices: p50 and p95. Measured externally, e.g. by recording the tap and the device audio together, because app-side timestamps do not capture output latency.
- **[Target — proposed]** Touch-to-sound latency ≤ 100 ms p50 on the low-end device.
- **[Check]** 10 snap sounds triggered within 2 seconds all play, with no errors or crashes. Any audible clipping is noted as an observation.
- **[Check]** Audio stops when the app goes to the background and resumes correctly on return.
- **[Measure & report]** Frame timing (§8.1) while SFX play during the S-03 drag scenario.

**S-06 Persistence** (atomic write-and-replace remains a recommendation; TD-01 and Q-014 stay open)

These are proposed acceptance criteria for a throwaway spike. None of the tests below exist yet; they are written during S-06 only if the spike is approved. Each scenario is automated where possible, with at least one run on a physical device.

*Process-termination scenarios.* These four test different things and are reported separately.

- **[Check] Background process termination.**
  - Put the app in the background with an unfinished puzzle and a completed save.
  - Terminate the process as Android would when reclaiming memory. For example: `adb shell am kill <package>`, which kills a background process; or the Developer Options background-process limit; or memory pressure.
  - Relaunch. The state matches the last completed save exactly.
  - This confirms that save-per-placement does not depend on lifecycle callbacks that may never arrive.
- **[Check] Force-stop and relaunch.**
  - Force-stop the app (`adb shell am force-stop <package>`, or Settings → Force stop) at various moments, including during a burst of placements, then relaunch.
  - The store loads a complete, valid state: either the previous one or the new one.
  - **Limitation:** a force-stop is triggered externally and its timing cannot be aligned with an individual filesystem operation. A single save is expected to take only a few milliseconds, so this test rarely, if ever, interrupts a specific write stage. It tests whole-app interruption, not write-stage atomicity. Controlled termination (below) covers that.
- **[Check] Controlled termination during writes.**
  - The throwaway spike implementation includes test-only hooks. Each hook terminates the process abruptly at one save stage; for example, the process kills itself with SIGKILL rather than exiting gracefully, so no cleanup code runs.
  - Each stage is run repeatedly (see *Repeated termination*). After relaunch, the observed outcome is recorded against the expected outcome:

| Stage | Termination point | Expected outcome on relaunch |
| --- | --- | --- |
| 1 | Before temporary-file creation | Previous complete state; no temporary file |
| 2 | During temporary-file writing (partial bytes written) | Previous complete state; partial temporary file detected, ignored and cleaned up |
| 3 | After temporary-file flush/close, before replacement | Previous complete state; leftover temporary file handled per the approved recovery policy (it must never be loaded without full validation) |
| 4 | During replacement of the primary file | Either the previous or the new complete state, never a mix. *Note:* replacement by rename is expected to be atomic at the filesystem level on the same volume. A hook can therefore only terminate immediately before or immediately after the rename call, not inside it. Whether the chosen Dart/Android file APIs give this atomicity is itself confirmed in the spike |
| 5 | Immediately after replacement | New complete state |

- **[Check] Repeated termination.** At least 100 controlled terminations per stage (automated loop), plus repeated background-kill and force-stop cycles, produce zero corrupted or inconsistent states.
- **[Observation] Abrupt device interruption (limitation).**
  - Emulator and process-kill tests **cannot fully reproduce sudden power loss or hardware-level storage interruption**. After a process kill, data already handed to the operating system usually still reaches storage. After power loss, data still in OS or storage caches can be lost or partially written.
  - The spike documents which file APIs are used and whether they request durable writes to storage (e.g. a sync/flush to disk), as opposed to only handing data to the OS. It does not assume either.
  - Where practical, add physical-device testing, such as a forced device reboot during a continuous save loop. Record the results as observations rather than proof of power-loss safety.

*Recovery behaviour*

- **[Check] Incomplete temporary file.** A leftover or truncated temporary file at startup is detected, never loaded without full validation, and cleaned up.
- **[Check] Missing or invalid primary file.** If the primary save is missing, or fails to parse or validate (schema version, checksum or structure), the app recovers without crashing and logs the recovery for diagnosis. It follows **the recovery policy that is eventually approved** (see *Recovery policy*). The tests verify that approved policy, whichever it is.
- **[Check] Cross-field consistency.** After any interruption or recovery, puzzle progress, collected cards, coin balance and the reward-granted marker are consistent with each other. No card or coins are recorded without the matching completion record, and no completion record exists without its reward.
- **[Check] No double rewards.** Neither recovery nor relaunch ever silently awards coins or collectible cards a second time.
- **[Check] Exact restoration.** An unfinished puzzle restores with an identical layout and identical piece locations (tray or board) to the last saved state.
- **[Check]** The schema version is written, and a sample migration from version N to N+1 is demonstrated.

*Recovery policy (alternatives; requires explicit approval)*

S-06 evaluates the alternatives below and reports the trade-offs. **No policy is selected by this review.**

| Option | Description | Trade-off |
| --- | --- | --- |
| Last-known-good backup | Keep the previous valid save as a backup; if the primary is missing or invalid, restore from it | Limits loss to the most recent changes; adds a second file and its own validation and rotation rules |
| Defined default state | If the primary is missing or invalid, start from a defined default (new-player) state | Simplest; a corrupted save loses all progress |

Other designs may be proposed by the spike. Whatever policy is approved must preserve the *No double rewards* and *Cross-field consistency* checks above.

*Performance*

- **[Measure & report]** Save duration per placement on the low-end device (p50, p95, max), and frame timing (§8.1) during a scripted placement sequence with saving on versus off.
- **[Target — proposed]** Saving adds no more than 1 percentage point to the missed-frame rate of the same scenario without saving.

**S-07 Screen and orientation**

- **[Check]** The portrait layout is usable (no overlap, clipping or hardcoded coordinates) on 16:9 and 20:9 phones at 360 dp width, a tablet, and a foldable (folded and unfolded), on an API 36 emulator or device.
- **[Check]** Document the observed behaviour on ≥ 600 dp displays when targeting API 36: (a) with no exemption, (b) with `android:appCategory="game"`, and (c) with the temporary opt-out property. This confirms or corrects §6.4.
- **[Check]** Document how Flutter's `SystemChrome.setPreferredOrientations` behaves in each case.
- Results are input to Q-013 and R-07, not decisions.

## 9. Documentation Inconsistencies Found

| # | Location | Issue | Suggested action |
| --- | --- | --- | --- |
| D-01 | GAMEPLAY §1 "Dragging and snapping" step 1 | Says pieces can be dragged "from the board". If correctly placed pieces lock (open in Q-010), board-to-board moves never happen | **Fixed 2026-11-23** after Q-010 resolved locking |
| D-02 *(fixed 2026-11-23: layout always persisted, PS-23)* | DATA_MODELS `PuzzleSessionSnapshot.layout` | "Saved if it cannot be reproduced exactly": Dart `Random` is not guaranteed stable across SDK versions, so reproduction from a seed is fragile | Recommend always persisting the layout (TD-02); update when the ADR is approved |
| D-03 | TESTING_STRATEGY §2 | Reward-rule tests (application layer) are listed under "Puzzle Domain — Required Coverage" | Move to an application-layer section when the testing strategy is next revised |
| D-04 | ADR_INDEX "Planned ADRs" | Lists TD-01 to TD-04 and Rive only; TD-05 to TD-08 are missing | Updated in this change |
| D-05 | IMPLEMENTATION_STATUS | Did not reflect that the feasibility review had been performed | Updated in this change |

No contradictions with confirmed product decisions were found.

---

## 10. Next Steps (proposed)

1. Product owner reviews this document.
2. Decide which spikes to run and in what order; the recommended order is in §8.
3. ~~Product input on Q-009 constraints, Q-010 and Q-011, which are needed to finish S-03 and S-04.~~ Done (2026-11-23).
4. Write ADRs for TD-01 and TD-02 after their investigations (S-06 and S-04). TD-03, TD-04 and TD-05 already have accepted ADRs ([ADR-0001](../decisions/ADR-0001-flame-riverpod-manual-bridge.md), [ADR-0002](../decisions/ADR-0002-pub-workspace-and-domain-boundary.md), [ADR-0003](../decisions/ADR-0003-handwritten-riverpod-providers.md), 2026-11-24). TD-06 to TD-08 can be decided without spikes.
5. Only then create the Flutter project structure (TD-04) and start the puzzle domain (Roadmap Phase 2).
