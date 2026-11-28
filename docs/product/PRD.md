# Jigsaw Cards — Product Requirements Document

| Field | Value |
| --- | --- |
| Version | 1.0 (canonical repository edition, reconciliation 10: W4-R1 hybrid visual direction and artwork sourcing, approved 2026-11-28) |
| Status | Approved product decisions; pre-development technical validation |
| Platform | Android first, portrait |
| Tagline | **Solve. Discover. Collect.** |

## 0. How to Read This Document

This is the canonical product specification for the repository. Every requirement carries one of these labels:

| Label | Meaning |
| --- | --- |
| **[Confirmed]** | Approved product decision. Changing it requires explicit approval. |
| **[Proposed]** | Recommended approach, not yet approved. |
| **[Open]** | Undecided. Tracked in [OPEN_QUESTIONS.md](../../planning/OPEN_QUESTIONS.md). |
| **[Source text needed]** | The approved PRD v1.0 covers this topic, but its approved wording has not yet been supplied to the repository. Content here is limited to what has been confirmed so far. Nothing is invented to fill the gap. |

**Provenance.** The approved PRD v1.0 was produced in an earlier planning discussion that is not stored in this repository. This edition consolidates the decisions confirmed in the repository setup brief and the reconciliation brief. Sections marked **[Source text needed]** must be completed from the approved PRD text (OPEN_QUESTIONS Q-019).

Requirement IDs (e.g. `GP-03`) are stable and may be referenced from issues, ADRs and tests. Superseded requirements keep their IDs, are struck through and must not be implemented.

**Revision notes**

| Reconciliation | Date | Change |
| --- | --- | --- |
| 4 | 2026-11-24 | Q-001 target audience resolved |
| 5 | 2026-11-25 | Gameplay revised twice: free placement with memory reveal (GP-20 to GP-28, then superseded), then the **rectangular picture-swap puzzle** (GP-29 to GP-36). Q-010 and Q-011 revised. **Q-022** resolved (equal-sized tiles; mixed-size partition superseded for this gameplay; PS-01, PS-06, PS-08, PS-19 to PS-24, GP-02 revised) and **Q-023** resolved (correct tiles remain movable; GP-32, GP-34). Hints excluded from the prototype, planned for v1 (GP-36) |
| 6 | 2026-11-26 | Puzzle introduction (card entrance and reveal), already implemented and approved on the product owner's device, recorded as **GP-37**. M3.1 "Bright & Celebrate" approved: **Sunlit Storybook** palette for the whole UI (**VI-06**), bright code-drawn daytime placeholder picture (**VI-07**), board spacing (**GP-38**), completion celebration without rewards (**GP-39**) and the next-puzzle transition (**GP-40**) |
| 7 | 2026-11-26 | M3.1 implemented and approved on the product owner's Android device. **VI-06** refined: the gameplay background is a patterned violet storybook background (flat `#7543EE`, darker `#6531DE` diamond lattice, subtle four-petal motifs, cream header text), replacing the sky-to-cream gradient with clouds. GP-37 to GP-40 behaviour approved on device |
| 8 | 2026-11-26 | M3.2 **Connected Tile Groups** implemented and approved on the product owner's Android device as an approved **core gameplay feature** (**GP-41 to GP-44**, **VI-08**). Groups form through correct **relative** picture alignment anywhere on the board, not only at final cells; the full-board drag-and-swap model (GP-29 to GP-34) remains. A free-placement prototype with a scattered workbench and continuous positions (M3.2 "Direction B") was built for evaluation and **rejected**; it is historical work only. GP-32 and FP-03 annotated |
| 9 | 2026-11-26 | M3.3 **positive connection feedback** implemented and approved on the product owner's Android device: short animated praise (**Nice!**, **Great!**, **Amazing!**, **Fantastic!**, **Perfect!**) for actual connections and completion (**GP-45**, **VI-09**). After device testing, **Fantastic!** was limited to the first group reaching 10 or more tiles in each puzzle. No rewards, scoring, combos or sound |
| 10 | 2026-11-28 | **W4-R1 (approved by the product owner 2026-11-28).** After the code-drawn Sunny Meadows experiment (W4) was rejected as repetitive, the product owner approved a **hybrid visual direction**, combining realistic photography and semi-realistic illustration, and a **hybrid sourcing strategy**: licensed or commissioned photography; AI-assisted or commissioned illustration; a provenance record for every asset. Product vision (§1), **TA-07**, **VI-01**, **VI-02**, **VI-04** and **VI-07** revised, with the earlier wording kept as history. New: **VI-10** (provenance), **VI-11** (image technical requirements, limits proposed), **VI-12** (artwork quality review), **WP-04** and **WP-05** (original location names and taglines; candidates only, not approved). The already-approved World Journey structure (five locations, ten levels each, Normal 4×4 and Hard 5×5, the Hard-level distribution, sequential unlocking, replay, no 6×6) is recorded unchanged as **WP-06 to WP-10**. Product-owner decisions recorded the same day: the 40 MB artwork ceiling for all 50 puzzle images combined (VI-11, Q-025 resolved; Play Asset Delivery timing tracked separately as Q-028); the end of the main World Journey after location 5 level 10 (WP-08); production images in `app/assets/`, provenance outside the bundle; art styles for puzzles, mascot and cards (**VI-13**, Q-026 resolved); Sunny Castle stays as the temporary level-1 placeholder and the Sunlit Storybook UI palette is kept for now (Q-027 resolved); image sources stay open (Q-024). **WP-03** and **RW-03** (collections unlock worlds) are **superseded** by sequential level unlocking (WP-08), and the §8 loop is updated. Location names remain unapproved. No code, world IDs or gameplay changed |

---

## 1. Product Vision

**[Confirmed]** *(revised 2026-11-28, W4-R1)* Jigsaw Cards is a **premium casual puzzle adventure**. Players travel through a journey of **locations**, each with its own name, tagline and presentation, and solve puzzles made from striking **realistic photographs** and **semi-realistic illustrations**. Every new level reveals a different, surprising picture, so players are curious about what comes next. Completing each level unlocks the next, and level 10 of a location opens the next location (WP-08). Along the way they discover animated characters, collect cards and complete themed collections.

*History (until 2026-11-28):* "Jigsaw Cards is a magical storybook puzzle adventure. Players solve beautifully illustrated image puzzles to discover animated characters, collect cards, complete themed collections and unlock new fantasy worlds."

The product identity is **Solve. Discover. Collect.**

| Pillar | Meaning |
| --- | --- |
| Solve | Satisfying, tactile jigsaw gameplay designed for mobile |
| Discover | Every level reveals a surprising new picture; designated puzzles also reveal animated characters *(revised 2026-11-28; was: "Puzzles reveal animated characters within a storybook world")* |
| Collect | Collectible cards, themed collections and new locations to unlock |

## 2. Unique Selling Proposition

**[Confirmed — principle]** Jigsaw Cards combines three experiences that are usually separate:

1. **Satisfying jigsaw gameplay** with drag-and-snap pieces.
2. **Character discovery**: puzzles reveal animated characters, not just a finished picture.
3. **Card collection**: collectible cards, with rarity, in themed collections. *(Revised 2026-11-28: collections no longer drive progression into new worlds; locations unlock by sequential level completion, WP-08.)*

