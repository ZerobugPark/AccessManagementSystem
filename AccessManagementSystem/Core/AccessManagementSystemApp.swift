//
//  AccessManagementSystemApp.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI

@main
struct AccessManagementSystemApp: App {
    var body: some Scene {
        WindowGroup {
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
}
