//
//  TabController.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI

struct TabController: View {
    enum MyTab: Hashable {
        case main, record
    }
    
    
    @State private var selectedTab: MyTab = .main
    
    var body: some View {
        TabView(selection: $selectedTab) { 
            
            Tab("main", systemImage: "key.card", value: .main) { 
                MainView()
            }
            
            Tab("record", systemImage: "list.clipboard", value: .record) {
                RecordView()
            }
            
        }
    }
}

#Preview {
    TabController()
}
