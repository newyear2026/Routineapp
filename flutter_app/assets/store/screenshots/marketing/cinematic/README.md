# LOOPET cinematic Google Play screenshots

Eight Korean 1080 × 1920 RGB PNGs inspired by the supplied dark streaming-app template. The dark plum gradient, large white captions, angled devices, and layered layouts are new; every device interior uses LOOPET's freshly Flutter-rendered app screens from `cinematic/source/play/ko`. The widget close-up is a crop of that same captured widget screen.

- `play_console_ko/`: eight individual PNGs, ordered for upload
- `preview_ko.png`: full-set contact sheet
- `loopet_cinematic_play_ko.zip`: the eight PNGs in one archive

Run `python3 tool/generate_cinematic_store_screenshots.py` from `flutter_app` to regenerate. The current source captures were generated on 2026-10-01 with `flutter test --dart-define=STORE_SCREENSHOT_OUTPUT_ROOT=assets/store/screenshots/marketing/cinematic/source --dart-define=STORE_SCREENSHOT_LOCALE=ko tool/generate_store_screenshots.dart`. Recapture after substantial app UI changes.
