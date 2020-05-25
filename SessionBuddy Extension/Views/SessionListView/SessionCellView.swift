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
    @IBOutlet weak var stackViewActions: NSStackView?
    
    private var trackingArea: NSTrackingArea!
    
    private var highlight = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    // MARK: - Mouse hover
    deinit {
        removeTrackingArea(trackingArea)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited,/* NSTrackingAreaOptions.mouseMoved */],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
        
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        self.setupView()
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if !highlight {
            highlight = true
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if highlight {
            highlight = false
        }
    }
    
    @IBAction func goToDetail(_ sender: Any) {
        onDetailClick?()
    }
    
    @IBAction func restoreSession(_ sender: Any) {
        onRestoreSession?()
    }
    
    @IBAction func UpdateSessionName(_ sender: NSTextField) {
        onUpdateSession?(sender.stringValue)
    }
    
    private func setupView() {
        lblTabCount?.isEditable = false
        lblTabCount?.isHidden = highlight
        stackViewActions?.isHidden = !highlight
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
