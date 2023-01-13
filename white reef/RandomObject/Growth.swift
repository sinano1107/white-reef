//
//  Growth.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/12.
//

import simd

/// メッシュを成長させる
func growth(positions inputPositions: [simd_float3], normals inputNormals: [simd_float3]) -> (positions: [simd_float3], normals: [simd_float3]) {
    struct GrowthData {
        /** 成長点（座標） */
        let growthPoint: simd_float3
        /** 成長させるメッシュの座標のリスト */
        let meshPositions: [simd_float3]
        /** 成長させるメッシュの法線 */
        let meshNormal: simd_float3
        /** 成長させるメッシュ以外のメッシュの座標のリスト */
        let positions: [simd_float3]
        /** 成長させつメッシュ以外のメッシュの法線のリスト */
        let normals: [simd_float3]
        
        init(positions inputPositions: [simd_float3], normals inputNormals: [simd_float3]) throws {
            // 成長させるメッシュ
            let startIndex = Int.random(in: 0 ..< inputPositions.count / 3) * 3
            let endIndex = startIndex + 2
            meshPositions = inputPositions[startIndex ... endIndex].map { $0 }
            meshNormal = inputNormals[startIndex]
            // 成長させるメッシュ以外のメッシュ
            var positions = inputPositions
            var normals = inputNormals
            positions.removeSubrange(startIndex ... endIndex)
            normals.removeSubrange(startIndex ... endIndex)
            self.positions = positions
            self.normals = normals
            // 外心の算出
            guard let circumcenter = calcCircumcenter(meshPositions) else { throw GrowthError.failureGetCircumcenter }
            /** 半径 */
            let radius = distance(circumcenter, meshPositions[0])
            // 成長点ベクトルの取得
            let vector = randomInHemisphere(radius: radius)
            // 成長点ベクトルの法線方向への回転
            let quaternion = simd_quatf(from: [0, 1, 0], to: normalize(meshNormal))
            let turnedVector = quaternion.act(vector)
            // 外心から成長点ベクトル方向の点を成長点とする
            growthPoint = circumcenter + turnedVector
        }
        
        /**　成長点を採用した場合、既存のポリゴンと干渉（衝突）するか確認する */
        func checkCollision() -> Bool {
            for point_index in 0...2 {
                /** 成長面を構成する一点（ループによってすべてチェックする）*/
                let point = meshPositions[point_index]
                let linePoints = [growthPoint, point]
                for polygon_index in 0 ..< positions.count / 3 {
                    // 既存のポリゴン（ループによってすべてチェックする）
                    let startIndex = polygon_index * 3
                    let endIndex = startIndex + 2
                    let polygonPoints = positions[startIndex ... endIndex].map { $0 }
                    let normal = normals[startIndex] // 三点の法線はすべて同じ値なので適当に最初のを取り出す
                    if doesItCollision(polygonPoints: polygonPoints, normal: normal, linePoints: linePoints) {
                        return true
                    }
                }
            }
            return false
        }
        
        /** MeshDescriptorに代入できるデータを生成する */
        func build() -> (positions: [simd_float3], normals: [simd_float3]) {
            var positions = self.positions
            var normals = self.normals
            for i in 0...2 {
                let a = meshPositions[i]
                let b = meshPositions[(i + 1) % 3]
                let normal = normalize(cross(a - growthPoint, b - a))
                positions += [growthPoint, a, b]
                normals += [simd_float3](repeating: normal, count: 3)
            }
            return (positions, normals)
        }
    }
    
    enum GrowthError: Error {
        case failureGetCircumcenter
    }
    
    do {
        var data = try GrowthData(positions: inputPositions, normals: inputNormals)
        // 衝突しなくなるまで試行する
        while data.checkCollision() {
            data = try GrowthData(positions: inputPositions, normals: inputNormals)
        }
        // ビルドして返す
        return data.build()
    } catch GrowthError.failureGetCircumcenter {
        fatalError("外心の算出に失敗しました")
    } catch {
        fatalError("成長に失敗しました: \(error)")
    }
}
