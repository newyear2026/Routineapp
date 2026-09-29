# LOOPET organic store screenshots

Eight Korean marketing cards inspired by the supplied mint app screenshot reference. The phone interiors come from the Flutter-rendered screens in `marketing/play/ko`; the intro and final cards use the existing LOOPET cat asset. The reference page's English marketing copy was replaced with descriptions of implemented LOOPET features.

- `play/ko/`: eight 1080 × 1920 PNGs for Google Play
- `ios/ko/`: eight 1290 × 2796 PNGs for the 6.7-inch App Store slot
- `preview_ko.png`: contact sheet

Regenerate from `flutter_app` with `python3 tool/generate_organic_store_screenshots.py`. Regenerate the source UI captures first with `flutter test tool/generate_store_screenshots.dart` after changing app screens.
