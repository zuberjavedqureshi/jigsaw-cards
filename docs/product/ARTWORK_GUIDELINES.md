# Artwork Guidelines

> Status: **approved 2026-11-28** (W4-R1). It details PRD VI-01, VI-02, VI-04, VI-07 and VI-10 to VI-13. In §4, the 40 MB ceiling, the `app/assets/` location and provenance outside the bundle are **[Confirmed]**; the other numeric limits are **[Proposed]** until the W4-R2 measurements. No image source (stock agency, AI provider, subscription or budget) is selected yet (Q-024). This document is product and process guidance only. It is not legal advice; material legal questions go to the product owner (and counsel where needed) before an asset is used.

## 1. Visual direction (VI-01, VI-02, VI-04)

Jigsaw Cards pictures are **realistic photographs** or **semi-realistic illustrations**. Both styles can appear in the same location.

| | Realistic photography | Semi-realistic illustration |
| --- | --- | --- |
| Look | Natural textures, realistic light and shadow, rich colour, depth | Polished, detailed artwork with realistic textures, light and depth; artistic personality |
| Avoid | Shallow depth of field that blurs large areas; flat, empty skies or walls; visible logos, plates or signage | Flat cartoon shapes; thick outlines; childish proportions; the shared "storybook kit" look of the W4 experiment |

**A location is a chapter, not a subject.** A location's identity comes from its name, tagline and presentation (VI-04). Its ten pictures mix subjects freely: machinery, flowers, food, animals, birds, vehicles, buildings, landscapes, everyday objects. Within a location:

- No two consecutive levels share a main subject, dominant colour family or composition type (for example two top-down flat-lays, or two wide landscapes with a horizon).
- Photographs and illustrations are mixed, but there is no fixed alternation.
- A main subject used in one location is not repeated in another unless the product owner decides otherwise.

**Other surfaces (VI-13).** The mascot is a polished 3D or semi-realistic character. Collectible cards use a premium illustrated presentation. Consistency comes from shared UI presentation and quality standards, not from forcing every puzzle picture into one style.

## 2. Sourcing policy (VI-07)

Only these sources are allowed for **production** pictures:

| Source | Allowed when | Ownership | Key checks |
| --- | --- | --- | --- |
| **Licensed stock photography** | The licence explicitly permits use inside a commercially distributed mobile game (in-app display, worldwide, for the expected install volume) | Licence only, usually non-exclusive | Exact licence tier and its limits (print-run or impression caps, "template" or "product for resale" restrictions, redistribution of the file); editorial-only images excluded; model and property releases where people, private property or artworks appear |
| **Commissioned photography** | A written agreement assigns copyright or grants an exclusive, perpetual, worldwide licence for the game and its marketing | Owned or exclusively licensed | Signed agreement; releases for people and private property; no third-party brands |
| **AI-assisted illustration** | The provider's **current** terms permit commercial use of outputs in a distributed product, for the account and plan actually used | Varies by provider and jurisdiction: purely generated images may have weak or no copyright protection | Terms checked and dated at the time of generation; no prompts naming living artists, brands, characters or franchises; output checked for logos, text and lookalike characters; generation records kept; meaningful human editing recommended (it also strengthens the work's originality) |
| **Commissioned illustration** | A written agreement assigns copyright (work for hire or assignment) or grants an exclusive, perpetual, worldwide licence | Owned or exclusively licensed | Signed agreement; the artist confirms the work is original and states whether AI tools were used |

**Never used:** images taken from websites, search results or social media without a verified licence; "free" images whose licence does not clearly cover in-app use in a commercial game, or which forbid redistributing the file inside an app; images showing recognisable brands, logos, trademarks, number plates, copyrighted characters or identifiable people without releases; any image whose rights are unclear.

**Placeholder art.** Code-drawn pictures (Sunny Castle, the W4 Sunny Meadows experiment) are prototype or placeholder art. They are labelled as such in code and documents and are never presented as production art. Sunny Castle stays as the temporary level-1 placeholder until replacement artwork is approved (Q-027).

