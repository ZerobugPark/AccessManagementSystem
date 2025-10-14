//
//  User.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import Foundation


struct User: Codable {
    let name: String
    let department: String
    let company: String
    let cardID: String
}

extension User {
    ///  유저 정보를 UserDefaults에 저장
    func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaultManager.userInfo = data
            print("✅ 사용자 정보가 UserDefaults에 저장되었습니다.")
        } catch {
            print("❌ 사용자 정보 저장 실패:", error)
        }
    }

    ///  UserDefaults에서 유저 정보 불러오기
    static func loadFromUserDefaults() -> User? {
        let data = UserDefaultManager.userInfo
        guard !data.isEmpty else { return nil }
        do {
            return try JSONDecoder().decode(User.self, from: data)
        } catch {
            print("❌ 사용자 정보 불러오기 실패:", error)
            return nil
        }
    }

    ///  저장된 사용자 정보 제거
    static func clearFromUserDefaults() {
        UserDefaultManager.userInfo = Data()
    }
}
