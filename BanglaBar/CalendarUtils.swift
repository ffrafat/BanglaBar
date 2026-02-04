//
//  CalendarUtils.swift
//  BanglaBar
//

import Foundation

struct CalendarUtils {
    static func getJulianDay(for date: Date) -> Double {
        let calendar = Calendar.current
        var year = Double(calendar.component(.year, from: date))
        var month = Double(calendar.component(.month, from: date))
        let day = Double(calendar.component(.day, from: date))
        
        if month <= 2 {
            year -= 1
            month += 12
        }
        
        let A = floor(year / 100.0)
        let B = 2.0 - A + floor(A / 4.0)
        
        return floor(365.25 * (year + 4716.0)) +
               floor(30.6001 * (month + 1.0)) +
               day + B - 1524.5
    }
}
