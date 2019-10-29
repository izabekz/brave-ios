/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public final class SyncSite: Codable {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private enum SerializationKeys: String, CodingKey {
        case customTitle
        case title
        case favicon
        case location
        case creationTime
        case lastAccessedTime
    }
    
    // MARK: Properties
    public var customTitle: String?
    public var title: String?
    public var favicon: String?
    public var location: String?
    public var creationTime: Int?
    public var lastAccessedTime: Int?
    
    public var creationNativeDate: Date? {
        return Date.fromTimestamp(Timestamp(creationTime ?? 0))
    }
    
    public var lastAccessedNativeDate: Date? {
        return Date.fromTimestamp(Timestamp(lastAccessedTime ?? 0))
    }
    
    public init() {
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SerializationKeys.self)
        customTitle = try container.decodeIfPresent(String.self, forKey: .customTitle)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        favicon = try container.decodeIfPresent(String.self, forKey: .favicon)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        creationTime = try container.decodeIfPresent(Int.self, forKey: .creationTime)
        lastAccessedTime = try container.decodeIfPresent(Int.self, forKey: .lastAccessedTime)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SerializationKeys.self)
        try container.encodeIfPresent(customTitle, forKey: .customTitle)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(favicon, forKey: .favicon)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(creationTime, forKey: .creationTime)
        try container.encodeIfPresent(lastAccessedTime, forKey: .lastAccessedTime)
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    public func dictionaryRepresentation() -> [String: AnyObject] {
        let result = (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self), options: .allowFragments)) as? [String: Any]
        return result?.compactMapValues({ $0 as AnyObject? }) ?? [:]
    }
    
}
