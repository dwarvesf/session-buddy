//
//  Tab.swift
//  SessionRestore
//
//  Created by phucld on 4/29/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation

struct Tab: Codable, Hashable {
    
    // DON'T DO THIS
    // let id = UUID().uuidString
    // This will make the id change whenever making a objectt copy
    // Still don't know why
    
    let id: String
    var title: String
    var url: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.url == rhs.url
    }

    /// Used to store the encoded `CKRecord.ID` so that local records can be matched with
    /// records on the server. This ensures updates don't cause duplication of records.
    var ckData: Data? = nil
    
    init(id: String = UUID().uuidString, title: String, url: String) {
        self.id = id
        self.title = title
        self.url = url
    }
}
