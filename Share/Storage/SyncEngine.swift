//
//  SyncEngine.swift
//  SessionBuddy
//
//  Created by phucld on 5/27/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation
import CloudKit
import os.log

final class SyncEngine {

    let log = OSLog(subsystem: SyncConstants.subsystemName, category: String(describing: SyncEngine.self))

    private let defaults: UserDefaults

    private(set) lazy var container: CKContainer = {
        CKContainer(identifier: SyncConstants.containerIdentifier)
    }()

    private(set) lazy var privateDatabase: CKDatabase = {
        container.privateCloudDatabase
    }()

    private(set) lazy var privateSubscriptionId: String = {
        return "\(SyncConstants.customZoneID.zoneName).subscription"
    }()

    private var buffer: [Session]

    /// Called after models are updated with CloudKit data.
    var didUpdateModels: ([Session]) -> Void = { _ in }

    /// Called when models are deleted remotely.
    var didDeleteModels: ([String]) -> Void = { _ in }

    init(defaults: UserDefaults, initialSessions: [Session]) {
        self.defaults = defaults
        self.buffer = initialSessions

        start()
    }

    private let workQueue = DispatchQueue(label: "SyncEngine.Work", qos: .userInitiated)
    private let cloudQueue = DispatchQueue(label: "SyncEngine.Cloud", qos: .userInitiated)

    // MARK: - Setup boilerplate

    private func start() {
        prepareCloudEnvironment { [weak self] in
            guard let self = self else { return }

            os_log("Cloud environment preparation done", log: self.log, type: .debug)

            self.uploadLocalDataNotUploadedYet()
            self.fetchRemoteChanges()
        }
    }

    private lazy var cloudOperationQueue: OperationQueue = {
        let q = OperationQueue()

        q.underlyingQueue = cloudQueue
        q.name = "SyncEngine.Cloud"
        q.maxConcurrentOperationCount = 1

        return q
    }()

    private lazy var createdCustomZoneKey: String = {
        return "CREATEDZONE-\(SyncConstants.customZoneID.zoneName)"
    }()

    private var createdCustomZone: Bool {
        get {
            return defaults.bool(forKey: createdCustomZoneKey)
        }
        set {
            defaults.set(newValue, forKey: createdCustomZoneKey)
        }
    }

    private lazy var createdPrivateSubscriptionKey: String = {
        return "CREATEDSUBDB-\(SyncConstants.customZoneID.zoneName)"
    }()

    private var createdPrivateSubscription: Bool {
        get {
            return defaults.bool(forKey: createdPrivateSubscriptionKey)
        }
        set {
            defaults.set(newValue, forKey: createdPrivateSubscriptionKey)
        }
    }

    private func prepareCloudEnvironment(then block: @escaping () -> Void) {
        workQueue.async { [weak self] in
            guard let self = self else { return }

            self.createCustomZoneIfNeeded()
            self.cloudOperationQueue.waitUntilAllOperationsAreFinished()
            guard self.createdCustomZone else { return }

            self.createPrivateSubscriptionsIfNeeded()
            self.cloudOperationQueue.waitUntilAllOperationsAreFinished()
            guard self.createdPrivateSubscription else { return }

            DispatchQueue.main.async { block() }
        }
    }

    private func createCustomZoneIfNeeded() {
        guard !createdCustomZone else {
            os_log("Already have custom zone, skipping creation but checking if zone really exists", log: log, type: .debug)

            checkCustomZone()

            return
        }

        os_log("Creating CloudKit zone %@", log: log, type: .info, SyncConstants.customZoneID.zoneName)

        let zone = CKRecordZone(zoneID: SyncConstants.customZoneID)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)

        operation.modifyRecordZonesCompletionBlock = { [weak self] _, _, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to create custom CloudKit zone: %{public}@",
                       log: self.log,
                       type: .error,
                       String(describing: error))

