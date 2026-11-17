# Male mannequin preview and rollback

- `male_mannequin_3d_embossed.png` is the earlier style reference.
- `male_mannequin_legacy_preview.png` preserves the previous flat preview.
- `male_muscle_paths_legacy.dart` preserves the original per-muscle geometry.
- The hand-drawn SVG experiment remains in `../../lib/widgets/male_mannequin_generated_paths.dart`, but it is inactive.
- The app uses the original geometry in `../../lib/widgets/body_muscle_paths.dart` and its original renderer. Set `useGeneratedMaleMannequin` to `true` in `../../lib/widgets/body_overlay_painter.dart` to preview the experiment again.

These preview files are not loaded by the app.
