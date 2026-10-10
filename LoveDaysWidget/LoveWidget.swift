import WidgetKit
import SwiftUI

struct LoveEntry: TimelineEntry {
    let date: Date
    let start: Date?
    let n1: String
    let n2: String
}

struct Provider: TimelineProvider {
    func current() -> LoveEntry {
        let d = Palette.defaults
        let ts = d.double(forKey: "start")
        return LoveEntry(date: Date(), start: ts > 0 ? Date(timeIntervalSince1970: ts) : nil,
                         n1: d.string(forKey: "n1") ?? "", n2: d.string(forKey: "n2") ?? "")
    }
    func placeholder(in context: Context) -> LoveEntry {
        LoveEntry(date: Date(), start: Calendar.current.date(byAdding: .day, value: -100, to: Date()), n1: "You", n2: "Me")
    }
    func getSnapshot(in context: Context, completion: @escaping (LoveEntry) -> Void) { completion(current()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LoveEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))?
            .addingTimeInterval(60) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [current()], policy: .after(next)))
    }
}

extension View {
    @ViewBuilder func wBG(_ system: Bool) -> some View {
        let g = LinearGradient(colors: [Palette.top, Palette.bottom], startPoint: .top, endPoint: .bottom)
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) { if system { g } else { Color.clear } }
        } else if system {
            self.background(g)
        } else {
            self
        }
    }
}

struct LoveWidgetView: View {
    let entry: LoveEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        inner.wBG(family == .systemSmall || family == .systemMedium)
    }

    @ViewBuilder var inner: some View {
        if let s = entry.start {
            let t = Together(start: s)
            switch family {
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Image(systemName: "heart.fill").font(.caption)
                        Text("\(t.days)").font(.system(.title3, design: .rounded).bold())
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Label("Together", systemImage: "heart.fill").font(.caption)
                    Text("\(t.days) days").font(.headline)
                    Text("\(t.daysUntilNext)d to \(t.nextNumber)-month mark").font(.caption2)
                }
            case .accessoryInline:
                Text("❤️ \(t.days) days together")
            case .systemMedium:
                HStack(spacing: 16) {
                    heart(t)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.headline).foregroundColor(Palette.accent)
                        Text("\(t.years)y \(t.months)m \(t.dayPart)d").font(.title3.bold())
                        Text("Next: \(t.nextLabel)").font(.caption).foregroundColor(.secondary)
                        Text(t.daysUntilNext == 0 ? "Today! 🎉" : "in \(t.daysUntilNext) days").font(.caption.bold()).foregroundColor(Palette.accent)
                    }
                    Spacer()
                }
            default:
                heart(t)
            }
        } else {
            Text("Open Love Days to set your date 💕").font(.caption).multilineTextAlignment(.center)
        }
    }

    var title: String { entry.n1.isEmpty || entry.n2.isEmpty ? "Our Love Story" : "\(entry.n1) ❤️ \(entry.n2)" }

    func heart(_ t: Together) -> some View {
        ZStack {
            Image(systemName: "heart.fill").font(.system(size: 112)).foregroundColor(Palette.accent)
            VStack(spacing: 0) {
                Text("\(t.days)").font(.system(size: 32, weight: .heavy, design: .rounded))
                Text(t.days == 1 ? "day" : "days").font(.caption.bold())
            }.foregroundColor(.white).offset(y: -3)
        }
    }
}

struct LoveWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LoveWidget", provider: Provider()) { entry in
            LoveWidgetView(entry: entry)
        }
        .configurationDisplayName("Days Together")
        .description("Your days together and next anniversary.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct PhotoWidgetView: View {
    let entry: LoveEntry
    var photo: UIImage? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Palette.group)
            .flatMap { UIImage(contentsOfFile: $0.appendingPathComponent("widget.jpg").path) }
    }
    var body: some View {
        let days = entry.start.map { Together(start: $0).days } ?? 0
        ZStack(alignment: .bottomLeading) {
            if let p = photo {
                Image(uiImage: p).resizable().scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
            } else {
                Image(systemName: "heart.fill").font(.system(size: 70)).foregroundColor(Palette.accent.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Text("❤️ \(days) days")
                .font(.system(.footnote, design: .rounded).weight(.bold)).foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.black.opacity(0.45), in: Capsule()).padding(6)
        }.wBG(true)
    }
}

struct LovePhotoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LovePhotoWidget", provider: Provider()) { entry in
            PhotoWidgetView(entry: entry)
        }
        .configurationDisplayName("Photo of Us")
        .description("Your latest photo with your day count.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct LoveBundle: WidgetBundle {
    var body: some Widget {
        LoveWidget()
        LovePhotoWidget()
    }
}
