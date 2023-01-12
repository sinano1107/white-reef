//
//  EntityAnchor.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/12.
//

import ARKit
import RealityKit

class EntitySaveAnchor: ARAnchor {
    static let positionsKey = "positions"
    static let normalsKey = "normals"
    
    let positions: Data
    let normals: Data

    convenience init(positions: [simd_float3], normals: [simd_float3], transform: float4x4) {
        do {
            let positions = try JSONEncoder().encode(positions)
            let normals = try JSONEncoder().encode(normals)
            self.init(positions: positions, normals: normals, transform: transform)
        } catch {
            fatalError("[エラー] MeshResourceAnchorの初期化に失敗: \(error)")
        }
    }

    init(positions: Data, normals: Data, transform: float4x4) {
        self.positions = positions
        self.normals = normals
        super.init(name: "EntitySaveAnchor", transform: transform)
    }

    required init(anchor: ARAnchor) {
        let anchor = anchor as! Self
        self.positions = anchor.positions
        self.normals = anchor.normals
        super.init(anchor: anchor)
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }

    required init?(coder: NSCoder) {
        guard
            let positions = coder.decodeObject(of: NSData.self, forKey: Self.positionsKey) as? Data,
            let normals = coder.decodeObject(of: NSData.self, forKey: Self.normalsKey) as? Data
        else { return nil }
        self.positions = positions
        self.normals = normals

        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(positions, forKey: Self.positionsKey)
        coder.encode(normals, forKey: Self.normalsKey)
    }
    
    /// 格納されているpositions, normalsのデータからMeshResourceを返す
    func generateMeshResource() -> MeshResource? {
        do {
            let positions = try JSONDecoder().decode([simd_float3].self, from: positions)
            let normals = try JSONDecoder().decode([simd_float3].self, from: normals)
            // descr
            var descr = MeshDescriptor()
            descr.positions = MeshBuffers.Positions(positions)
            descr.normals = MeshBuffers.Normals(normals)
            descr.primitives = .triangles([UInt32](0...UInt32(positions.count)))
            // generate
            return try MeshResource.generate(from: [descr])
        } catch {
            print("[エラー] generateMeshResourceに失敗しました: \(error)")
            return nil
        }
    }
}
