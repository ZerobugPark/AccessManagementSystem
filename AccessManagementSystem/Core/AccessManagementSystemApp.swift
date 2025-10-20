//
//  AccessManagementSystemApp.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI
import SwiftData


@main
struct AccessManagementSystemApp: App {
    
    @State private var showOnboarding = true
    
    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                Onboarding()
                    .transition(.opacity)
                    .onAppear { 
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            withAnimation(.easeOut(duration: 0.5)) { 
                                showOnboarding = false
                            }
                        }
                    }
            }
            else {
                MainView()
                    .onAppear {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                            if granted {
                                print("알림 권한 허용")
                            }
                        }
                        
                    }
            }
        }
        
        .modelContainer(for: [WorkLog.self]) 
    }
}