A recurring mascot guide gives the game a recognisable identity.

**[Source text needed]** The approved PRD's exact USP statement and competitive positioning.

## 3. Target Audience

**[Confirmed]** (Q-001, resolved 2026-11-24)

Jigsaw Cards is a broad casual puzzle game primarily designed for teenagers and adults, with a core target audience of 16–35 years. The game should remain welcoming and enjoyable for players aged 13 and above, without specifically targeting children under 13.

| ID | Dimension | Decision |
| --- | --- | --- |
| TA-01 | Core age group | 16–35 |
| TA-02 | Overall intended audience | 13+ |
| TA-03 | Primary players | Teenagers and adults |
| TA-04 | Under-13 audience | Not an intended target audience. Children under 13 are not specifically targeted; this does not describe them as prohibited from playing |
| TA-05 | Player interests | Puzzles, collecting, exploration and relaxing games |
| TA-06 | Difficulty | Easy to learn, progressively challenging |
| TA-07 | Art direction | *(revised 2026-11-28, W4-R1)* Premium, colourful and visually varied: realistic photography and semi-realistic illustration (VI-01, VI-02); not childish or exclusively child-oriented. *(Was: "Magical, colourful storybook aesthetic; not exclusively child-oriented")* |
| TA-08 | Experience | Relaxing, satisfying, rewarding and engaging |

**Product design implications [Confirmed]**

- Gameplay should be easy to learn, with progressively increasing puzzle complexity.
- Visual identity should appeal to teens and adults rather than looking exclusively designed for young children.
- Progression should provide meaningful collection rewards and a clear level-by-level journey through the locations (WP-08).
- The mascot should be charming and memorable without making the game feel exclusively child-oriented. The mascot's design remains open (Q-006).
- UI should remain readable, intuitive and comfortable to use.

**Compliance distinction.** This is a product-positioning decision. It is **not** a Google Play age rating, content rating or target-audience declaration, and it does not by itself establish how the game is classified for regulatory or store-policy purposes. Google Play target-audience and content requirements, the Families Policy, advertising, privacy and data-collection requirements must be assessed separately before release. Monetization (Q-004) and those compliance matters are not decided here.

## 4. Visual Identity — Premium Photographic and Illustrated Puzzles

**[Confirmed]**

- **VI-01** *(revised and approved 2026-11-28, W4-R1)* **Hybrid visual direction.** Puzzle pictures combine two approved styles, which may coexist within one location:
  - **Realistic photography:** natural textures, realistic lighting and shadows, rich colours, detailed compositions, high-resolution sources.
  - **Semi-realistic illustration:** detailed, polished artwork with realistic textures, lighting, depth and dimensionality, and artistic personality without childish cartoon styling.

  Avoided: flat cartoon drawings, repeated scenery and backgrounds, repetitive colour palettes, similar compositions on consecutive levels, and childish or simplistic shapes. The UI (VI-06) frames the pictures and stays bright and cheerful.
  *History:* "Magical Storybook visual identity: the game should feel like an enchanted, illustrated storybook." Superseded by the W4-R1 direction; the code-drawn Sunny Meadows experiment (W4) showed that a single storybook style became repetitive.
- **VI-02** *(revised and approved 2026-11-28, W4-R1)* **Pictures are the reward.** Every puzzle picture is a high-quality, visually distinct photograph or semi-realistic illustration that stays attractive when cut into 16 (4×4) or 25 (5×5) tiles and when whole. Each picture must pass the artwork quality review (VI-12) and be sourced under VI-07 with a provenance record (VI-10).
  *History:* "Puzzle images are beautifully illustrated, and the artwork is part of the reward."
- **VI-03** Characters are revealed with animation (Rive, subject to technical validation, TD).
- **VI-04** *(revised and approved 2026-11-28, W4-R1)* **Location identity, diverse pictures.** A location provides the chapter identity through its name, tagline and presentation. Its ten puzzle levels may contain a diverse mixture of subjects, visual environments, colours and compositions. The location theme **does not restrict** the subjects of its pictures: one location may contain, for example, construction machinery, roses, fruit, animals, birds, vehicles, buildings, landscapes and interesting objects. Consecutive levels avoid similar subjects, dominant colours and compositions, and no main subject is repeated across locations without a deliberate reason.
  *History:* "Each world has its own visual theme."
