//
//  MainView.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI
import Combine
import SwiftData


struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    @StateObject private var bleVM: AutoConnectViewModel
    @Environment(\.modelContext) private var context
    
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
                        BackgroundView()
                        VStack(spacing: 16) {
                            
                            HeaderView(isConnected: bleVM.isConnected, remainingTime: bleVM.remainingTime)
                            if let device {
                                CardView(device: device, user: user)
                                .offset(y: 100)
                                .padding()
                            } else {
                                EmptyCardView()
                            }
                            
                            Spacer()
                            
                            if bleVM.isConnected {
                                ActionButtonsView { str in
                                    saveWorkLog(content: str)
                                }
                                .offset(y: -50)
                            }
                        }
                    }
                }                
        
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .toolbar {  mainToolbar() }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .register:
                    RegisterView {
                        viewModel.updateCardInfo()
                    }
                case .user:
                    UserView {
                        viewModel.updateUserInfo()
                    } 
                case .record:
                    RecordView()
                }
            }
            
        }
        
    }
}


private extension MainView {
    enum ActiveSheet: Identifiable {
        case register
        case user
        case record
        
        var id: Int {
            hashValue
        }
    }
    
    func saveWorkLog(content: String) {
        let log = WorkLog(content: content)
        context.insert(log)
        
        do {
            try context.save()  // 영구 저장
            bleVM.savedWorkLog()
        } catch {
            print("저장 실패:", error)
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
    
    struct BackgroundView: View {
        var body: some View {
            UnevenRoundedRectangle(
                topLeadingRadius: 44,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 44
            )
            .fill(.lightgray)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    struct HeaderView: View {
        let isConnected: Bool
        let remainingTime: Int

        var body: some View {
            HStack {
                Text("출입 카드 목록")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 30)
                    .padding(.horizontal)

                if isConnected {
                    RemainingTimeView(remainingTime: remainingTime)
                }
            }
        }
    }
    
    struct CardView: View {
        let device: BluetoothDevice
        let user: User?

        var body: some View {
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
                    ZStack(alignment: .bottomTrailing) {
                        VStack(spacing: 10) {
                            Text(device.name)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .offset(y: -10)

                            Text(user?.cardID ?? "")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }  
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                        Text("unionbiometrics")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding([.trailing, .bottom], 12)
                    }
                    .frame(width: 300, height: 180)
                }
            }
        }
    }
    
    struct EmptyCardView: View {
        var body: some View {
            Spacer()
            Text("아직 등록된 카드가 없습니다.")
                .font(.headline)
                .foregroundColor(.gray)
                .padding()
        }
    }
    
    struct ActionButtonsView: View {
        var onAction: (String) -> Void

        var body: some View {
            HStack(spacing: 40) {
                AttendanceActionButton(action: .checkIn) {
                    onAction("출근")
                }

                AttendanceActionButton(action: .checkOut) {
                    onAction("퇴근")
                }
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
                Button("출입 관리 기록") {
                    activeSheet = .record
                }
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

