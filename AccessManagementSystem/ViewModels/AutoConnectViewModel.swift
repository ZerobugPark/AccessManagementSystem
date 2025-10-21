//
//  AutoConnectViewModel.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/17/25.
//

import Foundation
import CoreBluetooth
import Combine
import UIKit

final class AutoConnectViewModel: ObservableObject {
    
    
    @Published var isConnected: Bool = false
    @Published var statusMessage: String = ""
    @Published var remainingTime: Int = 30  
    
    /// Private method
    private let bleManager = BluetoothManager.shared
    private let userPublisher: AnyPublisher<User, Never>
    private let devicePublisher: AnyPublisher<BluetoothDevice, Never>
    
    private var pairedDevice: BluetoothDevice?
    private var userInfo: User?
    private var cancellables = Set<AnyCancellable>()
    private var countdownCancellable: AnyCancellable?
    
    private var currentIV: String = ""
    
    // MARK: - 초기화
    init(
        userPublisher: AnyPublisher<User, Never>,
        devicePublisher: AnyPublisher<BluetoothDevice, Never>,
    ) {
        
        self.userPublisher = userPublisher
        self.devicePublisher = devicePublisher
        
        setupBindings()
    }
    
    @MainActor
    func savedWorkLog() {
        countdownCancellable?.cancel()
        isConnected = false

        Task {
            /// 백그라운드 작업 요청
            let bgID = UIApplication.shared.beginBackgroundTask(withName: "AutoDisconnect") {
                // 시간이 다되서 iOS가 종료하려는 시점에 안전하게 처리(여기선 아무것도 안함)
            }

            /// 유효성 체크
            let validBgID = (bgID != .invalid) ? bgID : nil

            /// 필요한 delay 계산
            if remainingTime > 20 {
                let delaySeconds = remainingTime - 20
                do {
                    try await Task.sleep(for: .seconds(delaySeconds))
                } catch {
                    /// Task 취소됨 (ex. 앱이 포그라운드로 복귀하거나 사용자가 액션함)
                    self.bleManager.disconnect()    
                    
                }
            }

            await MainActor.run {
                self.bleManager.disconnect()
            }

            if let validBgID {
                UIApplication.shared.endBackgroundTask(validBgID)
            }
        }
    }
    
    
    deinit {
        countdownCancellable?.cancel()
        cancellables.removeAll()
    }
    
    
}

// MARK: Combine Binding 
private extension AutoConnectViewModel {
    
    func setupBindings() {
        
        Publishers.CombineLatest(userPublisher, devicePublisher)
            .first() // 둘 다 처음 준비되는 시점
            .sink { [weak self] user, dev in
                self?.userInfo = user
                self?.pairedDevice = dev
                self?.bleManager.mode = .auto
            }
            .store(in: &cancellables)
        
        /// 디버깅용 상태메시지
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
                if let id = pairedDevice?.id, device.id == id {
                    bleManager.connect(to: peripheral)
                }  else {
                    return 
                }
            
            }
            .store(in: &cancellables)
        
        bleManager.$connectedPeripheral
            .receive(on: DispatchQueue.main)
            .sink { [weak self] device in
                guard let self = self else { return }
                remainingTime = 30 //타이머 초기화
                self.isConnected = device != nil 
                
                
            }.store(in: &cancellables)
           
        
        /// 수신 텍스트 처리
        bleManager.receivedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.handleReceivedText(text)
            }
            .store(in: &cancellables)
    }
    
}



// MARK: Private Method 
private extension AutoConnectViewModel {
        
    private func sendIVData() async {
        //let ivMSG = "IV:\(CryptionKey.iv)"
        //await bleManager.sendChunked(ivMSG)
    } 
    
    private func handleReceivedText(_ text: String) {
        switch text.uppercased() {
        case "REQUEST_IV":
            currentIV = CryptionKey.generateRandomIVString()
            let payload = "IV:\(currentIV)"
            bleManager.send(payload)
        case "IV_UPDATED":
            
            if let encrypted = AES128CBC.encrypt(userInfo?.cardID ?? "", key: CryptionKey.secretKey, iv: currentIV) {
                print("🔒 암호문 (Base64):", encrypted)

                // 복호화 테스트
                if let data = Data(base64Encoded: encrypted), let decrypted = AES128CBC.decrypt(data, key: CryptionKey.secretKey, iv: currentIV) {
                    print("🔓 복호화 결과:", decrypted)
                } 
                
                let payload = "AUTH:\(encrypted)"
                Task {
                    await bleManager.sendChunked(payload)
                }
                
            } else {
                print("암호화 실패")
            }
            
        case "APPROVE":
            print("승인 되었습니다.")
            Task {
                startAutoDisconnectCountdown()
            }
            
        case "REFUSAL":
            print("승인되지 않은 카드입니다.")
            Task {
                try? await Task.sleep(for: .seconds(5)) // 5초 대기
                await MainActor.run {
                    self.bleManager.disconnect()
                }
            }
            
        default:
            break
        }
    }
    
    func startAutoDisconnectCountdown() {
        countdownCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                } else {
                    self.bleManager.disconnect()
                    self.isConnected = false
                    self.countdownCancellable?.cancel()
                }
            }
    }


    
}
    



