//
//  PreferencesViewConttroller.swift
//  Session Buddy Extension
//
//  Created by phucld on 6/11/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

class PreferencesViewConttroller: NSViewController {

    @IBOutlet weak var checkboxShowLatestSession: NSButton!
    
    var onNavigationBack: ((Bool) -> Void)?
    
    private var shouldUpdate = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func set(onNavigationBack: @escaping ((Bool) -> Void)) {
        self.onNavigationBack = onNavigationBack
    }
    
    private func setupViews() {
        checkboxShowLatestSession.state = Preferences.showLatestSession ? .on : .off
    }
    
    @IBAction func toggleShowTheLatestSession(_ sender: Any) {
        Preferences.showLatestSession = checkboxShowLatestSession.state == .on
        if checkboxShowLatestSession.state == .on {
            LocalStorage.sessions.removeAll(where: (\.isBackup))
            NotificationCenter.default.post(Notification(name: Notification.Name("sessionDidChange")))
        }
        
        shouldUpdate = true
    }
    
    @IBAction func backToPrevious(_ sender: Any) {
        self.onNavigationBack?(shouldUpdate)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
}
