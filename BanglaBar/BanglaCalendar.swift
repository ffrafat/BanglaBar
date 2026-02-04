//
//  BanglaCalendar.swift
//  BanglaBar
//
//  Pure logic module for Bangladesh Revised Bangla Calendar
//  Based on official Revised Bangla Calendar rules (post-1987)
//

import Foundation

/// Represents a date in the Bangladesh Bangla calendar
struct BanglaDate {
    let day: Int
    let month: Int
    let year: Int
    let weekday: String
    let season: String
    
    var monthName: String {
        BanglaCalendar.monthNames[month - 1]
    }
    
    var monthNameBengali: String {
        BanglaCalendar.monthNamesBengali[month - 1]
    }
}

/// Core calendar conversion logic for Bangladesh Revised Bangla Calendar
struct BanglaCalendar {
    
    // MARK: - Constants
    
    static let monthNames = [
        "Boishakh", "Jyoishtho", "Asharh", "Shrabon", "Bhadro",
        "Ashwin", "Kartik", "Ogrohayon", "Poush", "Magh",
        "Falgun", "Choitra"
    ]
    
    static let monthNamesBengali = [
        "বৈশাখ", "জ্যৈষ্ঠ", "আষাঢ়", "শ্রাবণ", "ভাদ্র",
        "আশ্বিন", "কার্তিক", "অগ্রহায়ণ", "পৌষ", "মাঘ",
        "ফাল্গুন", "চৈত্র"
    ]
    
    static let seasonsBengali = [
        "গ্রীষ্মকাল",   // Summer (Boishakh-Jyoishtho)
        "বর্ষাকাল",    // Monsoon (Asharh-Shrabon)
        "শরৎকাল",     // Autumn (Bhadro-Ashwin)
        "হেমন্তকাল",   // Late Autumn (Kartik-Ogrohayon)
        "শীতকাল",      // Winter (Poush-Magh)
        "বসন্তকাল"     // Spring (Falgun-Choitra)
    ]
    
    static let weekdaysBengali = [
        1: "রবিবার",    // Sunday
        2: "সোমবার",    // Monday
        3: "মঙ্গলবার",   // Tuesday
        4: "বুধবার",    // Wednesday
        5: "বৃহস্পতিবার", // Thursday
        6: "শুক্রবার",    // Friday
        7: "শনিবার"     // Saturday
    ]
    
    private static let bengaliDigits = ["০", "১", "২", "৩", "৪", "৫", "৬", "৭", "৮", "৯"]
    
    // MARK: - Public API
    
