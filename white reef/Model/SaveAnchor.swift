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
    static private let scaleKey = "scale"
    
    let objectData: ObjectData
    let scale: simd_float3
    
    init(objectData: ObjectData, scale: simd_float3, transform: float4x4) {
        self.objectData = objectData
        self.scale = scale
        super.init(name: "SaveAnchor", transform: transform)
    }
    
    required init(anchor: ARAnchor) {
        let anchor = anchor as! Self
        self.objectData = anchor.objectData
        self.scale = anchor.scale
        super.init(anchor: anchor)
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder: NSCoder) {
        guard
            let objectData = coder.decodeObject(of: ObjectData.self, forKey: Self.objectDataKey),
            let scaleData = coder.decodeObject(of: NSData.self, forKey: Self.scaleKey) as Data?
        else { return nil }
        
        do {
            scale = try JSONDecoder().decode(simd_float3.self, from: scaleData)
        } catch {
            fatalError("[エラー] SaveAnchorのdecodeに失敗しました: \(error)")
        }
        
        self.objectData = objectData
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        
        do {
            let scaleData = try JSONEncoder().encode(scale)
            coder.encode(scaleData, forKey: Self.scaleKey)
        } catch {
            fatalError("[エラー] SaveAnchorのencodeに失敗しました: \(error)")
        }
        
        coder.encode(objectData, forKey: Self.objectDataKey)
    }
    
    func generateAnchorEntity() -> AnchorEntity {
        #if targetEnvironment(simulator)
        return AnchorEntity()
        #else
        let anchorEntity = AnchorEntity(anchor: self)
        let object = objectData.generate(moveTheOriginDown: true)
        object.scale = scale
        anchorEntity.addChild(object)
        return anchorEntity
        #endif
    }
    
    static let sample = SaveAnchor(objectData: ObjectData.sample, scale: simd_float3(), transform: float4x4())
}
