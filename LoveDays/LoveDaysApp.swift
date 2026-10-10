import SwiftUI

@main
struct LoveDaysApp: App {
    @StateObject private var store = LoveStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
