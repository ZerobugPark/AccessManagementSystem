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
    @Published var isConnected: Bool = false
    @Published var statusMessage: String = "대기 중..."

    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var rssiThreshold: Int = -40 // ✅ 약 0~10cm 기준
    private var lastRSSILogTime = Date()

    // MARK: - 초기화
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
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

        // 로그 출력 제한 (1초마다 한 번)
        let now = Date()
        if now.timeIntervalSince(lastRSSILogTime) > 1 {
            print("📶 RSSI: \(RSSI.intValue)dBm for \(paired.name)")
            lastRSSILogTime = now
        }

        // ✅ RSSI 기준 충족 시 연결
        if RSSI.intValue >= rssiThreshold {
            print("✅ RSSI 기준 통과 → \(paired.name) 연결 시도 (\(RSSI.intValue)dBm ≥ \(rssiThreshold)dBm)")
            central.stopScan()
            connectedPeripheral = peripheral
            peripheral.delegate = self
            central.connect(peripheral, options: nil)
            statusMessage = "RSSI 기준 충족 → 자동 연결 중..."
        }
    }

    // MARK: - 연결 성공
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ \(peripheral.name ?? "Unknown") 연결 완료")
        statusMessage = "✅ 연결 완료"
        isConnected = true
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
}
