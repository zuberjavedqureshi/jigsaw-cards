# Raster Artwork Support — Technical Proposal

> Status: **proposal for review** (W4-R1, 2026-11-28). Nothing here is implemented. Implementation is a separate, reviewed engineering milestone, recorded as an ADR when approved (QG-07). It supports PRD VI-07 and VI-11.

## 1. Current architecture (inspected at commit `7a045f6`)

- `PuzzleArtwork` (`app/lib/artwork/puzzle_artwork.dart`) is a synchronous interface: `sourceSize`, `title`, and `paint(Canvas, Size)`, which paints the whole scene.
- `paintTile(canvas, artwork, dst, src)` clips to the tile, translates and scales, then calls `artwork.paint` for the **whole** scene. Each `TileComponent` records its tile once into a `ui.Picture` (`_art`) and redraws that picture every frame. The finished picture (`puzzle_screen.dart`) and the completion view use the same function.
- `artworkRegistry` (`artwork_registry.dart`) maps `ArtworkId → PuzzleArtwork`; a level is playable only if its picture is registered. Only Sunny Meadows level 1 (Sunny Castle) is registered.
- `artworkProvider` resolves the current level's picture synchronously.
- No raster assets are declared in `app/pubspec.yaml`. No image or caching packages are used.

## 2. Goals

1. Support raster pictures (WebP assets) **and** the existing code-drawn pictures behind the same `PuzzleArtwork` contract, so the board, groups, introduction, celebration and tests are unchanged.
2. Never decode on the gesture path. A puzzle starts only once its picture is ready.
3. Keep memory bounded: one decoded puzzle picture at a time, sized for the device.
4. No new dependencies. Flutter's built-in `rootBundle`, `ui.ImmutableBuffer`, `ui.instantiateImageCodec` and `Canvas.drawImageRect` are enough.

## 3. Proposed design

**Artwork sources.** Split *what* a picture is from *how it is loaded*:

```dart
/// Catalogue entry: describes a picture without loading it.
sealed class ArtworkSource {
  String get title;
}
final class CodeDrawnSource extends ArtworkSource { final PuzzleArtwork artwork; }
final class RasterAssetSource extends ArtworkSource {
  final String assetPath;   // app/assets/artwork/<location>/<id>.webp
  final int sourcePixels;   // 2048 (square)
}
```

**Loaded picture.** A `RasterArtwork implements PuzzleArtwork` holds a decoded `ui.Image`:

- `sourceSize` returns the logical source size, so tile maths stays in source units.
- `paint` draws the whole image with `drawImageRect(image, imageRect, Offset.zero & size, paint)` and `FilterQuality.medium` (mipmapped downscaling; avoids shimmering on small tiles).
- An **optional fast path** draws only the tile's region: `PuzzleArtwork` gains a default method `paintRegion(canvas, dst, src)` that falls back to today's clip-and-paint, and `RasterArtwork` overrides it with a single `drawImageRect(image, src→pixels, dst)`. `paintTile` calls it. Code-drawn pictures keep their current behaviour exactly.
- `dispose()` releases the image when the puzzle is left.

**Loading.** An `artworkLoaderProvider` (a hand-written Riverpod `FutureProvider` per level, as in ADR-0003) will:

1. Read the asset bytes (`rootBundle.loadBuffer`).
2. Decode with `instantiateImageCodec(targetWidth: decodePx, targetHeight: decodePx)`, where `decodePx = clamp(boardPhysicalWidth × 1.25, 768, 2048)`. The 1.25 factor leaves headroom for a lifted group, which is drawn 8% larger.
3. Return a `RasterArtwork`.

The puzzle screen shows the existing background and header while loading. Loading typically takes tens of milliseconds and is to be measured. The introduction (GP-37) starts only when the picture is ready, so nothing visible changes in gameplay. A decode failure shows an error state instead of a puzzle; it never silently substitutes another picture.

**Caching.** Keep the current puzzle's image, and optionally prefetch the **next** level's picture after completion (one extra decode in memory at most). Do not use Flutter's `ImageCache`; ownership is explicit and the image is disposed when the level changes. Per-tile `ui.Picture` recordings stay as they are; they reference the decoded image and do not copy pixels.

**Registry and catalogue.** `artworkRegistry` maps an `ArtworkId` to an `ArtworkSource` instead of a loaded artwork. `isPlayable` keeps its meaning (a source is registered). Level data and progression are unchanged (DL-01).

**Cropping.** None at runtime. Square pictures are prepared during production (VI-11); a loader assertion rejects non-square assets in debug builds and tests.

## 4. Memory and performance

| Case | Decoded size | Approximate GPU memory |
| --- | --- | --- |
| Phone, board ~1,200 physical px → decode at 1,500 px | 1500² × 4 B | ≈ 9 MB (+ mipmaps ≈ 12 MB) |
| Large tablet → decode at 2,048 px | 2048² × 4 B | ≈ 16.8 MB (+ mipmaps ≈ 22 MB) |
| Prefetched next picture | the same again | at most doubles, briefly |

Drawing is a GPU texture sample per tile (16 or 25 tiles plus the dragged group), cheaper than replaying the code-drawn scene's vector paths. The frame-timing measurement that is still outstanding for M1.1 should include a raster puzzle on a low-end device.

## 5. App size

- Baseline (measured 2026-11-28, W3 code, release build): **arm64 APK 15.5 MB**, armeabi-v7a 13.0 MB, x86_64 16.7 MB. There is no bitmap artwork yet.
- Fifty pictures at about 500 KB add about 25 MB. Approved ceiling (2026-11-28): at most 40 MB for all 50 bundled puzzle images combined, subject to measurement (PRD VI-11). Ship as an Android App Bundle; when to adopt Play Asset Delivery (install-time or fast-follow packs) is open as Q-028 (risk R-08).
- Pictures are already compressed WebP, so they gain almost nothing from APK or AAB compression; the budget counts their file sizes directly.

## 6. Testing

- Unit: the loader decodes at the requested size, rejects non-square images, never substitutes, and disposes on level change.
- Golden-free rendering checks: `paintRegion` for raster pictures matches clip-and-paint within a small pixel tolerance.
- Content tests per registered raster picture: asset exists; is WebP; is 2048 × 2048; is no larger than 800 KB; has a provenance record; passes tile distinctness at 4×4 and 5×5.
- All existing gameplay, progression and board tests unchanged.

## 7. Open points for the engineering milestone

- *(Decided 2026-11-28: production images live in `app/assets/artwork/`; provenance records stay outside the app bundle.)*
- Whether to keep `paintRegion` as an interface method or handle raster pictures inside `paintTile`.
- Device measurements: decode time and memory on a low-end Android phone.
