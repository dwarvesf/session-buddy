//
//  Tab+CloudKit.swift
//  SessionRestore
//
//  Created by phucld on 4/29/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation
import CloudKit

extension CKRecord.RecordType {
    static let tab = "Tab"
}

extension Tab {
    struct RecordError: LocalizedError {
        var localizedDescription: String
        
        static func missingKey(_ key: RecordKey) -> RecordError {
            RecordError(localizedDescription: "Missing required key \(key.rawValue)")
        }
    }
    
    enum RecordKey: String {
        case title
        case url
    }
    
    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id)
    }
    
    var record: CKRecord {
        let r = CKRecord(recordType: .tab, recordID: recordID)
        
        r[.title] = title
        r[.url] = url
        
        return r
    }
    
    init(record: CKRecord) throws {
        guard let title = record[.title] as? String else {
            throw RecordError.missingKey(.title)
        }
        guard let url = record[.url] as? String else {
            throw RecordError.missingKey(.url)
        }
        
        self.ckData = record.encodedSystemFields
        self.id = record.recordID.recordName
        self.title = title
        self.url = url
    }
}

extension CKRecord {

    var encodedSystemFields: Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        encodeSystemFields(with: coder)
        coder.finishEncoding()

        return coder.encodedData
    }

}

extension Tab {
    static func resolveConflict(clientRecord: CKRecord, serverRecord: CKRecord) -> CKRecord? {
        // Most recent record wins. This might not be the best solution but YOLO.

        guard let clientDate = clientRecord.modificationDate, let serverDate = serverRecord.modificationDate else {
            return clientRecord
        }

        if clientDate > serverDate {
            return clientRecord
        } else {
            return serverRecord
        }
    }
}

fileprivate extension CKRecord {
    subscript(key: Tab.RecordKey) -> Any? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue as? CKRecordValue
        }
    }
}

