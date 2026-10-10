import SwiftUI

// MARK: - Fun hub
struct FunView: View {
    @State private var slideshow = false
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                LoveBackground()
                ScrollView {
                    LazyVGrid(columns: cols, spacing: 12) {
                        tile("🎲", "Date Ideas") { ItemListView(title: "Date Ideas", placeholder: "Add a date idea", kp: \.ideas, pick: true) }
                        tile("💌", "Open When…") { LettersView() }
                        tile("💖", "Reasons I Love You") { ItemListView(title: "Reasons I Love You", placeholder: "Add a reason", kp: \.reasons, on: "heart.fill", off: "heart.fill", strike: false, pick: true, pickAll: true) }
                        tile("🎟️", "Love Coupons") { ItemListView(title: "Love Coupons", placeholder: "Add a coupon", kp: \.coupons, on: "checkmark.seal.fill", off: "ticket.fill") }
                        tile("🪣", "Bucket List") { ItemListView(title: "Bucket List", placeholder: "Add something to do together", kp: \.bucket) }
                        tile("🎵", "Our Songs") { ItemListView(title: "Our Songs", placeholder: "Add a song", kp: \.songs, on: "star.fill", off: "music.note", strike: false) }
                        tile("⏳", "Countdowns") { CountdownsView() }
                        tile("❓", "Question of the Day") { QuestionView() }
                        tile("🎯", "Decision Maker") { DecisionView() }
                        tile("😘", "Love Counters") { CountersView() }
                        tile("📖", "Our Story") { StoryView() }
                        tile("🎁", "Gift Ideas") { ItemListView(title: "Gift Ideas", placeholder: "Add a gift idea", kp: \.gifts, on: "gift.fill", off: "gift") }
                        tile("🍿", "Watchlist") { ItemListView(title: "Watchlist", placeholder: "Movie or show to watch", kp: \.movies) }
                        tile("😂", "Inside Jokes") { ItemListView(title: "Inside Jokes", placeholder: "Add an inside joke", kp: \.jokes, on: "face.smiling.fill", off: "face.smiling.fill", strike: false, pick: true, pickAll: true) }
                        tile("🤝", "Promises") { ItemListView(title: "Our Promises", placeholder: "Add a promise", kp: \.promises, on: "checkmark.seal.fill", off: "seal", strike: false) }
                        tile("🔥", "Truth or Dare") { TruthDareView() }
                        Button { slideshow = true } label: {
                            VStack(spacing: 6) { Text("🎞️").font(.largeTitle); Text("Slideshow").font(.subheadline.bold()) }.loveCard()
                        }.buttonStyle(.plain)
                    }.padding()
                }
            }
            .navigationTitle("Fun 🎉")
            .fullScreenCover(isPresented: $slideshow) { SlideshowView() }
        }
    }

    func tile<D: View>(_ emoji: String, _ title: String, @ViewBuilder _ dest: @escaping () -> D) -> some View {
        NavigationLink { dest() } label: {
            VStack(spacing: 6) {
                Text(emoji).font(.largeTitle)
                Text(title).font(.subheadline.bold()).multilineTextAlignment(.center)
            }.foregroundColor(.primary).loveCard()
        }.buttonStyle(.plain)
    }
}

// MARK: - Generic checklist / jar (ideas, reasons, coupons, bucket list, songs)
struct ItemListView: View {
    @EnvironmentObject var store: LoveStore
    let title: String
    let placeholder: String
    let kp: WritableKeyPath<AppState, [Item]>
    var on = "checkmark.circle.fill"
    var off = "circle"
    var strike = true
    var pick = false
    var pickAll = false
    @State private var text = ""
    @State private var picked: String?

