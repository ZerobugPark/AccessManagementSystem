//
//  UserDefaultsManager.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/14/25.
//

import Foundation

@propertyWrapper struct AMSUserDefaultManager<T> {
    
    let key: String
    let empty: T
    
    init(key: String, empty: T) {
        self.key = key
        self.empty = empty
    }
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? empty
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: key)
        }
    }
}

enum UserDefaultManager {
    enum Key: String {
        case userInfo

    }
    
    @AMSUserDefaultManager(key: Key.userInfo.rawValue, empty: Data())
    static var userInfo: Data

}


