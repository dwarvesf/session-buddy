//
//  ExportCellView.swift
//  Session Buddy Extension
//
//  Created by phucld on 5/19/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

class ExportCellView: NSTableCellView {
    @IBOutlet weak var checkBox: NSButton?
    @IBOutlet weak var lblTitle: NSTextField?
    
    var isSelectedChanged: ((Bool) -> Void)?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func set(
        title: String,
        isChecked: Bool,
        isSelectedChanged: @escaping ((Bool) -> Void)
    ) {
        self.lblTitle?.stringValue = title
        self.checkBox?.state = isChecked ? .on : .off
        self.isSelectedChanged = isSelectedChanged
    }
    
    @IBAction func selectCheckbox(_ sender: Any) {
        isSelectedChanged?(checkBox?.state == .some(.on))
    }
    
}