    var body: some View {
        ZStack {
            LoveBackground()
            VStack(spacing: 0) {
                HStack {
                    TextField(placeholder, text: $text).textFieldStyle(.roundedBorder).onSubmit(add)
                    Button(action: add) { Image(systemName: "plus.circle.fill").font(.title).foregroundColor(Palette.accent) }
                }.padding()
                List {
                    ForEach(store.state[keyPath: kp]) { item in
                        Button { toggle(item.id) } label: {
                            HStack {
                                Image(systemName: item.done ? on : off).foregroundColor(Palette.accent)
                                Text(item.text).foregroundColor(.primary).strikethrough(strike && item.done)
                                Spacer()
                            }
                        }.listRowBackground(Color.white.opacity(0.78))
                    }.onDelete { store.state[keyPath: kp].remove(atOffsets: $0) }
                }.scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(title)
        .toolbar { if pick { Button { choose() } label: { Label("Pick one", systemImage: "dice.fill") } } }
        .alert(picked ?? "", isPresented: Binding(get: { picked != nil }, set: { if !$0 { picked = nil } })) {
            Button("Yay 💕", role: .cancel) {}
        }
    }

    func add() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        store.state[keyPath: kp].insert(Item(text: t), at: 0)
        text = ""
    }
    func toggle(_ id: UUID) {
        if let i = store.state[keyPath: kp].firstIndex(where: { $0.id == id }) { store.state[keyPath: kp][i].done.toggle() }
    }
    func choose() {
        let pool = store.state[keyPath: kp].filter { pickAll || !$0.done }
        picked = pool.randomElement()?.text ?? "Nothing left, add more!"
    }
}

// MARK: - Open When letters
struct LettersView: View {
    @EnvironmentObject var store: LoveStore
    @State private var adding = false

    var body: some View {
        ZStack {
            LoveBackground()
            List {
                ForEach(store.state.letters) { l in
                    NavigationLink { LetterReader(letter: l) } label: {
                        HStack(spacing: 12) {
                            Text(isLocked(l) ? "🔒" : "💌").font(.title2)
                            VStack(alignment: .leading) {
                                Text(l.title).font(.headline)
                                if let u = l.unlock, isLocked(l) {
                                    Text("Opens \(u.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }.listRowBackground(Color.white.opacity(0.78))
                }.onDelete { store.state.letters.remove(atOffsets: $0) }
            }.scrollContentBackground(.hidden)
        }
        .navigationTitle("Open When…")
        .toolbar { Button { adding = true } label: { Image(systemName: "plus") } }
        .sheet(isPresented: $adding) { NewLetter() }
    }
    func isLocked(_ l: Letter) -> Bool { (l.unlock ?? .distantPast) > Date() }
}

struct LetterReader: View {
    let letter: Letter
    var body: some View {
        ZStack {
            LoveBackground()
            if let u = letter.unlock, u > Date() {
                VStack(spacing: 12) {
                    Text("🔒").font(.system(size: 60))
                    Text("Locked until \(u.formatted(date: .long, time: .omitted))").font(.headline)
                }
            } else {
                ScrollView { Text(letter.body).font(.system(.body, design: .serif)).loveCard().padding() }
            }
        }.navigationTitle(letter.title)
    }
}

struct NewLetter: View {
    @EnvironmentObject var store: LoveStore
    @Environment(\.dismiss) var dismiss
    @State private var title = "Open when you miss me"
    @State private var body_ = ""
    @State private var useDate = false
    @State private var date = Date().addingTimeInterval(86400)

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Section("Your letter") { TextEditor(text: $body_).frame(minHeight: 180) }
                Toggle("Lock until a date", isOn: $useDate)
                if useDate { DatePicker("Opens on", selection: $date, in: Date()..., displayedComponents: .date) }
            }
            .tint(Palette.accent)
            .navigationTitle("New letter 💌")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.state.letters.insert(Letter(title: title, body: body_, unlock: useDate ? date : nil), at: 0)
                        dismiss()
                    }.disabled(body_.isEmpty)
                }
            }
        }
    }
}

// MARK: - Countdowns
struct CountdownsView: View {
    @EnvironmentObject var store: LoveStore
    @State private var adding = false

