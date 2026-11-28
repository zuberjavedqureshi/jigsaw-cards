# Visual Identity

> Status: **puzzle-picture direction revised and approved 2026-11-28 (W4-R1): hybrid photography and semi-realistic illustration** (§2, [ARTWORK_GUIDELINES.md](ARTWORK_GUIDELINES.md)); UI direction confirmed at a high level; **Sunlit Storybook palette approved 2026-11-26**, with the gameplay background refined and approved on device the same day (§2a, §2b); detailed style guide (typography, iconography, components) not yet produced. Style guide work belongs in [`design/style-guide/`](../../design/style-guide/).

## 1. Identity

- **Name:** Jigsaw Cards
- **Tagline:** Solve. Discover. Collect.
- **Theme:** Premium casual puzzle adventure through a journey of locations *(revised 2026-11-28; was "Magical storybook puzzle adventure")*.
- **Puzzle pictures [Confirmed 2026-11-28, W4-R1]:** realistic photography and semi-realistic illustration (PRD VI-01). *(Was: "Visual identity: Magical Storybook".)*
- **UI [Confirmed]:** the bright, cheerful Sunlit palette and patterned violet background (§2a, §2b) are **kept temporarily** and will be revisited after the W4-R2 visual prototype (Q-027).
- **Mascot and cards [Confirmed 2026-11-28, VI-13]:** a polished 3D or semi-realistic mascot; collectible cards with a premium illustrated presentation.

## 2. Art Direction (revised 2026-11-28, W4-R1)

- **Pictures are the reward:** high-quality realistic photographs and semi-realistic illustrations, mixed within each location (PRD VI-01, VI-02).
- **Every level is a surprise:** a location's ten pictures vary in subject, colour and composition. The location's identity comes from its name, tagline and presentation, not from a picture theme (PRD VI-04).
- **Sourcing, provenance and quality:** licensed or commissioned photography; AI-assisted or commissioned illustration; a provenance record and quality review for every picture (PRD VI-07, VI-10 to VI-12; [ARTWORK_GUIDELINES.md](ARTWORK_GUIDELINES.md)).
- Characters are revealed and **animated** when a designated puzzle is completed and its guaranteed card is awarded (PRD CC-03).
- **Styles by surface (PRD VI-13):** puzzle pictures are photographic or semi-realistic; the mascot is a polished 3D or semi-realistic character; cards have a premium illustrated presentation. Consistency comes from shared presentation and quality, without forcing all puzzle pictures into one style.
- *History:* the earlier principles were "beautifully illustrated puzzle images", "storybook feel: the game reads like an enchanted book" and "each world has a distinct palette and atmosphere".

## 2a. Sunlit Storybook Palette (approved 2026-11-26)

**[Confirmed]** The overall atmosphere is rich, cheerful and polished (PRD VI-06): a patterned violet storybook background (§2b), cream paper surfaces and harmonious accents, rather than dull or excessively dark scenes. The puzzle board is the focal point and the background stays atmospheric. The palette is defined as **shared design tokens** and used consistently across gameplay, menus and progression screens.

| Token | Colour | Use |
| --- | --- | --- |
| Violet backdrop | `#7543EE` | Gameplay background: flat base, no gradient (§2b) |
| Lattice line | `#6531DE` | Diamond lattice on the backdrop (§2b) |
| Lattice motif | `#6633DD` | Four-petal motifs on the backdrop (§2b) |
| Text on backdrop | `#FFFBF2` | Header title and instructions drawn on the backdrop |
| Warm cream | `#FFF4D6` | App base (scaffold) colour; not the gameplay background |
| Sky | `#BFE8FF` | Reserved light accent; no longer the gameplay background (superseded 2026-11-26, §2b) |
| Surface | `#FFFBF2` | Cards, dialogs, panels |
| Parchment | `#F6EAD0` | Secondary surfaces |
| Ink (text) | `#2B3A55` | Body and heading text (contrast ≥ 7:1 on cream) |
| Primary turquoise | `#19B3D1` | Primary actions; matches the card backs |
| Deep teal | `#0E7C93` | Pressed states, links |
| Sunflower | `#FFC845` | Highlights, celebration, future rewards |
| Coral | `#FF7A6B` | Celebration accents |
| Leaf | `#5CC27A` | Correct-tile and success feedback |
| Lavender | `#A98BE0` | Secondary accent |
| Board frame | `#E8C48A` with a `#C8964F` edge | Light honey-wood board frame |
| Board bed | `#EAF4FA` | Behind the tiles (visible under a lifted tile) |

