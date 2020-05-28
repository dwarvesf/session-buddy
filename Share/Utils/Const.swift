//
//  Const.swift
//  SessionRestore
//
//  Created by phucld on 5/4/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation
import CloudKit

public struct SyncConstants {

    public static let containerIdentifier = "iCloud.foundation.dwarves.sessionBuddy"
    
    public static let appGroup = "group.foundation.dwarves.sessionbuddy"
    
    public static let subsystemName = "foundation.dwarves.sessionbuddy"
    
    public static let customZoneID: CKRecordZone.ID = {
        CKRecordZone.ID(zoneName: "SessionBuddyZone", ownerName: CKCurrentUserDefaultName)
    }()

}
