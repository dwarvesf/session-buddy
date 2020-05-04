//
//  SessionCellView.swift
//  SessionRestore Extension
//
//  Created by phucld on 4/13/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

class SessionCellView: NSTableCellView {

    private var onDetailClick: (()->Void)?
    private var onRestoreSession: (()->Void)?
    private var onUpdateSession: ((String)->Void)?
    
    @IBOutlet weak var lblName: NSTextField?
    @IBOutlet weak var lblTabCount: NSTextField?
    
    @IBAction func goToDetail(_ sender: Any) {
        onDetailClick?()
    }
    
    @IBAction func restoreSession(_ sender: Any) {
        onRestoreSession?()
    }
    
    @IBAction func UpdateSessionName(_ sender: NSTextField) {
        onUpdateSession?(sender.stringValue)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.setupView()
    }
    
    private func setupView() {
        lblTabCount?.isEditable = false
    }
    
    func set(title: String,
             tabCount: Int,
             onDetailClick: @escaping (() -> Void),
             onRestoreSession: @escaping (() -> Void),
             onUpdateSession: @escaping ((String) -> Void)
    ) {
        self.lblName?.stringValue = title
        self.lblTabCount?.stringValue = "\(tabCount) " + (tabCount > 1 ? "tabs" : "tab")
        self.onDetailClick = onDetailClick
        self.onRestoreSession = onRestoreSession
        self.onUpdateSession = onUpdateSession
    }
}
