//
//  HolidayManager.swift
//  BanglaBar
//

import Foundation

struct Holiday: Codable, Identifiable {
    let id = UUID()
    let startDate: String // "YYYY-MM-DD"
    let endDate: String
    let name: String
    let type: String
    let moonDep: String
    let bankOnly: String
    let hilltractsOnly: String
    
    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
        case name
        case type
        case moonDep = "moon_dep"
        case bankOnly = "bank_only"
        case hilltractsOnly = "hilltracts_only"
    }
    
    var start: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: startDate)
    }
    
    var end: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: endDate)
    }
}

class HolidayManager {
    static let shared = HolidayManager()
    private var holidays: [Holiday] = []
    
    init() {
        loadHolidays()
    }
    
    private func loadHolidays() {
        guard let url = Bundle.main.url(forResource: "holidays", withExtension: "json") else {
            // Fallback for direct file access if bundle is not ready in dev
            let path = "/Users/ffrafat/Documents/Dev/BanglaBar/BanglaBar/holidays.json"
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                decode(data)
            }
            return
        }
        
        if let data = try? Data(contentsOf: url) {
            decode(data)
        }
    }
    
    private func decode(_ data: Data) {
        do {
            holidays = try JSONDecoder().decode([Holiday].self, from: data)
        } catch {
            print("Failed to decode holidays: \(error)")
        }
    }
    
    func getTodayHoliday(for date: Date = Date()) -> Holiday? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        
        return holidays.first { holiday in
            guard let startDate = holiday.start, let endDate = holiday.end else { return false }
            return startOfToday >= calendar.startOfDay(for: startDate) && startOfToday <= calendar.startOfDay(for: endDate)
        }
    }
    
    func getUpcomingHoliday(from date: Date = Date()) -> (holiday: Holiday, daysLeft: Int)? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        
        let upcoming = holidays.compactMap { holiday -> (Holiday, Date, Int)? in
            guard let startDate = holiday.start else { return nil }
            let holidayStart = calendar.startOfDay(for: startDate)
            
            if holidayStart > startOfToday {
                let components = calendar.dateComponents([.day], from: startOfToday, to: holidayStart)
                return (holiday, startDate, components.day ?? 0)
            }
            return nil
        }.sorted { $0.1 < $1.1 }
        
        if let first = upcoming.first {
            return (first.0, first.2)
        }
        return nil
    }
}
