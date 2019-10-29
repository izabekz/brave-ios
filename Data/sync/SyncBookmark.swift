/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

final class SyncBookmark: SyncRecord {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private enum SerializationKeys: String, CodingKey {
        case isFolder
        case parentFolderObjectId
        case site
        case syncOrder
    }
    
    // MARK: Properties
    var isFavorite: Bool = false
    var isFolder: Bool? = false
    var parentFolderObjectId: [Int]?
    var site: SyncSite?
    var syncOrder: String?
    
    required init() {
        super.init()
    }
    
    required init(record: Syncable?, deviceId: [Int]?, action: Int?) {
        super.init(record: record, deviceId: deviceId, action: action)
        
        let bm = record as? Bookmark
        
        let unixCreated = Int(bm?.created?.toTimestamp() ?? 0)
        let unixAccessed = Int(bm?.lastVisited?.toTimestamp() ?? 0)
        
        let site = SyncSite()
        site.title = bm?.title
        site.customTitle = bm?.customTitle
        site.location = bm?.url
        site.creationTime = unixCreated
        site.lastAccessedTime = unixAccessed
        // FIXME: This sometimes crashes the app. See issue #1760.
        // site.favicon = bm?.domain?.favicon?.url
        
        self.isFavorite = bm?.isFavorite ?? false
        self.isFolder = bm?.isFolder
        self.parentFolderObjectId = bm?.syncParentUUID
        self.site = site
        syncOrder = bm?.syncOrder
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SerializationKeys.self)
        isFolder = try container.decodeIfPresent(Bool.self, forKey: .isFolder)
        syncOrder = try container.decodeIfPresent(String.self, forKey: .syncOrder)
        parentFolderObjectId = try container.decodeIfPresent([Int].self, forKey: .parentFolderObjectId)
        site = try container.decodeIfPresent(SyncSite.self, forKey: .site)
        try super.init(from: container.superDecoder())
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SerializationKeys.self)
        try container.encodeIfPresent(isFolder, forKey: .isFolder)
        try container.encodeIfPresent(syncOrder, forKey: .syncOrder)
        try container.encodeIfPresent(parentFolderObjectId, forKey: .parentFolderObjectId)
        try container.encodeIfPresent(site, forKey: .site)
        try super.encode(to: container.superEncoder())
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    override func dictionaryRepresentation() -> [String: Any] {
        guard let objectData = self.objectData else { return [:] }

        let result = (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self), options: .allowFragments)) as? [String: Any]
        
        var dictionary = super.dictionaryRepresentation()
        dictionary[objectData.rawValue] = result ?? [:]
        return dictionary
    }
    
}
