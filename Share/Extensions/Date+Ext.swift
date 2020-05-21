//
//  Date+Ext.swift
//  SessionRestore
//
//  Created by phucld on 5/19/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation

extension Date {
    func commonStringFormat() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        return dateFormatter.string(from: self)
    }
    
    func saveFileStringFormat() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.dateFormat = "MM-dd-yyyy-HH-mm"
        return dateFormatter.string(from: self)
    }
}
