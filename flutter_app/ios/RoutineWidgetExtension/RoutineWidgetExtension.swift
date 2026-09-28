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

private enum PackArtwork {
    static func image(_ name: String) -> Image {
        guard let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Artwork"),
              let uiImage = UIImage(contentsOfFile: path) else { return Image(systemName: "sparkle") }
        return Image(uiImage: uiImage)
    }
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
    let characterPackId: String?
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
    let nextLabel: String?
    let refreshHint: String?
    let validUntilEpochMs: Int64?
    let timelineStates: [WidgetStateDto]?
    let timingStartTemplate: String?
    let timingEndTemplate: String?
    let durationHoursMinutesTemplate: String?
    let durationHoursTemplate: String?
    let durationMinutesTemplate: String?
}

private struct WidgetStateDto: Codable {
    let effectiveAtEpochMs: Int64?
    let currentRoutineTitle: String?
    let currentRoutineStatus: String?
    let currentRoutineTimingHint: String?
    let nextRoutineTitle: String?
    let nextRoutineTime: String?
    let centerTimeLabel: String?
    let ringSegments: [RingSegDto]?
    let activeSegmentId: String?
    let timingTargetEpochMs: Int64?
    let timingMode: String?
}

private func stateAt(_ payload: PayloadDto?, date: Date) -> WidgetStateDto? {
    guard let payload = payload else { return nil }
    if let states = payload.timelineStates, !states.isEmpty {
        let nowMs = Int64(date.timeIntervalSince1970 * 1000)
        return states.last(where: { ($0.effectiveAtEpochMs ?? Int64.max) <= nowMs })
    }
    return WidgetStateDto(
        effectiveAtEpochMs: nil,
        currentRoutineTitle: payload.currentRoutineTitle,
        currentRoutineStatus: payload.currentRoutineStatus,
        currentRoutineTimingHint: payload.currentRoutineTimingHint,
        nextRoutineTitle: payload.nextRoutineTitle,
        nextRoutineTime: payload.nextRoutineTime,
        centerTimeLabel: payload.centerTimeLabel,
        ringSegments: payload.ringSegments,
        activeSegmentId: payload.activeSegmentId,
        timingTargetEpochMs: nil,
        timingMode: nil
    )
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
    let state: WidgetStateDto?
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RoutineEntry {
        RoutineEntry(date: Date(), payload: nil, state: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RoutineEntry) -> Void) {
        let date = Date()
        let payload = loadPayload()
        completion(RoutineEntry(date: date, payload: payload, state: stateAt(payload, date: date)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoutineEntry>) -> Void) {
        let now = Date()
        let payload = loadPayload()
        let horizon = now.addingTimeInterval(24 * 3600)
        var dates = Set<Date>([now])
        var tick = (floor(now.timeIntervalSince1970 / 300) + 1) * 300
        while tick < horizon.timeIntervalSince1970 {
            dates.insert(Date(timeIntervalSince1970: tick))
            tick += 300
        }
        for state in payload?.timelineStates ?? [] {
            guard let ms = state.effectiveAtEpochMs else { continue }
            let date = Date(timeIntervalSince1970: Double(ms) / 1000)
            if date > now && date < horizon { dates.insert(date) }
        }
        let entries = dates.sorted().map { date in
            RoutineEntry(date: date, payload: payload, state: stateAt(payload, date: date))
        }
        let timeline = Timeline(entries: entries, policy: .after(horizon))
        completion(timeline)
    }
}

private struct RoutineMediumWidgetEntryView: View {
    var entry: RoutineEntry

    private var garden: Bool { entry.payload?.characterPackId == "poodle_garden" }
    private var packAccent: Color { garden ? Color(hex: 0x078F96) : WidgetTokens.accent }
    private var packBackground: LinearGradient {
        LinearGradient(colors: garden
            ? [Color(hex: 0xF7F0FF), Color(hex: 0xD4F7E8)]
            : [Color(hex: 0xFFF4DC), Color(hex: 0xE6D8FF)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var expired: Bool {
        guard let until = entry.payload?.validUntilEpochMs, until > 0 else { return false }
        return Int64(entry.date.timeIntervalSince1970 * 1000) >= until
    }

    @ViewBuilder var body: some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(for: .widget) {
                packBackground
            }
        } else {
            content
        }
    }

    private var content: some View {
        ZStack {
            packBackground
            if garden {
                PackArtwork.image("widget_leaf")
                    .resizable().interpolation(.none).frame(width: 20, height: 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(10)
                PackArtwork.image("widget_daisy")
                    .resizable().interpolation(.none).frame(width: 33, height: 33)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            } else {
                PackArtwork.image("widget_stars")
                    .resizable().interpolation(.none).scaledToFill()
                    .opacity(0.45).clipped()
            }
            HStack(alignment: .center, spacing: 5) {
                PackArtwork.image(garden ? "widget_poodle" : "widget_cat")
                    .resizable().interpolation(.none).scaledToFit()
                    .frame(width: 56, height: 70, alignment: .bottom)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                leftColumn
                Rectangle().fill(WidgetTokens.border).frame(width: 1)
                RoutineRingView(state: expired ? nil : entry.state,
                                date: entry.date,
                                centerLabel: entry.state?.centerTimeLabel ?? entry.payload?.centerTimeLabel ?? "")
                    .frame(width: 106, height: 106)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 8)
        }
        .overlay(PixelWidgetShape().stroke(WidgetTokens.textPrimary, lineWidth: 1.5))
    }

    /// 정보 위계: 상태·시간 → 루틴 이름 → 남은 시간 → 다음 일정.
    /// 위젯 이름이 이미 '하루 루틴 시간표'라 카드 안에서 제목을 반복하지 않는다.
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            // 시작·종료 시각은 싣지 않는다. 좁은 왼쪽 칸에서 배지와 나란히 두면
            // 잘리고, 아래 타이밍 힌트가 같은 것을 더 쓸모 있게 말한다.
            let status = expired ? "" : (entry.state?.currentRoutineStatus ?? "")
            if !status.isEmpty {
                Text(status)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(packAccent)
                    .clipShape(PixelWidgetShape(step: 2, steps: 1))
                    .padding(.bottom, 7)
            }

            // 루틴의 정체성은 색상으로 표현한다 (Routine.iconEmoji 주석 참고).
            Text(expired
                 ? (entry.payload?.refreshHint ?? localizedFallback("refresh"))
                 : (entry.state?.currentRoutineTitle ?? localizedFallback("refresh")))
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(WidgetTokens.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            let hint = expired ? "" : currentTimingHint
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

    private var currentTimingHint: String {
        guard let state = entry.state else { return "" }
        guard let targetMs = state.timingTargetEpochMs,
              let mode = state.timingMode,
              targetMs > Int64(entry.date.timeIntervalSince1970 * 1000),
              let payload = entry.payload else {
            return state.currentRoutineTimingHint ?? ""
        }
        let remaining = Int(ceil((Double(targetMs) / 1000 - entry.date.timeIntervalSince1970) / 60))
        let hours = remaining / 60
        let minutes = remaining % 60
        let duration: String
        if hours > 0 && minutes > 0 {
            duration = (payload.durationHoursMinutesTemplate ?? "")
                .replacingOccurrences(of: "{hours}", with: String(hours))
                .replacingOccurrences(of: "{minutes}", with: String(minutes))
        } else if hours > 0 {
            duration = (payload.durationHoursTemplate ?? "")
                .replacingOccurrences(of: "{hours}", with: String(hours))
        } else {
            duration = (payload.durationMinutesTemplate ?? "")
                .replacingOccurrences(of: "{minutes}", with: String(minutes))
        }
        let template = mode == "start"
            ? (payload.timingStartTemplate ?? "")
            : (payload.timingEndTemplate ?? "")
        if template.contains("{duration}") && !duration.isEmpty {
            return template.replacingOccurrences(of: "{duration}", with: duration)
        }
        return state.currentRoutineTimingHint ?? ""
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
            Text(entry.payload?.nextLabel ?? localizedFallback("next"))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(WidgetTokens.textMuted)
            Text(expired ? "" : (entry.state?.nextRoutineTitle ?? localizedFallback("none")))
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(WidgetTokens.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(expired ? "" : (entry.state?.nextRoutineTime ?? ""))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(WidgetTokens.textMuted)
        }
    }
}

private func localizedFallback(_ key: String) -> String {
    let language = Locale.current.languageCode ?? "en"
    let strings: [String: [String: String]] = [
        "ko": ["next": "다음", "none": "없음", "now": "지금", "refresh": "앱을 열어주세요"],
        "en": ["next": "Next", "none": "None", "now": "Now", "refresh": "Open the app"],
        "es": ["next": "Siguiente", "none": "Ninguna", "now": "Ahora", "refresh": "Abre la app"],
        "ja": ["next": "次", "none": "なし", "now": "今", "refresh": "アプリを開く"],
        "pt": ["next": "Próxima", "none": "Nenhuma", "now": "Agora", "refresh": "Abra o app"]
    ]
    return strings[language]?[key] ?? strings["en"]?[key] ?? ""
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
    let state: WidgetStateDto?
    let date: Date
    let centerLabel: String

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

                for seg in state?.ringSegments ?? [] {
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

                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                let minuteOfDay = Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
                let ptr = angle(minuteOfDay)
                if state != nil {
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
                            Calendar.current.component(.hour, from: date),
                            Calendar.current.component(.minute, from: date)))
                    .font(.system(size: 23, weight: .heavy, design: .monospaced))
                    .foregroundColor(WidgetTokens.textPrimary)
                Text(centerLabel.isEmpty ? localizedFallback("now") : centerLabel)
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
