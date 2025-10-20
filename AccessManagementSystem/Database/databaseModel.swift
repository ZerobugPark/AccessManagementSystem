//
//  databaseModel.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/20/25.
//

import SwiftData 
import Foundation

@Model
final class WorkLog {
    @Attribute(.unique) var id: UUID // Attribute: 속성값
    var content: String
    var createdAt: Date

    init(content: String) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
    }
}
