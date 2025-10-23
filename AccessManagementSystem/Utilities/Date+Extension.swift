//
//  Date+Extension.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/23/25.
//

import Foundation

extension Date {
    var yyyyMMdd: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")  
        df.dateFormat = "yyyy-MM-dd"           
        return df.string(from: self)
    }
}
