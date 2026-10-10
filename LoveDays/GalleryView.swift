import SwiftUI
import PhotosUI

struct GalleryView: View {
    @EnvironmentObject var store: LoveStore
    @State private var pickerItems: [PhotosPickerItem] = []
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        NavigationStack {
            ZStack {
                LoveBackground()
                ScrollView {
                    if store.state.memories.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 50)).foregroundColor(Palette.accent.opacity(0.6))
                            Text("No memories yet.\nAdd your first photo together 💕")
                                .multilineTextAlignment(.center).foregroundColor(.secondary)
                        }.padding(.top, 120)
                    } else {
                        LazyVGrid(columns: cols, spacing: 6) {
                            ForEach(store.state.memories) { m in
                                NavigationLink {
                                    PhotoDetailView(id: m.id)
                                } label: {
                                    Color.clear.aspectRatio(1, contentMode: .fit)
                                        .overlay(
                                            Group {
                                                if let img = store.image(for: m) {
                                                    Image(uiImage: img).resizable().scaledToFill()
                                                } else { Palette.accent.opacity(0.2) }
                                            }
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }.padding(8)
                    }
                }
            }
            .navigationTitle("Memories")
            .toolbar {
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 10, matching: .images) {
                    Image(systemName: "plus.circle.fill").foregroundColor(Palette.accent)
                }
            }
            .onChange(of: pickerItems) { items in
                Task {
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            await MainActor.run { store.addPhoto(data) }
                        }
                    }
                    await MainActor.run { pickerItems = [] }
                }
            }
        }
    }
}

struct PhotoDetailView: View {
    @EnvironmentObject var store: LoveStore
    @Environment(\.dismiss) var dismiss
    let id: UUID

    var idx: Int? { store.state.memories.firstIndex { $0.id == id } }

    var body: some View {
        ZStack {
            LoveBackground()
            if let i = idx {
                let m = store.state.memories[i]
                let t = Together(start: store.state.startDate ?? Date())
                ScrollView {
                    VStack(spacing: 16) {
                        if let img = store.image(for: m) {
                            Image(uiImage: img).resizable().scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(color: Palette.accent.opacity(0.3), radius: 8)
                        }
                        Text("Day \(t.dayNumber(on: m.date)) of us 💕")
                            .font(.headline).foregroundColor(Palette.accent)
                        VStack(spacing: 10) {
                            TextField("Add a caption…", text: $store.state.memories[i].caption)
                                .textFieldStyle(.roundedBorder)
                            DatePicker("Date", selection: $store.state.memories[i].date,
                                       in: ...Date(), displayedComponents: .date).tint(Palette.accent)
                        }.loveCard()
                        Button(role: .destructive) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { store.delete(id: id) }
                        } label: { Label("Delete photo", systemImage: "trash") }
                    }.padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
