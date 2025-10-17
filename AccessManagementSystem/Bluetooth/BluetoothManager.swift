//
//  BluetoothManager.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/16/25.
//

import Combine
import CoreBluetooth

enum BluetoothMode {
    case auto
    case manual
    case idle
}


final class BluetoothManager: NSObject, ObservableObject {
    
    static let shared = BluetoothManager()
    
    @Published var mode: BluetoothMode = .idle
    @Published var connectedPeripheral: CBPeripheral?
    @Published var statusMessage: String = "대기 중..."
    
    
    // 스캔 결과 전파 (뷰모델에서 구독)
    let discoveredPeripheral = CurrentValueSubject<(CBPeripheral, Int)?, Never>(nil)
    let receivedSubject = PassthroughSubject<String, Never>()  // 이벤트 스트림 (ViewModel용)
    
    // Private Properties
    private var central: CBCentralManager!
    private var targetCharacteristic: CBCharacteristic?
    private var restoredPeripherals: [CBPeripheral] = [] // 복구 목록
    private var rssiMap: [UUID: Int] = [:] // 복구 목록 rssi 딕셔너리
    private var isRestoring = false
    
    
    
    private override init() {
        super.init()
        
        /// 블루투스 객체 생성
        /// delegate: self → 이 매니저가 CBCentralManagerDelegate 이벤트를 받음
        /// queue: nil → 메인 스레드에서 콜백 수신 (UI 업데이트 용이)
        /// CBCentralManagerOptionRestoreIdentifierKey: 복원 식별자 설정 (백그라운드 모드에서 사용)
        central = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: BluetoothIdentifier.centralRestoreKey]
        )
    }
    
    
}

/// 블루투스 연결 전체 흐름도
/// connect() -Peripheral과 물리적 연결
/// discoverServices() - 서비스 목록 요청 (FFE0 등)
/// didDiscoverServices - Peripheral이 서비스 목록 응답
/// discoverCharacteristics() - 서비스 내부의 특성(FFE1 등) 요청
/// didDiscoverCharacteristicsFor - 특성 목록 응답 수신
/// setNotifyValue(true) - Notify 수신 등록
/// didUpdateValueFor -Peripheral이 Notify로 데이터 전송

//discoverServices()
//→ “너(Peripheral)가 제공하는 서비스 목록(FFE0 등) 을 나(Central)에게 보내줘.”
//didDiscoverServices
//→ Peripheral이 실제로 그 서비스 정보를 보내왔을 때 실행되는 콜백
//→ 이 시점에서 iOS는 peripheral.services 배열을 채워둠.
//discoverCharacteristics(for: service)
//→ “그 서비스(예: FFE0) 안에 있는 특성 목록(FFE1 등) 을 보내줘.”
//didDiscoverCharacteristicsFor
//→ Peripheral이 그 서비스의 특성 목록을 보내왔을 때 실행되는 콜백.
//→ 이 시점에서 service.characteristics 배열이 채워짐.
//
//[Central (iPhone)]                    [Peripheral (HM-10)]
//------------------------------------------------------------
//connect() ──────────────────────────────▶ (연결 수락)
//discoverServices([FFE0]) ───────────────▶ "FFE0 서비스 알려줘"
//                               ◀───────── 서비스 정보 응답 (FFE0)
//didDiscoverServices() 호출
//discoverCharacteristics([FFE1], for: FFE0) ─▶ "FFE0 안의 FFE1 알려줘"
//                               ◀───────── 특성 정보 응답 (FFE1)
//didDiscoverCharacteristicsFor() 호출
//setNotifyValue(true, for: FFE1) ─────────▶ "FFE1 Notify 켜줘"
//                               ◀───────── OK
//didUpdateValueFor() 호출 (데이터 수신)

