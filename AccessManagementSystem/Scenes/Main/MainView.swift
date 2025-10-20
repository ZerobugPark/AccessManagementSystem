//
//  MainView.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI
import Combine


struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    @StateObject private var bleVM: AutoConnectViewModel
    
    
    @State private var activeSheet: ActiveSheet? = nil
     
    private var user: User? { get { viewModel.userInfo } }
    private var device:  BluetoothDevice? { get { viewModel.pairedDevice } }
    
    init() {
        
        let main = MainViewModel()
        _viewModel = StateObject(wrappedValue: main)
        _bleVM = StateObject(
            wrappedValue: AutoConnectViewModel(
                userPublisher: main.$userInfo.compactMap { $0 }.eraseToAnyPublisher(),
                devicePublisher: main.$pairedDevice.compactMap {$0}.eraseToAnyPublisher()
            )
        )
    }
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack(alignment: .top, spacing: 10) {
                    if let user {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("부서: \(user.department)")
                                .font(.callout.bold())
                            Text("이름: \(user.name)")
                                .font(.callout.bold())
                            Text("직급: \(user.position)")
                                .font(.callout.bold())
                        }
                    } else {
                        Text("사용자 등록이 필요합니다.")
                            .font(.callout.bold())
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .offset(y: -30)
                
                VStack(spacing: 0) {
                    ZStack {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 44, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 44
                        )
                        .fill(.lightgray)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                        
                        VStack(spacing: 16) {
                            
                            HStack {
                            
                                Text("출입 카드 목록")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top,30)
                                    .padding(.horizontal)
                                
                                if bleVM.isConnected {
                                    RemainingTimeView(remainingTime: bleVM.remainingTime)
                                }
                                
                            }
                            
                            
                            if let device {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(LinearGradient(
                                            colors: [.blue.opacity(0.7), .appPrimary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 300, height: 180)
                                        .shadow(radius: 8)
                                    
                                    VStack {
                                        ZStack(alignment: .bottomTrailing) { // 🔹 하단 오른쪽 기준 정렬
                                            VStack(spacing: 10) {
                                                Text("\(device.name)")
                                                    .font(.title3.bold())
                                                    .foregroundColor(.white)
                                                    .offset(y: -10)

                                                Text("\(user?.cardID ?? "")")
                                                    .font(.title3.bold())
                                                    .foregroundColor(.white)
                                            }
                                            // 🔹 가운데 정렬 유지
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                                            // 🔹 하단 오른쪽에 고정
                                            Text("unionbiometrics")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding([.trailing, .bottom], 12)
                                        }
                                        .frame(width: 300, height: 180)
                       
                                    }
                                         
                                    
                                }
                                .offset(y: 100)
                                .padding()
                                
                              
                                
                            } else {
                                Spacer()
                                Text("아직 등록된 카드가 없습니다.")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding()
                                
                            }
                            
                            Spacer()
                            
                            if bleVM.isConnected {
                                HStack(spacing: 40) {
                                    AttendanceActionButton(action: .checkIn) {
                                        print("출근 버튼 눌림")
                                    }

                                    AttendanceActionButton(action: .checkOut) {
                                        print("퇴근 버튼 눌림")
                                    }
                                }
                                .offset(y: -50)
                            }
                                
                           
                        }
                    }
                }
                
        
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//            .onAppear {
//                viewModel.loadPairedDevice()
//            }
            .toolbar {  mainToolbar() }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .register:
                    RegisterView {
                        
                    }
                case .user:
                    UserView {
                        viewModel.updateUserInfo()
                    } 
                }
            }
            
        }
        
    }
}


private extension MainView {
    enum ActiveSheet: Identifiable {
        case register
        case user
        
        var id: Int {
            hashValue
        }
    }
}

// MARK: Component 분리 
private extension MainView {
    struct RemainingTimeView: View {
        let remainingTime: Int
        var body: some View {
            Text("남은 시간: \(remainingTime)초")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .font(.headline)
                .padding(.top, 30)
                .padding(.horizontal)
        }
    }
    
    enum AttendanceAction {
        case checkIn   // 출근
        case checkOut  // 퇴근

        var title: String {
            switch self {
            case .checkIn: return "출근"
            case .checkOut: return "퇴근"
            }
        }

        var systemImage: String {
            switch self {
            case .checkIn: return "figure.walk"
            case .checkOut: return "figure.run"
            }
        }
    }

    struct AttendanceActionButton: View {
        let action: AttendanceAction
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                Label(action.title, systemImage: action.systemImage)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.appPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.appPrimary)
            }
        }
    }
}

// MARK: - Toolbar 구성 분리
private extension MainView {
    @ToolbarContentBuilder
    func mainToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Image(.unionBiometricsLogo)
                .resizable()
                .scaledToFit()
                .frame(height: 44)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
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
}

#Preview {
    MainView()
}

