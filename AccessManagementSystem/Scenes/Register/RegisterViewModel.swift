//
//  RegisterViewModel.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import Foundation
import Combine
import CoreBluetooth

struct DiscoveredDevice: Identifiable {
    let id = UUID()
    let peripheral: CBPeripheral
    let name: String
}

final class BluetoothViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var devices: [DiscoveredDevice] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var statusMessage: String = "스캔 중..."
    @Published var receivedText: String = ""
    @Published var isRegistered: Bool = false // ✅ OK 수신 여부
    @Published var isFinshed: Bool = false

    private var central: CBCentralManager!
    private var targetCharacteristic: CBCharacteristic?
    private var lastConnectedDevice: DiscoveredDevice?
    private var isUserInitiatedDisconnect = false

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Bluetooth Delegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "스캔 시작"
            // ✅ 앱 시작 시 즉시 스캔
            central.scanForPeripherals(withServices: nil, options: nil)
        default:
            statusMessage = "주변에 기기가 없습니다."
        }
    }

    // MARK: - 주변 장치 발견
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let cacheName = peripheral.name
        let uuid = peripheral.identifier.uuidString
        let displayName = advName ?? cacheName ?? "(UUID: \(uuid.prefix(6)))"

        // ✅ 'Door' 포함된 이름만 표시
        guard displayName.localizedCaseInsensitiveContains("DOOR") else { return }

        if let index = devices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
            devices[index] = DiscoveredDevice(peripheral: peripheral, name: displayName)
        } else {
            devices.append(DiscoveredDevice(peripheral: peripheral, name: displayName))
        }
    }

    // MARK: - 연결
    func connect(to device: DiscoveredDevice) {
        statusMessage = "\(device.name) 연결 시도..."
        isUserInitiatedDisconnect = false
        isRegistered = false
        connectedPeripheral = nil
        central.connect(device.peripheral, options: nil)
    }

    // 연결 성공 시
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusMessage = "✅ 연결 성공: \(peripheral.name ?? "이름 없음")"
        connectedPeripheral = peripheral
        lastConnectedDevice = DiscoveredDevice(peripheral: peripheral, name: peripheral.name ?? "")
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: "FFE0")])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics([CBUUID(string: "FFE1")], for: service)
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
                    peripheral.setNotifyValue(true, for: char)
                    // ✅ 연결 직후 아두이노에 register 요청
                    send("register")
                }
            }
        }
    }

    // MARK: - 데이터 수신
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
                receivedText = text
                print("📩 수신: \(text)")

                // ✅ OK 수신 시 등록 완료로 판단
                if text.uppercased() == "OK" {
                    isRegistered = true
                    statusMessage = "✅ 등록 완료"
                }
            }
        }
    }

    // MARK: - 전송
    private func send(_ text: String) {
        if let peripheral = connectedPeripheral,
           let char = targetCharacteristic,
           let data = (text + "\n").data(using: .utf8) {
            peripheral.writeValue(data, for: char, type: .withResponse)
            print("📤 전송: \(text)")
        }
    }

    // MARK: - 연결 해제
    func disconnect() {
        if let peripheral = connectedPeripheral {
            isUserInitiatedDisconnect = true
            central.cancelPeripheralConnection(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        if isUserInitiatedDisconnect {
            statusMessage = "🔌 사용자에 의해 연결 해제"
        } else {
            statusMessage = "⚠️ 연결 끊김 — 재시도 가능"
        }
    }
}