// MARK: CBCentralManagerDelegate
// Central: 중앙 기기 (BEL 연결 요청 및 관리, iPhone)
//Central (스마트폰, 앱)
//   ↓ 스캔(scan)
//   ↓ 연결(connect)
//   ↓ 서비스 탐색(discoverServices)
//   ↓ 데이터 요청(Read/Write/Notify)
//Peripheral (BLE 기기, HM-10)
//   ↑ 광고(advertise)
//   ↑ 응답(response)
//   ↑ 알림(notify)
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "블루투스 활성화됨"
            startScan()
        case .poweredOff:
            statusMessage = "블루투스 꺼져 있음"
        case .unauthorized:
            statusMessage = "권한 없음"
        case .unsupported:
            statusMessage = "지원되지 않음"
        default:
            statusMessage = "블루투스 상태: \(central.state.rawValue)"
        }
    }
    
    
    /// 주변기기 탐색 (광고 패킷 수신)
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let rssiValue = Int(truncating: RSSI)
        
        
        //RSSI 127 → BLE 표준에서 '측정 불가'
        guard rssiValue != BluetoothThreshold.rssiIgnoreValue else {
            //print("RSSI=127 → 무시:", peripheral.name ?? "Unknown")
            return
        }
        
        // 약한 신호 무시
        guard rssiValue >= BluetoothThreshold.rssiThresholdMin else {
            //print("기준 이하 신호 신호 무시:", peripheral.name ?? "Unknown", "→", rssiValue)
            return
        }
        
        if mode == .auto {
            guard rssiValue >= BluetoothThreshold.rssiAutoConnectLimit else {
                //print("자동 거리 기준 미달", peripheral.name ?? "Unknown", "→", rssiValue)
                return
            }
        }
        

        discoveredPeripheral.send((peripheral, rssiValue)) // 구독측으로 데이터 전달   
        
        // 복원 후보 RSSI 갱신 (복원 시점용)
        if isRestoring,
           restoredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            rssiMap[peripheral.identifier] = rssiValue
            print("복원 후보 RSSI:", peripheral.name ?? "Unknown", "→", rssiValue)
        }
        
        
    }
    
    /// 연결 성공시 서비스 요청 (실제 데이터 송수신은 아직 전)
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isRestoring = false
        connectedPeripheral = peripheral
        statusMessage = "연결됨: \(peripheral.name ?? "Unknown")"
        peripheral.delegate = self
        //peripheral.discoverServices(nil) // 해당 장치의 GATT 서비스 목록 조회
        /// 해당 기기의 FFE0 서비스를 요청 (비동기)
        peripheral.discoverServices([BluetoothUUID.serviceUART]) // FFE0: HM-10 GATT Service (UART(시리얼) 통신을 위한 서비스) 
        
    }
    
    /// 연결 해제시 호출되는 메서드
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        connectedPeripheral = nil
        targetCharacteristic = nil

        switch mode {
        case .auto:
            statusMessage = "자동 재연결 대기 중..."
            print("🔁 자동 모드 — Task 기반 재연결 시작")

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self else { return }
                startScan()
                self.statusMessage = "자동 재연결 시도 중..."
            }

        case .manual:
                statusMessage = "연결 해제됨"
                startScan()
        default:
                statusMessage = "연결 종료"
            
        }
    }
    
    
    
    // MARK: 복원 
    /// 복원 매니저 (앱이 배그라운드에서 깨어날때, 
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    
//        isRestoring = true
//        
//        guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral],
//              !peripherals.isEmpty else { return }
//        
//        // DOOR 포함된 장치만 복원 후보
//        restoredPeripherals = peripherals.filter {
//            ($0.name ?? "").localizedCaseInsensitiveContains("DOOR")
//        }
//        
//        guard !restoredPeripherals.isEmpty else {
//            print("복원 가능한 목록이 없습니다")
//            statusMessage = "복원 실패: DOOR 장치 없음"
//            return 
//        }
//        
//        print("복원 후보 목록:")
//        restoredPeripherals.forEach { print(" -", $0.name ?? "Unknown", $0.identifier) }
//        
//        rssiMap.removeAll()
//        statusMessage = " 복원 중..."
//        
//        // ✅ RSSI 재측정 (2초 스캔)
//        central.scanForPeripherals(withServices: [BluetoothUUID.serviceUART], options: nil)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            central.stopScan()
//            self.connectToStrongestPeripheral()
//        }
        
    }
    
    
    
}

