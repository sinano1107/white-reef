//
//  LocalCoral.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/20.
//

import ARKit
import RealityKit

class LocalCoral: Coral {
    override class var supportsSecureCoding: Bool { true }
    static var armapKey = "armap"
    static var imageDataKey = "imageData"
    
    let armap: ARWorldMap
    let imageData: Data
    
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
        self.armap = armap
        self.imageData = imageData
        super.init(index: index, coordinator: coordinator)
    }
    
    required init?(coder: NSCoder) {
        guard
            let armap = coder.decodeObject(of: ARWorldMap.self, forKey: Self.armapKey),
            let imageData = coder.decodeObject(of: NSData.self, forKey: Self.imageDataKey) as? Data
        else { return nil }
        self.armap = armap
        self.imageData = imageData
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(armap, forKey: Self.armapKey)
        coder.encode(imageData, forKey: Self.imageDataKey)
    }
    
    static func unarchive(index: Int) -> LocalCoral {
        let key = "localCorals/\(index)"
        guard let data = UserDefaults().data(forKey: key) else { fatalError("データがない") }
        guard let coral = try! NSKeyedUnarchiver.unarchivedObject(ofClass: Self.self, from: data)
        else { fatalError("coralがnil") }
        return coral
    }
}
