//
//  SaveAnchor.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/16.
//

import ARKit
import RealityKit

class SaveAnchor: ARAnchor {
    static private let objectDataKey = "objectData"
    
    let objectData: ObjectData
    
    init(objectData: ObjectData, transform: float4x4) {
        self.objectData = objectData
        super.init(name: "SaveAnchor", transform: transform)
    }
    
    required init(anchor: ARAnchor) {
        let anchor = anchor as! Self
        self.objectData = anchor.objectData
        super.init(anchor: anchor)
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder: NSCoder) {
        guard let objectData = coder.decodeObject(of: ObjectData.self, forKey: Self.objectDataKey)
        else { return nil }
        
        self.objectData = objectData
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(objectData, forKey: Self.objectDataKey)
    }
    
    func generateAnchorEntity() -> AnchorEntity {
        let anchorEntity = AnchorEntity(anchor: self)
        let object = objectData.generate(moveTheOriginDown: true)
        anchorEntity.addChild(object)
        return anchorEntity
    }
    
    static let sample = SaveAnchor(objectData: ObjectData(positions: [], normals: []), transform: float4x4())
}
