//
//  LocalCoral.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/20.
//

import CoreLocation
import ARKit
import RealityKit

class LocalCoral: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    static var indexKey = "index"
    static var latitudeKey = "latitude"
    static var longitudeKey = "longitude"
    static var armapKey = "armap"
    static var imageDataKey = "imageData"
    
    let index: Int
    let latitude: Double
    let longitude: Double
    let armap: ARWorldMap
    let imageData: Data
    var coordinator: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    convenience init?(capturing view: ARView,
                      index: Int,
                      coordinator: CLLocationCoordinate2D,
                      armap: ARWorldMap) {
        guard let frame = view.session.currentFrame
            else { return nil }
        
        let image = CIImage(cvPixelBuffer: frame.capturedImage)
        let orientation = CGImagePropertyOrientation(cameraOrientation: UIDevice.current.orientation)
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let data = context.jpegRepresentation(
            of: image.oriented(orientation),
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7])
        else { return nil }
        
        self.init(index: index, coordinator: coordinator, armap: armap, imageData: data)
    }
    
    init(index: Int, coordinator: CLLocationCoordinate2D, armap: ARWorldMap, imageData: Data) {
        self.index = index
        self.latitude = coordinator.latitude
        self.longitude = coordinator.longitude
        self.armap = armap
        self.imageData = imageData
    }
    
    required init?(coder: NSCoder) {
        guard
            let armap = coder.decodeObject(of: ARWorldMap.self, forKey: Self.armapKey),
            let imageData = coder.decodeObject(of: NSData.self, forKey: Self.imageDataKey) as? Data
        else { return nil }
        self.index = coder.decodeInteger(forKey: Self.indexKey)
        self.latitude = coder.decodeDouble(forKey: Self.latitudeKey)
        self.longitude = coder.decodeDouble(forKey: Self.longitudeKey)
        self.armap = armap
        self.imageData = imageData
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(index, forKey: Self.indexKey)
        coder.encode(latitude, forKey: Self.latitudeKey)
        coder.encode(longitude, forKey: Self.longitudeKey)
        coder.encode(armap, forKey: Self.armapKey)
        coder.encode(imageData, forKey: Self.imageDataKey)
    }
}
