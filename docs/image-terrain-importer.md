# Image Terrain Importer

## Goal

Turn map-like graphical inputs into a playable first-person terrain surface without depending on native terrain addons.

## Current model

The runtime now uses `scripts/TerrainImportModel.gd` as the terrain reconstruction layer.

It supports profile-driven import from image sources with explicit reconstruction modes:

- `hillshade_reconstruction`
  Best for grayscale shaded-relief or hillshade images like the current Washington source.

- `contour_reconstruction`
  Intended for future contour-map inputs where dark contour lines and local gradients should inform height estimates.

## Active demo profile

The current first-person branch uses this profile:

- `id`: `wa_hillshade_demo`
- `mode`: `hillshade_reconstruction`
- `source`: `assets/maps/wa_hillshade.png`

That means the terrain shown in the demo is no longer a purely synthetic ridge field. It is reconstructed from the specific Washington hillshade segment already in the repo, then exaggerated enough to stay legible in first person.

## How the hillshade mode works

For each sample in the terrain grid:

1. Read source-image luminance.
2. Apply contrast and gamma shaping so brighter relief pushes upward more strongly.
3. Add broad valley shaping so the terrain does not collapse into evenly distributed noise.
4. Add small ridge and spur detail to keep the terrain from feeling smoothed flat at gameplay resolution.
5. Use dark-line influence as a hint for stronger relief edges.
6. Convert normalized relief to world height using profile `height_scale` and `height_offset`.

## How the contour mode is intended to work

The contour mode is currently a first-pass estimator, not a surveyed topographic solver.

It combines:

- overall luminance
- dark line presence
- local image gradient

This is enough to support future contour-map experiments, but it is still a heuristic. If we later want true contour-to-height import, the next step is to add line extraction plus contour indexing instead of relying on simple darkness/gradient inference.

## Why this exists

- Browser preview compatibility: no GDExtension dependency
- Repeatable terrain generation from source imagery
- A path to support both hillshade and contour-map inputs
- Easier testing, because the importer exposes profile metadata that can be asserted in CI

## Next improvements

- Add a small importer-debug overlay showing source image, sampled heightfield, and terrain output side by side
- Add a selectable import mode in debug builds so hillshade and contour reconstruction can be compared on the same source
- Add a true contour-line parser for maps with clear elevation intervals
