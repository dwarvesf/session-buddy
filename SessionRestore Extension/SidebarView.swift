//
//  SidebarView.swift
//  Session Buddy Extension
//
//  Created by phucld on 5/11/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

class SidebarView: NSOutlineView {

  override func makeView(withIdentifier identifier: NSUserInterfaceItemIdentifier, owner: Any?) -> NSView? {
    let view = super.makeView(withIdentifier: identifier, owner: owner)

    if identifier == NSOutlineView.disclosureButtonIdentifier {
      if let btnView = view as? NSButton {
        btnView.imageScaling = .scaleProportionallyDown
        btnView.image = #imageLiteral(resourceName: "ico_disclosure")
        btnView.alternateImage = #imageLiteral(resourceName: "ico_disclosure_down")
        
        // can set properties of the image like the size
        btnView.image?.size = NSSize(width: 8.0, height: 8.0)
        btnView.alternateImage?.size = NSSize(width: 8.0, height: 8.0)
      }
    }
    return view
  }

    @IBAction func doubleClickeditem(_ sender: NSOutlineView) {
        let item = sender.item(atRow: sender.clickedRow)
        
        if item is Session {
            if sender.isItemExpanded(item) {
                sender.collapseItem(item)
            } else {
                sender.expandItem(item)
            }
        }
    }
}
