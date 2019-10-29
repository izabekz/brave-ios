/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

/*
 * Due to sync's 'callbacks' running through the same function, parameters are reused
 * for ever single function call, resulting in a complex web of peculiar naming.
 *
 * Direct key mappings are using to pluck the variable names from the data, and an attempt
 * to make them more native feeling (e.g. descriptive names) has been made. In some cases
 * variable names are still generic due to the extreme usage of them (i.e. no nice way to make non-generic)
 *
 * At some point a switch to fullblown generic names may need necessary, but this hybrid approach seemed best
 * at the time of building it
 */

typealias SyncDefaultResponseType = SyncRecord
final class SyncResponse {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private enum SerializationKeys: String, CodingKey {
        case arg2
        case message
        case arg1
        case arg3
        case arg4 // isTruncated
    }
    
    // MARK: Properties
    // TODO: rename this property
    var rootElements: [[String: Any]]? // arg2
    var message: String?
    var arg1: String?
    var lastFetchedTimestamp: Int? // arg3
    var isTruncated: Bool? // arg4
    
    /// Initiates the instance based on the object.
    ///
    /// - parameter object: The object of either Dictionary or Array kind that was passed.
    /// - returns: An initialized instance of the class.
    convenience init(object: String) {
        if let data = object.data(using: .utf8) {
            self.init(json: (try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)) as? [String: Any])
        } else {
            self.init(json: [:])
        }
    }
    
    required init(json: [String: Any]?) {
        rootElements = json?[SerializationKeys.arg2.rawValue] as? [[String: Any]]
        message = json?[SerializationKeys.message.rawValue] as? String
        arg1 = json?[SerializationKeys.arg1.rawValue] as? String
        lastFetchedTimestamp = json?[SerializationKeys.arg3.rawValue] as? Int
        isTruncated = json?[SerializationKeys.arg4.rawValue] as? Bool
    }
    
    /// Commented out for now because this might change in the near future
    /*required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SerializationKeys.self)
     
        //rootElements is actually an array of `SyncRecord`
        rootElements = try container.decodeIfPresent([SyncRecord].self, forKey: .arg2)
        message = try container.decode(String.self, forKey: .message)
        arg1 = try container.decodeIfPresent(String.self, forKey: .arg1)
        lastFetchedTimestamp = try container.decodeIfPresent(Int.self, forKey: .arg3)
        isTruncated = try container.decodeIfPresent(Bool.self, forKey: .arg4)
    }*/
}
