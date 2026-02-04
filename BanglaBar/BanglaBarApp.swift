//
//  BanglaBarApp.swift
//  BanglaBar
//
//  Created by Faisal F Rafat on 2/4/26.
//

import SwiftUI
import Combine
import ServiceManagement

enum MenuBarFormat: String, CaseIterable, Identifiable {
    case short = "Short"
    case standard = "Medium"
    case full = "Long"
    
    var id: String { self.rawValue }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Set policy to accessory to hide from Dock while keeping UI accessible
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Auto-enable Launch at Login on first run
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            do {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                    print("Launch at Login enabled by default.")
                }
            } catch {
                print("Failed to auto-enable Launch at Login: \(error)")
            }
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
}

@main
struct BanglaBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dateManager = BanglaDateManager()
    @AppStorage("menuBarFormat") private var menuBarFormat: MenuBarFormat = .standard
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(dateManager)
        } label: {
            Text(formattedDate)
        }
        .menuBarExtraStyle(.window)
    }
    
    private var formattedDate: String {
        switch menuBarFormat {
        case .standard:
            return dateManager.currentBanglaDate.formatted()
        case .short:
            return dateManager.currentBanglaDate.formattedShort()
        case .full:
            return dateManager.currentBanglaDate.formattedFull()
        }
    }
}




/// Manages the current Bangla date and updates at midnight
class BanglaDateManager: ObservableObject {
    @Published var currentBanglaDate: BanglaDate
    @Published var todayHolidayName: String?
    @Published var todayHolidayIcons: [String] = []
    @Published var upcomingHolidayLabel: String = "পরবর্তী সরকারি ছুটি"
    @Published var upcomingHolidayName: String?
    @Published var upcomingHolidayIcons: [String] = []
    @Published var upcomingHolidayDate: String?
    @Published var upcomingHolidayDaysLeftText: String?
    @Published var sunriseTime: String?
    @Published var sunsetTime: String?
    @Published var moonPhaseName: String?
    @Published var moonPhaseIcon: String?
    private var timer: Timer?
    
    init() {
        self.currentBanglaDate = BanglaCalendar.toBanglaDate(Date())
        updateHolidayInfo()
        startTimer()
    }
    
    private func startTimer() {
        // Update at midnight (and holidays)
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateDate()
        }
    }
    
    private func updateDate() {
        let now = Date()
        let newDate = BanglaCalendar.toBanglaDate(now)
        if newDate.day != currentBanglaDate.day ||
           newDate.month != currentBanglaDate.month ||
           newDate.year != currentBanglaDate.year {
            currentBanglaDate = newDate
            updateHolidayInfo()
        }
    }
    
    func updateHolidayInfo() {
        let now = Date()
        
        // Solar Times
        let solar = SolarCalculator.getSolarTimes(for: now)
        sunriseTime = solar.sunrise
        sunsetTime = solar.sunset
        
        // Moon Phase
        let moon = MoonCalculator.getMoonPhase(for: now)
        moonPhaseName = moon.name
        moonPhaseIcon = moon.icon
        
        // 1. Check for today's holiday
        if let today = HolidayManager.shared.getTodayHoliday(for: now) {
            todayHolidayName = today.name
            todayHolidayIcons = [] // No icons for today as requested
        } else {
            todayHolidayName = nil
            todayHolidayIcons = []
        }
        
        // 2. Check for upcoming holiday
        if let next = HolidayManager.shared.getUpcomingHoliday(from: now) {
            upcomingHolidayName = next.holiday.name
            upcomingHolidayIcons = getIcons(for: next.holiday)
            
            // Format Gregorian Date
            if let startDate = next.holiday.start {
                upcomingHolidayDate = BanglaCalendar.formatGregorianDateToBengali(startDate)
            } else {
                upcomingHolidayDate = nil
            }
            
            // Format Days Left in Bengali
            let daysNum = BanglaCalendar.toBengaliNumerals(next.daysLeft)
            upcomingHolidayDaysLeftText = "\(daysNum) দিন পর"
        } else {
            upcomingHolidayName = nil
            upcomingHolidayIcons = []
            upcomingHolidayDate = nil
            upcomingHolidayDaysLeftText = nil
        }
    }
    
    private func getIcons(for holiday: Holiday) -> [String] {
        var icons: [String] = []
        if holiday.moonDep == "yes" { icons.append("🌙") }
        if holiday.hilltractsOnly == "yes" { icons.append("⛰️") }
        if holiday.bankOnly == "yes" { icons.append("🏦") }
        return icons
    }
    
    deinit {
        timer?.invalidate()
    }
}


