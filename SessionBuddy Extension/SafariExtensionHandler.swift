//
//  SafariExtensionHandler.swift
//  SessionRestore Extension
//
//  Created by phucld on 4/13/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
        
    override func messageReceived(
        withName messageName: String,
        from page: SFSafariPage,
        userInfo: [String : Any]?) {
        
        // This method will be called when a content script provided by
        // your extension calls safari.extension.dispatchMessage("message").
        if messageName == "DOMContentLoaded" || messageName == "BeforeUnload" {
            DispatchQueue.global(qos: .userInitiated).async {
                self.saveLatestSession()
            }
        }
    }
    
    private func saveLatestSession() {
        guard Preferences.showLatestSession else {return}
        
        // Get old backupSessionIdx
        LocalStorage.sessions.removeAll(where: \.isBackup)
        
        SFSafariApplication.getActiveWindow { window in
            window?.getAllTabs { tabs in
                var sessionTabs = [Tab]()
                
                for (index, tab) in tabs.enumerated() {
                    tab.getActivePage { page in
                        page?.getPropertiesWithCompletionHandler { properties in
                            if let url = properties?.url?.absoluteString,
                                let title = properties?.title {
                                sessionTabs.append(Tab(title: title, url: url))
                            }
                            
                            // Last element
                            if index == tabs.count - 1 {
                                var newSession = Session(
                                    title: "Latest Session",
                                    tabs: sessionTabs)
                                
                                newSession.isBackup = true
                                LocalStorage.sessions = [newSession] + LocalStorage.sessions
                                  NotificationCenter.default.post(Notification(name: Notification.Name("sessionDidChange")))
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        NSLog("The extension's toolbar item was clicked")
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
}
