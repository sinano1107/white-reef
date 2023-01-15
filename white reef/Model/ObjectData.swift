//
//  ObjectData.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/15.
//

import RealityKit

class ObjectData {
    private(set) var positions: [simd_float3]
    private(set) var normals: [simd_float3]
    
    init(positions: [simd_float3], normals: [simd_float3]) {
        self.positions = positions
        self.normals = normals
    }
    
    func update(positions: [simd_float3], normals: [simd_float3]) {
        self.positions = positions
        self.normals = normals
    }
    
    func generate() -> ModelEntity {
        var descr = MeshDescriptor()
        descr.positions = MeshBuffers.Positions(positions)
        descr.normals = MeshBuffers.Normals(normals)
        descr.primitives =  .triangles([UInt32](0...UInt32(positions.count)))
        let material = randomMaterial()
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
