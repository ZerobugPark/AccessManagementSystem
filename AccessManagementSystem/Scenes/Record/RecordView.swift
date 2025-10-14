//
//  RecordView.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI

struct RecordView: View {
    @State private var showRegisterView = false // ✅ 모달 표시 상태

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("출입 기록 내용이 여기에 표시됩니다.")
                Spacer()
            }
            .toolbar {
                // 중앙 타이틀
                ToolbarItem(placement: .principal) {
                    Text("출입관리기록")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                // 우측 설정 메뉴
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // ✅ 카드 등록 → RegisterView 모달 표시
                        Button("출입 카드 등록") {
                            showRegisterView = true
                        }

                        Button("출입 카드 관리") {
                            print("카드 관리 선택됨")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                }
            }
            // ✅ RegisterView 모달 연결
            .sheet(isPresented: $showRegisterView) {
                RegisterView()
            }
        }
    }
}

#Preview {
    RecordView()
}