**Source selection.** No stock agency, AI provider, subscription or budget is selected. The choice follows the evaluation of the W4-R2 prototype and a comparison of commercial licences (Q-024). Every chosen source must meet the table above.

**Escalation.** Any material legal uncertainty, such as a licence clause that is unclear for app embedding or a provider's terms that changed, is recorded in the provenance record and raised with the product owner. Until it is resolved, the asset is not used.

## 3. Provenance record

One record per production asset, created **before** the asset is integrated and kept for the life of the product. Records are stored in the repository at `artwork/provenance/<asset-id>.md` (proposed location, outside the app bundle so it is never shipped). Purchase receipts, invoices and signed agreements may contain personal or billing data. They are therefore stored in the product owner's own document storage, and the record only references them.

```
asset_id:            proto-01-fishing-harbour         # stable ID, also the filename stem
filename:            proto-01-fishing-harbour.webp
level:               <location key>-<level number>  (or "prototype")
main_subject:        Fishing harbour with boats, nets and buoys
style:               photograph | semi-realistic illustration
production_method:   licensed stock | commissioned photo | AI-assisted illustration | commissioned illustration
source_or_provider:  <stock agency / photographer / AI provider / illustrator>
source_reference:    <asset number or URL at the provider; order or job ID>
creator:             <author, where applicable>
licence:             <licence name, tier and version; or provider terms version>
terms_checked_on:    YYYY-MM-DD
commercial_use:      yes | no | unclear  (unclear => do not use)
in_app_embedding:    permitted | not permitted | unclear
attribution:         none required | required: "<exact text>" (and where it is shown)
evidence:            <reference to receipt, licence certificate or agreement in owner storage>
releases:            model: n/a | on file | missing;  property: n/a | on file | missing
restrictions:        <caps, territories, editorial-only, no-resale-as-file, etc.>
ai_records:          provider, model/version, date, prompts, seeds, source images (if any)
edits:               <crop, retouch, paint-over, colour work; by whom>
master_file:         <location of the full-resolution master>
quality_review:      passed | failed  (reviewer, date, link to §5 checklist)
notes:               <open questions, legal flags>
```

## 4. Image technical requirements

These limits are **proposed**, derived from the current architecture:

