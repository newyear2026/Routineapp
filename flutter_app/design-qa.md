# Routine icon design QA — 2026-09-21

## Scope and evidence

- Source visual truth: `/Users/jaewook/Downloads/Codex 이미지 2026년 9월 8일 오후 05_15_56.png` (841 × 1870 px).
- Rendered implementation: `output/design-qa/routine-icon-picker.png` (780 × 1688 px), captured from the current Flutter routine-add screen at a 390 × 844 logical-pixel viewport and device-pixel ratio 2. The reference has no recorded device scale; width-normalizing it to 390 logical pixels implies about 2.16 source pixels per logical pixel. The comparison concerns the icon-picker region rather than absolute full-page pixel alignment.
- Focused side-by-side evidence: `output/design-qa/routine-icon-comparison.png`, with the source on the left and rendered implementation on the right. Both crops retain their original pixels; the slightly different source density and scroll position are not treated as icon defects.
- State: more-settings expanded, first icon selected. The implementation preserves all 13 existing icon choices; the mockup shows five visible choices.

## Findings

- No actionable P0/P1/P2 visual mismatch remains in the requested icon set. The first five choices match the mockup's book, coffee, dumbbell, plant and paw subjects and order. Each has a stepped navy outline, interior shading and distinguishing details, and remains legible at the rendered picker size.
- P3: The generated icons have slightly more dimensional shading than the flatter mockup. This is acceptable for the requested extra detail, and the palette stays within the existing cream/lavender/navy design system.
- The 13-choice picker is taller than the five-choice mockup. Keeping the eight additional choices is intentional to preserve existing routine options and saved icon IDs.

## Required fidelity surfaces

- Typography and copy: unchanged from the existing Flutter screen; the picker heading and surrounding labels remain readable and do not wrap unexpectedly.
- Spacing/layout: first row now fits exactly five icons at 390 logical pixels. The preview and other routine surfaces retain their existing positions.
- Colors/tokens: selection outline remains purple; icon artwork uses cream, lavender and navy with subject-specific muted accents.
- Image quality: 13 transparent 128 × 128 PNG assets are bundled, each under 130 KB; `FilterQuality.none` keeps pixel edges crisp at small sizes.
- Content: existing icon IDs, saved values, labels, and routine behavior remain unchanged.

## Comparison history

