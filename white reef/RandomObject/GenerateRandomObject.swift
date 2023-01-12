//
//  RandomObject.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/12.
//

import simd

func generateRandomObjectAnchor(transform: float4x4) -> EntitySaveAnchor {
    let tetrahedron = generateTetrahedron()
    var positions = tetrahedron.positions
    var normals = tetrahedron.normals
    
    for _ in 0 ..< 10 {
        (positions, normals) = growth(positions: positions, normals: normals)
    }
    
    return EntitySaveAnchor(positions: positions, normals: normals, transform: transform)
}
