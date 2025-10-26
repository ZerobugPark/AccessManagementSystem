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
                        NotificationManager.shared.requestAuthorization()                        
                    }
            }
        }
        
        .modelContainer(for: [WorkLog.self]) 
    }
}

// MARK: - Notification Manager
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
    }
    
    /// 알림 권한 요청
    func requestAuthorization() {
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 알림 권한 허용")
            } else if let error = error {
                print("❌ 알림 권한 오류: \(error.localizedDescription)")
            } else {
                print("⚠️ 알림 권한 거부")
            }
            
            
        }
    }
    
    /// 포어그라운드에서도 알림 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        
        print("🔔 willPresent 호출됨! (포어그라운드)")
        print("   - Title: \(notification.request.content.title)")
        print("   - Body: \(notification.request.content.body)")
        
        completionHandler([.banner, .sound, .badge])
    }
    
    /// 알림 탭했을 때 처리 (선택사항)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📱 알림 탭됨: \(response.notification.request.content.body)")
        completionHandler()
    }
    
    /// 알림 발송 헬퍼 메서드
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 즉시 발송
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 알림 발송 실패: \(error.localizedDescription)")
            } else {
                print("✅ 알림 발송 성공: \(body)")
            }
        }
    }
}
