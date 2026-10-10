import SwiftUI

struct LoveBackground: View {
    var body: some View {
        LinearGradient(colors: [Palette.top, Palette.bottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
    }
}

extension View {
    func loveCard() -> some View {
        self.padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: Palette.accent.opacity(0.18), radius: 8, y: 4)
    }
}

struct HeartSpec {
    let x = CGFloat.random(in: 0...1)
    let size = CGFloat.random(in: 12...32)
    let duration = Double.random(in: 7...14)
    let delay = Double.random(in: 0...6)
    let opacity = Double.random(in: 0.15...0.45)
}

struct FloatingHearts: View {
    @State private var animate = false
    private let hearts = (0..<14).map { _ in HeartSpec() }
    var body: some View {
        GeometryReader { geo in
            ForEach(Array(hearts.enumerated()), id: \.offset) { _, h in
                Image(systemName: "heart.fill")
                    .font(.system(size: h.size))
                    .foregroundColor(Palette.accent.opacity(h.opacity))
                    .position(x: h.x * geo.size.width, y: animate ? -40 : geo.size.height + 40)
                    .animation(.linear(duration: h.duration).repeatForever(autoreverses: false).delay(h.delay), value: animate)
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}

struct BurstOnce: View {
    @State private var go = false
    private let items = (0..<30).map { _ in
        (angle: Double.random(in: 0..<(2 * .pi)), dist: CGFloat.random(in: 110...340),
         emoji: ["❤️", "💖", "💕", "🌸", "✨", "💘"].randomElement() ?? "❤️", size: CGFloat.random(in: 18...36))
    }
    var body: some View {
        ZStack {
            ForEach(items.indices, id: \.self) { i in
                Text(items[i].emoji).font(.system(size: items[i].size))
                    .offset(x: go ? cos(items[i].angle) * items[i].dist : 0,
                            y: go ? sin(items[i].angle) * items[i].dist : 0)
                    .opacity(go ? 0 : 1)
                    .animation(.easeOut(duration: 1.5), value: go)
            }
        }
        .onAppear { go = true }
    }
}

struct ShareCard: View {
    let days: Int
    let title: String
    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.top, Palette.bottom], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 14) {
                Text(title).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(Palette.accent)
                ZStack {
                    Image(systemName: "heart.fill").font(.system(size: 230)).foregroundColor(Palette.accent)
                    VStack(spacing: 0) {
                        Text("\(days)").font(.system(size: 64, weight: .heavy, design: .rounded))
                        Text("days together").font(.system(size: 18, weight: .semibold, design: .rounded))
                    }.foregroundColor(.white).offset(y: -6)
                }
            }.padding(30)
        }.frame(width: 360, height: 400)
    }
}
