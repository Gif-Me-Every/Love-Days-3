import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: LoveStore
    @State private var beat = false
    @State private var showSettings = false
    @State private var burst = 0

    var body: some View {
        let start = store.state.startDate ?? Date()
        let t = Together(start: start)
        let title = (store.state.name1.isEmpty || store.state.name2.isEmpty)
            ? "Our Love Story" : "\(store.state.name1) ❤️ \(store.state.name2)"

        ZStack {
            LoveBackground()
            FloatingHearts()
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape.fill").foregroundColor(Palette.accent)
                        }
                    }
                    Text(title)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.accent)

                    ZStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 250))
                            .foregroundStyle(LinearGradient(colors: [Palette.accent, .red.opacity(0.8)],
                                                            startPoint: .top, endPoint: .bottom))
                            .shadow(color: Palette.accent.opacity(0.5), radius: 14)
                        VStack(spacing: 0) {
                            Text("\(t.days)")
                                .font(.system(size: 62, weight: .heavy, design: .rounded))
                            Text(t.days == 1 ? "day" : "days")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .offset(y: -8)
                    }
                    .scaleEffect(beat ? 1.05 : 0.97)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: beat)
                    .onTapGesture { burst += 1; UIImpactFeedbackGenerator(style: .medium).impactOccurred() }

                    Text("together since \(start.formatted(date: .long, time: .omitted))")
                        .font(.subheadline).foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        chip("\(t.years)", "years")
                        chip("\(t.months)", "months")
                        chip("\(t.dayPart)", "days")
                    }

                    HStack(spacing: 10) {
                        chip("\(t.weeks)", "weeks")
                        chip("\(t.hours)", "hours")
                        chip("\(t.totalMonths)", "total months")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next up: \(t.nextLabel)").font(.headline).foregroundColor(Palette.accent)
                        ProgressView(value: t.progressToNext).tint(Palette.accent)
                        Text(t.daysUntilNext == 0 ? "Today! 🎉" : "in \(t.daysUntilNext) day\(t.daysUntilNext == 1 ? "" : "s")")
                            .font(.subheadline).foregroundColor(.secondary)
                    }.loveCard()

                    BirthdayCard()

                    if !store.state.memories.isEmpty {
                        let m = store.state.memories[(Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0) % store.state.memories.count]
                        if let img = store.image(for: m) {
                            VStack(spacing: 8) {
                                Text("Memory of the day 📸").font(.headline).foregroundColor(Palette.accent)
                                Image(uiImage: img).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 14))
                                if !m.caption.isEmpty { Text(m.caption).font(.caption) }
                            }.loveCard()
                        }
                    }

                    Text(quoteOfTheDay)
                        .font(.system(.body, design: .serif).italic())
                        .multilineTextAlignment(.center)
                        .loveCard()

                    ShareLink(item: shareImage(t), preview: SharePreview("Our days together", image: shareImage(t))) {
                        Label("Share our days", systemImage: "square.and.arrow.up")
                            .foregroundColor(.white)
                            .padding(.horizontal, 24).padding(.vertical, 12)
                            .background(Palette.accent, in: Capsule())
                    }
                }
                .padding()
            }
        }
        .overlay { if burst > 0 { BurstOnce().id(burst).allowsHitTesting(false) } }
        .onAppear {
            beat = true
            let bToday = [store.state.bday1, store.state.bday2].contains { $0.map { nextBirthday($0).days == 0 } ?? false }
            if bToday || t.days > 0 && (t.dayPart == 0 || [50, 100, 200, 365, 500, 1000].contains(t.days)) { burst += 1 }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    @MainActor func shareImage(_ t: Together) -> Image {
        let n1 = store.state.name1, n2 = store.state.name2
        let r = ImageRenderer(content: ShareCard(days: t.days, title: n1.isEmpty || n2.isEmpty ? "Our Love Story" : "\(n1) ❤️ \(n2)"))
        r.scale = 2
        return Image(uiImage: r.uiImage ?? UIImage())
    }

    func chip(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(.title2, design: .rounded).weight(.bold)).foregroundColor(Palette.accent)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct BirthdayCard: View {
    @EnvironmentObject var store: LoveStore
    var body: some View {
        let list: [(String, Date)] = [
            (store.state.name1.isEmpty ? "Me" : store.state.name1, store.state.bday1),
            (store.state.name2.isEmpty ? "Them" : store.state.name2, store.state.bday2)
        ].compactMap { n, d in d.map { (n, $0) } }
        if !list.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Birthdays 🎂").font(.headline).foregroundColor(Palette.accent)
                ForEach(list, id: \.0) { n, d in
                    let b = nextBirthday(d)
                    HStack {
                        VStack(alignment: .leading) {
                            Text(n).font(.subheadline.bold())
                            Text(zodiac(d)).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(b.days == 0 ? "Today! 🎉 turns \(b.age)" : "turns \(b.age) in \(b.days)d")
                            .font(.subheadline.weight(.semibold)).foregroundColor(Palette.accent)
                    }
                }
            }.loveCard()
        }
    }
}
