//
//  ContentView.swift
//  BanglaBar
//
//  Created by Faisal F Rafat on 2/4/26.
//

import SwiftUI
import ServiceManagement

struct MenuBarContentView: View {
    @EnvironmentObject var dateManager: BanglaDateManager
    @State private var showingSettings = false
    @State private var showingAbout = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content Area (Now Transparent)
            VStack(alignment: .center, spacing: 10) {
                // Greeting + Icon + Day Info
                HStack(spacing: 6) {
                    Text(BanglaCalendar.getGreeting())
                    Image(systemName: BanglaCalendar.getGreetingIconName())
                        .font(.system(size: 10))
                    Text(dateManager.todayHolidayName != nil ? "আজ ছুটির দিন" : dateManager.currentBanglaDate.formattedWeekdayPrefix())
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                
                // Today Holiday Name (if any)
                if let today = dateManager.todayHolidayName {
                    Text(today)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, -4)
                }
                
                // Date
                Text(dateManager.currentBanglaDate.formattedDateOnly())
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Season
                Text(dateManager.currentBanglaDate.season)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                // Solar Times (Sunrise/Sunset)
                if let sunrise = dateManager.sunriseTime, let sunset = dateManager.sunsetTime {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("সূর্যোদয়")
                            Image(systemName: "sunrise.fill")
                            Text(sunrise)
                        }
                        
                        HStack(spacing: 4) {
                            Text("সূর্যাস্ত")
                            Image(systemName: "sunset.fill")
                            Text(sunset)
                        }
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .imageScale(.small)
                }
                
                // Moon Phase
                if let moonIcon = dateManager.moonPhaseIcon, let moonName = dateManager.moonPhaseName {
                    HStack(spacing: 6) {
                        Image(systemName: moonIcon)
                            .imageScale(.small)
                        Text(moonName)
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                }
                
                // Upcoming Holiday
                if let hName = dateManager.upcomingHolidayName,
                   let daysText = dateManager.upcomingHolidayDaysLeftText {
                    VStack(spacing: 3) {
                        Text("পরবর্তী সরকারি ছুটি \(daysText)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                        
                        HStack(spacing: 4) {
                            Text(hName)
                            ForEach(dateManager.upcomingHolidayIcons, id: \.self) { icon in
                                Text(icon).font(.system(size: 13))
                            }
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        
                        if let hDate = dateManager.upcomingHolidayDate {
                            Text(hDate)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            
            Divider().background(Color.white.opacity(0.1))
            
            // Minimal Footer (Right Aligned)
            HStack(spacing: 16) {
                Spacer()
                
                Button(action: { showingAbout.toggle() }) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.3))
                .popover(isPresented: $showingAbout, arrowEdge: .bottom) {
                    AboutPopoverView()
                }
                
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.3))
                .popover(isPresented: $showingSettings, arrowEdge: .bottom) {
                    SettingsPopoverView()
                }
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .frame(width: 300)
        .background(.ultraThinMaterial) // Native translucency
        .preferredColorScheme(.dark)
    }
}

// MARK: - Subviews (Also Minimal)

struct SettingsPopoverView: View {
    @State private var isLaunchAtLoginEnabled: Bool = SMAppService.mainApp.status == .enabled
    @AppStorage("menuBarFormat") private var menuBarFormat: MenuBarFormat = .standard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings").font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Menu Bar Style")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $menuBarFormat) {
                    ForEach(MenuBarFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            Toggle("Launch at Login", isOn: $isLaunchAtLoginEnabled)
                .toggleStyle(.checkbox)
                .onChange(of: isLaunchAtLoginEnabled) { newValue in
                    updateLaunchAtLogin(enabled: newValue)
                }
        }
        .padding(16)
        .frame(width: 220)
        .preferredColorScheme(.dark)
        .onAppear {
            // Re-sync status when popover appears
            isLaunchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("Failed to update Launch at Login: \(error)")
            // Rollback state if it fails
            isLaunchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }
}

struct AboutPopoverView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("BanglaBar").font(.headline)
            Text("Version 1.0.1")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
            
            Divider().background(Color.white.opacity(0.1))
            
            VStack(spacing: 4) {
                Text("Developed by")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                Text("Faisal F Rafat")
                    .font(.system(size: 14, weight: .bold))
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    if let url = URL(string: "mailto:ff@rafat.cc") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.5))
                
                Button(action: {
                    if let url = URL(string: "https://rafat.cc") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Image(systemName: "globe")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 2)
            
            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    Text("Made with")
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.red.opacity(0.7))
                    Text("in Dhaka")
                }
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
                
                HStack(spacing: 3) {
                    Image(systemName: "c.circle")
                        .font(.system(size: 9))
                    Text("2026")
                }
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.2))
            }
            .padding(.top, 4)
            
            Divider().background(Color.white.opacity(0.1))
            
            Button("Check for Updates") {
                if let url = URL(string: "https://github.com/ffrafat/banglabar/releases") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.1)))
        }
        .padding(18)
        .frame(width: 240)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MenuBarContentView()
        .environmentObject(BanglaDateManager())
}

struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}