    /// Convert a Gregorian date to Bangla date
    static func toBanglaDate(_ gregorianDate: Date) -> BanglaDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current // Use local time
        
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: gregorianDate)
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let weekdayIndex = components.weekday else {
            fatalError("Invalid date components")
        }
        
        return toBanglaDate(year: year, month: month, day: day, weekdayIndex: weekdayIndex)
    }
    
    /// Convert Gregorian year/month/day to Bangla date
    static func toBanglaDate(year: Int, month: Int, day: Int, weekdayIndex: Int = 1) -> BanglaDate {
        // Step 1: Determine Bangla Year
        var banglaYear: Int
        if (month > 4) || (month == 4 && day >= 14) {
            banglaYear = year - 593
        } else {
            banglaYear = year - 594
        }
        
        // Step 2: Determine start of current Bangla year
        var startYearForOffset: Int
        if (month > 4) || (month == 4 && day >= 14) {
            startYearForOffset = year
        } else {
            startYearForOffset = year - 1
        }
        
        // Step 3: Compute day offset
        // offsetDays = number of days between banglaYearStart (April 14) and current date
        // Must use calendar calculation to handle leap years correctly in the Gregorian span
        let offsetDays = daysBetweenDate(
            fromYear: startYearForOffset, month: 4, day: 14,
            toYear: year, toMonth: month, toDay: day
        )
        
        // Step 4: Build Bangla month lengths for this year
        // Base: [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 29, 30] (2019 Revision: Ashwin is 31)
        var monthLengths = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 29, 30]
        
        // Check if Falgun needs adjustment
        // Determining Gregorian year in which Falgun occurs
        let falgunGregorianYear: Int
        if (month > 4) || (month == 4 && day >= 14) {
             // Bangla year started this Gregorian year, so Falgun is next year
             falgunGregorianYear = year + 1
        } else {
             // Bangla year started last Gregorian year, so Falgun is this year
             falgunGregorianYear = year
        }
        
        if isGregorianLeapYear(falgunGregorianYear) {
            monthLengths[10] = 30
        }
        
        // Step 5: Resolve Bangla month and day
        var remaining = offsetDays
        var banglaMonthIndex = 0
        var banglaDay = 1
        
        for i in 0..<12 {
            if remaining < monthLengths[i] {
                banglaMonthIndex = i
                banglaDay = remaining + 1
                break
            } else {
                remaining -= monthLengths[i]
            }
        }
        
        // Step 6: Weekday
        // Gregorian Sunday=1 maps to Bengali Sunday
        let weekdayName = weekdaysBengali[weekdayIndex] ?? "রবিবার"
        
        // Step 7: Season
        // 1-2: Grishma, 3-4: Barsha, 5-6: Sharat, 7-8: Hemanta, 9-10: Sheet, 11-12: Basanta
        // banglaMonthIndex is 0-based
        let seasonIndex = banglaMonthIndex / 2
        let seasonName = seasonsBengali[seasonIndex]
        
        // Bangla Month is 1-based (1..12) for the struct
        return BanglaDate(
            day: banglaDay,
            month: banglaMonthIndex + 1,
            year: banglaYear,
            weekday: weekdayName,
            season: seasonName
        )
    }
    
    /// Convert a number to Bengali digits
    static func toBengaliNumerals(_ number: Int) -> String {
        String(number).map { char in
            if let digit = Int(String(char)) {
                return bengaliDigits[digit]
            }
            return String(char)
        }.joined()
    }
    
    /// Format a Gregorian date to Bengali string: \"রবিবার, ২৩ মার্চ, ২০২৬\"
    static func formatGregorianDateToBengali(_ date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let weekdayIndex = calendar.component(.weekday, from: date)
        
        let bWeekdays = [
            1: "রবিবার", 2: "সোমবার", 3: "মঙ্গলবার", 4: "বুধবার",
            5: "বৃহস্পতিবার", 6: "শুক্রবার", 7: "শনিবার"
        ]
        
        let bMonths = [
            1: "জানুয়ারি", 2: "ফেব্রুয়ারি", 3: "মার্চ", 4: "এপ্রিল",
            5: "মে", 6: "জুন", 7: "জুলাই", 8: "আগস্ট",
            9: "সেপ্টেম্বর", 10: "অক্টোবর", 11: "নভেম্বর", 12: "ডিসেম্বর"
        ]
        
        let dayStr = toBengaliNumerals(day)
        let yearStr = toBengaliNumerals(year)
        let weekdayStr = bWeekdays[weekdayIndex] ?? ""
        let monthStr = bMonths[month] ?? ""
        
        return "\(weekdayStr), \(dayStr) \(monthStr), \(yearStr)"
    }
    
    // MARK: - Greeting Logic
    
    static func getGreeting(for date: Date = Date()) -> String {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 5..<12:
            return "সুপ্রভাত" // Morning
        case 12..<18:
            return "শুভ অপরাহ্ন" // Noon/Afternoon
        case 18..<23:
            return "শুভ সন্ধ্যা" // Evening
        default:
            return "শুভ রাত্রি" // Late night (23-5)
        }
    }
    
    static func getGreetingIconName(for date: Date = Date()) -> String {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 5..<18:
            return "sun.max.fill" // Morning & Afternoon
        default:
            return "moon.fill" // Evening & Night
        }
    }

    // MARK: - Helper Functions
    
    /// Calculate exact days between two dates using Calendar
    private static func daysBetweenDate(fromYear: Int, month: Int, day: Int,
                                      toYear: Int, toMonth: Int, toDay: Int) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // Use GMT to avoid DST gaps
        
        let fromComponents = DateComponents(year: fromYear, month: month, day: day)
        let toComponents = DateComponents(year: toYear, month: toMonth, day: toDay)
        
        guard let fromDate = calendar.date(from: fromComponents),
              let toDate = calendar.date(from: toComponents) else {
            return 0
        }
        
        let components = calendar.dateComponents([.day], from: fromDate, to: toDate)
        return components.day ?? 0
    }
    
    /// Check if a Gregorian year is a leap year
    private static func isGregorianLeapYear(_ year: Int) -> Bool {
        if year % 400 == 0 { return true }
        if year % 100 == 0 { return false }
        if year % 4 == 0 { return true }
        return false
    }
}

// MARK: - Formatting Extensions

extension BanglaDate {
    /// Format: "আজ বুধবার"
    func formattedWeekdayPrefix() -> String {
        return "আজ \(weekday)"
    }
    
    /// Format: "২১ মাঘ, ১৪৩২"
    func formattedDateOnly() -> String {
        let dayStr = BanglaCalendar.toBengaliNumerals(day)
        let yearStr = BanglaCalendar.toBengaliNumerals(year)
        return "\(dayStr) \(monthNameBengali), \(yearStr)"
    }

    /// Format: "আজ বুধবার, ২১ মাঘ, ১৪৩২"
    func formattedWithPrefix() -> String {
        return "\(formattedWeekdayPrefix()), \(formattedDateOnly())"
    }

    /// Format as "১২ মাঘ ১৪৩২"
    func formatted() -> String {
        let dayStr = BanglaCalendar.toBengaliNumerals(day)
        let yearStr = BanglaCalendar.toBengaliNumerals(year)
        return "\(dayStr) \(monthNameBengali) \(yearStr)"
    }
    
    /// Format as "১২ মাঘ"
    func formattedShort() -> String {
        let dayStr = BanglaCalendar.toBengaliNumerals(day)
        return "\(dayStr) \(monthNameBengali)"
    }
    
    /// Get SF Symbol name for the season
    var seasonIconName: String {
        switch season {
        case "গ্রীষ্ম", "গ্রীষ্মকাল": return "sun.max.fill"
        case "বর্ষা", "বর্ষাকাল": return "cloud.heavyrain.fill"
        case "শরৎ", "শরৎকাল": return "cloud.sun.fill"
        case "হেমন্ত", "হেমন্তকাল": return "wind"
        case "শীত", "শীতকাল": return "snowflake"
        case "বসন্ত", "বসন্তকাল": return "leaf.fill"
        default: return "sun.max.fill"
        }
    }
    
    /// Format full with weekday: "শুক্রবার, ২২ মাঘ, ১৪৩২"
    func formattedFull() -> String {
        return "\(weekday), \(formattedDateOnly())"
    }
    
    /// Format with English month name for debugging
    func formattedEnglish() -> String {
        "\(day) \(monthName) \(year)"
    }
}
