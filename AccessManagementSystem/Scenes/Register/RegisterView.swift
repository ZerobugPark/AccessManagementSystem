//
//  RegisterView.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var bluetoothVM = BluetoothViewModel()

    var body: some View {
        VStack {
            // 상단 제목
            Text("연결 가능한 기기 목록")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)

            // BLE 기기 리스트
            List(bluetoothVM.devices) { device in
                HStack {
                    Text(device.name)
                        .font(.body)
                    Spacer()
                    Button("연결") {
                        bluetoothVM.connect(to: device)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.insetGrouped)

            // 상태 표시
            Text(bluetoothVM.statusMessage)
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.vertical, 8)
        }
        .padding()
        .presentationDetents([.medium, .large]) // 모달 높이 조정
        .presentationDragIndicator(.visible)    // 드래그 표시선
    }
}

#Preview {
    RegisterView()
}
