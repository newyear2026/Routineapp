import WidgetKit
import SwiftUI

private let kAppGroupId = "group.com.example.routineTimer"
private let kPayloadKey = "routine_widget_payload"
private let kWidgetKind = "RoutineMediumWidget"

private struct RingSegDto: Codable {
    let id: String
    let startMinutesFromMidnight: Int
    let sweepMinutes: Int
    let colorArgb: Int
}

private struct PayloadDto: Codable {
    let schemaVersion: Int
    let headerTitle: String
    let subtitle: String
    let currentRoutineTitle: String
    let currentRoutineIconEmoji: String
    let currentRoutineTimeRange: String
    let currentRoutineStatus: String
    let nextRoutineLine: String
    let nextRoutineTitle: String
    let nextRoutineTime: String
    let currentTimeHour: Int
    let currentTimeMinute: Int
    let pointerAngleRad: Double
    let centerTimeLabel: String
    let ringSegments: [RingSegDto]
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
        HStack(alignment: .center, spacing: 8) {
            leftColumn
            Spacer(minLength: 0)
            RoutineRingView(payload: entry.payload)
                .frame(width: 120, height: 120)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(red: 1.0, green: 0.97, blue: 0.93)
        }
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.payload?.headerTitle ?? "하루 루틴 시간표")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(red: 0.36, green: 0.25, blue: 0.2))
            Text(entry.payload?.subtitle ?? "앱을 열어 동기화해 주세요")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(red: 0.55, green: 0.49, blue: 0.45))
            HStack(alignment: .top, spacing: 6) {
                Text(entry.payload?.currentRoutineIconEmoji ?? "📌")
                    .font(.system(size: 18))
                Text(entry.payload?.currentRoutineTitle ?? "—")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(red: 0.36, green: 0.25, blue: 0.2))
                    .lineLimit(1)
            }
            .padding(.top, 6)
            HStack(spacing: 8) {
                Text(entry.payload?.currentRoutineTimeRange ?? "")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(Color(red: 0.36, green: 0.25, blue: 0.2))
                Text(entry.payload?.currentRoutineStatus ?? "")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.88, green: 0.48, blue: 0.37))
                    .clipShape(Capsule())
            }
            Text(entry.payload?.nextRoutineLine ?? "")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(Color(red: 0.55, green: 0.49, blue: 0.45))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RoutineRingView: View {
    let payload: PayloadDto?

    var body: some View {
        ZStack {
            Canvas { context, size in
                let w = min(size.width, size.height)
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let scale = w / 200
                let innerR = 52 * scale
                let outerR = 78 * scale
                let midR = (innerR + outerR) / 2
                let strokeW = outerR - innerR
                let minPerDay = 24 * 60.0

                var track = Path()
                track.addArc(
                    center: c,
                    radius: midR,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270),
                    clockwise: true
                )
                context.stroke(track, with: .color(Color(red: 0.94, green: 0.91, blue: 0.88).opacity(0.65)), lineWidth: strokeW)

                if let p = payload {
                    for seg in p.ringSegments {
                        let startRad = Double(seg.startMinutesFromMidnight) / minPerDay * 2 * .pi - .pi / 2
                        let sweepRad = Double(seg.sweepMinutes) / minPerDay * 2 * .pi
                        let isActive = p.activeSegmentId.map { $0 == seg.id } ?? false
                        var arc = Path()
                        arc.addArc(
                            center: c,
                            radius: midR,
                            startAngle: Angle(radians: startRad),
                            endAngle: Angle(radians: startRad + sweepRad),
                            clockwise: false
                        )
                        let col = Color(argb: seg.colorArgb)
                        context.stroke(arc, with: .color(col.opacity(isActive ? 1 : 0.72)), lineWidth: strokeW)
                    }

                    var hole = Path()
                    hole.addEllipse(in: CGRect(x: c.x - innerR + 1, y: c.y - innerR + 1, width: (innerR - 1) * 2, height: (innerR - 1) * 2))
                    context.fill(hole, with: .color(Color(red: 1.0, green: 0.98, blue: 0.96)))

                    let ptr = p.pointerAngleRad
                    let r0 = midR - strokeW * 0.42
                    let r1 = outerR + 3 * scale
                    var line = Path()
                    line.move(to: CGPoint(x: c.x + CGFloat(cos(ptr)) * r0, y: c.y + CGFloat(sin(ptr)) * r0))
                    line.addLine(to: CGPoint(x: c.x + CGFloat(cos(ptr)) * r1, y: c.y + CGFloat(sin(ptr)) * r1))
                    context.stroke(line, with: .color(Color(red: 0.88, green: 0.48, blue: 0.37)), lineWidth: max(3, 5 * scale))

                    let dot = CGRect(
                        x: c.x + CGFloat(cos(ptr)) * r1 - 3.8 * scale / 2,
                        y: c.y + CGFloat(sin(ptr)) * r1 - 3.8 * scale / 2,
                        width: 3.8 * scale,
                        height: 3.8 * scale
                    )
                    context.fill(Path(ellipseIn: dot), with: .color(Color(red: 0.88, green: 0.48, blue: 0.37)))
                }
            }
            if let p = payload {
                VStack(spacing: 2) {
                    Text(String(format: "%02d:%02d", p.currentTimeHour, p.currentTimeMinute))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 0.36, green: 0.25, blue: 0.2))
                    Text(p.centerTimeLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(red: 0.6, green: 0.54, blue: 0.67))
                }
            }
        }
    }
}

private extension Color {
    init(argb: Int) {
        let u = UInt32(truncatingIfNeeded: argb)
        let a = Double((u >> 24) & 0xFF) / 255.0
        let r = Double((u >> 16) & 0xFF) / 255.0
        let g = Double((u >> 8) & 0xFF) / 255.0
        let b = Double(u & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
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
