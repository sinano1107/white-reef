//
//  CollisionDetection.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/13.
//

import simd

/// 複数のポリゴンと線分の衝突判定を行う
func doesItCollision(polygonPoints: [simd_float3], normal: simd_float3, linePoints: [simd_float3]) -> Bool {
    precondition(polygonPoints.count == 3, "polygonPointsには３つの値を代入してください")
    precondition(linePoints.count == 2, "linePointsには２つの値を代入してください")
    // 平行だったら衝突しない
    if dot(normal, linePoints[1] - linePoints[0]) == 0 { return false }
    
    // 2点が平面の同一方向にあるので衝突しない
    let vector_point0 = linePoints[0] - polygonPoints[0]
    let vector_point1 = linePoints[1] - polygonPoints[0]
    let theta_point0 = dot(normal, vector_point0)
    let theta_point1 = dot(normal, vector_point1)
    if theta_point0 * theta_point1 >= 0 { return false }
    
    // 衝突点を算出
    let normal_length = length(normal)
    // 平面との各点の距離
    let d_point0 = abs(theta_point0) / normal_length
    let d_point1 = abs(theta_point1) / normal_length
    /** 内分比 */
    let a = d_point0 / (d_point0 + d_point1)
    /** 衝突点に対するベクトル */
    let vector = (1 - a) * vector_point0 + a * vector_point1
    /** 衝突点 */
    let collisionPoint = polygonPoints[0] + vector
    
    // 衝突点がポリゴン内に含まれるか確認
    let dot_results = [Int](0...2).map {
        let start = polygonPoints[$0]
        let end = polygonPoints[($0 + 1) % 3]
        let cross = normalize(cross(end - start, collisionPoint - end))
        return dot(normal, cross)
    }
    // 全てが正の値(鋭角)ならば衝突点はポリゴン内に含まれる
    return dot_results.allSatisfy { $0 > 0 }
}
