//
//  ContentView.swift
//  white reef
//
//  Created by 長政輝 on 2022/12/29.
//

import SwiftUI
import RealityKit
import ARKit

var arView = ARView(frame: .zero)

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

struct ContentView : View {
    @State private var model = ModelEntity(mesh: .generateBox(size: 1), materials: [SimpleMaterial()])
    @State private var sheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink {
                    PersistanceView()
                } label: {
                    Text("PersistanceView")
                }
                .padding(.bottom)
                
                NavigationLink {
                    GeospatialView()
                } label: {
                    Text("GeospatialView")
                }
                .padding(.bottom)
                
                Button("Sheet") {
                    setModel()
                    sheet.toggle()
                }
            }
            .navigationTitle("White Reef")
        }
        .sheet(isPresented: $sheet) {
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
        }
    }
    
    func setModel() {
        let (positions, normals) = generateRandomObject()
        var descr = MeshDescriptor()
        descr.positions = MeshBuffers.Positions(positions)
        descr.normals = MeshBuffers.Normals(normals)
        descr.primitives = .triangles([UInt32](0...UInt32(positions.count)))
        let material = randomMaterial()
        model = ModelEntity(mesh: try! .generate(from: [descr]), materials: [material])
    }
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
