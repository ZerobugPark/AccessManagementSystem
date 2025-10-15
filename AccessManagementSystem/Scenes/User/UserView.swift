//
//  UserView.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI

struct UserView: View {
    @Environment(\.dismiss) private var dismiss   // ✅ 모달 닫기용 환경 변수
    @State private var name = ""
    @State private var department = ""
    @State private var position = ""
    @State private var cardID = ""
    @State private var showAlert = false
    
    init() {
        self.cardID = makeCardID()
    }

    var body: some View {
        VStack(spacing: 24) {
            // 상단 헤더 (제목 + 닫기 버튼)
            ZStack {
                // 중앙 제목
                Text("사용자 등록")
                    .font(.headline)
                    .bold()
                    .padding(.bottom, 5)

                // 우측 상단 닫기 버튼
                HStack {
                    Spacer()
                    Button {
                        dismiss() // ✅ 모달 닫기
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 16)
                }
            }
            .padding(.top, 20)

            // 입력 필드 그룹
            Group {
                LabeledTextField(label: "이름", text: $name)
                LabeledTextField(label: "부서", text: $department)
                LabeledTextField(label: "직책", text: $position)
            }
            .padding(.horizontal)

            // 자동 생성된 카드 ID 표시
            VStack(alignment: .leading, spacing: 6) {
                Text("카드 ID (자동 생성)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(cardID)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
            }
            .padding(.horizontal)

            // 등록 버튼
            Button(action: registerUser) {
                Text("등록 완료")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.appPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            Spacer()
        }
        .alert("등록 완료", isPresented: $showAlert) {
            Button("확인", role: .cancel) {
                dismiss() // ✅ 등록 완료 후 자동 닫기 (선택 사항)
            }
        } message: {
            Text("사용자 \(name) 님이 등록되었습니다.")
        }
        .ignoresSafeArea(edges: .bottom)
    }


}

private extension UserView {
    /// User Register
    func registerUser() {
        
        let user = User(
            name: name,
            department: department,
            company: "유니온바이오메트릭스",
            cardID: cardID
        )
        
        do {
            let encoded = try JSONEncoder().encode(user)
            UserDefaultManager.userInfo = encoded
        } catch {
            print("사용자 정보 인코딩 실패:", error)
        }

        showAlert = true
    }
    
    ///카드 ID 자동 생성기
    func makeCardID() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let datePart = formatter.string(from: Date())
        return "CARD-\(datePart)"
    }
}

struct LabeledTextField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            TextField("\(label)을 입력하세요", text: $text)
                .padding(14)
                .background(Color(.systemGray6))
                .cornerRadius(16)
        }
    }
}



#Preview {
    UserView()
}
