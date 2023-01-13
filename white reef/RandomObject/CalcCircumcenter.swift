//
//  CalcCircumcenter.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/12.
//

import simd

/// 外心を算出する
func calcCircumcenter(_ positions: [simd_float3]) -> simd_float3? {
    precondition(positions.count == 3, "値が３つの配列を渡してください")
    
    let dimension = (m: 3, n: 3)
    let p1 = positions[0]
    let p2 = positions[1]
    let p3 = positions[2]
    
    // 平面の連立方程式
    let planeA: [Float] = [
        p1.x, p2.x, p3.x,
        p1.y, p2.y, p3.y,
        p1.z, p2.z, p3.z
    ]
    let planeB: [Float] = [1, 1, 1]
    guard let planeX = leastSquares_nonsquare(a: planeA, dimension: dimension, b: planeB) else {
        print("平面の連立方程式の解決に失敗しました")
        return nil
    }
    
    // 外心点の連立方程式
    let vector_p1_p2 = p2 - p1
    let vector_p1_p3 = p3 - p1
    let center_p1_p2 = (p1 + p2) / 2
    let center_p1_p3 = (p1 + p3) / 2
    
    let centerA: [Float] = [
        planeX[0], vector_p1_p2[0], vector_p1_p3[0],
        planeX[1], vector_p1_p2[1], vector_p1_p3[1],
        planeX[2], vector_p1_p2[2], vector_p1_p3[2]
    ]
    let centerB: [Float] = [
        1,
        (vector_p1_p2 * center_p1_p2).sum(),
        (vector_p1_p3 * center_p1_p3).sum()
    ]
    guard let centerX = leastSquares_nonsquare(a: centerA, dimension: dimension, b: centerB) else {
        print("外心点の連立方程式の解決に失敗しました")
        return nil
    }
    
    return SIMD3(x: centerX[0], y: centerX[1], z: centerX[2])
}

