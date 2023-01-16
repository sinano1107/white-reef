//
//  ObjectData.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/15.
//

import UIKit
import RealityKit

class ObjectData {
    private(set) var positions: [simd_float3]
    private(set) var normals: [simd_float3]
    private(set) var material: MaterialData
    
    struct MaterialData {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let roughness: MaterialScalarParameter
        let isMetallic: Bool
        
        init() {
            let colors = Array(repeating: 0, count: 3).map { _ in CGFloat.random(in: 0...1) }
            let roughness = MaterialScalarParameter(floatLiteral: Float.random(in: 0...1))
            let isMetallic = Bool.random()
            
            red = colors[0]
            green = colors[1]
            blue = colors[2]
            self.roughness = roughness
            self.isMetallic = isMetallic
        }
        
        func generate() -> SimpleMaterial {
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1)
            let material = SimpleMaterial(color: color, roughness: roughness, isMetallic: false)
            return material
        }
    }
    
    init(positions: [simd_float3], normals: [simd_float3]) {
        self.positions = positions
        self.normals = normals
        self.material = MaterialData()
    }
    
    func update(positions: [simd_float3], normals: [simd_float3]) {
        self.positions = positions
        self.normals = normals
        self.material = MaterialData()
    }
    
    func generate() -> ModelEntity {
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
