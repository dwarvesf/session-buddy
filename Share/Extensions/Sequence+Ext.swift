//
//  Sequence+Ext.swift
//  SessionBuddy
//
//  Created by phucld on 5/25/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation

extension Sequence where Element: Hashable {
    func unique() -> [Element] {
        var seen: Set<Element> = []
        return filter { element in
            if seen.contains(element) {
                return false
            } else {
                seen.insert(element)
                return true
            }
        }
    }
}