    var body: some View {
        ZStack {
            LoveBackground()
            List {
                ForEach(store.state.countdowns.sorted { $0.date < $1.date }) { c in
                    let left = Together(start: Date()).daysFromToday(to: c.date)
                    HStack {
                        VStack(alignment: .leading) {
                            Text(c.title).font(.headline)
                            Text(c.date.formatted(date: .long, time: .omitted)).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(left == 0 ? "Today! 🎉" : left > 0 ? "in \(left)d" : "passed")
                            .font(.subheadline.weight(.bold)).foregroundColor(Palette.accent)
                    }.listRowBackground(Color.white.opacity(0.78))
                }.onDelete { offs in
                    let sorted = store.state.countdowns.sorted { $0.date < $1.date }
                    let ids = offs.map { sorted[$0].id }
                    store.state.countdowns.removeAll { ids.contains($0.id) }
                }
            }.scrollContentBackground(.hidden)
        }
        .navigationTitle("Countdowns")
        .toolbar { Button { adding = true } label: { Image(systemName: "plus") } }
        .sheet(isPresented: $adding) { NewCountdown() }
        .onChange(of: store.state.countdowns) { _ in store.reschedule() }
    }
}

struct NewCountdown: View {
    @EnvironmentObject var store: LoveStore
    var kp: WritableKeyPath<AppState, [Countdown]> = \.countdowns
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var date = Date().addingTimeInterval(86400 * 7)
    var body: some View {
        NavigationStack {
            Form {
                TextField("What are we counting down to?", text: $title)
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .tint(Palette.accent)
            .navigationTitle("New event ⏳")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { store.state[keyPath: kp].append(Countdown(title: title, date: date)); dismiss() }.disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Question of the day
let questions = [
    "What's your favorite memory of us so far?", "What's something small I do that makes you happy?",
    "Where would you take us on a dream trip?", "What song reminds you of me?",
    "What's one thing you want us to try this year?", "When did you first know you liked me?",
    "What's your love language?", "What's the best date we've ever had?",
    "What's one thing you've never told me?", "What would our perfect lazy Sunday look like?",
    "What's a goal you want me to help you reach?", "What's your favorite thing about us?",
    "If we could live anywhere, where?", "What was your first impression of me?",
    "What's a tradition we should start?", "What makes you feel most loved?",
    "What's the funniest thing that's happened to us?", "What are you most excited about for our future?"
]

struct QuestionView: View {
    @State private var i = (Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0) % questions.count
    var body: some View {
        ZStack {
            LoveBackground()
            VStack(spacing: 24) {
                Text(questions[i]).font(.system(.title2, design: .serif).italic()).multilineTextAlignment(.center).loveCard()
                Button { i = Int.random(in: 0..<questions.count) } label: {
                    Text("Another one 🎲").foregroundColor(.white).padding(.horizontal, 28).padding(.vertical, 12)
                        .background(Palette.accent, in: Capsule())
                }
            }.padding()
        }.navigationTitle("Question of the Day")
    }
}

// MARK: - Decision maker
struct DecisionView: View {
    @State private var text = ""
    @State private var result: String?
    var body: some View {
        ZStack {
            LoveBackground()
            VStack(spacing: 20) {
                Text("Can't decide where to eat? Type options separated by commas.").font(.subheadline).multilineTextAlignment(.center)
                TextField("pizza, sushi, tacos", text: $text).textFieldStyle(.roundedBorder)
                Button {
                    let opts = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    withAnimation(.spring()) { result = opts.randomElement() }
                } label: {
                    Text("Choose for us! 🎯").foregroundColor(.white).padding(.horizontal, 28).padding(.vertical, 12)
                        .background(Palette.accent, in: Capsule())
                }
                if let r = result {
                    Text(r).font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundColor(Palette.accent)
                        .loveCard().transition(.scale)
                }
                Spacer()
            }.padding()
        }.navigationTitle("Decision Maker")
    }
}

// MARK: - Love counters
struct CountersView: View {
    @EnvironmentObject var store: LoveStore
    let kinds = [("😘", "Kisses"), ("🤗", "Hugs"), ("💬", "I love yous"), ("🍽️", "Dates")]
    var body: some View {
        ZStack {
            LoveBackground()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(kinds, id: \.1) { k in
                    Button {
                        store.state.counters[k.1, default: 0] += 1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 4) {
                            Text(k.0).font(.system(size: 44))
                            Text("\(store.state.counters[k.1, default: 0])")
                                .font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundColor(Palette.accent)
                            Text(k.1).font(.caption).foregroundColor(.secondary)
                        }.loveCard()
                    }
                    .buttonStyle(.plain)
                    .contextMenu { Button("Reset", role: .destructive) { store.state.counters[k.1] = 0 } }
                }
            }.padding()
            .frame(maxHeight: .infinity, alignment: .top)
        }.navigationTitle("Love Counters")
    }
}

// MARK: - Slideshow
struct SlideshowView: View {
    @EnvironmentObject var store: LoveStore
    @Environment(\.dismiss) var dismiss
    @State private var i = 0
    @State private var zoom = false
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        let mem = store.state.memories
        let t = Together(start: store.state.startDate ?? Date())
        ZStack {
            Color.black.ignoresSafeArea()
            if mem.isEmpty {
                Text("Add some photos in Memories first 💕").foregroundColor(.white)
            } else {
                let m = mem[i % mem.count]
                if let img = store.image(for: m) {
                    Image(uiImage: img).resizable().scaledToFit()
                        .scaleEffect(zoom ? 1.12 : 1.0)
                        .animation(.linear(duration: 4), value: zoom)
                        .id(i).transition(.opacity)
                }
                VStack {
                    Spacer()
                    VStack(spacing: 4) {
                        if !m.caption.isEmpty { Text(m.caption).font(.headline) }
                        Text("Day \(t.dayNumber(on: m.date)) of us 💕").font(.caption)
                    }.foregroundColor(.white).padding().frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                }
            }
            VStack {
                HStack { Spacer(); Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title).foregroundColor(.white.opacity(0.8)) } }.padding()
                Spacer()
            }
        }
        .onAppear { zoom = true }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 1)) { i += 1 }
            zoom.toggle()
        }
    }
}

