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
    
    //　正規化
    positions = normalizePositions(positions: positions)

    return EntitySaveAnchor(positions: positions, normals: normals, transform: transform)
}

/// 正規化を行う
func normalizePositions(positions: [simd_float3]) -> [simd_float3] {
    // 各軸の最小値と最大値を取得
    var minX = positions[0].x
    var maxX = positions[0].x
    var minY = positions[0].y
    var maxY = positions[0].y
    var minZ = positions[0].z
    var maxZ = positions[0].z
    positions[1...].forEach { position in
        if position.x < minX { minX = position.x }
        else if maxX < position.x { maxX = position.x }
        
        if position.y < minY { minY = position.y }
        else if maxY < position.y { maxY = position.y }
        
        if position.z < minZ { minZ = position.z }
        else if maxZ < position.z { maxZ = position.z }
    }
    // 各軸の幅を取得
    let rangeX = maxX - minX
    let rangeY = maxY - minY
    let rangeZ = maxZ - minZ
    /// 最も大きな幅
    let maxRange = max(rangeX, rangeY, rangeZ)
    print(rangeX, rangeY, rangeZ, maxRange)
    // X軸,Y軸の中心の座標
    let centerX = minX + rangeX / 2
    let centerZ = minZ + rangeZ / 2
    // 正規化
    return positions.map { position in
        var position = position
        // 一番低い頂点の座標が0になるように調整
        position.y -= minY
        // オブジェクトを上から見た時の中心が原点になるように調整
        position.x -= centerX
        position.z -= centerZ
        // 最も大きな幅が1であるように調整
        position /= maxRange
        return position
    }
}
