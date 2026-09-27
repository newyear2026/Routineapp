import WidgetKit
import SwiftUI

private let kAppGroupId = "group.com.dayround.app"
private let kPayloadKey = "routine_widget_payload"
private let kWidgetKind = "RoutineMediumWidget"

/// 앱 팔레트 미러 — 기준은 `lib/widget_medium/widget_theme.dart`.
///
/// 값을 바꾸면 Dart · Android(`widget_colors.xml`, `RoutineWidgetRingBitmap.kt`)도
/// 함께 고쳐야 한다. 예전에는 여기만 브라운/테라코타 계열로 남아 있어서
/// 앱과 위젯이 다른 앱처럼 보였다.
private enum WidgetTokens {
    /// #F5EEDA
    static let background = Color(hex: 0xF5EEDA)
    /// #FFFFFF
    static let surface = Color(hex: 0xFFFFFF)
    /// #E5DCC8
    static let border = Color(hex: 0xE5DCC8)
    /// #221C42 — 배경 위 13.8:1
    static let textPrimary = Color(hex: 0x221C42)
    /// #6A6489 — 배경 위 4.77:1
    static let textMuted = Color(hex: 0x6A6489)
    /// #6744F4 — 흰 글자와 5.66:1
    static let accent = Color(hex: 0x6744F4)
    /// #E4DCFB
    static let ringTrack = Color(hex: 0xE4DCFB)
    static let dialSurface = Color(hex: 0xF3EDF9)
    static let labelSurface = Color(hex: 0xF0E9D9)
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

private struct RoutineEntry: TimelineEntry {
    let date: Date
    let payload: PayloadDto?
}

private struct Provider: TimelineProvider {
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

private struct RoutineMediumWidgetEntryView: View {
    var entry: RoutineEntry

    @ViewBuilder var body: some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(for: .widget) {
                WidgetTokens.background
            }
        } else {
            content
        }
    }

    private var content: some View {
        HStack(alignment: .center, spacing: 8) {
            leftColumn
            Rectangle()
                .fill(WidgetTokens.border)
                .frame(width: 1)
            RoutineRingView(payload: entry.payload)
                .frame(width: 124, height: 124)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(WidgetTokens.background)
        .overlay(PixelWidgetShape().stroke(WidgetTokens.textPrimary, lineWidth: 1.5))
    }

    /// 정보 위계: 상태·시간 → 루틴 이름 → 남은 시간 → 다음 일정.
    /// 위젯 이름이 이미 '하루 루틴 시간표'라 카드 안에서 제목을 반복하지 않는다.
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            // 시작·종료 시각은 싣지 않는다. 좁은 왼쪽 칸에서 배지와 나란히 두면
            // 잘리고, 아래 타이밍 힌트가 같은 것을 더 쓸모 있게 말한다.
            let status = entry.payload?.currentRoutineStatus ?? ""
            if !status.isEmpty {
                Text(status)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(WidgetTokens.accent)
                    .clipShape(PixelWidgetShape(step: 2, steps: 1))
                    .padding(.bottom, 7)
            }

            // 루틴의 정체성은 색상으로 표현한다 (Routine.iconEmoji 주석 참고).
            Text(entry.payload?.currentRoutineTitle ?? "앱을 열어 동기화해 주세요")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(WidgetTokens.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            let hint = entry.payload?.currentRoutineTimingHint ?? ""
            if !hint.isEmpty {
                timingText(hint)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 5)
            }

            Spacer(minLength: 0)
            Rectangle().fill(WidgetTokens.border).frame(height: 1)
                .padding(.bottom, 7)
            nextRoutineRow
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timingText(_ hint: String) -> Text {
        let end = hint.hasSuffix(" 남음") ? String(hint.dropLast(3)) : hint
        guard let range = end.range(of: #"\d+(?:시간\s*\d+)?분|\d+시간"#,
                                   options: .regularExpression) else {
            return Text(end).foregroundColor(WidgetTokens.accent)
                + Text(hint.hasSuffix(" 남음") ? " 남음" : "")
                    .foregroundColor(WidgetTokens.textMuted)
        }
        let prefix = String(end[..<range.lowerBound])
        let duration = String(end[range])
        let rest = String(end[range.upperBound...])
        return Text(prefix).foregroundColor(WidgetTokens.accent)
            + Text(duration).font(.system(size: 16, weight: .heavy))
                .foregroundColor(WidgetTokens.accent)
            + Text(rest).foregroundColor(WidgetTokens.accent)
            + Text(hint.hasSuffix(" 남음") ? " 남음" : "")
                .foregroundColor(WidgetTokens.textMuted)
    }

    private var nextRoutineRow: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(WidgetTokens.textMuted)
            Text("다음")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(WidgetTokens.textMuted)
            Text(entry.payload?.nextRoutineTitle ?? "없음")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(WidgetTokens.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(entry.payload?.nextRoutineTime ?? "")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(WidgetTokens.textMuted)
        }
    }
}

