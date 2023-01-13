//
//  RandomPointInHemiSphere.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/12.
//

import simd

/** 上に凸な半球内のランダムなポジションを返す */
func randomInHemisphere(radius: Float = 1) -> simd_float3 {
    let cosTheta = Float.random(in: -1...1)
    let sinTheta = sqrt(1 - cosTheta * cosTheta)
    // 0...1にすると全球となる
    let phi = 2 * Float.pi * Float.random(in: 0...0.5)
    let r = pow(Float.random(in: 0...1), 1 / 3) * radius
    
    return simd_float3(
        x: r * sinTheta * cos(phi),
        y: r * sinTheta * sin(phi),
        z: r * cosTheta)
}
