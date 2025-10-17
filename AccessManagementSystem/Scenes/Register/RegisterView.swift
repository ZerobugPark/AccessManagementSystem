//
//  RegisterView.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var registerVM = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // 상단 제목
            Text("연결 가능한 기기 목록")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)

            // BLE 기기 리스트
            List(registerVM.devices) { device in
                HStack {
                    Text(device.name)
                        .font(.body)
                    Spacer()
                    Button("연결") {
                        registerVM.connect(to: device)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding(.vertical, 4)
            }
            

            // 상태 표시
            Text(registerVM.statusMessage)
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemGray6)) 
        .ignoresSafeArea()               
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onChange(of: registerVM.isRegistered) { _, newValue in
            if newValue {
                Task {
                    try? await Task.sleep(for: .seconds(1)) // 1초 대기 (연결 해제 완료 대기)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}
