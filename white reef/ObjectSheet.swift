//
//  ObjectSheet.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/14.
//

import SwiftUI
import RealityKit

struct ObjectSheet: View {
    @Binding var model: ModelEntity
    
    var body: some View {
        VStack(alignment: .trailing) {
            Button(action: {
                setModel()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title)
            }
            .padding([.top, .trailing])
            OrbitView($model, radius: 1.5)
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            setModel()
        }
    }
    
    /// modelを設定
    func setModel() {
        let (positions, normals) = generateRandomObject()
        var descr = MeshDescriptor()
        descr.positions = MeshBuffers.Positions(positions)
        descr.normals = MeshBuffers.Normals(normals)
        descr.primitives =  .triangles([UInt32](0...UInt32(positions.count)))
        let material = randomMaterial()
        model = ModelEntity(mesh: try! .generate(from: [descr]), materials: [material])
    }
}

/// ランダムな設定のSimpleMaterialを返す
func randomMaterial() -> SimpleMaterial {
    let randomNumbers = Array(repeating: 0, count: 4)
        .map { _ in CGFloat.random(in: 0...1) }
    let color = UIColor(
        red: randomNumbers[0],
        green: randomNumbers[1],
        blue: randomNumbers[2],
        alpha: 1
    )
    let material = SimpleMaterial(
        color: color,
        roughness: MaterialScalarParameter(
            floatLiteral: Float(randomNumbers[3])),
        isMetallic: true
    )
    return material
}

struct ObjectSheet_Previews: PreviewProvider {
    @State static var model = ModelEntity(mesh: .generateBox(size: 1))
    
    static var previews: some View {
        VStack {}
            .sheet(isPresented: .constant(true)) {
                ObjectSheet(model: $model)
            }
    }
}
