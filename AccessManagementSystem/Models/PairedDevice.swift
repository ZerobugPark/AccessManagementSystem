//
//  PairedDevice.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/15/25.
//

import Foundation

struct PairedDevice: Codable, Identifiable {
    let id: UUID             // peripheral.identifier
    let name: String         // 표시용 이름
    let serviceUUID: String  // 주 서비스 (예: "FFE0")
    let lastRSSI: Int?       // 마지막 감지 신호 세기
}

extension PairedDevice {
    ///  페어링된 기기를 UserDefaults에 저장
    func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaultManager.pairedDevice = data
            print("✅ 페어링된 기기 정보가 UserDefaults에 저장되었습니다.")
        } catch {
            print("❌ 페어링 기기 저장 실패:", error)
        }
    }

    ///  UserDefaults에서 페어링 기기 불러오기
    static func loadFromUserDefaults() -> PairedDevice? {
        let data = UserDefaultManager.pairedDevice
        guard !data.isEmpty else { return nil }
        do {
            return try JSONDecoder().decode(PairedDevice.self, from: data)
        } catch {
            print("❌ 페어링 기기 불러오기 실패:", error)
            return nil
        }
    }

    ///  저장된 페어링 기기 정보 제거
    static func clearFromUserDefaults() {
        UserDefaultManager.pairedDevice = Data()
        print("🗑️ 페어링된 기기 정보가 삭제되었습니다.")
    }
}