// MARK: Peripheral
// Peripheral: 주변 기기 (BLE 광고를 보내고 대기)
extension BluetoothManager: CBPeripheralDelegate {
    
    /// 연결된 기기의 서비스 목록 탐색 (서비스 정보 응답 수신)
    /// discoverServices에서 요청한 서비스 목록 응답, 비동기적으로 iOS가 해당 서비스 (ex. FFE1 등)에  
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] {
            //peripheral.discoverCharacteristics(nil, for: service) // 전체 특성
            peripheral.discoverCharacteristics([BluetoothUUID.characteristicTXRX], for: service) // FFE1 데이터 송수신용 채널
        }
    }
    
    /// 특성 정보 응답 수신
    /// targetCharacteristic 에는 “데이터 송수신 채널”, 즉 Peripheral(예: HM-10)의 FFE1 특성(Characteristic)  저장
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        for char in service.characteristics ?? [] {
            if char.uuid == BluetoothUUID.characteristicTXRX {
                targetCharacteristic = char // FFF1
                peripheral.setNotifyValue(true, for: char) // 해당 채널에서 데이데이터가 변경되면 didUpdateValueFor 메서드 호출
                switch mode {
                case .auto:
                    send("CONNECTED")
                case .manual:
                    send("REGISTER")
                default:
                    break
                }
            }
        }
    }
    
    /// 데이터 수신 (Notify)
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil, let data = characteristic.value else { return }
        if let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) {
            
            Task { @MainActor in
                receivedSubject.send(text)
            }
        }
    }
    
}

// MARK: - Private Method
private extension BluetoothManager {
    
    /// RSSI 기반 복원 연결
    func connectToStrongestPeripheral() {
        guard let best = rssiMap
            .filter({ $0.value >= BluetoothThreshold.rssiThresholdMin })
            .max(by: { $0.value < $1.value }) else {
            print(" 복원 실패: 근처 DOOR 없음")
            statusMessage = "복원 실패: DOOR 없음"
            return
        }
        
        guard let targetPeripheral = restoredPeripherals.first(where: { $0.identifier == best.key }) else { return }
        
        print(" 복원 대상:", targetPeripheral.name ?? "Unknown", "| RSSI:", best.value)
        statusMessage = " 복원 중: \(targetPeripheral.name ?? "Unknown")"
        central.connect(targetPeripheral, options: nil)
    }
    
    func startScan(for services: [CBUUID]? = [BluetoothUUID.serviceUART]) {
        central.scanForPeripherals(withServices: nil, options: nil)
        statusMessage = "스캔 중..."   
    }
  
}

// MARK: - Public API
extension BluetoothManager {
    
    
    func stopScan() {
        central.stopScan()
        statusMessage = "스캔 중지"
    }
    
    func connect(to peripheral: CBPeripheral) {
        central.connect(peripheral, options: nil)
        statusMessage = "연결 시도 중..."
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    func send(_ text: String) {
        guard let peripheral = connectedPeripheral,
              let char = targetCharacteristic else { return }
        let message = (text + "\n").data(using: .utf8)!
        peripheral.writeValue(message, for: char, type: .withResponse)
    }
    
    func sendChunked(_ text: String) async {
        guard let peripheral = connectedPeripheral,
              let char = targetCharacteristic else { return }

        let data = Data(text.utf8)
        let mtu = 20
        var offset = 0

        while offset < data.count {
            let end = min(offset + mtu, data.count)
            let chunk = data.subdata(in: offset..<end)
            peripheral.writeValue(chunk, for: char, type: .withResponse)
            
            // 살짝 delay 주기 (HM-10 버퍼 처리 여유)
            try? await Task.sleep(nanoseconds: 50_000) // 50ms
            offset = end
        }

        // 마지막 줄바꿈 (\n)
        if let newline = "\n".data(using: .utf8) {
            peripheral.writeValue(newline, for: char, type: .withResponse)
        }
        
    }
    
}
