//
//  Util.swift
//  SessionRestore
//
//  Created by phucld on 5/19/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

enum Util {
    static func showErrorDialog(text: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.icon = #imageLiteral(resourceName: "Image")
        alert.informativeText = text
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
