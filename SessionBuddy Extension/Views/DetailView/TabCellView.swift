//
//  TabCellView.swift
//  SessionRestore Extension
//
//  Created by phucld on 4/27/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

class TabCellView: NSTableCellView {
    
    @IBOutlet weak var btnDelete: NSButton?
    @IBOutlet weak var txtfieldTitle: NSTextField?
    
    private var onDelete: (() -> Void)?
    
    private var title = ""
    
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
        
        btnDelete?.isHidden = !highlight
        setupHandPointer()
        setupTitle()
    }
    
    private func setupHandPointer() {
        discardCursorRects()
        addCursorRect(self.bounds, cursor: NSCursor.pointingHand)
    }
    
    private func setupTitle() {
        if highlight {
            txtfieldTitle?.allowsEditingTextAttributes = true
            
            let attributedString = NSAttributedString(
                string: txtfieldTitle?.stringValue ?? "",
                attributes: [
                    NSAttributedString.Key.underlineStyle:  NSUnderlineStyle.single.rawValue
            ])
            
            txtfieldTitle?.attributedStringValue = attributedString
        } else {
            txtfieldTitle?.stringValue = title
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
    
    @IBAction func onDelete(_ sender: Any) {
        self.onDelete?()
    }
    
    func set(title: String, onDelete: @escaping (() -> Void)) {
        self.title = title
        self.txtfieldTitle?.stringValue = title
        self.onDelete = onDelete
    }
}
