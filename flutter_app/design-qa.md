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

---

# Card and circular home widgets (2026-10-07)

The user selected the first and second displayed widget mockups. This change applies them to the existing Android widgets and Flutter preview screen; it does not scaffold a separate prototype or change the iOS WidgetKit layout.

## Visual evidence

- Selected images: `output/widget-design-2026-10-07/reference-card.png` (1774 × 887) and `reference-ring.png` (1672 × 941).
- Actual Android RemoteViews captures in the same directory: `android-cards-360.png`, `android-ring-360.png`, `android-cards-250.png`, `android-ring-250.png`, `android-cards-completed.png`, and `android-ring-completed.png`.
- Android viewports: 360 × 180 dp (990 × 495 pixels, density 2.75) and 250 × 160 dp (687 × 440 pixels, with fractional pixel rounding).
- Actual Flutter captures: `cards-360.png`, `ring-360.png`, `cards-250.png`, and `ring-250.png`; 360/250 × 180 logical pixels at 3× density.
- Comparison state: Korean, Starlight Cat, Reading 21:00–21:30, 12 minutes remaining, Stretching next at 21:30. Completed captures are supplemental states; the selected mocks only specify the active state.
- Each reference and its latest Android implementation were opened in the same comparison response. Comparison uses the card content, excluding the generated image's outer presentation canvas, and judges positions at a common logical width. The card reference's content aspect ratio is approximately 2.18:1; Android uses 2:1 to accommodate its 4 × 2 sizing and a usable action. The ring reference is approximately 2:1. Pixel-for-pixel equivalence of the surrounding mockup canvas is not claimed.
- Full-size captures make the countdown, action, labels and mascot clearly readable; no separate detail crop was needed. Narrow and completed states were inspected independently.

## Required fidelity surfaces

- Typography: readable system Korean sans-serif, bold routine/countdown hierarchy, smaller secondary labels, and white completion labels. Android uses native text rather than baking copy into artwork. Explicit row heights and disabled extra fallback line spacing prevent Korean glyph clipping. Long titles truncate within the widget instead of covering the action.
- Spacing: card content keeps the current routine and countdown at left, mascot at right, and next routine/action beneath a divider. The circular layout keeps the action left and the cat above the dial. A separate compact layout retains the same hierarchy at 250 × 160 dp. New widgets default to 4 × 2; existing launcher placements retain their old size until resized or re-added.
- Colors: existing cream/lavender skin, dark ink and purple action are preserved. Other character packs retain their own artwork and text/background tokens. Buttons use the app's flat purple treatment and stepped border instead of the generated highlight gradient.
- Assets: shipped cat sprites and decoration artwork replace the reference's generated approximation of the same character. The 24-hour dial renders actual routine segments, so it does not invent the reference's decorative extra appointments. No new generated artwork is required.
- Copy: current state, routine name, time range, remaining duration, next routine and localized completion action follow the selected hierarchy. Completion, no-current-routine and expired-data states use real state rather than continuing to show an actionable sample timer. New labels are present in all five supported locales.

## Findings and iteration history

1. P1: the initial Flutter capture lacked its Material icon font. The capture harness now loads the existing MaterialIcons font; the completion check renders correctly.
2. P2: an early ring layout clipped the next routine title. Combined the native next time/title into one bounded row and adjusted vertical spacing. The final normal and narrow captures show the entire Korean fixture row.
3. P2: Spanish next-label text overflowed in Flutter. Constrained the localized prefix and title; the five-locale 1.0×/1.3× layout regression run passes.
4. P2: reducing native height to the declared minimum clipped the card countdown and native next-row baseline. Allocated explicit text rows, removed excess fallback line spacing, reduced vertical gaps, and reduced the narrow mascot frame. Added native bounds checks for visible child/text clipping. All six native states pass after these changes and the final captures show complete glyphs.
5. P3: reduced the completed circular widget's clock type size to leave more clearance from the dial's 06/18 labels. Its clock derives from the same render timestamp as the rest of the view.

The existing rounded Android outer frame and small status badge differ slightly from the generated pixel corner shapes; the stepped action and dial preserve the pixel style. These are minor integration differences. No actionable P0/P1/P2 visual findings remain after the corrections above.

## Interaction and regression verification

- 119 relevant Dart test cases passed across the final widget, payload/timeline, action, background-callback and localization/layout runs. The callback test sends two concurrent actions, observes one persisted completion, and verifies updates for all three Android widget providers.
- Completion targets the displayed routine ID and occurrence date, including the sleep wake date. Tests cover stale/deleted/changed definitions, wrong dates, malformed actions, overlap, duplicate completion and preserving skipped records.
- Android saves under the repository's shared native lock and informs the foreground app of changes. After saving, the background callback cancels the routine's snooze and regenerates widget data. Storage failure does not produce a completed state.
- Native instrumentation renders the real RemoteViews without changing saved routines/logs, checks completion PendingIntent binding, confirms its removal for completed state, and checks visible text/child bounds at both sizes.
- Targeted Dart static analysis: no issues. Android debug APK and instrumentation APK build: passed.
- Launcher picker previews use the verified native captures and preserve their aspect ratio. The app's widget preview shows both designs; sample completion remains isolated from real logs.
- Physical launcher taps through the OS background worker and physical-device battery restrictions have not been verified end to end. Callback persistence and native action binding were tested separately. Existing five-minute/boundary refresh scheduling is retained; this is not a per-second countdown.