private struct PixelWidgetShape: Shape {
    var step: CGFloat = 3
    var steps: Int = 3

    func path(in rect: CGRect) -> Path {
        let cut = min(step * CGFloat(steps), min(rect.width, rect.height) / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        for i in 0..<steps {
            p.addLine(to: CGPoint(x: rect.maxX - cut + CGFloat(i + 1) * step,
                                  y: rect.minY + CGFloat(i) * step))
            p.addLine(to: CGPoint(x: rect.maxX - cut + CGFloat(i + 1) * step,
                                  y: rect.minY + CGFloat(i + 1) * step))
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        for i in 0..<steps {
            p.addLine(to: CGPoint(x: rect.maxX - CGFloat(i) * step,
                                  y: rect.maxY - cut + CGFloat(i + 1) * step))
            p.addLine(to: CGPoint(x: rect.maxX - CGFloat(i + 1) * step,
                                  y: rect.maxY - cut + CGFloat(i + 1) * step))
        }
        p.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        for i in 0..<steps {
            p.addLine(to: CGPoint(x: rect.minX + cut - CGFloat(i + 1) * step,
                                  y: rect.maxY - CGFloat(i) * step))
            p.addLine(to: CGPoint(x: rect.minX + cut - CGFloat(i + 1) * step,
                                  y: rect.maxY - CGFloat(i + 1) * step))
        }
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        for i in 0..<steps {
            p.addLine(to: CGPoint(x: rect.minX + CGFloat(i) * step,
                                  y: rect.minY + cut - CGFloat(i + 1) * step))
            p.addLine(to: CGPoint(x: rect.minX + CGFloat(i + 1) * step,
                                  y: rect.minY + cut - CGFloat(i + 1) * step))
        }
        p.closeSubpath()
        return p
    }
}

/// `OrbitRingPainter`(Dart)와 같은 형태 — 얇은 호 + 24시간 틱 + 세그먼트 간격.
/// 치수는 모두 referenceSize 292 기준 비례값이다.
private struct RoutineRingView: View {
    let payload: PayloadDto?

    private static let referenceSize: CGFloat = 150
    private static let radiusFactor: CGFloat = 0.395
    private static let gapRad = 0.05

    var body: some View {
        ZStack {
            PixelDialShape(radiusFactor: 0.48)
                .fill(WidgetTokens.dialSurface)
            PixelDialShape(radiusFactor: 0.48)
                .stroke(WidgetTokens.textPrimary, lineWidth: 1.5)
            PixelDialShape(radiusFactor: 0.335)
                .fill(WidgetTokens.surface)

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
                               style: StrokeStyle(lineWidth: trackStroke, lineCap: .butt))

                for hour in stride(from: 0, to: 24, by: 4) {
                    let a = angle(Double(hour) * 60)
                    let isMajor = hour % 12 == 0
                    let tickLength = (isMajor ? 9 : 6) * scale
                    let base = orbitRadius - trackStroke / 2 - 7 * scale
                    var tick = Path()
                    tick.move(to: CGPoint(x: c.x + cos(a) * base, y: c.y + sin(a) * base))
                    tick.addLine(to: CGPoint(x: c.x + cos(a) * (base - tickLength),
                                             y: c.y + sin(a) * (base - tickLength)))
                    context.stroke(
                        tick,
                        with: .color(WidgetTokens.textMuted.opacity(isMajor ? 0.34 : 0.18)),
                        style: StrokeStyle(lineWidth: (isMajor ? 2.6 : 1.8) * scale, lineCap: .butt)
                    )
                }

                let labels = [("00", CGPoint(x: c.x, y: c.y - w * 0.445)),
                              ("06", CGPoint(x: c.x + w * 0.445, y: c.y)),
                              ("12", CGPoint(x: c.x, y: c.y + w * 0.445)),
                              ("18", CGPoint(x: c.x - w * 0.445, y: c.y))]
                for (label, position) in labels {
                    context.draw(
                        Text(label)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(WidgetTokens.textPrimary),
                        at: position
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
                                   style: StrokeStyle(lineWidth: segmentStroke, lineCap: .butt))
                }

                if let ptr = payload?.pointerAngleRad {
                    let nowPoint = CGPoint(x: c.x + cos(ptr) * (orbitRadius + 4 * scale),
                                           y: c.y + sin(ptr) * (orbitRadius + 4 * scale))
                    var line = Path()
                    line.move(to: c)
                    line.addLine(to: nowPoint)
                    context.stroke(line, with: .color(WidgetTokens.accent.opacity(0.5)),
                                   lineWidth: 1.5 * scale)
                    context.fill(Path(CGRect(x: nowPoint.x - 6 * scale,
                                             y: nowPoint.y - 6 * scale,
                                             width: 12 * scale, height: 12 * scale)),
                                 with: .color(WidgetTokens.surface))
                    context.fill(Path(CGRect(x: nowPoint.x - 4 * scale,
                                             y: nowPoint.y - 4 * scale,
                                             width: 8 * scale, height: 8 * scale)),
                                 with: .color(WidgetTokens.accent))
                }
            }

            VStack(spacing: 3) {
                Text(String(format: "%02d:%02d",
                            payload?.currentTimeHour ?? 0,
                            payload?.currentTimeMinute ?? 0))
                    .font(.system(size: 23, weight: .heavy, design: .monospaced))
                    .foregroundColor(WidgetTokens.textPrimary)
                Text(payload?.centerTimeLabel ?? "지금")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(WidgetTokens.textMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(WidgetTokens.labelSurface)
                    .overlay(Rectangle().stroke(WidgetTokens.border, lineWidth: 0.7))
            }
        }
    }
}

private struct PixelDialShape: Shape {
    let radiusFactor: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) * radiusFactor
        let step: CGFloat = 2.5
        let cx = rect.midX
        let cy = rect.midY
        let rows = Int(ceil(radius / step))
        var right: [CGPoint] = []
        var left: [CGPoint] = []
        for i in -rows..<rows {
            let y = CGFloat(i) * step
            let middle = y + step / 2
            let half = floor(sqrt(max(0, radius * radius - middle * middle)) / step + 0.5) * step
            if half == 0 { continue }
            right += [CGPoint(x: cx + half, y: cy + y),
                      CGPoint(x: cx + half, y: cy + y + step)]
            left += [CGPoint(x: cx - half, y: cy + y),
                     CGPoint(x: cx - half, y: cy + y + step)]
        }
        var p = Path()
        guard let first = right.first else { return p }
        p.move(to: first)
        for point in Array(right.dropFirst()) + Array(left.reversed()) {
            p.addLine(to: point)
        }
        p.closeSubpath()
        return p
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
