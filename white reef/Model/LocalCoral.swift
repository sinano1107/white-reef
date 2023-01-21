//
//  LocalCoral.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/20.
//

import CoreLocation
import ARKit

class LocalCoral: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    static var indexKey = "index"
    static var latitudeKey = "latitude"
    static var longitudeKey = "longitude"
    static var armapKey = "armap"
    
    let index: Int
    let latitude: Double
    let longitude: Double
    let armap: ARWorldMap
    var coordinator: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(index: Int, coordinator: CLLocationCoordinate2D, armap: ARWorldMap) {
        self.index = index
        self.latitude = coordinator.latitude
        self.longitude = coordinator.longitude
        self.armap = armap
    }
    
    required init?(coder: NSCoder) {
        guard let armap = coder.decodeObject(of: ARWorldMap.self, forKey: Self.armapKey) else { return nil }
        self.index = coder.decodeInteger(forKey: Self.indexKey)
        self.latitude = coder.decodeDouble(forKey: Self.latitudeKey)
        self.longitude = coder.decodeDouble(forKey: Self.longitudeKey)
        self.armap = armap
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(index, forKey: Self.indexKey)
        coder.encode(latitude, forKey: Self.latitudeKey)
        coder.encode(longitude, forKey: Self.longitudeKey)
        coder.encode(armap, forKey: Self.armapKey)
    }
}