// MARK: - Our Story timeline
struct StoryView: View {
    @EnvironmentObject var store: LoveStore
    @State private var adding = false

    var body: some View {
        let start = store.state.startDate ?? Date()
        let t = Together(start: start)
        let events = (store.state.story + [Countdown(title: "We started dating 💕", date: start)]).sorted { $0.date < $1.date }
        ZStack {
            LoveBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(events) { e in
                        HStack(alignment: .top, spacing: 14) {
                            VStack(spacing: 0) {
                                Circle().fill(Palette.accent).frame(width: 14, height: 14)
                                Rectangle().fill(Palette.accent.opacity(0.3)).frame(width: 2).frame(minHeight: 46)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.title).font(.headline)
                                Text("\(e.date.formatted(date: .long, time: .omitted)) · Day \(t.dayNumber(on: e.date))")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .contextMenu { Button("Delete", role: .destructive) { store.state.story.removeAll { $0.id == e.id } } }
                    }
                }.padding()
            }
        }
        .navigationTitle("Our Story")
        .toolbar { Button { adding = true } label: { Image(systemName: "plus") } }
        .sheet(isPresented: $adding) { NewCountdown(kp: \.story) }
    }
}

// MARK: - Truth or Dare
struct TruthDareView: View {
    @State private var text = "Pick one 😏"
    let truths = ["What's your favorite thing about me?", "What was your first thought when we met?", "What's something you're scared to tell me?", "What's your most embarrassing moment?", "When did you realize you liked me?", "What's your biggest turn-on in a person?", "What's one thing I do that drives you crazy?", "What's the cutest thing I've ever done?"]
    let dares = ["Give me a 30-second massage 💆", "Say 3 things you love about me", "Do your best impression of me", "Slow dance with me, no music 💃", "Send me a voice note singing", "Make me laugh in 10 seconds", "Give me your best compliment", "Tell me a secret in a whisper"]
    var body: some View {
        ZStack {
            LoveBackground()
            VStack(spacing: 24) {
                Text(text).font(.system(.title2, design: .rounded).weight(.semibold)).multilineTextAlignment(.center).loveCard()
                HStack(spacing: 16) {
                    btn("Truth 💬") { text = truths.randomElement() ?? "" }
                    btn("Dare 🔥") { text = dares.randomElement() ?? "" }
                }
            }.padding()
        }.navigationTitle("Truth or Dare")
    }
    func btn(_ t: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(t).font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding()
                .background(Palette.accent, in: Capsule())
        }
    }
}
