//
//  RandomObject.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/12.
//

import simd

func generateRandomObjectAnchor(transform: float4x4) -> EntitySaveAnchor {
    let tetrahedron = generateTetrahedron()
    let result = growth(positions: tetrahedron.positions, normals: tetrahedron.normals)
    return EntitySaveAnchor(positions: result.positions, normals: result.normals, transform: transform)
}
