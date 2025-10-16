//
//  MainViewModel.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/15/25.
//

import Foundation
import CoreBluetooth
import Combine

final class MainViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var pairedDevice: PairedDevice?
    @Published var userInfo: User?
    @Published var isConnected: Bool = false
    @Published var statusMessage: String = "대기 중..."
    
    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var rssiThreshold: Int = -30 // ✅ 약 0~10cm 기준
    private var lastRSSILogTime = Date()
    private var targetCharacteristic: CBCharacteristic?
    
    // MARK: - 초기화
    /// NSObject 채택시, 오버라이드 필요
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
        userInfo = User.loadFromUserDefaults()
        loadPairedDevice()
    }
    
    // MARK: - 저장된 장치 불러오기
    func loadPairedDevice() {
        pairedDevice = PairedDevice.loadFromUserDefaults()
    }
    
    // MARK: - 블루투스 상태 변화
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("📡 Bluetooth ON → 지속 스캔 시작")
            if let paired = pairedDevice {
                startContinuousScan(for: paired.serviceUUID)
            } else {
                statusMessage = "등록된 기기가 없습니다."
            }
            
        default:
            print("⚠️ Bluetooth 비활성화")
            statusMessage = "블루투스를 켜주세요"
            central.stopScan()
        }
    }
    
    // MARK: - 지속 스캔 (타이머 없이)
    private func startContinuousScan(for serviceUUID: String) {
        central.stopScan()
        central.scanForPeripherals(
            withServices: [CBUUID(string: serviceUUID)],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true] // ✅ 광고 수신마다 didDiscover 호출
        )
        print("🔍 지속 스캔 시작 (\(serviceUUID))")
    }
    
    // MARK: - 주변 장치 발견 (RSSI 기준 자동 연결)
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        guard let paired = pairedDevice else { return }
        guard peripheral.identifier == paired.id else { return }
        
        let rssiValue = Int8(truncating: RSSI)

        // ⚠️ 유효하지 않은 RSSI는 무시 (실제 신호가 아닌 잘못된 값, 측정 실패)
        if rssiValue == 127 {
            print("⚠️ RSSI 유효하지 않음 (127)")
            return
        }
        
        
        // 로그 출력 제한 (1초마다 한 번)
        let now = Date()
        if now.timeIntervalSince(lastRSSILogTime) > 1 {
            print("📶 RSSI: \(rssiValue)dBm for \(paired.name)")
            lastRSSILogTime = now
        }
        
        
        // ✅ RSSI 기준은 Int로 변환해서 비교
        if Int(rssiValue) >= rssiThreshold {
            print("✅ RSSI 기준 통과 → \(paired.name) 연결 시도 (\(rssiValue)dBm ≥ \(rssiThreshold)dBm)")
            central.stopScan()
            connectedPeripheral = peripheral
            peripheral.delegate = self
            central.connect(peripheral, options: nil)
            statusMessage = "RSSI 기준 충족 → 자동 연결 중..."
        }    
    }
    
    // MARK: - 연결 성공 (물리적 연결)
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\(peripheral.name ?? "Unknown") 연결 완료")
        statusMessage = "연결 완료"
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: "FFE0")]) // FFE0 UUID ㅊ검색 (HM-10 모듈)
    }
    
    // MARK: 서비스 제공 목록 찾음
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics([CBUUID(string: "FFE1")], for: service) // FFE1 데이터 송수신용 채널
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let chars = service.characteristics {
            for char in chars {
                if char.uuid == CBUUID(string: "FFE1") {
                    targetCharacteristic = char
                    peripheral.setNotifyValue(true, for: char) // 데이터 수신 허용
                    // ✅ 연결 직후 아두이노에 register 요청
                    Task {
                        await sendChunked("IV:\(CryptionKey.iv)")    
                    }
                    
                }
            }
        }
    }
    
    
    
    // MARK: - 연결 해제 → 자동 스캔 재시작
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 연결 해제됨 → 스캔 재시작")
        isConnected = false
        statusMessage = "연결 끊김 — 자동 재검색 중..."
        
        // 다시 스캔 재시작
        if let paired = pairedDevice {
            startContinuousScan(for: paired.serviceUUID)
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil else {
            print("characteristic update error: \(error!.localizedDescription)")
            return
        }
        
        if let data = characteristic.value,
           let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) {
            
            Task { @MainActor in
                //receivedText = text
                print("📩 수신: \(text)")
                
                switch text.uppercased() {
                case "IV_UPDATED":
                    
                    if let encrypted = AES128CBC.encrypt(userInfo?.cardID ?? "", key: CryptionKey.secretKey, iv: CryptionKey.iv) {
                        print("🔒 암호문 (Base64):", encrypted)

                        // 복호화 테스트
                        if let data = Data(base64Encoded: encrypted), let decrypted = AES128CBC.decrypt(data, key: CryptionKey.secretKey, iv: CryptionKey.iv) {
                            print("🔓 복호화 결과:", decrypted)
                        } 
                        
                        let payload = "AUTH:\(encrypted)"
                        await sendChunked(payload)
                    } else {
                        print("암호화 실패")
                    }
                    
                case "APPROVE":
                    print("승인 되었습니다.")
                    Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5초 대기
                        await MainActor.run {
                            self.disconnect()
                        }
                    }
                    
                case "REFUSAL":
                    print("승인되지 않은 카드입니다.")
                    Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5초 대기
                        await MainActor.run {
                            self.disconnect()
                        }
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - 전송
    private func sendChunked(_ text: String) async {
        guard let peripheral = connectedPeripheral,
              let char = targetCharacteristic else { return }
        
        let message = text + "\r\n"               // HM-10이 CRLF를 한 줄 끝으로 인식
        let data = Data(message.utf8)
        let mtu = 20                              // HM-10 실제 데이터 한도
        var offset = 0
        
        while offset < data.count {
            let end = min(offset + mtu, data.count)
            let chunk = data.subdata(in: offset..<end)
            peripheral.writeValue(chunk, for: char, type: .withResponse)
            print("📤 Chunk (\(chunk.count) bytes): \(String(data: chunk, encoding: .utf8) ?? "")")
            try? await Task.sleep(nanoseconds: 50_000)                        // 50 ms 대기로 버퍼 안정화
            offset = end
        }
    }
    
    // MARK: - 연결 해제
    func disconnect() {
        if let peripheral = connectedPeripheral {
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
}
