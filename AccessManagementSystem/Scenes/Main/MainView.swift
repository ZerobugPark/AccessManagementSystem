//
//  MainView.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        VStack {
            Spacer()

            if let device = viewModel.pairedDevice {
                // ✅ 등록된 카드 UI
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.8), .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 300, height: 180)
                        .shadow(radius: 8)

                    VStack(spacing: 10) {
                        Text("등록된 카드")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(device.name)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Text("UUID: \(device.id.uuidString.prefix(8))…")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
            } else {
                // ⚠️ 등록된 카드 없음
                Text("아직 등록된 카드가 없습니다.")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            viewModel.loadPairedDevice()
        }
    }
}

#Preview {
    MainView()
}