- **Text contrast:** all text meets at least WCAG AA contrast (4.5:1 for body text) against its background.
- **Text pairings that meet this rule** (measured contrast): cream text on the violet backdrop 5.36:1 (6.67:1 where it crosses a lattice line); ink on surface 11.1:1, on cream 10.4:1, on sky 8.8:1, on sunflower 7.4:1, on leaf 5.1:1, on primary turquoise 4.6:1; white on deep teal 4.9:1; deep teal on surface 4.7:1. **White text on primary turquoise (2.5:1) or on coral (2.6:1) fails**: those colours carry text only in ink, and are otherwise used for accents, borders and effects. Filled primary buttons therefore use deep teal with white text, or turquoise with ink text.
- **Per-location presentation (direction):** each location adds its own accent and background tint on top of the shared cream surfaces, as part of its identity (VI-04). Even darker themes, such as a cosmic world, keep bright, readable UI surfaces. The per-world colours are not yet designed.
- **Typography:** open. The system font is used until a typeface is approved; bundling a font is a new asset and needs approval.
- **Placeholder art (PRD VI-07, revised 2026-11-28):** the code-drawn pictures (Sunny Castle; the W4 Sunny Meadows experiment) are prototype or placeholder art only and are labelled as such. Sunny Castle stays the temporary level-1 placeholder until replacement artwork is approved (Q-027). Production pictures follow the hybrid sourcing policy ([ARTWORK_GUIDELINES.md](ARTWORK_GUIDELINES.md)). *(Was: "No AI-generated or downloaded artwork.")*

## 2b. Gameplay Background (approved on device 2026-11-26)

**[Confirmed]** The gameplay background is a **patterned violet storybook background**, drawn in code. No image assets are used, and nothing is copied from reference material.

- **Base:** flat, rich violet `#7543EE`. No gradient, clouds or extra textures.
- **Diamond lattice:** two families of diagonal lines in a darker violet `#6531DE` (about 1.24:1 against the base: subtle but clearly visible), 3.4 dp thick. They form diamonds about 122 dp wide and 133 dp tall, centred horizontally.
- **Four-petal motifs:** one small flower at the centre of every diamond, about 34 dp across, made of four slim oval petals pointing up, down, left and right, in `#6633DD`.
- **Coverage:** sizes are in density-independent units, so the pattern keeps the same scale on every screen. It covers the whole screen, behind and around the board.
- **Hierarchy:** the board and tiles are the strongest focus. The light honey-wood frame separates the board from the background (3.35:1). The header and progress counter are secondary; the header text is cream `#FFFBF2` (5.36:1). The background is atmospheric only.

*History:* the first M3.1 implementation used a sky-to-cream gradient (`#BFE8FF` → `#FFF4D6`) with soft white clouds. After device review it looked washed out and competed with the board, so it was replaced on 2026-11-26: briefly by a muted periwinkle gradient, then by the patterned violet background above, which was approved on the product owner's Android device.

## 2c. Connected Tile Groups (approved on device 2026-11-26)

**[Confirmed]** (PRD VI-08, with GP-41 to GP-44) Connected groups read as **one piece of the picture**. No new colours or assets are introduced; the existing board tokens are reused.

