//
//  SearchCellView.swift
//  Session Buddy Extension
//
//  Created by phucld on 5/20/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

class SearchCellView: NSTableCellView {
    @IBOutlet weak var lblTitle: NSTextField?
    
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
        let backgroundColor = highlight ? NSColor.textColor.withAlphaComponent(0.1) : .clear
        self.layer?.backgroundColor = backgroundColor.cgColor
    }
    
    private func setupHandPointer() {
        discardCursorRects()
        addCursorRect(self.bounds, cursor: NSCursor.pointingHand)
    }
    
    func set(title: String, with searchKey: String) {
        let attributedString = NSMutableAttributedString(string: title, attributes: nil)
        let keyRange = (attributedString.string as NSString).range(of: searchKey)
        attributedString.setAttributes([NSAttributedString.Key.font: NSFont.systemFont(ofSize: 14, weight: .medium)], range: keyRange)
        
        self.lblTitle?.attributedStringValue = attributedString
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
}
