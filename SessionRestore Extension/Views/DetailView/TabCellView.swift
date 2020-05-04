//
//  TabCellView.swift
//  SessionRestore Extension
//
//  Created by phucld on 4/27/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

class TabCellView: NSTableCellView {
    
    private var onDelete: (() -> Void)?
    
    @IBAction func onDelete(_ sender: Any) {
        self.onDelete?()
    }
    
    func set(title: String, onDelete: @escaping (() -> Void)) {
        self.textField?.stringValue = title
        self.onDelete = onDelete
    }
}