- **At rest:** no edge lines between members of a group, only the light tile edge (white, about 80% opacity) around the group's outside. This applies wherever the group is, even away from its final cells. A correctly placed group stays edge to edge with no outline, as in M3.1. Loose tiles keep their full light edge.
- **Pressed or lifted:** the sunflower selection outline runs around the group's outside only. A lifted group is drawn about 8% larger and seamless (members spaced with the same scale), with **one shared soft shadow** instead of one shadow per tile.
- **Target feedback:** a single deep-teal outline with a soft turquoise glow around every cell the group would occupy (no inner lines). Displaced tiles get the existing target highlight.
- **Single tiles:** unchanged from M3.1 (selection outline, target cell outline, correct-tile glow).

## 2d. Praise Messages (approved on device 2026-11-26)

**[Confirmed]** (PRD VI-09, with GP-45) Short praise words celebrate connections, inspired by the reference gameplay ("Perfect!" with sparkles). Everything is drawn in code; there are no image or font assets.

- **Type:** bold (heavy weight) system font, tilted about 7°, with a dark contrasting outline (about 20% of the font size), a soft drop shadow and a light-to-saturated vertical gradient fill.
- **Colours by level:**

  | Praise | Fill (top → bottom) | Outline |
  | --- | --- | --- |
  | Nice! | `#E4FFC2` → `#5CC27A` (leaf) | `#1E6B3A` |
  | Great! | `#FFF6B0` → `#FFB31A` (gold) | `#9A4300` |
  | Amazing! | `#FFD6F4` → `#E052C4` (pink) | `#64188A` |
  | Fantastic! | `#FFE1B8` → `#FF7A3C` (coral) | `#8A2410` |
  | Perfect! | `#E6FCFF` → `#19B3D1` (turquoise) | `#0B3C8A` |

- **Glow and sparkles:** a soft warm glow behind the word and eight small four-point sparkles (white and gold) that twinkle around it.
- **Motion:** pops in from about 35% to 118% size, settles with a subtle bounce to 100%, holds, then fades (about 1.25 s in total). A message replaced by a stronger one fades out in about 0.16 s.
- **Size and placement:** the font size is 8.5% of the board width (20–40 dp). The message is centred on the connected tiles (the board centre for Perfect!) and kept fully on screen; it is drawn above the tiles but never captures touches.
- **Reduced motion:** with the system setting on, the message only fades in and out at full size, with no bounce or sparkles.

## 3. Mascot

- One recurring mascot character guides the player throughout the game (onboarding, world transitions, encouragement).
- Mascot design, name and personality: **TBC** (OPEN_QUESTIONS Q-006).

## 4. Locations — Identity

*(Revised 2026-11-28, W4-R1.)* A location's identity is its original **name**, **tagline** and **presentation** (accent and background tint, transitions). It does not set a picture theme: its ten pictures mix subjects freely (PRD VI-04). Candidate names, none approved yet, are listed in [GAME_PROGRESSION.md §2](GAME_PROGRESSION.md#2-locations) (Q-021).

*History:* the earlier non-binding directions tied each world to a picture theme: Enchanted Forest (woodland), Ocean Kingdom (underwater), Fantasy Kingdom (castles) and Cosmic Adventures (space).

## 5. UI Principles

- Portrait, one-handed friendly.
- Large touch targets for dragging pieces.
- UI frames the artwork and does not compete with it.
- Layout must adapt to different Android screen sizes and aspect ratios.
- **[Confirmed, 2026-11-26] Board spacing (PRD GP-38):** 20–32 dp horizontal margin from the outer edge of the board frame to each screen edge, safe areas respected, balanced vertical spacing, and a maximum board width on large screens. The board never touches the screen edges. No bottom action bar is reserved until hint and preview actions exist.

## 6. Open Items

- Typography and iconography (the colour palette was approved 2026-11-26, §2a).
- Per-world colour variations.
- Card frame design and visual treatment of card rarity (rarity itself is confirmed; tiers are open, Q-007).
- Animation style guide for Rive characters.
- Accessibility considerations (contrast, colour-blind safety).