| Item | Proposed requirement | Rationale |
| --- | --- | --- |
| Aspect ratio | **1:1 square** | Every board is square (4×4 and 5×5, square tiles). The current picture interface already uses a 1024 × 1024 source size, and the board keeps the picture's aspect ratio (GP-35), so a square picture uses the board fully |
| Shipped resolution | **2048 × 2048 px** | The board frame is at most 560 dp wide (`PlayAreaLayout.maxFrameWidth`). On phones the board is about 266–345 dp; at device pixel ratios up to 3.5 that is roughly 930–1,210 physical pixels. A large tablet at a ratio of about 2.6 reaches about 1,450 px. 2048 px gives at least 1.4× headroom everywhere. Each 5×5 tile is still about 410 px in the source, so detail stays crisp when a group is lifted (drawn 8% larger) |
| Master files | **≥ 3000 px**, kept outside the app | Allows re-export at another size, retouching and later uses (cards, store listing) |
| Format | **WebP**, lossy, quality about 80–85; no alpha channel | Supported natively by Flutter's image decoder on Android, with no new dependency. It is much smaller than PNG for photographic content. Quality is chosen per image by inspecting the result at 5×5 tile size |
| File size | Target **300–600 KB**; maximum **800 KB** per picture **[Proposed, subject to measurement]** | Estimate for richly detailed 2048 px pictures at this quality. To be confirmed with the W4-R2 prototype images |
| App-size budget | **[Confirmed 2026-11-28, Q-025]** a **ceiling of 40 MB for all 50 bundled puzzle images combined** (five locations × ten levels), subject to actual asset-size measurements. The 800 KB per-image limit above stays **[Proposed]** until measured. When to adopt Play Asset Delivery is a separate open question (Q-028) | Baseline measured 2026-11-28: the release arm64 APK is **15.5 MB** without bitmap artwork. Fifty pictures at the 500 KB average add about 25 MB, so the download would be about 40 MB. That is well within Google Play's limits, but install size affects conversion; the feasibility review flags it as risk R-08 |
| Colour | sRGB, 8-bit | Consistent on Android displays |
| Decoding | Decoded once per puzzle, asynchronously, **before** the introduction starts, at a target width matched to the board's physical pixel width (at most 2048); never on the gesture path; released when the puzzle is left | Peak memory: 2048² × 4 bytes ≈ 16.8 MB decoded, plus mipmaps ≈ 22 MB. Decoding at the board's size on phones (about 1,200 px) cuts this to about 6–8 MB. This matches the feasibility review estimate of about 8 MB for a 1440 px texture |
| Composition safety | Meaningful detail up to every edge; no essential subject part within about 2% of an edge; no text, watermarks, signatures or frames | Tiles are cut exactly on the grid and nothing is cropped at runtime. Edge and corner tiles are the hardest to place when they carry little detail |
| Storage in the app | **[Confirmed 2026-11-28]** `app/assets/artwork/<location-key>/<asset-id>.webp`, declared in `app/pubspec.yaml` | Flutter asset paths are relative to the package, so production images live inside the `app` package. The repository's top-level `assets/` placeholder folders are not used for production puzzle images |
| Provenance | **[Confirmed 2026-11-28]** outside the app bundle: `artwork/provenance/<asset-id>.md` (§3) | Records stay reviewable and versioned without increasing the app size |

## 5. Artwork quality checklist

A picture is integrated only when every item passes. The reviewer records the result in the provenance record.

| # | Check | How to review | Fails when |
| --- | --- | --- | --- |
| 1 | Clear, recognisable main subject | View the whole picture at phone size (about 7 cm wide) | The subject is unclear at a glance or too small to recognise |
| 2 | Distinct visual regions | Overlay the 4×4 and 5×5 grids | Several tiles show the same colour and texture with nothing to tell them apart |
| 3 | Attractive colour composition | Whole picture and the location contact sheet | Muddy or washed-out colour; a palette too close to the previous or next level |
| 4 | Sufficient texture and detail | Inspect single 5×5 tiles at 100% | Tiles are smooth, soft or noisy without readable detail |
| 5 | No large empty or monotonous areas | Grid overlay | Any area of two or more adjacent 5×5 tiles is plain sky, water, wall or shadow |
| 6 | Interesting content near the edges | Check the 16 outer tiles of 5×5 | Corner or edge tiles are empty or very similar to each other |
| 7 | No excessive background blur | Inspect background tiles | Bokeh or depth-of-field blur makes tiles nearly identical |
| 8 | No repeated composition | Compare with all other levels on the contact sheet | The same layout, viewpoint or scene type appears on another level, especially consecutive ones |
| 9 | Suitable difficulty for 4×4 and 5×5 | Play both sizes on a device | Too easy (a few huge distinct blocks) or frustrating (many indistinguishable tiles) |
| 10 | High quality on a mobile screen | Device check in light and dark rooms | Artefacts, compression banding, oversharpening, AI glitches (hands, text, warped geometry) |

Additional checks: no logos, brands, text, watermarks or identifiable people without releases; the provenance record is complete and rights are clear.

**Automated support.** The existing tile-distinctness test (8×8 mean-colour thumbnails per tile; mean absolute difference above 8 between every pair; brightness checks) is run on every picture at 4×4 and 5×5. Passing it is necessary but **not sufficient**: the W4 experiment passed it while still looking repetitive. Human review on the contact sheet and real gameplay on an Android device are required.
