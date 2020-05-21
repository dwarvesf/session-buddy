//
//  SessionTabCellView.swift
//  Session Buddy Extension
//
//  Created by phucld on 5/12/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

class SessionTabCellView: NSTableCellView {
    
    @IBOutlet weak var lblName: NSTextField!
    
    private var title: String = ""
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
        
        setupHandPointer()
        setupTitle()
    }
    
    private func setupHandPointer() {
        discardCursorRects()
        addCursorRect(self.bounds, cursor: NSCursor.pointingHand)
    }
    
    private func setupTitle() {
        if highlight {
            lblName?.allowsEditingTextAttributes = true
            
            let attributedString = NSAttributedString(
                string: lblName?.stringValue ?? "",
                attributes: [
                    NSAttributedString.Key.underlineStyle:  NSUnderlineStyle.single.rawValue
            ])
            
            lblName?.attributedStringValue = attributedString
        } else {
            lblName?.stringValue = title
        }
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
    
    func set(title: String) {
        self.title = title
        lblName.stringValue = title
    }
    
}
