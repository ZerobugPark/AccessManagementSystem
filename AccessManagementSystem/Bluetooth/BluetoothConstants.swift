//
//  BluetoothConstants.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/16/25.
//

import CoreBluetooth

// MARK: - BLE UUID Constants
enum BluetoothUUID {
    static let serviceUART = CBUUID(string: "FFE0") // HM-10 UART Service
    static let characteristicTXRX = CBUUID(string: "FFE1") // HM-10 TX/RX Channel
}

// MARK: - BLE Commands
enum BluetoothCommand {
    static let register = "REGISTER"
    static let readyForData = "READY_FOR_DATA"
    static let complete = "COMPLETE"
    static let ok = "OK"
}

// MARK: - BLE Connection Thresholds
enum BluetoothThreshold {
    static let rssiAutoConnectLimit = -60  // 자동 연결 최소 신호 세기 (~10cm)
    static let rssiThresholdMin = -90  // 약한 신호 무시
    static let rssiIgnoreValue = 127       // RSSI 무효 값 (스캔 필터링용)
}

// MARK: - BLE Restore Identifier
enum BluetoothIdentifier {
    static let centralRestoreKey = "ble.central.restore"
}
