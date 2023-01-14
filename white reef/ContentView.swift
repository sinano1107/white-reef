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
                OrbitView($model, radius: 2)
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
        let material = SimpleMaterial(color: .cyan, isMetallic: true)
        model = ModelEntity(mesh: try! .generate(from: [descr]), materials: [material])
    }
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
