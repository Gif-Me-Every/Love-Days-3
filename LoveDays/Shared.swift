import SwiftUI

struct Together {
    let start: Date
    private let cal = Calendar.current
    init(start: Date) { self.start = start }
    private var s: Date { cal.startOfDay(for: start) }
    private var today: Date { cal.startOfDay(for: Date()) }

    var days: Int { max(0, cal.dateComponents([.day], from: s, to: today).day ?? 0) }
    var ymd: DateComponents { cal.dateComponents([.year, .month, .day], from: s, to: max(s, today)) }
    var years: Int { ymd.year ?? 0 }
    var months: Int { ymd.month ?? 0 }
    var dayPart: Int { ymd.day ?? 0 }
    var totalMonths: Int { years * 12 + months }
    var weeks: Int { days / 7 }
    var hours: Int { days * 24 }
    var lastMonthsary: Date { cal.date(byAdding: .month, value: totalMonths, to: s) ?? s }
    var nextMonthsary: Date { cal.date(byAdding: .month, value: totalMonths + 1, to: s) ?? s }
    var nextNumber: Int { totalMonths + 1 }
    var nextLabel: String {
        nextNumber % 12 == 0 ? "\(nextNumber / 12)-year anniversary 🎉" : "\(nextNumber)-month anniversary"
    }
    var daysUntilNext: Int { cal.dateComponents([.day], from: today, to: nextMonthsary).day ?? 0 }
    var progressToNext: Double {
        let total = Double(cal.dateComponents([.day], from: lastMonthsary, to: nextMonthsary).day ?? 30)
        let done = Double(cal.dateComponents([.day], from: lastMonthsary, to: today).day ?? 0)
        return total > 0 ? min(1, max(0, done / total)) : 0
    }
    func date(afterDays n: Int) -> Date { cal.date(byAdding: .day, value: n, to: s) ?? s }
    func dayNumber(on date: Date) -> Int {
        max(0, cal.dateComponents([.day], from: s, to: cal.startOfDay(for: date)).day ?? 0)
    }
    func daysFromToday(to date: Date) -> Int {
        cal.dateComponents([.day], from: today, to: cal.startOfDay(for: date)).day ?? 0
    }
}

enum Palette {
    static let group = "group.com.edui.lovedays"
    static let defaults = UserDefaults(suiteName: group) ?? .standard
    static let themes: [(name: String, accent: Color, top: Color, bottom: Color)] = [
        ("Rose", .pink, Color(red: 1, green: 0.93, blue: 0.96), Color(red: 1, green: 0.80, blue: 0.88)),
        ("Lavender", Color(red: 0.6, green: 0.35, blue: 0.9), Color(red: 0.96, green: 0.93, blue: 1), Color(red: 0.84, green: 0.78, blue: 0.97)),
        ("Sunset", Color(red: 0.97, green: 0.45, blue: 0.25), Color(red: 1, green: 0.95, blue: 0.9), Color(red: 1, green: 0.82, blue: 0.72)),
        ("Ocean", Color(red: 0.1, green: 0.6, blue: 0.8), Color(red: 0.9, green: 0.97, blue: 1), Color(red: 0.72, green: 0.9, blue: 0.97)),
        ("Berry", Color(red: 0.75, green: 0.1, blue: 0.35), Color(red: 1, green: 0.9, blue: 0.93), Color(red: 0.95, green: 0.7, blue: 0.8))
    ]
    static var index: Int { min(max(defaults.integer(forKey: "theme"), 0), themes.count - 1) }
    static var accent: Color { themes[index].accent }
    static var top: Color { themes[index].top }
    static var bottom: Color { themes[index].bottom }
}
