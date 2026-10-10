import SwiftUI

struct MilestonesView: View {
    @EnvironmentObject var store: LoveStore
    let marks = [50, 100, 200, 300, 365, 500, 730, 1000, 1095, 1500, 1826, 2000, 3000]

    var body: some View {
        let t = Together(start: store.state.startDate ?? Date())
        NavigationStack {
            ZStack {
                LoveBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(marks, id: \.self) { n in
                            let date = t.date(afterDays: n)
                            let left = t.daysFromToday(to: date)
                            HStack(spacing: 14) {
                                Image(systemName: left <= 0 ? "heart.fill" : "heart")
                                    .font(.title).foregroundColor(left <= 0 ? Palette.accent : Palette.accent.opacity(0.4))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(n) days").font(.headline)
                                    Text(date.formatted(date: .long, time: .omitted))
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(left <= 0 ? "Reached 🎉" : "in \(left)d")
                                    .font(.subheadline.weight(.semibold)).foregroundColor(Palette.accent)
                            }.loveCard()
                        }
                    }.padding()
                }
            }
            .navigationTitle("Milestones")
        }
    }
}
