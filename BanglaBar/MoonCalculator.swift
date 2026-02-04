//
//  MoonCalculator.swift
//  BanglaBar
//
//  Offline Moon Phase Calculator
//

import Foundation

struct MoonCalculator {
    static let SYNODIC_MONTH = 29.530588853
    static let REFERENCE_NEW_MOON_JD = 2451550.1 // 2000-01-06 18:14 UTC
    
    static func getMoonPhase(for date: Date = Date()) -> (name: String, icon: String) {
        let JD = CalendarUtils.getJulianDay(for: date)
        
        let daysSinceNew = JD - REFERENCE_NEW_MOON_JD
        var moonAge = daysSinceNew.truncatingRemainder(dividingBy: SYNODIC_MONTH)
        if moonAge < 0 {
            moonAge += SYNODIC_MONTH
        }
        
        // Standard thresholds based on 29.53 day cycle
        if moonAge < 1.84566 {
            return ("অমাবস্যা", "moonphase.new.moon")
        } else if moonAge < 5.53699 {
            return ("চাঁদ বাড়ছে", "moonphase.waxing.crescent")
        } else if moonAge < 9.22831 {
            return ("প্রথম চতুর্থাংশ", "moonphase.first.quarter")
        } else if moonAge < 12.91963 {
            return ("চাঁদ বাড়ছে", "moonphase.waxing.gibbous")
        } else if moonAge < 16.61096 {
            return ("পূর্ণিমা", "moonphase.full.moon")
        } else if moonAge < 20.30228 {
            return ("চাঁদ কমছে", "moonphase.waning.gibbous")
        } else if moonAge < 23.99361 {
            return ("শেষ চতুর্থাংশ", "moonphase.last.quarter")
        } else if moonAge < 27.68493 {
            return ("চাঁদ কমছে", "moonphase.waning.crescent")
        } else {
            return ("অমাবস্যা", "moonphase.new.moon")
        }
    }
}
