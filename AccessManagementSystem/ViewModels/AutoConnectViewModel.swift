//
//  AutoConnectViewModel.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/17/25.
//

import Foundation
import CoreBluetooth
import Combine

final class AutoConnectViewModel: ObservableObject {
    
    
    @Published var isConnected: Bool = false
    @Published var statusMessage: String = "대기 중..."
    @Published var remainingTime: Int = 30  
    
    /// Private method
    private let bleManager = BluetoothManager.shared
    private let userPublisher: AnyPublisher<User, Never>
    private let devicePublisher: AnyPublisher<BluetoothDevice, Never>
    
    private var pairedDevice: BluetoothDevice?
    private var userInfo: User?
    private var cancellables = Set<AnyCancellable>()
    private var countdownCancellable: AnyCancellable?
    
    // MARK: - 초기화
    init(
        userPublisher: AnyPublisher<User, Never>,
        devicePublisher: AnyPublisher<BluetoothDevice, Never>,
    ) {
        
        self.userPublisher = userPublisher
        self.devicePublisher = devicePublisher
        
        setupBindings()
    }
    
    func savedWorkLog() {
        self.countdownCancellable?.cancel()   
        self.isConnected = false
        Task {
            
            
            
            if remainingTime > 20 {
                let second = remainingTime - 20
                try? await Task.sleep(for: .seconds(second))
            } 
            self.bleManager.disconnect()    
                
             
            
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
        
        
        bleManager.$statusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$statusMessage) // 자동으로 store 해제됨 (.assign(to: &$property)
        
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
        
        
        
        /// 스캔 결과 수신 → 장치 리스트 업데이트
        bleManager.$connectedPeripheral
            .receive(on: DispatchQueue.main)
            .sink { [weak self] device in
                guard let self = self else { return }
                self.isConnected = device != nil 
                
                if device != nil {
                    Task {
                        // DiscoverCharacteristice와 notify 등록이 끝날 때 까지 잠깐 대기
                        try? await Task.sleep(for: .seconds(0.3))
                        await self.sendIVData()
                    }
                }
                
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
        let ivMSG = "IV:\(CryptionKey.iv)"
        await bleManager.sendChunked(ivMSG)
    } 
    
    private func handleReceivedText(_ text: String) {
        switch text.uppercased() {
        case "IV_UPDATED":
            
            if let encrypted = AES128CBC.encrypt(userInfo?.cardID ?? "", key: CryptionKey.secretKey, iv: CryptionKey.iv) {
                print("🔒 암호문 (Base64):", encrypted)

                // 복호화 테스트
                if let data = Data(base64Encoded: encrypted), let decrypted = AES128CBC.decrypt(data, key: CryptionKey.secretKey, iv: CryptionKey.iv) {
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
        remainingTime = 30
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
    