1. Initial render used 56-pixel choice tiles, which fit only four icons per row (P2 mismatch against the mockup's five). Reduced tiles to 52 pixels and recaptured; five now fit in the first row.
2. The first render at 38-pixel artwork size looked slightly smaller than the source. Increased artwork to 42 pixels and recaptured the final implementation shown above.

## Validation and limits

- Flutter tests for icon assets, asset size, and routines passed.
- Targeted Flutter analysis found no issues.
- Rendered-widget verification passed at 390 × 844 logical pixels. This does not claim physical-device, screen-reader, or every text-scale state has been visually inspected.

final result: passed

---

# Routine, progress, and settings sky ornaments QA — 2026-09-22

## Scope and evidence

- Source visual truth for the routine screen: `/var/folders/1d/f_54vtrd34b966kbj7vfrncc0000gn/T/codex-clipboard-ec7c559f-2236-4a34-97cb-248f38832542.png` (853 × 1844 px), the user's selected list-screen proposal.
- Final implementation captures: `output/design-qa-menu-clouds-2026-09-22/routines.png`, `progress.png`, and `settings.png`, each rendered at 390 × 844 logical pixels and device-pixel ratio 2 (780 × 1688 px).
- Routine comparisons: `output/design-qa-menu-clouds-2026-09-22/routines-full-comparison.png` and the focused `routines-header-comparison.png`. The source was nearest-neighbor normalized to 780 × 1688 as `routines-target-normalized.png` before comparison.
- Three-screen review sheet: `output/design-qa-menu-clouds-2026-09-22/menu-clouds-contact-sheet.png`.
- State: Korean light theme on 2026-09-08; the routines screen contains five daily routines, progress shows rest as active, and settings shows the default cat theme. The progress and settings screens use the previously approved four-screen concept board as style direction rather than as exact state targets.

## Findings and comparison history

1. The routine header now reproduces the selected proposal's composition: a lavender pixel cloud at upper-left, layered clouds behind the reading cat, and sparse warm-gold stars. The title, subtitle, tabs, routine cards, and floating action remain unobstructed.
2. The progress header keeps its established information hierarchy and adds the same sky language around the existing cat. The ornament was enlarged slightly and repositioned so it reads as part of the header rather than as a detached background detail.
3. Settings now has a dedicated upper-right crescent-moon/cloud/star ornament and subtle clouds behind the current theme card. These additions preserve the card badge and settings controls as the primary content.
4. The first render captured before newly declared assets had decoded, so the render harness now pre-caches every decorative sky image. A later settings review found that a flipped copy of the progress ornament placed gold stars over the `사용 중` badge; it was replaced with a dedicated cloud-only card asset.
5. Final full, focused, and three-screen comparisons were inspected together. No actionable P0, P1, or P2 visual mismatch remains within the requested decorative scope. Intentional P3 differences are the real app's existing card heights and spacing, which are data-driven and were not replaced with mock-only geometry.

## Required fidelity surfaces

- Typography and copy: existing localized Korean text, type scale, and pixel-number styles are unchanged.
- Spacing/layout: decorations are isolated to the header/card backgrounds and do not alter navigation, touch targets, scrolling, or content order.
- Colors/tokens: pale two-tone lavender clouds, warm gold stars, purple accents, navy borders, and the cream background remain consistent across all three menus.
- Image quality: transparent RGBA assets are rendered with nearest-neighbor filtering for crisp pixel edges. No reference UI, text, cat, or card content is baked into an ornament.
- Content and behavior: routines, progress state, settings values, actions, and existing update/review logic remain driven by the app.

## Image generation provenance

- Mode: built-in image generation, followed only by nearest-neighbor resizing for application assets.
- Final prompt set:
  - `routines-sky.png`: create a transparent wide pixel-art routine-header ornament based on the selected list-screen proposal and the app's existing sky palette, with an upper-left lavender cloud, layered clouds around the cat zone, four sparse gold stars, and a clear left text area; exclude UI, text, cards, and characters.
  - `settings-sky.png`: create a transparent upper-right settings ornament based on the approved four-screen concept, with a gold crescent moon, layered lavender clouds, and two small stars while keeping the left title area clear; exclude UI, text, and characters.
  - `settings-card-cloud.png`: create one isolated transparent lavender two-tone pixel cloud for a settings card, with no moon, stars, text, outline, or other object.
- Final assets: `assets/decorations/routines-sky.png` (384 × 158), `assets/decorations/settings-sky.png` (180 × 110), and `assets/decorations/settings-card-cloud.png` (96 × 48).

## Validation and limits

- Targeted Flutter analysis reported no issues. The routine/progress, settings, and asset-budget tests all passed (26 tests), and the render harness passed at 390 × 844 plus its compact/text-scale checks.
- The full Flutter suite passed all 391 tests and `git diff --check` passed. Full-project analysis reports only three existing informational lints in `tool/generate_store_screenshots.dart`; the files changed for this visual work remain clean.
- This is a Flutter test-rendered comparison rather than a physical-device capture.

final result: passed

---

# Home ring icon implementation QA — 2026-09-21

## Scope and evidence

- Source visual truth: `/Users/jaewook/.codex/generated_images/01a0a616-b54f-7f32-a972-3536d3b82911/exec-8d48dd1a-8911-42b0-96bf-86139d57d633.png` (853 × 1844 px).
- Rendered implementation: `output/design-qa/home-ring-icons.png` (1170 × 2532 px), captured from the Flutter home screen at 390 × 844 logical pixels and device-pixel ratio 3.
- Full-view comparison: `output/design-qa/home-ring-icons-comparison.png`. The implementation was normalized to 853 × 1844 px for comparison against the generated image.
- Focused ring comparison: `output/design-qa/home-ring-icons-focused-comparison.png`, cropped from the same normalized side-by-side image.
- State: five example routines on 2026-09-08 at 15:14, rest active, Korean locale, light theme. The reference image was generated from this screen but assigned illustrative icons to arcs independently of the saved routine data. The implementation intentionally shows each actual saved routine icon at the midpoint of its own arc.

## Findings

- No actionable P0/P1/P2 visual mismatch remains for the requested change. Five compact pixel icon badges appear just inside their corresponding colored arcs, without obscuring the center clock, hour labels, current-time pointer, or adjacent badges.
- The badge subjects and angular positions differ from the generated mock because the mock's illustrative icon-to-arc assignments did not match the actual example routine IDs. Using the saved `Routine.iconId` and real routine schedule is required behavior, not design drift.
- P3: At small ring sizes, detailed artwork is necessarily reduced. The source PNG assets remain legible with nearest-neighbor filtering; the routine card and list retain larger versions.

## Required fidelity surfaces

- Typography and copy: existing Korean fonts, hierarchy, text content, and wrapping are unchanged.
- Spacing/layout: home regions, ring diameter, position, cat, plant, cards, and controls are unchanged. Badge centers sit at 30.5% of dial width from center, just inside the arc.
- Colors/tokens: existing routine arc colors stay intact. Badge fill is white with navy outline; the active badge uses the existing purple accent.
- Image quality: badges reuse the exact transparent `assets/routine_icons/*.png` artworks used elsewhere in the app, with `FilterQuality.none` through `RoutineMark`.
- Content: each badge uses its routine's stored `iconId`; no synthetic icon inference is performed by the ring. Segments under 30 minutes or without room for a non-overlapping badge retain their color arc without an icon.

## Comparison history and validation

1. Initial implementation capture was compared against the selected mock at the same 390 × 844 logical viewport. The full-view and focused comparison found no actionable P0/P1/P2 visual issue; no visual correction cycle was needed.
2. `flutter test test/routine_ring_icon_layout_test.dart test/home_screen_test.dart` passed, including stored-icon propagation, active-routine collision priority, and small-screen layout. The full `flutter test` suite also passed (344 tests), and `flutter analyze` reported no issues.
3. This is a Flutter test-rendered screen, not a physical-device capture. Physical-device and screen-reader verification remain outside this QA pass.

final result: passed

---

# Home ring centered-time QA — 2026-09-21

## Scope and evidence

- Source visual truth: `output/design-qa/home-time-before.png` (1170 × 2532 px), the user's current-home screenshot with the central `지금` badge.
- Rendered implementation: `output/design-qa/home-time-centered.png` (1170 × 2532 px), captured from the Flutter home screen at a 390 × 844 logical-pixel viewport and device-pixel ratio 3.
- Full-view side-by-side: `output/design-qa/home-time-centered-comparison.png`; focused ring comparison: `output/design-qa/home-time-centered-focused.png`. Both sides retain their 1170 × 2532 source pixels without scaling.
- State: Korean light-theme home, five example routines on 2026-09-08 at 15:14, with rest active. The requested edit is limited to the home ring center; the surrounding cards, icons, and controls are kept.

## Findings

- No actionable P0/P1/P2 visual mismatch remains. The `지금` badge is absent, and the clock text is vertically centered in the dial instead of sitting above a badge.
- The dial arcs, routine icon badges, current-time pointer, hour markers, decorations, and home controls remain in place.
- The visual badge is removed only on the home screen. Other uses of the circular timetable keep their existing default. Screen-reader semantics still announce the time as `지금 12:30` in the tested state.

## Required fidelity surfaces

- Typography and copy: the clock's font, size, and text format are unchanged; only the redundant visual `지금` copy is removed.
- Spacing/layout: the time text is centered within the existing dial; dial size and surrounding vertical spacing are unchanged.
- Colors/tokens: existing cream, navy, purple, and routine arc colors are unchanged.
- Image quality: routine icon assets and nearest-neighbor rendering are unchanged.
- Content: routine order, icon assignment, active routine, and action labels are unchanged.

## Validation and limits

- The new home widget test checks badge absence, time-text center alignment within 1 logical pixel, and accessible current-time semantics.
- `flutter test` passed all 345 tests. Targeted `flutter analyze` for the three edited Dart files found no issues; full-app analysis reports three unrelated informational lints in the untracked store-screenshot generator.
- The final screenshot was visually inspected against the supplied screenshot. This is a Flutter test-rendered screen, not a physical-device capture.

final result: passed

---

# Bottom navigation icon polish QA — 2026-09-21

## Scope and evidence

- Source visual truth: `output/design-qa/home-time-centered.png` (1170 × 2532 px), the existing home screen before this tab-icon change.
- Rendered implementation: `output/design-qa/home-nav-icons-updated.png` (1170 × 2532 px), the updated Flutter home at a 390 × 844 logical-pixel viewport and device-pixel ratio 3.
- Full-view comparison: `output/design-qa/home-nav-icons-comparison.png`; focused bottom-navigation comparison: `output/design-qa/home-nav-icons-focused.png`. Both sides use the same 1170 × 2532 pixel density without scaling.
- Selected-state evidence: `output/design-qa/home-nav-icons-all-states.png`, a 2 × 2 montage of home, progress, routines, and settings tab strips. The home capture was reduced from 3× to 2× with nearest-neighbor sampling to match the other screens' 780 × 1688 px captures.
- State: Korean light theme, sample routine data, and each of the four tabs active in turn. This is a constrained icon refresh, not a navigation layout redesign.

## Findings

- No actionable P0/P1/P2 visual mismatch remains. The four 24-logical-pixel icons retain their positions and pixel rendering while using clearer subjects: house with a defined doorway, partly filled progress circle, checkbox-style routine list, and balanced adjustment sliders.
- The selected icon and label still use the purple accent, top indicator, and pale background. Unselected items remain muted gray. The active-state montage shows all four selected treatments without clipping or alignment drift.
- The new glyphs are bottom-navigation-only. The shared progress icon used elsewhere, including the medium widget, and the settings icon used in other controls remain unchanged.

## Required fidelity surfaces

- Typography and copy: the Korean tab labels, font, size, weight, and truncation remain unchanged.
- Spacing/layout: four equal-width hit areas, icon size, icon-to-label gap, bar height, and safe-area handling remain unchanged.
- Colors/tokens: existing purple selection and muted-gray idle colors remain unchanged.
- Image quality: all four icons render as sharp pixels without blur at the captured density; no new raster assets are introduced.
- Content: tab order and destinations remain home, progress, routines, settings; labels and navigation semantics remain unchanged.

## Validation and limits

- The bottom-navigation widget test checks the four dedicated glyphs and all four tap callbacks. `flutter test` passed all 346 tests, and targeted `flutter analyze` found no issues.
- The full view, focused before/after strip, and all active states were visually inspected. These are Flutter test-rendered captures, not physical-device captures.

final result: passed

---

# Home cat and circular timetable spacing QA — 2026-09-21

## Scope and evidence

- Source visual truth: `output/design-qa/home-cat-concept-source.png` (1536 × 1024 px), the user's earlier four-screen concept board. Its first home-phone panel is the reference for cat-to-dial scale and overlap, not for a whole-screen pixel-perfect clone.
- Before state: `output/design-qa/home-cat-before.png` (1170 × 2532 px), the user's actual home screenshot showing a small cat nearly detached from the dial.
- Final implementation: `output/design-qa/home-cat-final.png` (1170 × 2532 px), captured from the Flutter home at 390 × 844 logical pixels and device-pixel ratio 3.
- Full-view comparison: `output/design-qa/home-cat-final-full-comparison.png`; focused before/final/concept comparison: `output/design-qa/home-cat-final-focused-comparison.png`. The concept's first phone was cropped to 364 × 860 px. The implementation was width-normalized to 364 × 788 px and padded vertically for the full-view comparison; the 364 × 292 px hero crops retain their aspect ratios. Concept capture density is unknown, so the focused comparison judges relative proportions and overlap rather than exact pixels.
- State: Korean light theme, rest routine active at 15:14, sleeping cat pose. Dial and existing cat artwork are unchanged.

## Findings

- No actionable P0/P1/P2 mismatch remains for the requested relationship. The dial stays the same size; the sleeping cat is visibly larger, sits toward the right screen edge, and overlaps the dial's lower-right edge enough to read as one composition.
- The cat does not cover the clock, hour labels, or routine icon badges. Its lower edge remains clear of the primary action button in the final home capture.
- P3: The older concept uses a thinner circular timetable and different surrounding illustrations, which were not in scope for this cat-spacing adjustment.

## Required fidelity surfaces

- Typography and copy: clock, card, action, and navigation text are unchanged.
- Spacing/layout: dial diameter and center are unchanged. The cat display box scales with scene width up to 132 logical pixels, shifts toward the right edge, and the scene height reduces from 0.93 to 0.89 of its width so the cat and action bar sit closer to the dial.
- Colors/tokens: no colors or selection states changed.
- Image quality: the existing approved cat PNG and nearest-neighbor filtering are reused; no cropped or stretched substitute was introduced.
- Content: routine schedule, icons, cat pose selection, and action labels remain unchanged.

## Comparison history and validation

1. Initial enlargement to roughly 130 logical pixels made the cat's width close to the concept, but the focused comparison still showed excess vertical distance between dial, cat, and button (P2). Evidence: `output/design-qa/home-cat-enlarged.png` and `output/design-qa/home-cat-focused-comparison.png`.
2. Reduced only the scene's vertical space, recaptured, and compared again against the same reference. The final focused comparison shows the cat rising into the dial's lower-right edge without moving or enlarging the dial.
3. The 390-pixel and 320-pixel widget checks cover cat/dial overlap, viewport edge, and button clearance. Targeted Flutter analysis found no issues; all 347 Flutter tests passed.
4. This is a Flutter test-rendered screen. The activity pose has geometry coverage on the narrow-screen test; other poses, physical-device appearance, and screen-reader behavior were not visually verified here.

final result: passed

---

# Home plant placement QA — 2026-09-21

## Scope and evidence

- Source visual truth: `output/design-qa/home-plant-before.png` (1170 × 2532 px), the current home screen showing the plant too small and isolated from the dial, together with the user's approved direction to enlarge it, move it toward the dial, and ground it with the cat.
- Rendered implementation: `output/design-qa/home-plant-adjusted.png` (1170 × 2532 px), the Flutter home at 390 × 844 logical pixels and device-pixel ratio 3.
- Full-view side-by-side: `output/design-qa/home-plant-full-comparison.png`; focused hero side-by-side: `output/design-qa/home-plant-focused-comparison.png`, using matching 1170 × 1000 px crops from both captures. No density or scale normalization was needed because both images have the same pixel dimensions and capture settings.
- State: Korean light-theme home, 2026-09-08 at 15:14, rest routine active, sleeping cat pose. Only the home plant placement and display size changed.

## Findings and comparison history

1. Baseline P2: the 54-logical-pixel plant was pinned to the scene's far left and floated above the cat's ground line, leaving excessive empty space between plant and timetable. Evidence: the left halves of the full and focused comparisons.
2. The existing plant PNG is now displayed up to 68 logical pixels, inset by 8% of scene width toward the timetable, and bottom-aligned with the cat's layout box. The right halves of the same comparisons show a closer plant-to-dial relationship without covering the `18` marker, routine badges, cat, or action button.
3. No actionable P0/P1/P2 mismatch remains in the final capture. The plant remains secondary to the dial and cat, and the rest of the page composition is unchanged.

## Required fidelity surfaces

- Typography and copy: date, title, dial text, routine card, buttons, and navigation labels retain their fonts, weights, sizes, wrapping, and wording.
- Spacing/layout: only the home plant's size, horizontal inset, and baseline changed; dial and cat sizes and positions remain fixed. The hero stays clear of the primary action button.
- Colors/tokens: cream background, navy outlines, purple accents, and routine colors are unchanged.
- Image quality: the existing pixel-art plant asset is reused with nearest-neighbor filtering, its aspect ratio preserved, and no visible blur or transparent edge introduced.
- Content: routine state, icons, cat pose, labels, and navigation destinations are unchanged.

## Validation and limits

- Widget geometry checks pass at 390 × 844 and 320 × 700 logical-pixel viewports, including plant-to-dial position, ground alignment with the cat, and button clearance.
- Targeted Flutter analysis found no issues; all 347 Flutter tests passed. The full and focused comparison images were visually inspected together.
- This is a Flutter test-rendered capture, not a physical-device capture. Other device densities and cat poses were not visually captured in this QA pass.

final result: passed

---

# Progress screen, selected concept 2 QA — 2026-09-22

## Scope and evidence

- Source visual truth: `output/progress-design-review/concept-2-current-first.png` (853 × 1844 px), the user's selected second proposal. The date and calendar button visible in that concept are explicit exclusions requested by the user.
- Final implementation: `output/design-qa/progress-option2-final-with-sky.png` (780 × 1688 px), rendered at 390 × 844 logical pixels, device-pixel ratio 2. The concept was normalized to 780 × 1688 with nearest-neighbor scaling in `output/design-qa/progress-option2-target-normalized.png` for composition review; its source aspect ratio differs slightly, so exact pixel coordinates are not a fidelity criterion.
- Full side-by-side: `output/design-qa/progress-option2-with-sky-full-comparison.png`; focused side-by-side: `output/design-qa/progress-option2-with-sky-focused-comparison.png`, with matching 780 × 1150 crops starting at y = 250. Both comparisons were inspected after the final top-padding adjustment.
- State: Korean light theme at 2026-09-21 15:14, three routines total (wake expired, rest active, dinner upcoming), zero completed. The missed wake routine is real data and begins below the fold, unlike the simplified concept.

## Findings and comparison history

1. The requested information order now matches the selected proposal: title and cat, active rest routine, compact three-segment `오늘 0 / 3 · 0%` summary, completed group, and upcoming dinner. The date and calendar button are absent. The progress tab retains the same 48-logical-pixel top padding as the other three tabs.
2. First visual comparison found a P2 summary hierarchy difference: `0%` was separated to the right instead of grouped with `0 / 3`. It was moved beside the count and recaptured.
3. The next comparison found a P2/P3 decorative gap around the cat. A small transparent pixel-art sky asset adds lavender clouds and star accents behind the existing approved cat. The final full and focused comparisons show no overlap with the title or cat and no actionable P0/P1/P2 mismatch for the requested layout.
4. P3 intentional differences remain: the generated concept has a diffuse cream glow and some larger decorative clouds; the implementation uses the app's existing flat cream token and sharper pixel art. The concept omits the missed group, while the real screen keeps it scrollable rather than hiding routine state.

## Required fidelity surfaces

- Typography and copy: existing Korean app type styles and pixel-number style are reused. Progress copy is localized; the user-requested date/calendar copy is removed from this screen only.
- Spacing/layout: active item appears before the summary; the summary is vertically stacked; the upcoming dinner card remains visible above bottom navigation at 390 × 844. Tab top padding is consistent at 48 logical pixels.
- Colors/tokens: cream background, navy text/borders, purple status and navigation accents, and pale segmented-bar fill use established app tokens.
- Image quality: the approved cat PNG is retained; only the transparent cloud/star decoration is new. Both use nearest-neighbor filtering and render with crisp pixel edges without clipping.
- Content: counts and routine states come from the real controller. Wake is shown in the missed group below the initial viewport, rest is active, and dinner is scheduled; no mock-only values are hardcoded into the screen.

## Validation and limits

- A 390 × 844 widget test verifies absent date/calendar controls, active-before-summary order, and dinner visibility. The rendering harness passes at 390 × 844 and 320 × 700 with 1.5× text scale; the latter is layout coverage, not a screenshot comparison.
- Targeted Flutter analysis found no issues, `git diff --check` passed, and all 343 Flutter tests passed. The first full-suite run exposed the top-padding mismatch; it was corrected and the suite rerun successfully.
- This is a Flutter test-rendered capture, not a physical-device capture. Other device densities, locales, and cat poses were not visually captured in this QA pass.

final result: passed

---

# Home cloud ornament QA — 2026-09-22

## Scope and evidence

- Source visual truth: `output/design-qa-home-cloud-2026-09-22/reference-concept.png` (1536 × 1024 px), specifically the lavender-filled clouds and small gold stars around the circular timetable in the first phone. The rest of that generated four-screen board is not a 1:1 target for this scoped cloud change.
- Baseline: `output/design-qa-home-cloud-2026-09-22/reference-before.png` (1170 × 2532 px), the user's current home screenshot with thin beige outline clouds and simple purple crosses.
- Final implementation: `output/design-qa-home-cloud-2026-09-22/home.png` (1170 × 2532 px), rendered at 390 × 844 logical pixels, device-pixel ratio 3, Korean light theme, 2026-09-08 15:14 with rest active.
- Full-view comparison: `output/design-qa-home-cloud-2026-09-22/home-cloud-full-comparison.png` (1170 × 844 px), ordered concept/before/after. The concept's first-phone crop (363 × 861) and both app captures were normalized to 390 × 844 for composition review; the concept includes different phone chrome and layout, so exact coordinates outside the hero are not compared.
- Focused comparison: `output/design-qa-home-cloud-2026-09-22/home-cloud-focused-comparison.png` (1083 × 284 px), ordered concept/before/after. The concept crop is x=23..384, y=416..700; same-state app hero crops are x=0..1170, y=650..1570 and width-normalized to 361 × 284. This compares the cloud/dial/cat relationship, not text metrics.

## Findings and comparison history

1. Baseline P2: two hollow cream clouds with beige outlines read like schematic placeholders next to the detailed cat and routine icons. The concept uses filled, softly layered lavender pixel silhouettes and small warm-gold sparkles.
2. A new transparent `assets/decorations/home-sky.png` (374 × 333 px, about 15 KB) replaces the two cloud painters and two cross painters. It uses three lavender two-tone clouds and sparse gold stars around an empty central dial-safe area. The asset is placed behind the existing ring, plant, and cat; those components and their geometry are unchanged.
3. The final full and focused comparisons were viewed together. Clouds have a more finished, concept-aligned pixel-art style without covering the clock numbers, routine marks, plant, cat, or primary action. No actionable P0/P1/P2 mismatch remains for the requested cloud treatment.
4. P3 intentional difference: the concept has additional moon and background glow, while the implementation keeps the established flat cream app background and no new moon because the user specifically identified cloud quality.

## Required fidelity surfaces

- Typography and copy: no text, font, number, or copy changed.
- Spacing/layout: no clock, cat, plant, card, or action placement changed; the new transparent ornament scales with the existing 374:333 home scene.
- Colors/tokens: cloud lavender and gold sparkles follow the concept and established decorative palette; the cream page, navy outlines, and purple routine accents remain unchanged.
- Image quality: a generated transparent RGBA raster is downsampled with nearest-neighbor filtering and displayed without Flutter interpolation. Clouds have filled stepped pixel edges rather than code-drawn outlines. The center stays transparent so the ring remains readable.
- Content: current routine, schedule, actions, and cat pose are unchanged.

## Image generation provenance

- Mode: built-in image generation, not CLI/API. Inputs were the user's four-phone concept board as a style/composition reference and the app's existing `progress-sky.png` as a palette/pixel-edge reference; neither input was edited.
- Final prompt (verbatim):

```text
Use case: stylized-concept.
Asset type: transparent pixel-art decorative overlay for the existing Flutter home circular-timetable scene, approximately a 374 x 300 logical-pixel wide composition. This is a NEW isolated asset, not an edit of either input image.
Input images: Image 1 is the user's four-phone concept board; use ONLY the lavender filled clouds and tiny golden stars around the dial in its FIRST (leftmost) phone as the target art direction and approximate spatial arrangement. Image 2 is an existing small transparent pixel cloud/star ornament from the same app; use as palette and pixel-edge reference.
Primary request: Create several beautiful, polished 2D pixel-art cloud silhouettes in pale lavender, with stepped/scalloped blocky edges, two subtly different lavender tones within each cloud, and a few sparse four-point gold stars. Place a small cloud near the upper-right edge, a cloud entering from the mid-left edge, another near the lower-left edge, plus tiny accents in the side margins. Keep the large central circular area completely empty and genuinely transparent so the app's existing clock dial is readable when composited on top. Keep the upper and lower center largely empty as well. The atmosphere should feel airy, delicate, cute and retro-game pixel art, visually close to the reference rather than flat schematic outlines.
Color palette: pale lavender/lilac clouds like #D3C9F6 and #BFC3FF; tiny warm golden-yellow stars like #FFB93F. No dark outlines.
Output: one wide transparent RGBA ornament with hard, crisp square pixel edges. No background color, checkerboard, glow, blur, shadows, gradients, antialiasing, text, labels, UI, phone frame, dial, cat, moon, plant, buttons, or extra objects.
```
- The original generated 1401 × 1123 RGBA was mechanically nearest-neighbor downsampled and padded transparently to the app asset. No part of the reference phone screen was copied into the asset.

## Validation and limits

- The Flutter render harness passed at 390 × 844 and its 320 × 700 / 1.5× text-scale layout check. Targeted Flutter analysis found no issues; all 343 Flutter tests passed and `git diff --check` passed.
- This is a Flutter test-rendered capture, not a physical-device capture. Other display densities and cat poses were not visually captured in this pass.

final result: passed
