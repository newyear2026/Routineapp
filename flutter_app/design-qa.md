# Notification settings design QA

- Source visual truth: `design/notification-settings/reference.png` (the user's selected image).
- Implementation screenshot: `design/notification-settings/implemented.png`.
- Implementation: native Flutter `NotificationSettingsScreen`, reached from Settings → Sound & vibration.
- Viewport: 390 × 844 logical pixels, Android appearance, Korean, vibration-only selected, completion haptic on, notifications permitted.
- Source: 853 × 1844 pixels (approximately 2.187 pixels per logical pixel).
- Implementation: 780 × 1688 pixels (2×). Compare at common 390-pixel logical width; no device chrome in either image.
- Capture: `flutter test tool/render_notification_settings.dart --dart-define=PREVIEW_FONT=/System/Library/Fonts/AppleSDGothicNeo.ttc`.

## Visual comparison

The reference and final implementation were opened together in the same comparison tool response. The full view resolves the rows, toggle, primary action, footer and navigation; a separate cropped region was not necessary.

- Typography: clean Korean system sans-serif, bold title, 18px option labels, secondary descriptions, single primary action. Existing app type tokens preserved. Labels wrap instead of overflowing at narrow widths and larger text.
- Layout: grouped three-row selector, selected lavender row, separate completion toggle, centered status and preview button, persistent four-tab navigation. Extra system-settings explanation uses some of the reference's upper whitespace. A close control returns to the existing Settings screen.
- Colors: existing cream page, white surface, purple accent, muted ink descriptions and stepped borders. The app's existing flat button/bevel replaces the generated mock's gradient as required by UI_STANDARDS.md.
- Assets: actual Material notification/vibration/message icons and existing app pixel navigation/switch components. The preview uses the selected mode's icon in place of the decorative rays to make the selected notification type clear. No generated image is used as functional UI.
- Copy: selection/status refers to the requested mode rather than promising to know the phone's current sound mode. Added phone vibrate/silent/DND explanation; snooze note retained.

## Comparison history

1. Initial rendering showed missing Material icon glyphs (P1 evidence defect). The render harness now explicitly loads the bundled MaterialIcons font. Re-rendered and verified all icons.
2. Footer explanation wrapped awkwardly near the navigation (P2). Shortened the Korean explanation into two intentional lines, regenerated localization and re-rendered. The full explanation and primary action are now visible together at 390 × 844.
3. Final source + implementation comparison: no actionable P0/P1/P2 visual discrepancies. Header whitespace and standard app icons are intentional integration differences, not separate redesigns.

## Interaction and regression verification

- Three modes persist, use distinct Android channels, and set the intended sound/vibration flags.
- Preview uses the same notification channel as real reminders; denied permission prevents posting.
- Pending snoozes retain their original time while adopting the selected mode; delivered snoozes are not recreated.
- Disabling/re-enabling all notifications preserves selected mode and completion preference.
- Completion haptic is independent of notification permission, occurs after successful completion storage, and is not repeated for an already-completed routine.
- Settings entry, selection, completion switch and preview response tested as actual Flutter widgets.
- Korean, English, Spanish, Japanese and Portuguese tested at 320 × 568 with 150% text scaling; the action remains reachable by scrolling without overflow.
- iOS does not expose an unsupported vibration-only option. Its screen explains phone-level vibration control; foreground notification delegate configured.
- Targeted static analysis: no issues.
- Final notification-related regression run: 80 tests passed.
- Expanded run: 84 passed, 1 timed out in the poodle garden routine-screen test while waiting for its repeating background animation. Reproduces in isolation; no assertion in that test concerns the new notification UI. The background animation and that test's waiting policy were not changed.

## Remaining physical-device verification

Unit/widget tests and a Flutter-rendered screenshot do not verify audible sound or physical vibration. On Android, try all modes under normal/vibrate/silent/DND settings, then change mode with a snooze pending and verify its arrival. iOS foreground presentation and phone-level vibration also require a physical-device pass.

final result: passed

---

# Character collection and store design QA

- Selected reference: `design/character-pack-store/reference.png`, supplied by the user with the instruction to implement this design in the existing Flutter app.
- Actual Flutter captures: `collection.png`, `store.png`, `store-bottom.png`, `collection-full.png`, and `store-full.png` in the same directory. `preview.png` places both full views together; `comparison.png` puts the supplied reference beside both implemented tabs.
- Reference: 1205 × 1305, two screens. Standard implementation viewport: 390 × 844 logical pixels at 2×. Supplemental tall viewport: 390 × 1150 to inspect every section. The comparison normalizes each screen to approximately 390 pixels wide; tall views document scroll content, not a claim that everything fits above the fold on a phone.
- Capture command: `flutter test --no-pub tool/render_character_pack_store.dart --dart-define=PREVIEW_FONT=/System/Library/Fonts/AppleSDGothicNeo.ttc`.
- Preview ownership/prices are deterministic fixtures: default cat, launch-gift cat and rabbit owned; ₩2,900 per sale pack and ₩6,900 for the bundle. Production prices still come only from Google Play; these example prices were not added to application code.

## Visual comparison and integration choices

The selected reference and the final implemented tabs were inspected together in `comparison.png`, followed by the full views in `preview.png`. The original app's bundled artwork, typography, pixel borders, minimum button heights, and color tokens are preserved.

- Layout follows the selected two-tab structure: current character hero, owned grid, selection marker, discover tile/link, sale grid, final horizontal sale card, and bundle.
- The collection contains only owned characters. Launch gifts have a badge plus a working Apply action. The selected card uses a lavender status and check mark.
- Real pack sprites and backgrounds replace generated reference artwork so the store shows assets actually included with each pack. The hero uses a translucent dark overlay for readable white text.
- Existing secondary buttons use an ink border and white surface. The bundle retains the app's purple primary button. These deliberate design-system differences replace the mockup's tinted/gradient buttons.
- Buttons keep 44px minimum height and body text uses the app's readable type scale. Consequently, more content scrolls below the initial viewport than in the compressed reference. Header and tabs stay visible. At 320px with 200% text, cards become a single column.
- Five individual sale packs remain unchanged. The existing bundle grants six characters including the rewarded poodle, plus ad removal. The bundle count and six portraits now come from the actual grant catalog; free cats are not shown as paid bundle contents. The rewarded-unlock entry remains available for unowned poodles.
- Sale cards open the existing product detail/checkout. Unavailable prices show a details action and store-unavailable status; owned cards show Owned. This preserves existing delivery, pending, restore and error behavior.

## Iteration history

1. Moved the launch-gift badge over the artwork so owned cards have room for a usable Apply button.
2. A narrow-screen 200% text test found hero overflow. Increased hero height with text scale, constrained artwork size, and reran all five locales successfully.
3. Reduced bundle portraits to a compact 3 × 2 group while preserving the actual six entitlements.
4. Made hero text width relative to its card, including when the app constrains content width on a wider display. Corrected the test host to preserve real MediaQuery dimensions; all eight collection tests passed again.
5. Final visual comparison found no remaining actionable P0/P1/P2 discrepancies within the selected layout and the documented native-app integration choices above.

## Verification and limits

- 105 relevant tests passed across collection, pack screens, purchase flow, purchases, character selection and catalog specifications.
- Tests cover ownership arrival/removal, persisted Apply success/failure, purchased character appearing in the collection, avoiding fake production prices, and all five supported locales at 320 × 640 with 200% text.
- Final collection regression after responsive-width adjustment: 8 passed. Final screenshot renderer: passed. Targeted analysis of six changed Dart files: no issues.
- Final Android debug APK build: passed.
- Installed a debug build on the Android emulator and verified Settings → Character packs opens the new collection screen. Native screenshots are retained alongside the widget captures.
- Real Google Play checkout on the user's physical phone was not verified by this UI change. No Play Console release was uploaded; the installed Play version needs a subsequent release to receive this screen.

final result: passed


## Follow-up: five-character bundle (2026-10-02)

The user explicitly selected replacing the existing bundle with five characters plus ad removal. This supersedes the six-character bundle composition described above; the selected two-tab layout remains unchanged.

- The existing product ID now grants exactly Postman Rabbit, Explorer Squirrel, Mooncloud Sheep, Red Panda Teashop, Sunny Sea Otter and home/progress ad removal. Future sale packs are not added automatically.
- The store card renders exactly those five portraits and the title “5종 팩 + 광고 제거”. The new description is translated into Korean, English, Spanish, Japanese and Portuguese. Poodle Garden remains a separate rewarded-unlock entry.
- Rendered and inspected the real Flutter store again, including the five portraits, title, wrapped description, full purchase button and separate poodle row. `five-pack-bundle.png` is a crop of `store-bottom.png`. Preview prices remain fixtures, not production pricing.
- Updated `STORE_PRODUCTS.md` with all five Play Console names/descriptions and fixed contents. Existing product ID and pricing are unchanged. Previously cached six-pack test grants are not forcibly deleted; fresh-install restores use the new five-pack contents.
- 108 regression tests passed, including exact new purchase/restore grants, future-pack exclusion, bundle checkout through the store into the owned collection, refund behavior and independent rewarded-poodle ownership.
- Targeted static analysis: no issues. Final Flutter screenshot render and Android debug APK build: passed. No Play Console product metadata or release was published.

final result: passed

## Follow-up: forest picnic artwork in the live store card (2026-10-02)

- User-selected visual source: `design/character-pack-store/five-pack-forest-picnic-v2.png`.
- Added the exact, byte-identical image as `assets/store/bundles/five_pack_forest_picnic.png` and registered that individual file in `pubspec.yaml`.
- The five-character bundle card now displays the illustration above its title, contents and existing checkout button. It preserves the original 1672:941 aspect ratio with `BoxFit.contain`; all five faces, ears and feet remain visible. The image is decorative for accessibility because the adjacent text describes the product.
- Compared the selected source image and the actual 390 × 844 Flutter store capture together. Inspected `forest-picnic-card.png` (a crop of that capture), and the 320 × 640 / 200% text capture. The price/action remains reachable and tappable by scrolling; text wraps naturally. No actionable P0/P1/P2 visual issues remain.
- Existing purchase, pending, owned and unavailable behavior is unchanged. The displayed preview price is still a fixture; production pricing comes from Play.
- P3 follow-up: at 200% text the shared AppButton ellipsizes the long purchase caption after the full price. The button remains tappable and its full Text semantics are retained. This existing shared-button behavior was not broadened into a component redesign for the artwork task.
- Verification: 45 existing screen/purchase-flow regression tests passed; actual screenshot render including large text and a hit-testable checkout button passed; targeted static analysis found no issues; Android debug build passed.
- No Play Console changes or release upload were performed. The selected illustration's earlier standalone-delivery note is superseded by this app integration.

final result: passed
