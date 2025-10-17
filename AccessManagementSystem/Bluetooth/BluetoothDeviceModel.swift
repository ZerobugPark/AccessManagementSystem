//
//  BluetoothDeviceModel.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/16/25.
//

import CoreBluetooth

struct BluetoothDevice: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let serviceUUID: String
    let lastRSSI: Int
    let peripheral: CBPeripheral? // 런타임에서만 동작   

    enum CodingKeys: String, CodingKey {
        case id, name, serviceUUID, lastRSSI
        // peripheral 제외
    }
    
    // 스캔 시 (CentralManager)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        serviceUUID = try container.decode(String.self, forKey: .serviceUUID)
        lastRSSI = try container.decode(Int.self, forKey: .lastRSSI)
        peripheral = nil // 복원 불가, 런타임에서만 설정됨
    }

    func encode(to encoder: Encoder) throws {
         var container = encoder.container(keyedBy: CodingKeys.self)
         try container.encode(id, forKey: .id)
         try container.encode(name, forKey: .name)
         try container.encode(serviceUUID, forKey: .serviceUUID)
         try container.encode(lastRSSI, forKey: .lastRSSI)
     }

     // MARK: - 런타임 초기화
     init(peripheral: CBPeripheral, name: String, rssi: Int, serviceUUID: String = "FFE0") {
         self.id = peripheral.identifier
         self.name = name
         self.lastRSSI = rssi
         self.serviceUUID = serviceUUID
         self.peripheral = peripheral
     }
    
    
}



extension BluetoothDevice {
    func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaultManager.pairedDevice = data
            print("BLE 기기 정보 저장 완료:", name)
        } catch {
            print("BLE 기기 저장 실패:", error)
        }
    }

    static func loadFromUserDefaults() -> BluetoothDevice? {
        let data = UserDefaultManager.pairedDevice
        guard !data.isEmpty else { return nil }
        do {
            return try JSONDecoder().decode(BluetoothDevice.self, from: data)
        } catch {
            print("BLE 기기 불러오기 실패:", error)
            return nil
        }
    }

    static func clearFromUserDefaults() {
        UserDefaultManager.pairedDevice = Data()
        print("BLE 기기 정보 삭제 완료")
    }
}




enum BLEPayload {
    case ivUpdated
    case approve
    case refusal
    case auth(String)
    case unknown(String)
    
    init(rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if text == "IV_UPDATED" {
            self = .ivUpdated
        } else if text == "APPROVE" {
            self = .approve
        } else if text == "REFUSAL" {
            self = .refusal
        } else if text.hasPrefix("AUTH:") {
            let payload = String(text.dropFirst(5))
            self = .auth(payload)
        } else {
            self = .unknown(text)
        }
    }
}


struct User: Codable {
    let name: String
    let department: String
    let company: String
    let cardID: String
}

extension User {
    ///  유저 정보를 UserDefaults에 저장
    func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaultManager.userInfo = data
            print("사용자 정보가 UserDefaults에 저장되었습니다.")
        } catch {
            print("사용자 정보 저장 실패:", error)
        }
    }

    ///  UserDefaults에서 유저 정보 불러오기
    static func loadFromUserDefaults() -> User? {
        let data = UserDefaultManager.userInfo
        guard !data.isEmpty else { return nil }
        do {
            return try JSONDecoder().decode(User.self, from: data)
        } catch {
            print("사용자 정보 불러오기 실패:", error)
            return nil
        }
    }

    ///  저장된 사용자 정보 제거
    static func clearFromUserDefaults() {
        UserDefaultManager.userInfo = Data()
    }
}
