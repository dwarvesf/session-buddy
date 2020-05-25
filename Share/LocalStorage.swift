//
//  Storage.swift
//  SessionRestore
//
//  Created by phucld on 4/14/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum Key {
        static let sessions = "sessions"
        static let backupTabs = "backupTabs"
    }
}

enum LocalStorage {
    static var sessions: [Session] {
        get {
            guard let data = UserDefaults.standard.value(forKey: UserDefaults.Key.sessions) as? Data else { return [] }
            return (try? JSONDecoder().decode([Session].self, from: data)) ?? []
        }
        
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: UserDefaults.Key.sessions)
        }
    }
    
    static var backupTabs: Set<Tab> {
           get {
            guard let data = UserDefaults.standard.value(forKey: UserDefaults.Key.backupTabs) as? Data,
                let tabs = try? JSONDecoder().decode(Set<Tab>.self, from: data)
                else { return Set() }
            
               return tabs
           }
           
           set {
               let data = try? JSONEncoder().encode(newValue)
               UserDefaults.standard.set(data, forKey: UserDefaults.Key.backupTabs)
           }
       }
}

extension Session {
    func save() {
        var sessions = LocalStorage.sessions
        sessions.append(self)
        LocalStorage.sessions = sessions
    }
}
