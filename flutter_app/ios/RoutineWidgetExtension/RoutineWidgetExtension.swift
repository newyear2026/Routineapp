import WidgetKit
import SwiftUI

private let kAppGroupId = "group.com.example.routineTimer"
private let kPayloadKey = "routine_widget_payload"
private let kWidgetKind = "RoutineMediumWidget"

/// 앱 팔레트 미러 — 기준은 `lib/widget_medium/widget_theme.dart`.
///
/// 값을 바꾸면 Dart · Android(`widget_colors.xml`, `RoutineWidgetRingBitmap.kt`)도
/// 함께 고쳐야 한다. 예전에는 여기만 브라운/테라코타 계열로 남아 있어서
/// 앱과 위젯이 다른 앱처럼 보였다.
private enum WidgetTokens {
    /// #EEE8DE
    static let background = Color(hex: 0xEEE8DE)
    /// #FFFFFF
    static let surface = Color(hex: 0xFFFFFF)
    /// #DCD3C4
    static let border = Color(hex: 0xDCD3C4)
    /// #241F31 — 배경 위 13.6:1
    static let textPrimary = Color(hex: 0x241F31)
    /// #6B6478 — 배경 위 4.63:1
    static let textMuted = Color(hex: 0x6B6478)
    /// #6744F4 — 흰 글자와 5.66:1
    static let accent = Color(hex: 0x6744F4)
    /// #D9D1F2
    static let ringTrack = Color(hex: 0xD9D1F2)
}

private struct RingSegDto: Codable {
    let id: String
    let startMinutesFromMidnight: Int
    let sweepMinutes: Int
    let colorArgb: Int
}

/// 페이로드 스키마가 올라가도 위젯이 빈 화면으로 죽지 않도록 전부 옵셔널로 읽는다.
private struct PayloadDto: Codable {
    let schemaVersion: Int?
    let currentRoutineTitle: String?
    let currentRoutineStatus: String?
    let currentRoutineTimingHint: String?
    let nextRoutineTitle: String?
    let nextRoutineTime: String?
    let currentTimeHour: Int?
    let currentTimeMinute: Int?
    let pointerAngleRad: Double?
    let centerTimeLabel: String?
    let ringSegments: [RingSegDto]?
    let activeSegmentId: String?
}

private func loadPayload() -> PayloadDto? {
    guard let defaults = UserDefaults(suiteName: kAppGroupId),
          let json = defaults.string(forKey: kPayloadKey),
          let data = json.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(PayloadDto.self, from: data)
}

