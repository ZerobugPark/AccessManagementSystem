//
//  MainViewModel.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/15/25.
//

import Foundation
import CoreBluetooth
import Combine

final class MainViewModel:  ObservableObject {
    @Published var pairedDevice: BluetoothDevice?
    @Published var userInfo: User?
    
    
    // MARK: - 초기화
    init() {
        loadPairedDeviceAndUserInfo()
    }
    
    // MARK: - 저장된 장치 불러오기
    func loadPairedDeviceAndUserInfo() {
        userInfo = User.loadFromUserDefaults()
        pairedDevice = BluetoothDevice.loadFromUserDefaults()
    }
    
 
}

extension MainViewModel {
    
    func updateUserInfo() {
        userInfo = User.loadFromUserDefaults()
    }
    
    func updateCardInfo() {
        pairedDevice = BluetoothDevice.loadFromUserDefaults()
    }
    
}
