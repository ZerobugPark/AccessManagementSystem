//
//  RegisterViewModel.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/16/25.
//

import Foundation
import Combine
import CoreBluetooth

final class RegisterViewModel: ObservableObject {
    // MARK: - Published Properties (UI 바인딩용)
    @Published var devices: [BluetoothDevice] = []
    @Published var statusMessage: String = ""
    @Published var isRegistered: Bool = false
    @Published var isFinished: Bool = false
    
    // MARK: Private
    private let bleManager = BluetoothManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currnetDevice: BluetoothDevice? 
    
    init() {
        bleManager.mode = .manual
        bleManager.disconnect()
        setupBindings()
        bleManager.startScan()
        
    
    }
    
    // MARK: - BLE 데이터 처리
    private func handleReceivedText(_ text: String) {
        switch text.uppercased() {
        case "READY_FOR_DATA":
            sendUserInfo()
        case "COMPLETE":
            if let device = currnetDevice {
                BluetoothDevice(peripheral: device.peripheral!, name: device.name, rssi: device.lastRSSI, serviceUUID: device.serviceUUID).saveToUserDefaults()
            }
            isRegistered = true
            statusMessage = "등록 완료"
            bleManager.disconnect()
        default:
            print("BLE 수신:", text)
        }
    }

    // MARK: - 사용자 정보 전송
    private func sendUserInfo() {
        guard let user = User.loadFromUserDefaults() else {
            statusMessage = "⚠️ 사용자 정보 없음"
            return
        }

        if let encrypted = AES128CBC.encrypt(user.cardID,
                                             key: CryptionKey.secretKey,
                                             iv: CryptionKey.iv) {
            let payload = "USER:\(encrypted)"
            Task {
                await bleManager.sendChunked(payload)    
            }
     
            statusMessage = "사용자 정보 전송 중..."
        } else {
            statusMessage = "암호화 실패"
        }
    }
    
    
}

// MARK: Combine Binding 
private extension RegisterViewModel {
    
    func setupBindings() {
        bleManager.$statusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$statusMessage) // 자동으로 store 해제됨 (.assign(to: &$property)
        
        
        /// 스캔 결과 수신 → 장치 리스트 업데이트
        bleManager.discoveredPeripheral
            .receive(on: DispatchQueue.main)
            .compactMap { $0 } // nil 제거
            .sink { [weak self] (peripheral, rssi) in
                guard let self = self else { return }
                let name = peripheral.name ?? "Unknown"
                guard name.localizedCaseInsensitiveContains("DOOR") else { return }
                let device = BluetoothDevice(peripheral: peripheral, name: name, rssi: rssi)
                if let index = self.devices.firstIndex(where: { $0.id == device.id }) {
                    self.devices[index] = device
                } else {
                    self.devices.append(device)
                }
            }
            .store(in: &cancellables)
        
        /// 수신 텍스트 처리
        bleManager.receivedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.handleReceivedText(text)
            }
            .store(in: &cancellables)
    }
    
}

extension RegisterViewModel {
    func connect(to device: BluetoothDevice) {
        bleManager.connect(to: device.peripheral!)
        currnetDevice = device
        statusMessage = "\(device.name) 연결 중..."
    }

    func stopScan() {
        bleManager.stopScan()
    }

    func disconnect() {
        bleManager.disconnect()
        statusMessage = "연결 해제됨"
    }
}