struct RoutineEntry: TimelineEntry {
    let date: Date
    let payload: PayloadDto?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RoutineEntry {
        RoutineEntry(date: Date(), payload: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RoutineEntry) -> Void) {
        completion(RoutineEntry(date: Date(), payload: loadPayload()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoutineEntry>) -> Void) {
        let entry = RoutineEntry(date: Date(), payload: loadPayload())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }
}

struct RoutineMediumWidgetEntryView: View {
    var entry: RoutineEntry

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            leftColumn
            Spacer(minLength: 0)
            RoutineRingView(payload: entry.payload)
                .frame(width: 96, height: 96)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            WidgetTokens.background
        }
    }

    /// 정보 위계: 상태·시간 → 루틴 이름 → 남은 시간 → 다음 일정.
    /// 위젯 이름이 이미 '하루 루틴 시간표'라 카드 안에서 제목을 반복하지 않는다.
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 시작·종료 시각은 싣지 않는다. 좁은 왼쪽 칸에서 배지와 나란히 두면
            // 잘리고, 아래 타이밍 힌트가 같은 것을 더 쓸모 있게 말한다.
            let status = entry.payload?.currentRoutineStatus ?? ""
            if !status.isEmpty {
                Text(status)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(WidgetTokens.accent)
                    .clipShape(Capsule())
                    .padding(.bottom, 6)
            }

            // 루틴의 정체성은 색상으로 표현한다 (Routine.iconEmoji 주석 참고).
            Text(entry.payload?.currentRoutineTitle ?? "앱을 열어 동기화해 주세요")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(WidgetTokens.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            let hint = entry.payload?.currentRoutineTimingHint ?? ""
            if !hint.isEmpty {
                Text(hint)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(WidgetTokens.textMuted)
                    .lineLimit(1)
                    .padding(.top, 4)
            }

            nextRoutineChip
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nextRoutineChip: some View {
        HStack(spacing: 8) {
            Text("다음")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(WidgetTokens.textMuted)
            Text(entry.payload?.nextRoutineTitle ?? "없음")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(WidgetTokens.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(entry.payload?.nextRoutineTime ?? "")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(WidgetTokens.textMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(WidgetTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(WidgetTokens.border, lineWidth: 1)
        )
    }
}

/// `OrbitRingPainter`(Dart)와 같은 형태 — 얇은 호 + 24시간 틱 + 세그먼트 간격.
/// 치수는 모두 referenceSize 292 기준 비례값이다.
private struct RoutineRingView: View {
    let payload: PayloadDto?

    private static let referenceSize: CGFloat = 292
    private static let radiusFactor: CGFloat = 0.40
    private static let gapRad = 0.04

    var body: some View {
        ZStack {
            Circle().fill(WidgetTokens.surface)

            Canvas { context, size in
                let w = min(size.width, size.height)
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let scale = w / Self.referenceSize
                let orbitRadius = w * Self.radiusFactor
                let segmentStroke = 11 * scale
                let trackStroke = 9 * scale
                let minPerDay = 24 * 60.0

                func angle(_ minutes: Double) -> Double {
                    minutes / minPerDay * 2 * .pi - .pi / 2
                }

                var track = Path()
                track.addArc(center: c, radius: orbitRadius,
                             startAngle: .radians(-.pi / 2),
                             endAngle: .radians(3 * .pi / 2),
                             clockwise: false)
                context.stroke(track, with: .color(WidgetTokens.ringTrack),
                               style: StrokeStyle(lineWidth: trackStroke, lineCap: .round))

                for hour in 0..<24 {
                    let a = angle(Double(hour) * 60)
                    let isMajor = hour % 6 == 0
                    let tickLength = (isMajor ? 11 : 6) * scale
                    let base = orbitRadius - trackStroke / 2 - 10 * scale
                    var tick = Path()
                    tick.move(to: CGPoint(x: c.x + cos(a) * base, y: c.y + sin(a) * base))
                    tick.addLine(to: CGPoint(x: c.x + cos(a) * (base - tickLength),
                                             y: c.y + sin(a) * (base - tickLength)))
                    context.stroke(
                        tick,
                        with: .color(WidgetTokens.textMuted.opacity(isMajor ? 0.34 : 0.18)),
                        style: StrokeStyle(lineWidth: (isMajor ? 2.4 : 1.3) * scale, lineCap: .round)
                    )
                }

                for seg in payload?.ringSegments ?? [] {
                    let sweep = Double(seg.sweepMinutes) / minPerDay * 2 * .pi
                    if sweep <= 0 { continue }
                    let start = angle(Double(seg.startMinutesFromMidnight)) + Self.gapRad
                    let safeSweep = max(0.02, sweep - Self.gapRad * 2)
                    var arc = Path()
                    arc.addArc(center: c, radius: orbitRadius,
                               startAngle: .radians(start),
                               endAngle: .radians(start + safeSweep),
                               clockwise: false)
                    context.stroke(arc, with: .color(Color(argb: seg.colorArgb)),
                                   style: StrokeStyle(lineWidth: segmentStroke, lineCap: .round))
                }

                if let ptr = payload?.pointerAngleRad {
                    let nowPoint = CGPoint(x: c.x + cos(ptr) * (orbitRadius + 4 * scale),
                                           y: c.y + sin(ptr) * (orbitRadius + 4 * scale))
                    var line = Path()
                    line.move(to: c)
                    line.addLine(to: nowPoint)
                    context.stroke(line, with: .color(WidgetTokens.accent.opacity(0.5)),
                                   lineWidth: 1.5 * scale)
                    context.fill(
                        Path(ellipseIn: CGRect(x: nowPoint.x - 7 * scale, y: nowPoint.y - 7 * scale,
                                               width: 14 * scale, height: 14 * scale)),
                        with: .color(WidgetTokens.surface)
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(x: nowPoint.x - 4.5 * scale, y: nowPoint.y - 4.5 * scale,
                                               width: 9 * scale, height: 9 * scale)),
                        with: .color(WidgetTokens.accent)
                    )
                }
            }

            VStack(spacing: 3) {
                Text(String(format: "%02d:%02d",
                            payload?.currentTimeHour ?? 0,
                            payload?.currentTimeMinute ?? 0))
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(WidgetTokens.textPrimary)
                Text(payload?.centerTimeLabel ?? "지금")
                    .font(.system(size: 11, weight: .heavy))
                    .kerning(1.1)
                    .foregroundColor(WidgetTokens.textMuted)
            }
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1
        )
    }

    init(argb: Int) {
        let u = UInt32(truncatingIfNeeded: argb)
        let a = Double((u >> 24) & 0xFF) / 255.0
        let r = Double((u >> 16) & 0xFF) / 255.0
        let g = Double((u >> 8) & 0xFF) / 255.0
        let b = Double(u & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a == 0 ? 1 : a)
    }
}

struct RoutineMediumWidget: Widget {
    let kind: String = kWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RoutineMediumWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("하루 루틴 시간표")
        .description("현재 루틴·시간·다음 루틴")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct RoutineWidgetBundle: WidgetBundle {
    var body: some Widget {
        RoutineMediumWidget()
    }
}
