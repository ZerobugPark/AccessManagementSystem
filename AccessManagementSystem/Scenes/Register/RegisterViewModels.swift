//
//  RegisterViewModel.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import Foundation
import Combine
import CoreBluetooth


//final class BluetoothViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
//    @Published var devices: [DiscoveredDevice] = []
//    @Published var connectedPeripheral: CBPeripheral?
//    @Published var statusMessage: String = "스캔 중..."
//    @Published var receivedText: String = ""
//    @Published var isRegistered: Bool = false // ✅ OK 수신 여부
//    @Published var isFinshed: Bool = false
//    
//    private var central: CBCentralManager!
//    private var targetCharacteristic: CBCharacteristic?
//    private var lastConnectedDevice: DiscoveredDevice?
//    private var isUserInitiatedDisconnect = false
//    
//    override init() {
//        super.init()
//        central = CBCentralManager(delegate: self, queue: nil)
//    }
//    
//    // MARK: - Bluetooth Delegate
//    
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        switch central.state {
//        case .poweredOn:
//            statusMessage = "스캔 시작"
//            // ✅ 앱 시작 시 즉시 스캔
//            central.scanForPeripherals(withServices: nil, options: nil)
//        default:
//            statusMessage = "주변에 기기가 없습니다."
//        }
//    }
//    
//    // MARK: - 주변 장치 발견
//    func centralManager(_ central: CBCentralManager,
//                        didDiscover peripheral: CBPeripheral,
//                        advertisementData: [String : Any],
//                        rssi RSSI: NSNumber) {
//        
//        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
//        let cacheName = peripheral.name
//        let uuid = peripheral.identifier.uuidString
//        let displayName = advName ?? cacheName ?? "(UUID: \(uuid.prefix(6)))"
//        
//        // ✅ 'Door' 포함된 이름만 표시
//        guard displayName.localizedCaseInsensitiveContains("DOOR") else { return }
//        
//        
//        if let index = devices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
//            devices[index] = DiscoveredDevice(peripheral: peripheral, name: displayName)
//        } else {
//            devices.append(DiscoveredDevice(peripheral: peripheral, name: displayName))
//        }
//    }
//    
//    // MARK: - 연결
//    func connect(to device: DiscoveredDevice) {
//        statusMessage = "\(device.name) 연결 시도..."
//        isUserInitiatedDisconnect = false
//        isRegistered = false
//        connectedPeripheral = nil
//        central.connect(device.peripheral, options: nil)
//    }
//    
//    // 연결 성공 시
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        //statusMessage = "✅ 연결 성공: \(peripheral.name ?? "이름 없음")"
//        connectedPeripheral = peripheral
//        lastConnectedDevice = DiscoveredDevice(peripheral: peripheral, name: peripheral.name ?? "")
//        print("123")
//        print(peripheral)
//        peripheral.delegate = self
//        peripheral.discoverServices([CBUUID(string: "FFE0")])
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        if let services = peripheral.services {
//            for service in services {
//                peripheral.discoverCharacteristics([CBUUID(string: "FFE1")], for: service)
//            }
//        }
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral,
//                    didDiscoverCharacteristicsFor service: CBService,
//                    error: Error?) {
//        if let chars = service.characteristics {
//            for char in chars {
//                if char.uuid == CBUUID(string: "FFE1") { // FFE1 → 실제 데이터 송수신이 일어나는 채널 (TX/RX)
//                    targetCharacteristic = char
//                    peripheral.setNotifyValue(true, for: char)
//                    // ✅ 연결 직후 아두이노에 register 요청
//                    send("REGISTER")
//                }
//            }
//        }
//        
//        for char in service.characteristics ?? [] {
//             print("   🔸 특성 발견: \(char.uuid) | 속성: \(char.properties)")
//         }
//        
//    }
//    
//    // MARK: - 데이터 수신
//    func peripheral(_ peripheral: CBPeripheral,
//                    didUpdateValueFor characteristic: CBCharacteristic,
//                    error: Error?) {
//        guard error == nil else {
//            print("characteristic update error: \(error!.localizedDescription)")
//            return
//        }
//        
//        if let data = characteristic.value,
//           let text = String(data: data, encoding: .utf8)?
//            .trimmingCharacters(in: .whitespacesAndNewlines) {
//            
//            Task { @MainActor in
//                receivedText = text
//                print("📩 수신: \(text)")
//                
//                switch text.uppercased() {
//                case "READY_FOR_DATA":
//                    let user = User.loadFromUserDefaults()
//                    if let user = user {
//                        
//                        if let encrypted = AES128CBC.encrypt(user.cardID, key: CryptionKey.secretKey, iv: CryptionKey.iv) {
//                            print("🔒 암호문 (Base64):", encrypted)
//
//                            // 복호화 테스트
//                            if let data = Data(base64Encoded: encrypted), let decrypted = AES128CBC.decrypt(data, key: CryptionKey.secretKey, iv: CryptionKey.iv) {
//                                print("🔓 복호화 결과:", decrypted)
//                            } 
//                            
//                            let payload = "USER:\(encrypted)"
//                            await sendChunked(payload)
//                        } else {
//                            print("암호화 실패")
//                        }
//                        
//                        statusMessage = "👤 사용자 정보 전송 중..."
//                    } else {
//                        statusMessage = "⚠️ 사용자 정보가 없습니다."
//                    }
//                    
//                case "COMPLETE":
//                    isRegistered = true
//                    statusMessage = "✅ 등록 완료"
//                    
//                    if let connected = connectedPeripheral {
//                        let paired = PairedDevice(
//                            id: connected.identifier,
//                            name: connected.name ?? "Unknown",
//                            serviceUUID: "FFE0",
//                            lastRSSI: nil
//                        )
//                        paired.saveToUserDefaults()
//                        print("💾 PairedDevice 저장 완료:", paired.name)
//                    }
//                    
//                    Task {
//                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
//                        await MainActor.run {
//                            self.disconnect()
//                        }
//                    }
//                    
//                case "OK":
//                    statusMessage = "✅ 연결 성공"
//                    
//                default:
//                    break
//                }
//            }
//        }
//    }
//    
//    // MARK: - 전송
//    private func send(_ text: String) {
//        if let peripheral = connectedPeripheral,
//           let char = targetCharacteristic {
//            if let data = (text + "\n").data(using: .utf8) { 
//                peripheral.writeValue(data, for: char, type: .withResponse)
//                print("📤 전송: \(text)")
//            }
//        }
//    }
//    
//    private func sendChunked(_ text: String) async {
//        guard let peripheral = connectedPeripheral,
//              let char = targetCharacteristic else { return }
//
//        let data = Data(text.utf8)
//        let mtu = 20
//        var offset = 0
//
//        while offset < data.count {
//            let end = min(offset + mtu, data.count)
//            let chunk = data.subdata(in: offset..<end)
//            peripheral.writeValue(chunk, for: char, type: .withResponse)
//            print("📤 Chunk (\(chunk.count) bytes): \(String(data: chunk, encoding: .utf8) ?? "")")
//            try? await Task.sleep(nanoseconds: 50_000) // 50ms delay
//            offset = end
//        }
//
//        // ✅ 모든 chunk 전송 후 줄바꿈(\r\n) 한 번만 보내기
//        if let newline = "\r\n".data(using: .utf8) {
//            peripheral.writeValue(newline, for: char, type: .withResponse)
//            print("📤 (마지막 줄바꿈 전송)")
//        }
//    }
//    
//    // MARK: - 연결 해제
//    func disconnect() {
//        if let peripheral = connectedPeripheral {
//            isUserInitiatedDisconnect = true
//            central.cancelPeripheralConnection(peripheral)
//        }
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
//        connectedPeripheral = nil
//        if isUserInitiatedDisconnect {
//            statusMessage = "🔌 사용자에 의해 연결 해제"
//        } else {
//            statusMessage = "⚠️ 연결 끊김 — 재시도 가능"
//        }
//    }
//}
//
