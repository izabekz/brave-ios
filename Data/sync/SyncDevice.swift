/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

class SyncDevice: SyncRecord {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private enum SerializationKeys: String, CodingKey {
        case name
    }
    
    // MARK: Properties
    var name: String?
    
    required init() {
        super.init()
    }
    
    required init(record: Syncable?, deviceId: [Int]?, action: Int?) {
        super.init(record: record, deviceId: deviceId, action: action)
        
        let device = record as? Device
        self.name = device?.name
        
        // Preference
        self.objectData = nil
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SyncObjectDataType.self)
        let innerContainer = try container.nestedContainer(keyedBy: SerializationKeys.self, forKey: .Device)
        name = try innerContainer.decodeIfPresent(String.self, forKey: .name)
        try super.init(from: container.superDecoder())
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SerializationKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try super.encode(to: container.superEncoder())
        self.objectData = nil
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    override func dictionaryRepresentation() -> [String: Any] {
        
        // Notice there is no objectData type, this is technically part of Preferences, which does not use that key/value pair
        
        // Device specific
        var deviceDict = [String: Any]()
        if let value = self.name { deviceDict[SerializationKeys.name.rawValue] = value }

        var dictionary = super.dictionaryRepresentation()
        dictionary[SyncObjectDataType.Device.rawValue] = deviceDict
        return dictionary
    }

}
