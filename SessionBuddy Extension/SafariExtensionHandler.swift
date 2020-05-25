//
//  SafariExtensionHandler.swift
//  SessionRestore Extension
//
//  Created by phucld on 4/13/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
        
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        page.getPropertiesWithCompletionHandler { properties in
            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
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
    
    override func page(_ page: SFSafariPage, willNavigateTo url: URL?) {
        guard let url = url else {return}
        
        // Handle auto backup session
        if let backupSessionIdx = LocalStorage.sessions.firstIndex(where: { $0.isBackup }) {
            // Update existed backup session
            var backupSessionTabs = LocalStorage.sessions[backupSessionIdx].tabs
            backupSessionTabs.append(Tab(title: url.absoluteString, url: url.absoluteString))
            // just add unique URL
            LocalStorage.sessions[backupSessionIdx].tabs = backupSessionTabs.unique()
        } else {
            // Create new backup session
            var backupSession = Session(title: "Backups - \(Date().commonStringFormat())", tabs: [Tab(title: url.absoluteString, url: url.absoluteString)])
            backupSession.isBackup = true
            LocalStorage.sessions.append(backupSession)
        }

    }
}
