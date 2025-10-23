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
    @Environment(\.dismiss) private var dismiss
    
    // 저장된 전체 WorkLog 가져오기
    private var allLogs: [WorkLog] {
         let descriptor = FetchDescriptor<WorkLog>(
             sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
         )
         return (try? context.fetch(descriptor)) ?? []
     }
    

    var body: some View {
        
        VStack(spacing: 16) {
            
            ZStack {
                Text("출입관리기록") 
                
                HStack {
                    Spacer()
                    Button { 
                        dismiss()
                    } label: { 
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                    }
                }
                .padding(.trailing, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            
            List(allLogs) { log in
                VStack(alignment: .leading, spacing: 16) {
                    Text(log.createdAt.yyyyMMdd)
                    
                    HStack {
                        
                        Image(systemName: "circle.fill")
                            .resizable()
                            .frame(width: 5, height: 5)
                            .foregroundStyle(log.content == "출근" ? .appPrimary : .brown)
                        
                        Text(log.content)
                            .font(.title3)
                            .foregroundStyle(log.content == "출근" ? .appPrimary : .brown)
                        
                        Spacer()
                        Text(log.createdAt, format: Date.FormatStyle
                                .dateTime
                                .hour()
                                .minute())
                    }
              
                    
                }
                
                .padding(.vertical, 4)
            }
        }
        
   
   
        
    }
    
}

#Preview {
    RecordView()
}
