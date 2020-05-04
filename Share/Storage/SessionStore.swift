//
//  SessionStore.swift
//  SessionRestore
//
//  Created by phucld on 5/4/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation
import CloudKit
import OSLog

class SessionStore {
    private(set) var sessions: [Session] = [] {
        didSet {
            // Broadcast notification
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "sessiondidload"), object: nil)
        }
    }
    
    private let log = OSLog(subsystem: SyncConstants.subsystemName, category: String(describing: SessionStore.self))
    
    private let fileManager = FileManager()
    
    private let queue = DispatchQueue(label: "RecipeStore")
    
    private let container: CKContainer
    private let defaults: UserDefaults
    private var syncEngine: SyncEngine?
    
    public init(sessions: [Session] = []) {
        self.container = CKContainer(identifier: SyncConstants.containerIdentifier)
        
        guard let defaults = UserDefaults(suiteName: SyncConstants.appGroup) else {
            fatalError("Invalid app group")
        }
        self.defaults = defaults
        
        if !sessions.isEmpty {
            self.sessions = sessions
            save()
        } else {
            load()
        }
        
        self.syncEngine = SyncEngine(
            defaults: self.defaults,
            initialRecipes: self.sessions
        )
        
        self.syncEngine?.didUpdateModels = { [weak self] sessions in
            self?.updateAfterSync(sessions)
        }
        
        self.syncEngine?.didDeleteModels = { [weak self] identifiers in
            self?.sessions.removeAll(where: { identifiers.contains($0.id) })
            self?.save()
        }
    }
    
    private var storeURL: URL {
        let baseURL: URL
        
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: SyncConstants.appGroup) {
            baseURL = containerURL
        } else {
            os_log("Failed to get container URL for app security group %@", log: self.log, type: .fault, SyncConstants.appGroup)
            
            baseURL = fileManager.temporaryDirectory
        }
        
        let url = baseURL.appendingPathComponent("RecipeStore.plist")
        
        if !fileManager.fileExists(atPath: url.path) {
            os_log("Creating store file at %@", log: self.log, type: .debug, url.path)
            
            if !fileManager.createFile(atPath: url.path, contents: nil, attributes: nil) {
                os_log("Failed to create store file at %@", log: self.log, type: .fault, url.path)
            }
        }
        
        return url
    }
    
    private func updateAfterSync(_ sessions: [Session]) {
        os_log("%{public}@", log: log, type: .debug, #function)
        
        sessions.forEach { updatedSession in
            guard let idx = self.sessions.firstIndex(where: { $0.id == updatedSession.id }) else { return }
            self.sessions[idx] = updatedSession
        }
        
        save()
    }
    
    public func addOrUpdate(_ session: Session) {
        if let idx = sessions.lastIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.append(session)
        }
        
        syncEngine?.upload(session)
        save()
    }
    
    public func delete(with id: String) {
        guard let session = self.session(with: id) else {
            os_log("Session not found with id %@ for deletion.", log: self.log, type: .error, id)
            return
        }
        
        syncEngine?.delete(session)
        save()
    }
    
    public func session(with id: String) -> Session? {
        sessions.first(where: { $0.id == id })
    }
    
    private func save() {
        os_log("%{public}@", log: log, type: .debug, #function)
        
        do {
            let data = try PropertyListEncoder().encode(sessions)
            try data.write(to: storeURL)
        } catch {
            os_log("Failed to save sessions: %{public}@", log: self.log, type: .error, String(describing: error))
        }
    }
    
    private func load() {
        os_log("%{public}@", log: log, type: .debug, #function)
        
        do {
            let data = try Data(contentsOf: storeURL)
            
            guard !data.isEmpty else { return }
            
            self.sessions = try PropertyListDecoder().decode([Session].self, from: data)
        } catch {
            os_log("Failed to load sessions: %{public}@", log: self.log, type: .error, String(describing: error))
        }
    }
    
    public func processSubscriptionNotification(with userInfo: [AnyHashable : Any]) {
        syncEngine?.processSubscriptionNotification(with: userInfo)
    }
    
}
