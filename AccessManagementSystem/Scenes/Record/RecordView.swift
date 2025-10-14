//
//  RecordView.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI

struct RecordView: View {
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
                        Button("카드 등록") {
                            print("카드 등록 선택됨")
                            // TODO: 카드 등록 화면으로 이동하도록 연결 가능
                        }

                        Button("카드 관리") {
                            print("카드 관리 선택됨")
                            // TODO: 카드 관리 화면으로 이동하도록 연결 가능
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                }
            }
        }
    }
}

#Preview {
    RecordView()
}