- **VI-05** Portrait UI that frames the artwork rather than competing with it.
- **VI-06** *(approved 2026-11-26; background refined and approved on device the same day)* The whole game UI follows the rich, cheerful **Sunlit Storybook** direction. The gameplay background is a **patterned violet storybook background**: a flat violet base (`#7543EE`) with a subtle, darker diamond lattice (`#6531DE`) and small four-petal motifs, drawn in code, with cream header text (`#FFFBF2`). It also uses cream paper surfaces, slate-blue text on light surfaces and harmonious accents, all defined as shared design tokens and used consistently across gameplay, menus and progression screens. The puzzle board is the focal point; the background stays atmospheric and never competes with it. Details: [VISUAL_IDENTITY.md §2a–2b](VISUAL_IDENTITY.md#2a-sunlit-storybook-palette-approved-2026-11-26). *(History: the first implementation used a sky-to-cream gradient background with clouds, replaced after device review.)* *(Note 2026-11-28, Q-027: the Sunlit Storybook UI palette and patterned violet background are **kept temporarily** and will be revisited after the W4-R2 visual prototype.)*
- **VI-07** *(approved 2026-11-26; **revised and approved 2026-11-28, W4-R1**: placeholder-only rule replaced by the hybrid sourcing policy)* **Artwork sourcing.** Production puzzle pictures come only from these approved sources:
  1. **Photography:** properly licensed stock photography, or commissioned photography.
  2. **Illustration:** AI-assisted illustration, only where the provider's current terms permit the intended commercial use (distribution inside a commercial mobile game), or commissioned illustration.

  Every production asset has a **provenance record** (VI-10) and passes the **visual quality review** (VI-12) **before** it is integrated. No unauthorised copyrighted content, recognisable brands, trademarks or logos, copyrighted characters, or imitation of a named living artist's style. An image is never assumed usable because it can be downloaded or generated: if its rights are unclear, it is **not used**. Material legal uncertainty is flagged to the product owner. Details: [ARTWORK_GUIDELINES.md](ARTWORK_GUIDELINES.md).
  **Temporary code-drawn artwork** (Sunny Castle, and the W4 Sunny Meadows experiment) is allowed only as clearly labelled **prototype or placeholder** artwork; it is not production art and is not a substitute for missing production pictures. **Sunny Castle remains the temporary level-1 placeholder** until replacement artwork is approved (Q-027). The W4 Sunny Meadows pictures stay an unregistered experiment kept for comparison.
  **Approved sources are not yet selected:** no stock agency, AI provider, subscription or budget is chosen. That decision follows the evaluation of the four-image prototype (W4-R2) and a comparison of commercial licences (Q-024).
  *History (2026-11-26 to 2026-11-28):* "Until real artwork exists, the placeholder puzzle picture is a **bright, code-drawn daytime** storybook scene, replacing the night scene. No AI-generated or downloaded artwork."
- **VI-08** *(approved 2026-11-26 on device, with GP-41 to GP-44)* Connected tile groups read as one piece of the picture: no edge lines between members, only the group's outer outline (a correctly placed group stays edge to edge, as before). A lifted group is drawn slightly enlarged and seamless, with one shared shadow and one outline, and its destination is shown as one outline around all of its cells.
- **VI-09** *(approved 2026-11-26 on device, with GP-45)* Praise is drawn in code with no assets: bold, slightly tilted text with a light-to-saturated fill, a dark contrasting outline, a soft glow and a few white and gold four-point sparkles, in a colour for each level from the Sunlit accents. It pops in, overshoots slightly, settles with a subtle bounce and fades out (about 1.25 s). It appears near the connected tiles (the board centre for **Perfect!**), always fully on screen and small enough not to hide the puzzle. With the system reduce-motion setting it only fades, with no bounce or sparkles.

- **VI-10** *(new and approved 2026-11-28, W4-R1)* **Provenance record for every production asset**, kept outside the app bundle and reviewed before integration. It records: asset ID and filename; main subject; production method (licensed stock, commissioned photo, AI-assisted illustration, commissioned illustration); original source or provider; creator or author where applicable; licence or applicable provider terms (with the version or date checked); commercial-use permission; attribution requirements; purchase or licence evidence reference; model and property release status where applicable; usage restrictions; for AI-assisted work, the provider, model, date, prompts and source records; any editing applied; reviewer and review date. Template: [ARTWORK_GUIDELINES.md §3](ARTWORK_GUIDELINES.md#3-provenance-record).
- **VI-11** *(new 2026-11-28, W4-R1)* **Image technical requirements.** Square 1:1 pictures (the board keeps the picture's aspect ratio, GP-35). **[Confirmed]** Production images are stored in the app package under **`app/assets/`** (`app/assets/artwork/<location-key>/<asset-id>.webp`). Provenance records are kept **outside the app bundle** (VI-10). The **40 MB ceiling** covers **all 50 bundled puzzle images combined** (five locations × ten levels), subject to actual asset-size measurements (the release arm64 APK measured 15.5 MB without image artwork on 2026-11-28). **[Proposed — to be confirmed with the W4-R2 measurements]** WebP, 2048 × 2048 px, normally 300–600 KB each, with a **per-image limit of 800 KB** that stays proposed until measured; master files of at least 3000 px kept outside the app. Pictures are decoded once, off the gesture path, before a puzzle's introduction starts, at a size suited to the device, and released when the puzzle is left. The composition carries meaningful detail up to every edge (tiles are cut exactly on the grid; nothing is cropped at runtime). Raster pictures and the existing code-drawn pictures are both to be supported. The engineering proposal is in [RASTER_ARTWORK_PROPOSAL.md](../architecture/RASTER_ARTWORK_PROPOSAL.md); implementation is a separate, reviewed milestone. Rationale: [ARTWORK_GUIDELINES.md §4](ARTWORK_GUIDELINES.md#4-image-technical-requirements).
- **VI-12** *(new and approved 2026-11-28, W4-R1)* **Artwork quality review.** Every puzzle picture is reviewed against the checklist in [ARTWORK_GUIDELINES.md §5](ARTWORK_GUIDELINES.md#5-artwork-quality-checklist): a clear, recognisable main subject; distinct visual regions; an attractive colour composition; sufficient texture and detail; no large empty or monotonous areas; interesting content near the edges; no excessive background blur; no composition repeated from another level; suitable difficulty for 4×4 and 5×5; high quality on a mobile screen. The picture must stay attractive when divided into 16 or 25 tiles. Automated tile-distinctness tests support the review but **do not replace** human visual review and gameplay testing on a device.
- **VI-13** *(new 2026-11-28, W4-R1; Q-026 resolved)* **Art styles by surface.**
  - **Puzzle pictures:** realistic photography and semi-realistic illustration (VI-01).
  - **Mascot:** a polished 3D or semi-realistic character (MC-01; design, name and personality remain open, Q-006).
  - **Collectible cards:** a premium illustrated presentation (CC-01).

  Visual consistency comes from shared UI presentation, quality standards and colour care, **without** forcing all puzzle pictures into one style.

Details: [VISUAL_IDENTITY.md](VISUAL_IDENTITY.md) · [ARTWORK_GUIDELINES.md](ARTWORK_GUIDELINES.md).
**[Source text needed]** Any palette, typography or style-guide direction in the original approved PRD text. Typography remains open; the M3.1 palette (VI-06) was approved separately on 2026-11-26.

## 5. Mascot and Character Discovery

**[Confirmed]**

- **MC-01** One recurring mascot character serves as the player's guide throughout the game.
- **MC-02** Characters are discovered through an animated reveal that accompanies the award of their card (CC-03, CC-04).

**[Open]** Mascot design, name, personality and where the mascot appears (onboarding, world transitions, hints) (Q-006).

## 6. Worlds and World-Based Progression

- **WP-01 [Confirmed]** Progression is world-based: content is organised into worlds.
- **WP-02** ~~[Proposed] Working world names (exact names not confirmed, Q-021):~~ **Superseded 2026-11-28** by WP-04 and WP-05 (original location names; candidates unapproved). The list below is history:

  | # | World |
  | --- | --- |
  | 1 | Enchanted Forest |
  | 2 | Ocean Kingdom |
  | 3 | Fantasy Kingdom |
  | 4 | Cosmic Adventures |

- **WP-03** ~~[Proposed] Completing themed collections unlocks new fantasy worlds.~~ **Superseded 2026-11-28** by WP-08: locations are unlocked only by sequential level completion. Collections do not unlock locations.
- **WP-04 [Confirmed]** *(2026-11-28, W4-R1)* **Original location names.** In player-facing text a world is called a **location**: an adventure chapter with an original, memorable name and a short, attractive tagline. Names and taglines must be original, easy to pronounce and suitable for a worldwide audience. Names, taglines and branding from the reference game are **never copied**. Before a name is approved it is checked for conflicts (app stores, trademarks). Names need not describe the pictures' subjects (VI-04).
- **WP-05 [Proposed — candidates only, not approved; naming review pending]** *(2026-11-28)* Candidate location names (Q-021): **Brightwater Landing**, **Copperbell Lane**, **Honeyglade**, **Starling Cove**, **Wonderglow Realm**. Further candidates and draft taglines: [GAME_PROGRESSION.md §2](GAME_PROGRESSION.md#2-locations). The implementation keeps its existing world IDs and working titles (Sunny Meadows, Enchanted Forest, Fantasy Kingdom, Ocean Kingdom, Sky Kingdom) until names are approved; renaming is a separate change.

**World Journey structure** *(approved and implemented in the World Journey milestones W0 and W1; recorded here unchanged on 2026-11-28)*:

- **WP-06 [Confirmed]** **Five locations**, each with **ten levels**.
- **WP-07 [Confirmed]** Two difficulties: **Normal 4×4** and **Hard 5×5**. Each level has one fixed difficulty. **No 6×6** difficulty at this stage.
- **WP-08 [Confirmed]** **Sequential unlocking (authoritative unlock rule):** the first level of the first location is always available; every other level unlocks when the level before it is completed. Completing **level 10 of locations 1–4** unlocks **level 1 of the next location**. Completing **level 10 of location 5** completes the **main World Journey** and shows a **final completion experience** (its design is not yet specified and it is not yet implemented). Further locations may be added later only through separate, approved content updates. Level completion is the only unlock mechanism; collections, cards and coins do not unlock levels or locations.
- **WP-09 [Confirmed]** **Replay:** completed levels remain playable at any time. A first play uses a deterministic layout; replays use a fresh shuffle.
- **WP-10 [Confirmed]** **Hard-level distribution** (level numbers per location, in play order; level 10 is always Hard): location 1 — 4, 7, 10; location 2 — 3, 5, 8, 10; location 3 — 2, 4, 6, 8, 10; location 4 — 2, 4, 5, 7, 9, 10; location 5 — 2, 3, 5, 6, 8, 9, 10.

**[Open]** Collection design: the number and size of collections per location and which puzzles are designated card puzzles (Q-002). Collections have no effect on unlocking (WP-08).

Details: [GAME_PROGRESSION.md](GAME_PROGRESSION.md).

## 7. Puzzle System

### 7.1 Hybrid puzzle system

**[Confirmed]** The puzzle system is hybrid (Q-018, resolved):

- **PS-01** ~~Mixed-sized rectangular pieces are used for the first prototype.~~ **Superseded 2026-11-25 (Q-022):** the first prototype uses **equal-sized rectangular tiles** on a uniform grid (GP-29, GP-30).
- **PS-02** Traditional irregular jigsaw pieces are future functionality.
- **PS-03** Puzzle rules live in an independent pure-Dart puzzle engine (Section 13).
- **PS-04** Jigsaw Cards will eventually support two **puzzle styles**: **rectangular tile puzzles** and **traditional irregular jigsaw puzzles**.
- **PS-05** The two styles are **separate puzzle styles**. They are not necessarily combined within one puzzle.

**Initial development: rectangular tile style [Confirmed]**

- **PS-06** ~~Mixed-sized rectangular pieces.~~ **Revised 2026-11-25 (Q-022):** equal-sized rectangular tiles, one per grid cell.
- **PS-07** Logical grid occupancy.
- **PS-08** ~~Rectangular partition generation.~~ **Superseded 2026-11-25 for the picture-swap gameplay (Q-022):** the illustration is divided into a uniform grid of equal tiles, so no partition generation is required.

**Future expansion: irregular jigsaw style [Confirmed as future; not approved for implementation]**

- **PS-09** Traditional interlocking jigsaw geometry.
- **PS-10** Tabs and blanks.
- **PS-11** Rotation.
- **PS-12** Connected-piece grouping.

**Shared across both styles [Confirmed]**

| ID | Shared capability |
| --- | --- |
| PS-13 | Puzzle session management |
| PS-14 | Level configuration framework |
| PS-15 | Common interaction contracts, where practical |
| PS-16 | Progress and completion reporting |
| PS-17 | Reward integration |

**Separate per style [Confirmed]**

- **PS-18** Geometry generation and rendering may remain separate for each style.

**Rectangular board for the initial prototype [Confirmed]** (Q-009, resolved 2026-11-23; **revised 2026-11-25 by Q-022** for the picture-swap gameplay; original wording kept and struck through where superseded):

| ID | Requirement |
| --- | --- |
| PS-19 | The initial prototype uses a 4×4 logical board (as GP-01): a uniform grid of 16 equal-sized tiles (Q-022) |
| PS-20 | ~~Allowed rectangular piece dimensions are 1×1, 1×2, 2×1 and 2×2~~ **Superseded 2026-11-25 (Q-022):** every tile has identical dimensions (one grid cell) |
| PS-21 | ~~Piece-count constraint: every generated prototype layout must contain between 8 and 12 pieces, inclusive~~ **Superseded 2026-11-25 (Q-022):** the prototype has exactly 16 tiles |
| PS-22 | ~~Valid layouts are generated using seeded generation~~ **Revised 2026-11-25 (Q-022):** the starting arrangement is generated with a seeded, deterministic shuffle (GP-31) |
| PS-23 | ~~The selected/generated layout is persisted, so an unfinished puzzle retains exactly the same arrangement~~ **Revised 2026-11-25 (Q-022):** the puzzle's tile arrangement is persisted, so an unfinished puzzle retains exactly the same arrangement (not yet implemented) |
| PS-24 | ~~Hand-authored layouts are not required for the initial prototype; they may be supported in a later phase~~ **Superseded 2026-11-25 (Q-022):** the uniform grid has no layout to author |

**[Open — technical, TD-02]** The original question was the partition-generation algorithm and whether generation runs at runtime or when content is built. Since Q-022, no partition algorithm is needed for the picture-swap gameplay; the seed source and runtime-versus-content shuffling remain technical choices under TD-02.

### 7.2 Prototype gameplay

All requirements below are **[Confirmed]** unless marked **Superseded**. GP-06 was confirmed, and GP-14 to GP-19 added, when Q-010 and Q-011 were resolved (2026-11-23). On 2026-11-25 the product owner revised Q-010 and Q-011 after Android device testing and approved the free-placement memory gameplay (GP-20 to GP-28): tap to reveal, free placement and an exactly 4-second preview. Superseded requirements keep their IDs as history and must not be implemented. On 2026-11-25 the product owner then **rejected** the memory and free-placement gameplay and approved the **rectangular picture-swap puzzle** from a reference gameplay recording (GP-29 to GP-36). GP-20 to GP-28 are superseded. Q-022 (equal-sized tiles) and Q-023 (correct tiles remain movable) were resolved the same day and are reflected in GP-02, GP-15, GP-29, GP-30, GP-32 and GP-34. On 2026-11-26 the implemented puzzle introduction was recorded (GP-37) and the M3.1 "Bright & Celebrate" requirements were approved (GP-38 to GP-40). Later on 2026-11-26 **Connected Tile Groups** were approved on device as a core gameplay feature (GP-41 to GP-44), extending the picture-swap model without replacing it, followed by **positive connection feedback** (GP-45).

| ID | Requirement |
| --- | --- |
| GP-01 | One 4×4 logical board |
| GP-02 | ~~Mixed-sized rectangular pieces~~ **Superseded 2026-11-25 (Q-022)** by GP-30: equal-sized rectangular tiles |
| GP-03 | ~~Piece tray below the board~~ **Superseded 2026-11-25** by GP-20 and GP-27 (Q-011 revised) |
| GP-04 | ~~Pieces are dragged from the tray onto the board~~ **Superseded 2026-11-25** by GP-24 (pieces are dragged freely on the board) |
| GP-05 | ~~Automatic magnetic snapping (at the correct position, within the snapping tolerance; GP-26)~~ **Superseded 2026-11-25** by GP-32 (tiles always settle exactly into grid cells by swapping) |
| GP-06 | ~~Incorrectly dropped pieces animate back to their previous position (Q-010)~~ **Superseded 2026-11-25** by GP-25 (incorrect drops stay where placed) |
| GP-07 | No rotation in the prototype |
| GP-08 | Optional reference-image preview (separate from the start-of-puzzle preview, GP-21; interaction still open, Q-008) |
| GP-09 | Completion detection |
| GP-10 | Character/card reveal |
| GP-11 | Coin reward animation |
| GP-12 | Sound effects |
| GP-13 | Automatic saving of unfinished puzzles |
| GP-14 | ~~Only a piece's correct position accepts it (Q-010)~~ **Superseded 2026-11-25** by GP-24 and GP-25 (free placement) |
| GP-15 | ~~Correctly placed pieces become permanently locked; locked pieces cannot be moved or swapped (Q-010; still applies under free placement)~~ **Superseded 2026-11-25** by GP-32: in the picture-swap puzzle correctly positioned tiles remain movable and nothing locks (Q-023) |
| GP-16 | ~~The tray below the board has two rows and scrolls horizontally (Q-011)~~ **Superseded 2026-11-25** (no tray in the primary interaction) |
| GP-17 | ~~Tray pieces keep comfortable touch targets (Q-011)~~ **Superseded 2026-11-25**; touch-target intent continues in GP-28 |
| GP-18 | ~~Picking up a piece enlarges it to board scale (Q-011)~~ **Superseded 2026-11-25** (pieces are always at board scale on the board) |
| GP-19 | ~~The board and tray layout adapts to different phone screen sizes (Q-011)~~ **Superseded 2026-11-25** by GP-28 |
| GP-20 | ~~At puzzle start, every piece is placed face-down (decorative back) at its own seeded, randomised position scattered across the board; starting positions are independent of the correct positions, visibly distributed, individually selectable and do not expose the solution (Q-011 revised)~~ **Superseded 2026-11-25** by GP-29 to GP-31 |
| GP-21 | ~~After a short introduction, every piece flips face-up and stays face-up for **exactly 4 seconds** (the preview); no interaction during the introduction or the preview~~ **Superseded 2026-11-25** by the picture-swap puzzle (no preview) |
| GP-22 | ~~After the preview, every piece flips face-down and play begins (memory mode)~~ **Superseded 2026-11-25** by the picture-swap puzzle (no memory mode) |
| GP-23 | ~~**Tap to reveal:** tapping a face-down piece reveals only that piece; a revealed piece stays face-up, including while it is moved~~ **Superseded 2026-11-25** by GP-30 (tiles are face-up from the start) |
| GP-24 | ~~**Free placement:** a revealed, unlocked piece can be dragged anywhere within the playable board area; pieces may overlap temporarily; the selected piece is drawn above the others (Q-010 revised)~~ **Superseded 2026-11-25** by GP-32 (drag-and-swap) |
| GP-25 | ~~An incorrectly placed piece stays where it was dropped and is never returned automatically; it can be picked up and repositioned repeatedly (Q-010 revised)~~ **Superseded 2026-11-25** by GP-32 and GP-33 |
| GP-26 | ~~When a piece is aligned with its correct position within the snapping tolerance, it animates exactly into place and locks (GP-05, GP-15); the tolerance is configurable~~ **Superseded 2026-11-25** by GP-32 |
| GP-27 | ~~The board is the primary gameplay workspace; the two-row tray is not part of the primary puzzle interaction (Q-011 revised)~~ **Superseded 2026-11-25** by GP-29 |
| GP-28 | ~~The board and its pieces fit different phone aspect ratios within the safe area; pieces stay fully accessible and never leave the board area; overlapping pieces remain individually selectable (the topmost selectable piece is chosen)~~ **Superseded 2026-11-25** by GP-35 |
| GP-29 | **Board:** a fixed, uniform rectangular grid: 4 × 4 for the prototype (GP-01, Q-022). Every cell holds exactly one tile: no empty cells, no overlap, no free placement and no free-floating pieces; tiles never leave the board |
| GP-30 | **Tiles:** 16 equal-sized rectangular fragments of one illustration with identical dimensions, cut on the grid without stretching (Q-022); every tile is visible face-up from the start and always shows its own fragment. A tile's identity and correct cell are fixed and separate from its current cell |
| GP-31 | **Start:** the tiles begin in a seeded, deterministic shuffled arrangement that is never already solved; every arrangement is solvable by swaps |
| GP-32 | **Drag-and-swap:** the player presses a tile (clear selection feedback), drags it over another tile (clear target feedback) and releases; the two tiles exchange cells with a smooth animation. Incorrect swaps are allowed and never rejected; tiles can be moved repeatedly, with unlimited swaps and no penalty. **Correctly positioned tiles remain movable:** no tile locks, any two tiles can be swapped at any time, and every swap is valid whether or not either tile was correct (Q-023). Direct drag-and-drop is the interaction (no tap-then-tap). No rotation. A tile that belongs to a connected group moves with its whole group (GP-41 to GP-44) |
| GP-33 | A drag released outside another tile is cancelled: the tile returns to its own cell |
| GP-34 | **Completion:** detected only when every tile (all 16 in the prototype) is in its correct cell, based solely on the whole board matching the target arrangement; tiles landing in their correct cell get visible feedback, which is visual only and never restricts movement (Q-023); completion shows the finished illustration and a New puzzle or Continue action, ready for future rewards and progression |
| GP-35 | **Layout:** the board keeps the illustration's aspect ratio, fits different phone screens within the safe area, is never clipped and keeps comfortable touch targets |
| GP-36 | **Hints** are intentionally excluded from the initial prototype and are planned for v1 (design not yet specified) |
| GP-37 | **Puzzle introduction** *(implemented, approved 2026-11-26 after testing on the product owner's device)*: every new puzzle starts with all tiles showing a shared card back; the tiles enter from below the board one by one, with staggered, tilted flights that settle into their actual shuffled cells; after the last tile has arrived they flip to their picture in a fast, coordinated sequence; then gameplay starts. Input is disabled until the reveal finishes. The sequence never changes the arrangement and runs again for every new puzzle. It is a reusable presentation shared by all puzzles, not puzzle-specific logic |
| GP-38 | **Board spacing** *(approved 2026-11-26)*: measured to the **outer edge of the board frame**, the horizontal margin to each screen edge is **20–32 dp**, scaling with screen width; the board is centred vertically between the header and the bottom safe area, with comfortable space above and below; it respects all safe areas (status bar, display cutouts, navigation and gesture insets), stays responsive across screen sizes with a maximum width on large screens, keeps tiles comfortable to touch, and never touches or crosses a screen edge. The 4×4 layout and the image aspect ratio are unchanged. No bottom action bar is reserved until hint and preview actions exist |
| GP-39 | **Completion celebration** *(approved 2026-11-26)*: when the last tile is correct, a satisfying but short celebration plays (picture shine and a brief sparkle effect), then the finished illustration is presented with a **Next puzzle** action. No coins, rewards, placeholder rewards or empty reward slots are shown until reward rules are implemented; the celebration is structured so rewards (GP-10, GP-11) can be added later. Input on the board stays disabled during the celebration |
| GP-40 | **Next-puzzle transition** *(approved 2026-11-26)*: **Next puzzle** clears the board with a short exit animation and starts a new puzzle; for now it **reshuffles the same placeholder picture**, and the puzzle introduction (GP-37) runs again. A transition can only be started once: repeated taps are ignored and sequences never overlap |
| GP-41 | **Connected tile groups — formation** *(approved 2026-11-26 after testing on the product owner's Android device; core gameplay feature)*: two tiles that are next to each other on the board (horizontally or vertically) **join** when they are next to each other the same way in the original picture, i.e. both are shifted from their correct cells by the same offset (**relative alignment**). Joining is transitive, so groups grow into lines, rectangles, L-shapes and other irregular shapes, and groups that line up **merge** into one. Groups form **anywhere on the board**; they are not restricted to their final cells (correctly placed neighbours are the zero-offset case). Groups are derived from the current arrangement after every move and are never stored, so membership is never stale |
| GP-42 | **Connected tile groups — movement:** pressing or dragging **any member** lifts the whole group, which follows the finger as one unit with its internal arrangement unchanged; the target feedback outlines every cell the group would occupy. On release, every member moves by the same offset (dragged tile's drop cell minus its start cell). The tiles in destination cells that the group does not already cover move into the cells the group left, sliding back against the drag direction, so **the board stays fully occupied** (GP-29). A group displaced whole keeps its shape; tiles knocked out of a group rejoin whatever they now line up with. A group that would not fit on the board is not moved and glides back. There are no empty spaces and no free placement |
| GP-43 | **Connected tile groups — single tiles:** a tile with no aligned neighbour is not in a group and keeps the GP-32 behaviour: it swaps with any tile, including a member of a group (which then leaves that group). Nothing locks: correct tiles and groups remain movable (Q-023) |
| GP-44 | **Connected tile groups — solvability and completion:** every arrangement remains solvable (dragging any group so that its tiles land in their own cells is always possible, never disturbs a correctly placed tile and adds at least one correct tile). Completion is unchanged (GP-34): every tile in its correct cell |
| GP-45 | **Positive connection feedback** *(approved 2026-11-26 after testing on the product owner's Android device)*: a short animated praise message is shown only for **actual results of a move**, never for ordinary drags or swaps that connect nothing: **Nice!** for a new pair; **Great!** when an existing group grows (or three or more loose tiles join at once); **Amazing!** when two or more groups merge; **Fantastic!** only the **first time in a puzzle** that a group reaches **10 or more tiles** (later growth or merges of a large group get the ordinary praise, and moving a group never earns praise); **Perfect!** only on completion, together with the completion celebration (no connection praise for the completing move). If one move makes several connections, one praise is shown (the strongest). Pacing: within 1.2 s of a praise, another of the same or a lower level is skipped, while a higher level replaces the visible one with a short fade. Praise never blocks or delays input and never changes puzzle state. The messages, the 10-tile threshold, the pacing and completion praise are configurable. No coins, rewards, scoring, combos or sound |

Details: [GAMEPLAY.md](GAMEPLAY.md). Technical specification: [PUZZLE_ENGINE.md](../architecture/PUZZLE_ENGINE.md).

### 7.3 Future puzzle functionality (not approved for implementation)

| ID | Feature | Notes |
| --- | --- | --- |
| FP-01 | Traditional irregular jigsaw pieces | Irregular jigsaw style, with interlocking geometry, tabs and blanks (PS-09, PS-10) |
| FP-02 | Rotation | Listed under irregular jigsaw expansion (PS-11) |
| FP-03 | Connected-piece grouping | Listed under irregular jigsaw expansion (PS-12). For the rectangular picture-swap puzzle, grouping by relative alignment is **approved and implemented** (GP-41 to GP-44); this entry remains for interlocking irregular pieces |
| FP-04 | Zoom and pan | Not assigned to a style |
| FP-05 | Different board sizes and difficulty levels | Not assigned to a style |

## 8. Core Gameplay Loop

**[Confirmed — structure]** *(unlock step revised 2026-11-28: sequential level unlocking, WP-08; the earlier proposed step "complete collections → unlock next world" is superseded)*.

```
Select an unlocked level (within a location; completed levels can be replayed)
      │
      ▼
Solve puzzle (drag and swap, connect groups, complete)
      │
      ▼
Reward: coins
        + designated puzzle → guaranteed card (character reveal), if not already collected
        + non-designated puzzle → progression rewards
      │
      ├──► Grow themed collections (no effect on unlocking)
      │
      ▼
First completion unlocks the next level
(level 10 of locations 1–4 → level 1 of the next location;
 level 10 of location 5 → main World Journey complete,
 final completion experience) ──► back to Select
```

The mascot guides the player through the loop (MC-01).

**[Source text needed]** Any additional loop steps in the approved PRD, such as a meta-loop, daily content or spending coins.

## 9. Collectible Cards

**[Confirmed]**

- **CC-01** Cards are collectible and belong to themed collections.
- **CC-02** Cards have **rarity**.
- **CC-03** A card is **guaranteed** when a **designated** puzzle is completed. A designated puzzle always grants its card on completion, accompanied by the character reveal.

**Card acquisition rules [Confirmed]** (Q-017, resolved):

- **CC-04** Designated card puzzles guarantee their associated collectible card.
- **CC-05** Non-designated puzzles award coins and progression rewards.
- **CC-06** Previously collected cards are not awarded as new collection progress.
- **CC-07** The first prototype puzzle must be a designated card puzzle, so that the full discovery and reward experience can be validated.

**[Open]**

- What "progression rewards" consist of for non-designated puzzles (Q-020).
- Which puzzles are designated, for example how many per collection (content design, Q-002).
- What, if anything, is shown or awarded when a designated puzzle's card is already collected (Q-007).
- Rarity tiers, how rarity is expressed and whether it affects acquisition (Q-007).
- The card detail view and collection size (Q-007).

> Correction in reconciliation 1: earlier repository text said that *every* completed puzzle awards a card. The confirmed rule is a guaranteed card after completion of a *designated* puzzle (CC-03).

## 10. Rewards

**[Confirmed]**

- **RW-01** Coins are awarded on puzzle completion, shown with a coin reward animation.
- **RW-02** Cards are guaranteed on designated puzzle completion (CC-03, CC-04). A card already collected does not count as new collection progress (CC-06).
- **RW-04** Non-designated puzzles award coins and progression rewards (CC-05). The content of progression rewards is open (Q-020).
- **RW-05** Reward integration is shared by both puzzle styles (PS-17).

**RW-03** ~~[Proposed] World progression is driven by completing collections (WP-03).~~ **Superseded 2026-11-28** by WP-08: progression is driven by sequential level completion.

**[Open]** What coins are spent on (Q-003) and the monetization model (Q-004).

## 11. Data-Driven Level System

**[Confirmed]**

- **DL-01** Levels and content are data-driven (configuration-driven). Worlds, collections, puzzles, pieces, card assignments (including which puzzles are designated) and rewards are defined in data, not hardcoded.
- **DL-02** Adding or changing a puzzle must not require changes to gameplay code.
- **DL-03** One level configuration framework serves both puzzle styles (PS-14). Each puzzle declares its style, and style-specific geometry settings sit alongside the shared fields.

**[Proposed]** Content data is validated when it is loaded, for example to check that pieces tile the board exactly (see [DATA_MODELS.md](../architecture/DATA_MODELS.md)).
**[Open]** Data format and authoring workflow.

## 12. Persistence Requirements

**[Confirmed]**

- **PR-01** Local-first persistence.
- **PR-02** Unfinished puzzles are saved automatically and restored exactly.
- **PR-03** Player progress (completed puzzles, unlocked worlds, cards, coins) persists across sessions.

**[Proposed]** Saved data is versioned to support migrations, and rewards are granted idempotently (never twice).
**[Open]** Storage technology (TD-01 / Q-014). Firebase-backed persistence, such as cloud save, only when justified.
**[Source text needed]** Any further persistence requirements in the approved PRD, such as save frequency or data-loss tolerance.

## 13. Technical Architecture (summary)

**[Confirmed]**

| Area | Decision |
| --- | --- |
| Platform / orientation | Android first, portrait |
| Framework / language | Flutter, Dart |
| Game engine | Flame |
| Architecture | Hybrid Flutter + Flame |
| State management | Riverpod |
| Puzzle domain | Independent pure-Dart puzzle engine, with no Flutter or Flame dependency |
| Audio | flame_audio |
| Character animation | Rive, subject to technical validation |
| Persistence | Local-first; database selection pending |
| Backend | Firebase, when justified |

Details: [ARCHITECTURE_OVERVIEW.md](../architecture/ARCHITECTURE_OVERVIEW.md) · [TECHNICAL_DECISIONS.md](../architecture/TECHNICAL_DECISIONS.md).

## 14. Technical Requirements and Quality Gates

**[Confirmed]**, from the approved Development Rules ([DEVELOPMENT_RULES.md](../development/DEVELOPMENT_RULES.md)):

| ID | Gate |
| --- | --- |
| QG-01 | Puzzle domain logic has unit tests; no domain change is merged without tests |
| QG-02 | The puzzle domain does not depend on Flame or Flutter |
| QG-03 | No business logic in rendering components |
| QG-04 | Levels are configuration-driven; no hardcoded screen coordinates |
| QG-05 | No unnecessary dependencies; each new dependency is justified |
| QG-06 | No secrets, API keys or signing credentials in the repository |
| QG-07 | Architectural decisions are documented as ADRs |
| QG-08 | Pull requests are focused and reviewable |
| QG-09 | Confirmed product decisions are preserved; future features are not implemented without approval |

**[Proposed]** Automated format, analyzer and test checks on every pull request ([TESTING_STRATEGY.md](../development/TESTING_STRATEGY.md)).

**[Source text needed]** The approved PRD's technical requirements and quality gates beyond the rules above, such as frame-rate targets, minimum Android version, app size, load-time limits, test-coverage thresholds and phase exit criteria. No numeric targets are set until they are supplied (Q-013, Q-019).

## 15. Prototype Scope

**[Confirmed]** The first prototype delivers the gameplay in Section 7.2 (GP-01 to GP-40, excluding requirements marked Superseded) for a single 4×4 picture-swap puzzle of equal-sized rectangular tiles (Q-022), on Android, in portrait.

**[Confirmed]** The prototype puzzle is a **designated card puzzle** (CC-07), so it validates the full discovery and reward experience: completion, character reveal, guaranteed card and coins.

**[Confirmed]** Initial development covers the rectangular tile style: equal-sized rectangular tiles on a uniform grid with logical grid occupancy (PS-06, PS-07, PS-19, PS-22, PS-23 as revised 2026-11-25 by Q-022). *(Originally: mixed-sized pieces and rectangular partition generation within PS-19 to PS-24; superseded for the picture-swap gameplay.)*

**Out of scope for the prototype [Confirmed]:** FP-01 to FP-05.

**[Proposed]** Prototype acceptance:

- A player completes one puzzle end to end: a shuffled 4 × 4 picture grid, drag one tile onto another to swap them until the picture is whole, completion, character/card reveal, coin animation and sound. (Revised 2026-11-25 for the picture-swap decision; earlier versions described the tray with strict placement, then the memory preview with free placement.)
- Leaving mid-puzzle and returning restores the exact state.
- Domain logic is unit-tested and independent of Flame.

## 16. Development Phases

**[Source text needed]** The approved PRD defines the development phases, and their approved names, order and exit criteria have not been supplied to the repository. Until then, the repository follows a **[Proposed]** sequence ([ROADMAP.md](../development/ROADMAP.md)):

1. Foundation (repository and documentation)
2. Technical validation
3. Puzzle domain
4. Playable prototype
5. MVP vertical slice

This sequence will be replaced by the approved phases when they are supplied (Q-019).

## 17. MVP Scope

**[Proposed]** The MVP builds on the prototype with:

- Content for the first world.
- A card collection view.
- World-based progression.
- The mascot guide.
- Local persistence of all progress.

**[Open]** Content volume and the final MVP feature list, to be set after the prototype.

## 18. Excluded Features

Not in the prototype, and not to be implemented without approval:

- Future puzzle functionality FP-01 to FP-05.
- iOS release.
- Landscape orientation.
- Backend or online features, unless justified and approved.
- Multiplayer and social features.
- Monetization implementation (model open, Q-004).

## 19. Success Criteria

**Technical validation [Confirmed — intent]**

- Flutter, Flame and Riverpod integrate cleanly in the hybrid architecture.
- Drag and snap feel smooth and responsive on target Android devices.
- The puzzle domain is independent and unit-tested.
- Rive is validated, or an alternative is decided.
- A local persistence technology is selected (ADR).

**Prototype:** see Section 15.

**MVP KPIs [Open]:** retention, session length, completion rate and their targets (Q-005).

## 20. Confirmed Decision Register

These must remain unchanged without explicit approval:

| # | Decision | Ref |
| --- | --- | --- |
| 1 | Android first | §13 |
| 2 | Portrait orientation | §13 |
| 3 | Flutter + Flame | §13 |
| 4 | Riverpod | §13 |
| 5 | Independent pure-Dart puzzle domain | PS-03, §13 |
| 6 | Hybrid puzzle system: separate rectangular tile and irregular jigsaw styles with shared session, configuration, interaction contracts, progress/completion reporting and reward integration | PS-04 to PS-18 |
| 7 | ~~Mixed rectangular pieces for the first prototype~~ Superseded 2026-11-25 by #36 (Q-022) | PS-01, GP-02 |
| 8 | Traditional irregular jigsaw as future functionality | PS-02, FP-01 |
| 9 | ~~Piece tray below the board~~ Superseded 2026-11-25 by #31 | GP-03 |
| 10 | ~~Drag pieces from tray onto board~~ Superseded 2026-11-25 by #32 | GP-04 |
| 11 | ~~Automatic magnetic snapping~~ Superseded 2026-11-25 by #34 | GP-05 |
| 12 | No rotation in the prototype | GP-07 |
| 13 | Optional reference-image preview | GP-08 |
| 14 | Guaranteed card after designated puzzle completion | CC-03, CC-04 |
| 15 | One recurring mascot serving as a guide | MC-01 |
| 16 | Automatic saving of unfinished puzzles | GP-13, PR-02 |
| 17 | World-based progression (locations unlocked by sequential level completion, WP-08) | WP-01 |
| 18 | ~~Magical Storybook visual identity~~ Superseded 2026-11-28 by #44 (W4-R1) | VI-01 |
| 19 | Collectible cards with rarity | CC-01, CC-02 |
| 20 | Data-driven level system | DL-01 |
| 21 | Local-first persistence; Firebase only when justified | PR-01, §13 |
| 22 | flame_audio; Rive subject to validation | §13 |
| 23 | Designated card puzzles guarantee their card; non-designated puzzles award coins and progression rewards | CC-04, CC-05 |
| 24 | Previously collected cards are not awarded as new collection progress | CC-06 |
| 25 | First prototype puzzle is a designated card puzzle | CC-07 |
| 26 | Initial development: logical grid occupancy (~~rectangular partition generation~~ superseded 2026-11-25 by #36, Q-022) | PS-06 to PS-08 |
| 27 | ~~Prototype piece generation: 4×4; pieces 1×1, 1×2, 2×1, 2×2; 8–12 pieces inclusive (generation constraint); seeded generation; layout persisted; hand-authored layouts not required for the prototype~~ Superseded 2026-11-25 by #36 (Q-022); the 4×4 board, seeded generation and persistence carry over as revised PS-19, PS-22, PS-23 | PS-19 to PS-24 |
| 28 | ~~Strict placement: only the correct position accepts a piece; incorrect drops animate back to the previous position; correct pieces are permanently locked and cannot be moved or swapped~~ Superseded 2026-11-25 by #32 (locking retained) | GP-06, GP-14, GP-15 |
| 29 | ~~Two-row, horizontally scrollable tray; comfortable touch targets; picked-up piece enlarges to board scale; layout adapts to phone screen sizes~~ Superseded 2026-11-25 by #31 | GP-16 to GP-19 |
| 30 | Target audience: core 16–35; overall intended audience 13+; teenagers and adults; under-13 not an intended target audience (product positioning, not a compliance determination) | TA-01 to TA-08 |
| 31 | ~~Pieces start face-down and scattered across the board, which is the primary workspace; no tray in the primary interaction; layout fits phone aspect ratios (Q-011 revised 2026-11-25)~~ Superseded 2026-11-25 by #34 | GP-20, GP-27, GP-28 |
| 32 | ~~Free placement: drag revealed pieces anywhere on the board; temporary overlap allowed; incorrect drops stay where placed and can be repositioned; correct alignment within the snapping tolerance snaps and permanently locks (Q-010 revised 2026-11-25)~~ Superseded 2026-11-25 by #34 | GP-15, GP-24 to GP-26 |
| 33 | ~~Memory reveal: all pieces face-up for exactly 4 seconds after a short introduction, then face-down; tap to reveal one piece at a time; revealed pieces stay face-up (2026-11-25)~~ Superseded 2026-11-25 by #34 | GP-21 to GP-23 |
| 34 | Rectangular picture-swap puzzle: fixed grid fully filled with face-up tiles in a shuffled arrangement; drag one tile onto another to exchange them; incorrect swaps allowed, unlimited, no penalty; release outside another tile cancels; completion when every tile is correct (Q-010 and Q-011 revised again 2026-11-25) | GP-29 to GP-35 |
| 35 | Hints excluded from the initial prototype; planned for v1 (2026-11-25) | GP-36 |
| 36 | Equal-sized rectangular tiles: uniform 4×4 grid, 16 tiles of identical dimensions, one per cell, cut as equal fragments of the illustration; mixed-size pieces superseded for the picture-swap gameplay (Q-022, resolved 2026-11-25) | PS-01, PS-06, PS-08, PS-19 to PS-24, GP-02, GP-29, GP-30 |
| 37 | Correctly positioned tiles remain movable: no locking; any two tiles can be swapped at any time; correct-position feedback is visual only; completion only when every tile is in its correct cell (Q-023, resolved 2026-11-25) | GP-15, GP-32, GP-34 |
| 38 | Puzzle introduction: card backs enter from below into the shuffled cells, then flip to the picture in sequence; input disabled until finished; runs for every new puzzle (2026-11-26) | GP-37 |
| 39 | Sunlit Storybook palette for the entire UI; bright code-drawn daytime placeholder picture; ~~no AI-generated or downloaded art~~ (2026-11-26; the sourcing restriction is superseded 2026-11-28 by #45; code-drawn art remains allowed as labelled placeholder) | VI-06, VI-07 |
| 40 | Board spacing: 20–32 dp horizontal margin to the frame's outer edge, safe areas respected, responsive; no reserved bottom action bar yet (2026-11-26) | GP-38 |
| 41 | Short completion celebration with no rewards shown yet (extensible for future rewards); Next puzzle reshuffles the same picture, reruns the introduction, and cannot be triggered twice (2026-11-26) | GP-39, GP-40 |
| 42 | Connected Tile Groups (core gameplay feature): neighbouring tiles join by correct relative picture alignment anywhere on the board, groups move and merge as one unit with their shape kept, single tiles keep drag-and-swap, the board stays full; free placement with a scattered workbench rejected (2026-11-26, approved on device) | GP-41 to GP-44, VI-08 |
| 43 | Positive connection feedback: Nice! (pair), Great! (growth), Amazing! (merge), Fantastic! (first group reaching 10+ tiles per puzzle), Perfect! (completion only); praise for actual connections only, paced, never blocks input; no rewards, scoring, combos or sound (2026-11-26, approved on device) | GP-45, VI-09 |
| 44 | Hybrid visual direction: realistic photography and semi-realistic illustration, mixed within locations; no flat cartoon, repetitive or childish art (2026-11-28, W4-R1) | §1, TA-07, VI-01, VI-02 |
| 45 | Hybrid artwork sourcing: licensed or commissioned photography; AI-assisted (commercial-use terms permitting) or commissioned illustration; provenance record for every asset; quality review before integration; unclear rights are never used; code-drawn art only as labelled placeholder (2026-11-28, W4-R1) | VI-07, VI-10, VI-12 |
| 46 | A location gives the chapter identity (original name, tagline, presentation); its ten pictures are diverse in subject, environment, colour and composition (2026-11-28, W4-R1) | VI-04, WP-04 |
| 47 | World Journey: five locations of ten levels; Normal 4×4 and Hard 5×5 with the approved Hard distribution; sequential level unlocking, with level 10 of locations 1–4 unlocking the next location and level 10 of location 5 completing the main World Journey with a final completion experience (the only unlock rule; collections-based unlocking superseded; future locations only through separate content updates); completed levels replayable; no 6×6 (approved in W0/W1; recorded 2026-11-28) | WP-03, WP-06 to WP-10, RW-03 |
| 48 | Artwork ceiling of 40 MB for all 50 bundled puzzle images combined, subject to measurement (the 800 KB per-image limit remains proposed); production images in `app/assets/`; provenance outside the app bundle (2026-11-28) | VI-10, VI-11 |
| 49 | Art styles: puzzle pictures photographic or semi-realistic; mascot polished 3D or semi-realistic; cards premium illustrated; consistency without one forced picture style (2026-11-28) | VI-13 |
| 50 | Sunny Castle is the temporary level-1 placeholder until replacement art is approved; Sunlit Storybook UI palette kept temporarily, revisited after W4-R2 (2026-11-28) | VI-06, VI-07 |

## 21. Source Gaps Summary

These sections need the approved PRD v1.0 text (Q-019):

| Section | Missing |
| --- | --- |
| §2 | Exact USP statement and positioning |
| §4 | Detailed visual direction, if specified |
| §8 | Any further loop steps |
| §12 | Further persistence requirements |
| §14 | Numeric technical requirements and quality gates |
| §16 | Approved development phases and exit criteria |