                error.retryCloudKitOperationIfPossible(self.log) { self.createCustomZoneIfNeeded() }
            } else {
                os_log("Zone created successfully", log: self.log, type: .info)
                self.createdCustomZone = true
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = privateDatabase

        cloudOperationQueue.addOperation(operation)
    }

    private func checkCustomZone() {
        let operation = CKFetchRecordZonesOperation(recordZoneIDs: [SyncConstants.customZoneID])

        operation.fetchRecordZonesCompletionBlock = { [weak self] ids, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to check for custom zone existence: %{public}@", log: self.log, type: .error, String(describing: error))

                if !error.retryCloudKitOperationIfPossible(self.log, with: { self.checkCustomZone() }) {
                    os_log("Irrecoverable error when fetching custom zone, assuming it doesn't exist: %{public}@", log: self.log, type: .error, String(describing: error))

                    DispatchQueue.main.async {
                        self.createdCustomZone = false
                        self.createCustomZoneIfNeeded()
                    }
                }
            } else if ids == nil || ids?.count == 0 {
                os_log("Custom zone reported as existing, but it doesn't exist. Creating.", log: self.log, type: .error)
                self.createdCustomZone = false
                self.createCustomZoneIfNeeded()
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = privateDatabase

        cloudOperationQueue.addOperation(operation)
    }

    private func createPrivateSubscriptionsIfNeeded() {
        guard !createdPrivateSubscription else {
            os_log("Already subscribed to private database changes, skipping subscription but checking if it really exists", log: log, type: .debug)

            checkSubscription()

            return
        }

        let subscription = CKRecordZoneSubscription(zoneID: SyncConstants.customZoneID, subscriptionID: privateSubscriptionId)

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true

        subscription.notificationInfo = notificationInfo
        subscription.recordType = .session

        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)

        operation.database = privateDatabase
        operation.qualityOfService = .userInitiated

        operation.modifySubscriptionsCompletionBlock = { [weak self] _, _, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to create private CloudKit subscription: %{public}@",
                       log: self.log,
                       type: .error,
                       String(describing: error))

                error.retryCloudKitOperationIfPossible(self.log) { self.createPrivateSubscriptionsIfNeeded() }
            } else {
                os_log("Private subscription created successfully", log: self.log, type: .info)
                self.createdPrivateSubscription = true
            }
        }

        cloudOperationQueue.addOperation(operation)
    }

    private func checkSubscription() {
        let operation = CKFetchSubscriptionsOperation(subscriptionIDs: [privateSubscriptionId])

        operation.fetchSubscriptionCompletionBlock = { [weak self] ids, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to check for private zone subscription existence: %{public}@", log: self.log, type: .error, String(describing: error))

                if !error.retryCloudKitOperationIfPossible(self.log, with: { self.checkSubscription() }) {
                    os_log("Irrecoverable error when fetching private zone subscription, assuming it doesn't exist: %{public}@", log: self.log, type: .error, String(describing: error))

                    DispatchQueue.main.async {
                        self.createdPrivateSubscription = false
                        self.createPrivateSubscriptionsIfNeeded()
                    }
                }
            } else if ids == nil || ids?.count == 0 {
                os_log("Private subscription reported as existing, but it doesn't exist. Creating.", log: self.log, type: .error)

                DispatchQueue.main.async {
                    self.createdPrivateSubscription = false
                    self.createPrivateSubscriptionsIfNeeded()
                }
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = privateDatabase

        cloudOperationQueue.addOperation(operation)
    }

    // MARK: - Upload

    private func uploadLocalDataNotUploadedYet() {
        os_log("%{public}@", log: log, type: .debug, #function)

        let sessions = buffer.filter({ $0.ckData == nil })

        guard !sessions.isEmpty else { return }

        os_log("Found %d local session(s) which haven't been uploaded yet.", log: self.log, type: .debug, sessions.count)

        let records = sessions.map { $0.record }

        uploadRecords(records)
    }
    
    func upload(_ session: Session) {
        os_log("%{public}@", log: log, type: .debug, #function)

        buffer.append(session)

        uploadRecords([session.record])
    }

    func delete(_ session: Session) {
        fatalError("Deletion not implemented")
    }

    private func uploadRecords(_ records: [CKRecord]) {
        guard !records.isEmpty else { return }

        os_log("%{public}@ with %d record(s)", log: log, type: .debug, #function, records.count)

        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)

        operation.perRecordCompletionBlock = { [weak self] record, error in
            guard let self = self else { return }

            // We're only interested in conflict errors here
            guard let error = error, error.isCloudKitConflict else { return }

            os_log("CloudKit conflict with record of type %{public}@", log: self.log, type: .error, record.recordType)

            guard let resolvedRecord = error.resolveConflict(with: Session.resolveConflict) else {
                os_log(
                    "Resolving conflict with record of type %{public}@ returned a nil record. Giving up.",
                    log: self.log,
                    type: .error,
                    record.recordType
                )
                return
            }

            os_log("Conflict resolved, will retry upload", log: self.log, type: .info)

            self.uploadRecords([resolvedRecord])
        }

        operation.modifyRecordsCompletionBlock = { [weak self] serverRecords, _, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to upload records: %{public}@", log: self.log, type: .error, String(describing: error))

                DispatchQueue.main.async {
                    self.handleUploadError(error, records: records)
                }
            } else {
                os_log("Successfully uploaded %{public}d record(s)", log: self.log, type: .info, records.count)

                DispatchQueue.main.async {
                    guard let serverRecords = serverRecords else { return }
                    self.updateLocalModelsAfterUpload(with: serverRecords)
                }
            }
        }

        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        operation.database = privateDatabase

        cloudOperationQueue.addOperation(operation)
    }

    private func handleUploadError(_ error: Error, records: [CKRecord]) {
        guard let ckError = error as? CKError else {
            os_log("Error was not a CKError, giving up: %{public}@", log: self.log, type: .fault, String(describing: error))
            return
        }

        if ckError.code == CKError.Code.limitExceeded {
            os_log("CloudKit batch limit exceeded, sending records in chunks", log: self.log, type: .error)

            fatalError("Not implemented: batch uploads. Here we should divide the records in chunks and upload in batches instead of trying everything at once.")
        } else {
            let result = error.retryCloudKitOperationIfPossible(self.log) { self.uploadRecords(records) }

            if !result {
                os_log("Error is not recoverable: %{public}@", log: self.log, type: .error, String(describing: error))
            }
        }
    }

    private func updateLocalModelsAfterUpload(with records: [CKRecord]) {
        let models: [Session] = records.compactMap { r in
            guard var model = buffer.first(where: { $0.id == r.recordID.recordName }) else { return nil }

            model.ckData = r.encodedSystemFields

            return model
        }

        DispatchQueue.main.async {
            self.didUpdateModels(models)
            self.buffer = []
        }
    }

    // MARK: - Remote change tracking

    private lazy var privateChangeTokenKey: String = {
        return "TOKEN-\(SyncConstants.customZoneID.zoneName)"
    }()

    private var privateChangeToken: CKServerChangeToken? {
        get {
            guard let data = defaults.data(forKey: privateChangeTokenKey) else { return nil }
            guard !data.isEmpty else { return nil }

            do {
                let token = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)

                return token
            } catch {
                os_log("Failed to decode CKServerChangeToken from defaults key privateChangeToken", log: log, type: .error)
                return nil
            }
        }
        set {
            guard let newValue = newValue else {
                defaults.setValue(Data(), forKey: privateChangeTokenKey)
                return
            }

            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)

                defaults.set(data, forKey: privateChangeTokenKey)
            } catch {
                os_log("Failed to encode private change token: %{public}@", log: self.log, type: .error, String(describing: error))
            }
        }
    }

    func fetchRemoteChanges() {
        os_log("%{public}@", log: log, type: .debug, #function)

        var changedRecords: [CKRecord] = []
        var deletedRecordIDs: [CKRecord.ID] = []

        let operation = CKFetchRecordZoneChangesOperation()

        let token: CKServerChangeToken? = privateChangeToken

        let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration(
            previousServerChangeToken: token,
            resultsLimit: nil,
            desiredKeys: nil
        )

        operation.configurationsByRecordZoneID = [SyncConstants.customZoneID: config]

        operation.recordZoneIDs = [SyncConstants.customZoneID]
        operation.fetchAllChanges = true

        operation.recordZoneChangeTokensUpdatedBlock = { [weak self] _, changeToken, _ in
            guard let self = self else { return }

            guard let changeToken = changeToken else { return }

            self.privateChangeToken = changeToken
        }

        operation.recordZoneFetchCompletionBlock = { [weak self] _, token, _, _, error in
            guard let self = self else { return }

            if let error = error as? CKError {
                os_log("Failed to fetch record zone changes: %{public}@",
                       log: self.log,
                       type: .error,
                       String(describing: error))

                if error.code == .changeTokenExpired {
                    os_log("Change token expired, resetting token and trying again", log: self.log, type: .error)

                    self.privateChangeToken = nil

                    DispatchQueue.main.async { self.fetchRemoteChanges() }
                } else {
                    error.retryCloudKitOperationIfPossible(self.log) { self.fetchRemoteChanges() }
                }
            } else {
                os_log("Commiting new change token", log: self.log, type: .debug)

                self.privateChangeToken = token
            }
        }

        operation.recordChangedBlock = { changedRecords.append($0) }

        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            // In the future we may need to use the second arg to this closure and map
            // between record types and deleted record IDs (when we need to sync more types)
            deletedRecordIDs.append(recordID)
        }

        operation.fetchRecordZoneChangesCompletionBlock = { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to fetch record zone changes: %{public}@",
                       log: self.log,
                       type: .error,
                       String(describing: error))

                error.retryCloudKitOperationIfPossible(self.log) { self.fetchRemoteChanges() }
            } else {
                os_log("Finished fetching record zone changes", log: self.log, type: .info)

                DispatchQueue.main.async { self.commitServerChangesToDatabase(with: changedRecords, deletedRecordIDs: deletedRecordIDs) }
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = privateDatabase

        cloudOperationQueue.addOperation(operation)
    }

    private func commitServerChangesToDatabase(with changedRecords: [CKRecord], deletedRecordIDs: [CKRecord.ID]) {
        guard !changedRecords.isEmpty || !deletedRecordIDs.isEmpty else {
            os_log("Finished record zone changes fetch with no changes", log: log, type: .info)
            return
        }

        os_log("Will commit %d changed record(s) and %d deleted record(s) to the database", log: log, type: .info, changedRecords.count, deletedRecordIDs.count)

        let models: [Session] = changedRecords.compactMap { record in
            do {
                return try Session(record: record)
            } catch {
                os_log("Error decoding recipe from record: %{public}@", log: self.log, type: .error, String(describing: error))
                return nil
            }
        }

        let deletedIdentifiers = deletedRecordIDs.map { $0.recordName }

        didUpdateModels(models)
        didDeleteModels(deletedIdentifiers)
    }

}

// Process Notification
extension SyncEngine {

    @discardableResult func processSubscriptionNotification(with userInfo: [AnyHashable : Any]) -> Bool {
        os_log("%{public}@", log: log, type: .debug, #function)

        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            os_log("Not a CKNotification", log: self.log, type: .error)
            return false
        }

        guard notification.subscriptionID == privateSubscriptionId else {
            os_log("Not our subscription ID", log: self.log, type: .debug)
            return false
        }

        os_log("Received remote CloudKit notification for user data", log: log, type: .debug)

        fetchRemoteChanges()

        return true
    }
}
