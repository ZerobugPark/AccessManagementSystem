//
//  RecordView.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI

struct RecordView: View {
    
    enum ActiveSheet: Identifiable {
        case register
        case user
        
        var id: Int {
            hashValue
        }
    }
    
    @State private var activeSheet: ActiveSheet? = nil
    
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
                        Button("출입 카드 등록") {
                            activeSheet = .register
                        } 
                        Button("사용자 등록") {
                            activeSheet = .user
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .imageScale(.medium)
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .register:
                    RegisterView {
                        
                    }
                case .user:
                    EmptyView()
                    //UserView() 
                }
            }
        }
    }
}

#Preview {
    RecordView()
}
