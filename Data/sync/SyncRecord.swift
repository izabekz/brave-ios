/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import CoreData

private let log = Logger.browserLogger

protocol SyncRecordProtocol {
    associatedtype CoreDataParallel: Syncable
//    var CoredataParallel: NSManagedObject.Type?
    
}

public class SyncRecord: SyncRecordProtocol, Codable {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private enum SerializationKeys: String, CodingKey {
        case objectId
        case deviceId
        case action
        case objectData
        case syncTimestamp
    }
    
    // MARK: Properties
    var objectId: [Int]?
    var deviceId: [Int]?
    var action: Int?
    var objectData: SyncObjectDataType?
    
    var syncTimestamp: Int?
    
//    var CoredataParallel: Syncable.Type?
    typealias CoreDataParallel = Device
    
    required init() {
        
    }
    
    /// Converts server format for storing timestamp(integer) to Date
    var syncNativeTimestamp: Date? {
        guard let syncTimestamp = syncTimestamp else { return nil }
        
        return Date.fromTimestamp(Timestamp(syncTimestamp))
    }
    
    // Would be nice to make this type specific to class
    required init(record: Syncable?, deviceId: [Int]?, action: Int?) {
        
        self.objectId = record?.syncUUID
        self.deviceId = deviceId
        self.action = action
        
        // TODO: Move to SyncObjectDataType enum
//        self.objectData = [Syncable.Type: SyncObjectDataType] = [Bookmark.self: .Bookmark][self.Type]
        self.objectData = .Bookmark
        
        // TODO: Need object type!!
        
        // Initially, a record should have timestamp set to now.
        // It should then be updated from resolved-sync-records callback.
        let timeStamp = (record?.created ?? Date()).timeIntervalSince1970
        syncTimestamp = Int(timeStamp)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SerializationKeys.self)
        
        // objectId can come in two different formats
        var objectId: [Int]? = try? container.decodeIfPresent([Int].self, forKey: .objectId)
        if objectId == nil {
            objectId = (try? container.decodeIfPresent([String].self, forKey: .objectId))?.compactMap { Int($0) }
        }
        self.objectId = objectId
        
        deviceId = try container.decodeIfPresent([Int].self, forKey: .deviceId)
        action = try container.decodeIfPresent(Int.self, forKey: .action)
        objectData = try container.decodeIfPresent(SyncObjectDataType.self, forKey: .objectData)
        syncTimestamp = try container.decodeIfPresent(Int.self, forKey: .syncTimestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SerializationKeys.self)
        try container.encodeIfPresent(objectId, forKey: .objectId)
        try container.encodeIfPresent(deviceId, forKey: .deviceId)
        try container.encodeIfPresent(action, forKey: .action)
        try container.encodeIfPresent(objectData, forKey: .objectData)
        try container.encodeIfPresent(syncTimestamp, forKey: .syncTimestamp)
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    func dictionaryRepresentation() -> [String: Any] {
        let result = (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self), options: .allowFragments)) as? [String: Any]
        return result ??  [:]
    }
}

// Uses same mappings above, but for arrays
extension SyncRecordProtocol where Self: SyncRecord {
    
    static func syncRecords(_ rootJSON: [[String: Any]]?) -> [Self]? {
        return rootJSON?.map {
            let data = (try? JSONSerialization.data(withJSONObject: $0, options: JSONSerialization.WritingOptions(rawValue: 0))) ?? Data()
            return (try? JSONDecoder().decode(Self.self, from: data)) ?? self.init()
        }
    }
    
    static func syncRecords(_ rootJSON: [String: Any]) -> [Self]? {
        return self.syncRecords([rootJSON])
    }
}

