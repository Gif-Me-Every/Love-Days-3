import SwiftUI
import LocalAuthentication
import WidgetKit

struct ContentView: View {
    @EnvironmentObject var store: LoveStore
    @Environment(\.scenePhase) var phase
    @AppStorage("theme", store: Palette.defaults) var theme = 0

    var body: some View {
        ZStack {
            if store.state.startDate == nil {
                SetupView()
            } else {
                TabView {
                    HomeView().tabItem { Label("Us", systemImage: "heart.fill") }
                    GalleryView().tabItem { Label("Memories", systemImage: "photo.on.rectangle.angled") }
                    MilestonesView().tabItem { Label("Milestones", systemImage: "star.fill") }
                    FunView().tabItem { Label("Fun", systemImage: "sparkles") }
                    NotesView().tabItem { Label("Notes", systemImage: "envelope.fill") }
                }
                .tint(Palette.accent)
                .id(theme)
            }
            if store.locked { LockView() }
        }
        .onChange(of: phase) { p in
            if p == .background && store.state.lock { store.locked = true }
        }
    }
}

struct LockView: View {
    @EnvironmentObject var store: LoveStore
    var body: some View {
        ZStack {
            LoveBackground()
            VStack(spacing: 18) {
                Image(systemName: "lock.fill").font(.system(size: 60)).foregroundColor(Palette.accent)
                Text("Our little secret 💕").font(.title2.bold())
                Button("Unlock") { auth() }
                    .padding(.horizontal, 30).padding(.vertical, 12)
                    .background(Palette.accent, in: Capsule()).foregroundColor(.white)
            }
        }
        .onAppear { auth() }
    }
    func auth() {
        LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your memories") { ok, _ in
            if ok { DispatchQueue.main.async { store.locked = false } }
        }
    }
}

struct SetupView: View {
    @EnvironmentObject var store: LoveStore
    @State private var name1 = ""
    @State private var name2 = ""
    @State private var date = Date()
    var body: some View {
        ZStack {
            LoveBackground()
            FloatingHearts()
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "heart.fill").font(.system(size: 80)).foregroundColor(Palette.accent)
                Text("Our Love Story")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold)).foregroundColor(Palette.accent)
                VStack(spacing: 12) {
                    TextField("Your name", text: $name1).textFieldStyle(.roundedBorder)
                    TextField("Their name", text: $name2).textFieldStyle(.roundedBorder)
                    DatePicker("We started dating", selection: $date, in: ...Date(), displayedComponents: .date)
                        .tint(Palette.accent)
                }.loveCard()
                Button {
                    store.state.name1 = name1; store.state.name2 = name2; store.state.startDate = date
                } label: {
                    Text("Start counting 💕").font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(Palette.accent, in: Capsule())
                }
                Spacer()
            }.padding()
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: LoveStore
    @Environment(\.dismiss) var dismiss
    @AppStorage("theme", store: Palette.defaults) var theme = 0
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Names") {
                    TextField("Your name", text: $store.state.name1)
                    TextField("Their name", text: $store.state.name2)
                }
                Section("Anniversary") {
                    DatePicker("Started dating", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                Section("Birthdays 🎂") {
                    BirthdayRow(label: "My birthday", date: $store.state.bday1)
                    BirthdayRow(label: "Their birthday", date: $store.state.bday2)
                }
                Section("Theme") {
                    HStack(spacing: 14) {
                        ForEach(Palette.themes.indices, id: \.self) { i in
                            Circle().fill(Palette.themes[i].accent).frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color.primary, lineWidth: theme == i ? 3 : 0))
                                .onTapGesture { theme = i; WidgetCenter.shared.reloadAllTimelines() }
                        }
                    }
                }
                Section("Extras") {
                    Toggle("Anniversary reminders 🔔", isOn: $store.state.notify)
                    Toggle("Face ID / passcode lock 🔒", isOn: $store.state.lock)
                }
            }
            .tint(Palette.accent)
            .navigationTitle("Settings")
            .toolbar { Button("Done") { store.state.startDate = date; store.reschedule(); dismiss() } }
            .onAppear { date = store.state.startDate ?? Date() }
            .onChange(of: store.state.notify) { _ in store.reschedule() }
            .onChange(of: store.state.bday1) { _ in store.reschedule() }
            .onChange(of: store.state.bday2) { _ in store.reschedule() }
        }
    }
}

struct BirthdayRow: View {
    let label: String
    @Binding var date: Date?
    var body: some View {
        Toggle(label, isOn: Binding(get: { date != nil }, set: { date = $0 ? (date ?? Date()) : nil }))
        if date != nil {
            DatePicker("Date", selection: Binding(get: { date ?? Date() }, set: { date = $0 }),
                       in: ...Date(), displayedComponents: .date)
        }
    }
}
