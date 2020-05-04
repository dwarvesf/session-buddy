//
//  AppDelegate.swift
//  SessionRestore
//
//  Created by phucld on 4/13/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SessionStore()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.registerForRemoteNotifications()
    }
    
    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
        store.processSubscriptionNotification(with: userInfo)
    }
}
