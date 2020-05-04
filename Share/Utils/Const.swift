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

    public static let containerIdentifier = "iCloud.foundation.dwarves.SessionRestore"
    
    public static let appGroup = "group.W777S7V8TN.foundation.dwarves.SessionRestore"
    
    public static let subsystemName = "foundation.dwarves.SessionRestore"
    
    public static let customZoneID: CKRecordZone.ID = {
        CKRecordZone.ID(zoneName: "SessionRestoreZone", ownerName: CKCurrentUserDefaultName)
    }()

}
