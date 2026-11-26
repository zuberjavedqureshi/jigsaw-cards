# Visual Identity

> Status: direction confirmed at a high level; **Sunlit Storybook palette approved 2026-11-26**, with the gameplay background refined and approved on device the same day (§2a, §2b); detailed style guide (typography, iconography, components) not yet produced. Style guide work belongs in [`design/style-guide/`](../../design/style-guide/).

## 1. Identity

- **Name:** Jigsaw Cards
- **Tagline:** Solve. Discover. Collect.
- **Theme:** Magical storybook puzzle adventure.
- **Visual identity [Confirmed]:** Magical Storybook.

## 2. Art Direction (confirmed principles)

- Beautifully illustrated puzzle images — the art is the reward.
- Storybook feel: the game reads like an enchanted book.
- Characters are revealed and **animated** when a designated puzzle is completed and its guaranteed card is awarded (PRD CC-03).
- Each world has a distinct palette and atmosphere.

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
- **Per-world variation (direction):** each world adds its own accent and background tint on top of the shared cream surfaces (VI-04). Even darker themes, such as a cosmic world, keep bright, readable UI surfaces. The per-world colours are not yet designed.
- **Typography:** open. The system font is used until a typeface is approved; bundling a font is a new asset and needs approval.
- **Placeholder art (PRD VI-07):** the placeholder puzzle picture is a bright, code-drawn daytime storybook scene. No AI-generated or downloaded artwork.

## 2b. Gameplay Background (approved on device 2026-11-26)

**[Confirmed]** The gameplay background is a **patterned violet storybook background**, drawn in code. No image assets are used, and nothing is copied from reference material.

- **Base:** flat, rich violet `#7543EE`. No gradient, clouds or extra textures.
- **Diamond lattice:** two families of diagonal lines in a darker violet `#6531DE` (about 1.24:1 against the base: subtle but clearly visible), 3.4 dp thick. They form diamonds about 122 dp wide and 133 dp tall, centred horizontally.
- **Four-petal motifs:** one small flower at the centre of every diamond, about 34 dp across, made of four slim oval petals pointing up, down, left and right, in `#6633DD`.
- **Coverage:** sizes are in density-independent units, so the pattern keeps the same scale on every screen. It covers the whole screen, behind and around the board.
- **Hierarchy:** the board and tiles are the strongest focus. The light honey-wood frame separates the board from the background (3.35:1). The header and progress counter are secondary; the header text is cream `#FFFBF2` (5.36:1). The background is atmospheric only.

*History:* the first M3.1 implementation used a sky-to-cream gradient (`#BFE8FF` → `#FFF4D6`) with soft white clouds. After device review it looked washed out and competed with the board, so it was replaced on 2026-11-26: briefly by a muted periwinkle gradient, then by the patterned violet background above, which was approved on the product owner's Android device.

## 3. Mascot

- One recurring mascot character guides the player throughout the game (onboarding, world transitions, encouragement).
- Mascot design, name and personality: **TBC** (OPEN_QUESTIONS Q-006).

## 4. Worlds — Visual Themes

World names are working names (proposed, PRD WP-02, Q-021).

| World | Direction (initial, non-binding) |
| --- | --- |
| Enchanted Forest | Woodland, soft light, magical creatures |
| Ocean Kingdom | Underwater, flowing, aquatic characters |
| Fantasy Kingdom | Castles, royalty, classic fairy tale |
| Cosmic Adventures | Space, stars, cosmic characters |

These descriptions are working directions, to be refined by the art team.

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
