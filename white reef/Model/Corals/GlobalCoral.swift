//
//  GlobalCoral.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/24.
//

import ARCore

class GlobalCoral: Coral {
    override class var supportsSecureCoding: Bool { true }
    static var objectDataKey = "objectData"
    static var altitudeKey = "altitude"
    static var xKey = "x"
    static var yKey = "y"
    static var zKey = "z"
    static var wKey = "w"
    
    let objectData: ObjectData
    let altitude: Double
    let x: Float
    let y: Float
    let z: Float
    let w: Float
    var eastUpSouthQTarget: simd_quatf {
        simd_quaternion(x, y, z, w)
    }
    
    convenience init(
        index: Int,
        transform: GARGeospatialTransform,
        objectData: ObjectData
    ) {
        self.init(
            index: index,
            coordinator: transform.coordinate,
            altitude: transform.altitude,
            eastUpSouthQTarget: transform.eastUpSouthQTarget.vector,
            objectData: objectData
        )
    }
    
    init(
        index: Int,
        coordinator: CLLocationCoordinate2D,
        altitude: Double,
        eastUpSouthQTarget: simd_float4,
        objectData: ObjectData
    ) {
        self.objectData = objectData
        print(altitude)
        self.altitude = altitude
        self.x = eastUpSouthQTarget.x
        self.y = eastUpSouthQTarget.y
        self.z = eastUpSouthQTarget.z
        self.w = eastUpSouthQTarget.w
        super.init(index: index, coordinator: coordinator)
    }
    
    required init?(coder: NSCoder) {
        guard let objectData = coder.decodeObject(of: ObjectData.self, forKey: Self.objectDataKey)
        else { return nil }
        self.objectData = objectData
        self.altitude = coder.decodeDouble(forKey: Self.altitudeKey)
        self.x = coder.decodeFloat(forKey: Self.xKey)
        self.y = coder.decodeFloat(forKey: Self.yKey)
        self.z = coder.decodeFloat(forKey: Self.zKey)
        self.w = coder.decodeFloat(forKey: Self.wKey)
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(objectData, forKey: Self.objectDataKey)
        coder.encode(altitude, forKey: Self.altitudeKey)
        coder.encode(x, forKey: Self.xKey)
        coder.encode(y, forKey: Self.yKey)
        coder.encode(z, forKey: Self.zKey)
        coder.encode(w, forKey: Self.wKey)
    }
    
    static func unarchive(index: Int) -> GlobalCoral {
        let key = "globalCorals/\(index)"
        guard let data = UserDefaults().data(forKey: key) else { fatalError("データがない") }
        guard let coral = try! NSKeyedUnarchiver.unarchivedObject(ofClass: Self.self, from: data)
        else { fatalError("coralがnil") }
        return coral
    }
}
