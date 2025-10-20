//
//  RecordView.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import SwiftUI
import SwiftData

struct RecordView: View {
    
    @Environment(\.modelContext) private var context
    
    // 저장된 전체 WorkLog 가져오기
    private var allLogs: [WorkLog] {
         let descriptor = FetchDescriptor<WorkLog>(
             sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
         )
         return (try? context.fetch(descriptor)) ?? []
     }
    
    var body: some View {
        List(allLogs) { log in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.content)
                        .font(.headline)
                    Spacer()
                    Text(log.createdAt, format: Date.FormatStyle
                            .dateTime
                            .year()
                            .month()
                            .day()
                            .hour()
                            .minute())
                }
                .padding(.horizontal)
                
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("출입 기록")
    }
}

#Preview {
    RecordView()
}
