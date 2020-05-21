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
        static let backupSession = "backupSession"
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
    
    static var backupSession: Session? {
           get {
               guard let data = UserDefaults.standard.value(forKey: UserDefaults.Key.backupSession) as? Data else { return nil }
               return try? JSONDecoder().decode(Session.self, from: data)
           }
           
           set {
               let data = try? JSONEncoder().encode(newValue)
               UserDefaults.standard.set(data, forKey: UserDefaults.Key.sessions)
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
