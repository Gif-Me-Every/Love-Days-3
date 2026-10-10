import SwiftUI

struct NotesView: View {
    @EnvironmentObject var store: LoveStore
    @State private var text = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LoveBackground()
                VStack(spacing: 0) {
                    HStack {
                        TextField("Write a love note…", text: $text, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            store.state.notes.insert(LoveNote(text: trimmed), at: 0)
                            text = ""
                        } label: {
                            Image(systemName: "paperplane.fill").foregroundColor(.white)
                                .padding(10).background(Palette.accent, in: Circle())
                        }
                    }.padding()

                    List {
                        ForEach(store.state.notes) { n in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(n.text)
                                Text(n.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            .listRowBackground(Color.white.opacity(0.78))
                        }
                        .onDelete { store.state.notes.remove(atOffsets: $0) }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Love Notes")
        }
    }
}
