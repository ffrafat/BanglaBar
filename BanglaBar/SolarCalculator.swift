//
//  SolarCalculator.swift
//  BanglaBar
//
//  Offline Sunrise/Sunset Calculator (NOAA Algorithm)
//  Calibrated for Dhaka, Bangladesh
//

import Foundation

struct SolarCalculator {
    struct SolarTimes {
        let sunrise: String
        let sunset: String
    }
    
    // Fixed Location: Dhaka
    static let latitude: Double = 23.7806
    static let longitude: Double = 90.2794
    static let timezone: Double = 6.0
    static let solarAltitude: Double = -0.833
    
    static func getSolarTimes(for date: Date = Date()) -> SolarTimes {
        // Step 1: Julian Day (JD)
        let JD = CalendarUtils.getJulianDay(for: date)
        
        // Step 2: Julian Century (T)
        let T = (JD - 2451545.0) / 36525.0
        
        // Step 3: Solar Mean Values
        var L0 = 280.46646 + T * (36000.76983 + 0.0003032 * T)
        L0 = L0.truncatingRemainder(dividingBy: 360.0)
        if L0 < 0 { L0 += 360.0 }
        
        let M = 357.52911 + T * (35999.05029 - 0.0001537 * T)
        let e = 0.016708634 - T * (0.000042037 + 0.0000001267 * T)
        
        // Step 4: Equation of Center
        let mRad = M * .pi / 180.0
        let C = sin(mRad) * (1.914602 - T * (0.004817 + 0.000014 * T)) +
                sin(2.0 * mRad) * (0.019993 - 0.000101 * T) +
                sin(3.0 * mRad) * 0.000289
        
        // Step 5: True Solar Longitude
        let trueLong = L0 + C
        let trueLongRad = trueLong * .pi / 180.0
        
        // Step 6: Obliquity of Ecliptic
        let epsilon = 23.439291 - 0.0130042 * T
        let epsilonRad = epsilon * .pi / 180.0
        
        // Step 7: Solar Declination
        let declination = asin(sin(epsilonRad) * sin(trueLongRad)) * 180.0 / .pi
        let decRad = declination * .pi / 180.0
        
        // Step 8: Equation of Time (minutes)
        let y = pow(tan(epsilonRad / 2.0), 2.0)
        let l0Rad = L0 * .pi / 180.0
        
        let eqTime = 4.0 * (180.0 / .pi) * (
            y * sin(2.0 * l0Rad) -
            2.0 * e * sin(mRad) +
            4.0 * e * y * sin(mRad) * cos(2.0 * l0Rad) -
            0.5 * y * y * sin(4.0 * l0Rad) -
            1.25 * e * e * sin(2.0 * mRad)
        )
        
        // Step 9: Hour Angle (degrees)
        let latRad = latitude * .pi / 180.0
        let altRad = solarAltitude * .pi / 180.0
        
        let cosH = (sin(altRad) - sin(latRad) * sin(decRad)) / (cos(latRad) * cos(decRad))
        
        // Clamp cosH to [-1, 1] to avoid NaN
        let clampedCosH = max(-1.0, min(1.0, cosH))
        let H = acos(clampedCosH) * 180.0 / .pi
        
        // Step 10: Solar Noon (minutes from midnight)
        let solarNoon = 720.0 - 4.0 * longitude - eqTime + timezone * 60.0
        
        // Step 11: Sunrise & Sunset (minutes)
        let sunriseMinutes = solarNoon - H * 4.0
        let sunsetMinutes = solarNoon + H * 4.0
        
        return SolarTimes(
            sunrise: formatMinutes(sunriseMinutes),
            sunset: formatMinutes(sunsetMinutes)
        )
    }
    
    private static func formatMinutes(_ totalMinutes: Double) -> String {
        var mins = Int(round(totalMinutes))
        var hours = mins / 60
        mins = mins % 60
        
        if mins == 60 {
            mins = 0
            hours += 1
        }
        
        var displayHours = hours % 12
        if displayHours == 0 { displayHours = 12 }
        
        let hStr = toBengaliNumerals(String(displayHours))
        let mStr = toBengaliNumerals(String(format: "%02d", mins))
        
        return "\(hStr) টা \(mStr) মি."
    }
    
    static func toBengaliNumerals(_ input: String) -> String {
        return input.map { char -> String in
            if let digit = Int(String(char)) {
                let bengaliDigits = ["০", "১", "২", "৩", "৪", "৫", "৬", "৭", "৮", "৯"]
                return bengaliDigits[digit]
            }
            return String(char)
        }.joined()
    }
}
