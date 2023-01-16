//
//  ObjectData.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/15.
//

import UIKit
import RealityKit

class ObjectData: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    static private let positionsKey = "positions"
    static private let normalsKey = "normals"
    static private let materialKey = "material"
    
    private(set) var positions: [simd_float3]
    private(set) var normals: [simd_float3]
    private(set) var material: MaterialData
    
    struct MaterialData: Codable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let roughness: Float
        let isMetallic: Bool
        
        init() {
            let colors = Array(repeating: 0, count: 3).map { _ in CGFloat.random(in: 0...1) }
            let roughness = Float.random(in: 0...1)
            let isMetallic = Bool.random()
            
            red = colors[0]
            green = colors[1]
            blue = colors[2]
            self.roughness = roughness
            self.isMetallic = isMetallic
        }
        
        func generate() -> SimpleMaterial {
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1)
            let material = SimpleMaterial(
                color: color,
                roughness: MaterialScalarParameter(floatLiteral: roughness),
                isMetallic: false
            )
            return material
        }
    }
    
    init(positions: [simd_float3], normals: [simd_float3], material: MaterialData? = nil) {
        self.positions = positions
        self.normals = normals
        self.material = material ?? MaterialData()
    }
    
    required convenience init?(coder: NSCoder) {
        guard
            let positionsData = coder.decodeObject(of: NSData.self, forKey: Self.positionsKey) as? Data,
            let normalsData = coder.decodeObject(of: NSData.self, forKey: Self.normalsKey) as? Data,
            let materialData = coder.decodeObject(of: NSData.self, forKey: Self.materialKey) as? Data
        else { return nil }
        
        do {
            let positions = try JSONDecoder().decode([simd_float3].self, from: positionsData)
            let normals = try JSONDecoder().decode([simd_float3].self, from: normalsData)
            let material = try JSONDecoder().decode(MaterialData.self, from: materialData)
            self.init(positions: positions, normals: normals, material: material)
        } catch {
            fatalError("[エラー] ObjectDataのcoderのデコードに失敗しました: \(error)")
        }
    }
    
    func encode(with coder: NSCoder) {
        do {
            let positions = try JSONEncoder().encode(positions)
            let normals = try JSONEncoder().encode(normals)
            let material = try JSONEncoder().encode(material)
            coder.encode(positions, forKey: Self.positionsKey)
            coder.encode(normals, forKey: Self.normalsKey)
            coder.encode(material, forKey: Self.materialKey)
        } catch {
            fatalError("[エラー] ObjectDataのエンコードに失敗しました: \(error)")
        }
    }
    
    func update(positions: [simd_float3], normals: [simd_float3]) {
        self.positions = positions
        self.normals = normals
        self.material = MaterialData()
    }
    
    func generate(moveTheOriginDown: Bool = false) -> ModelEntity {
        var positions = positions
        
        // 原点を下にする
        if moveTheOriginDown {
            let yMin = positions.min { a, b in a.y < b.y }!.y
            for index in 0..<positions.count { positions[index].y -= yMin }
        }
        
        var descr = MeshDescriptor()
        descr.positions = MeshBuffers.Positions(positions)
        descr.normals = MeshBuffers.Normals(normals)
        descr.primitives =  .triangles([UInt32](0...UInt32(positions.count)))
        let material = material.generate()
        let model = ModelEntity(mesh: try! .generate(from: [descr]), materials: [material])
        return model
    }
    
    static var sample: ObjectData {
        ObjectData(
            positions: [[0, 0.5, 0], [-0.5, -0.5, 0], [0.5, -0.5, 0]],
            normals: [[0, 0, -1], [0, 0, -1], [0, 0, -1]]
        )
    }
}
