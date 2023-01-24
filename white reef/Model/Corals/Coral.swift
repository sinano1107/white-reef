//
//  Coral.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/24.
//

import CoreLocation

class Coral: NSObject, NSSecureCoding {
    class var supportsSecureCoding: Bool { true }
    static var indexKey = "index"
    static var latitudeKey = "latitude"
    static var longitudeKey = "longitude"
    
    let index: Int
    let latitude: Double
    let longitude: Double
    var coordinator: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(index: Int, coordinator: CLLocationCoordinate2D) {
        self.index = index
        self.latitude = coordinator.latitude
        self.longitude = coordinator.longitude
    }
    
    required init?(coder: NSCoder) {
        index = coder.decodeInteger(forKey: Self.indexKey)
        latitude = coder.decodeDouble(forKey: Self.latitudeKey)
        longitude = coder.decodeDouble(forKey: Self.longitudeKey)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(index, forKey: Self.indexKey)
        coder.encode(latitude, forKey: Self.latitudeKey)
        coder.encode(longitude, forKey: Self.longitudeKey)
    }
}