## Handoff checklist

- [x] Both selected layouts implemented in the existing app.
- [x] Completion persistence and widget refresh connected.
- [x] Compact and completed-state rendering checked.
- [x] Launcher picker artwork updated.
- [x] Targeted tests, static analysis and Android build passed.
- [ ] Optional physical-phone pass for launcher sizing and OS-delivered completion taps.

final result: passed

---

# Horizontal routine timeline widget (2026-10-08)

The user supplied an additional image and requested the same treatment for the existing timeline widget. The earlier card and circular designs remain available.

## Evidence and comparison

- Source: `output/widget-timeline-2026-10-08/reference.png`, copied unchanged from the user's attachment, 1619 × 972 pixels.
- Android implementation: `android-timeline-360.png` (990 × 495 pixels, 360 × 180 dp at 2.75×) and `android-timeline-250.png` (687 × 440 pixels, 250 × 160 dp with fractional pixel rounding) in the same directory.
- Additional Android captures: `android-timeline-completed.png` and `android-timeline-count-0.png`, `android-timeline-count-1.png`, `android-timeline-count-2.png`.
- Flutter implementation: `timeline-360.png` and `timeline-250.png`, 360/250 × 180 logical pixels at 3× density.
- State: Korean Starlight Cat; Reading 21:00–21:30 at 21:18, Stretching at 21:30, Sleep at 22:00. The reference's surrounding presentation canvas is excluded from the layout comparison. Its widget region is approximately 1335 × 629 (2.12:1); the implementation uses the app's 360 × 180 native widget viewport (2:1).
- The source and actual native normal-size capture were opened together in the same comparison response. Flutter source comparisons and all five supplemental native states were also inspected. Comparison judges the widget content at a common logical width rather than claiming pixel equality with the reference's outer canvas. The full-size captures resolve all text and controls; no separate detail crop was necessary.

## Required fidelity surfaces

- Typography: bold current routine and remaining duration, compact status, readable Korean system text, and smaller milestone times/names. Native labels remain TextViews with intact accessibility text. The compact Flutter action uses a smaller check and tighter padding so its completion caption remains visible.
- Spacing: mascot left, status/title/countdown center, completion right, and a separate schedule below. The three milestone centers use 10%/50%/90% of the inner width, matching the reference's wide timeline. With one or two real items, the points recenter and unused columns disappear.
- Colors: existing cream/lavender character skin, dark ink, purple action/current item, and muted future points. Other character packs retain their own artwork and tokens. The solid purple action follows the app's UI standards.
- Assets: real bundled cat and background decorations are reused. The timeline is a data visualization with native text, not a screenshot used as the UI. Markers and line lengths derive from actual occurrence times.
- Copy: real current/next routines, translated status/countdown/completion, and a new localized timeline style label in all five languages. Empty schedules show the existing add-routine guidance and no invented points; completion removes the action and countdown.

## Findings and iteration history

1. P2: the initial compact Flutter button showed only the check. Reduced its icon, label size and horizontal padding; the revised 250-pixel render shows the full Korean completion caption and all five language interaction tests pass.
2. P2: the first timeline occupied too little horizontal space. Widened milestone placement while keeping labels aligned using the center column's weight. Native and Flutter captures now follow the supplied composition.
3. P2: native Korean title metrics exceeded its initial row height. Increased title height and adjusted compact gaps. The final native title renders fully.
4. P2: independently rounded dp heights clipped the last native footer/header child by 1–3 physical pixels. Reserved vertical rounding space and reran the existing text/child bounds checks. Both viewport sizes and all schedule-count/completed states pass and show complete glyphs.

No actionable P0/P1/P2 findings remain. P3 integration differences: the existing Android outer/status corners are rounded, the divider is solid rather than dashed, and the approved mascot's proportions differ slightly from the generated reference. These do not change the selected composition or behavior.

## Verification and limits

- 124 relevant Dart tests passed across the feature/payload/action/render run (23) and existing layout/localization/background-action regression run (101). A further final feature/render run passed after the spacing correction.
- Tests cover actual item counts, current/next boundary advancement, serialized occurrence dates, overnight sleep, five locales at 250/360 pixels, and a tappable completion action.
- Native instrumentation renders all three widget styles, checks completion binding and removal, verifies visible text/child bounds, and validates zero/one/two timeline items plus expired-state hiding. Final result: all checks passed.
- Targeted static analysis: no issues. Android app and instrumentation builds: passed. Launcher picker artwork is the verified native normal-size capture, using aspect-preserving display.
- Existing widgets keep their launcher placement until resized or re-added; the timeline now defaults to 4 × 2, with a 160dp minimum resize height. The old one-row layout remains as a compatibility fallback.
- Physical-phone launcher taps and OS background-worker delivery remain unverified end to end; callback persistence and native PendingIntent binding are tested separately. Existing boundary/five-minute refresh scheduling is preserved.

final result: passed
