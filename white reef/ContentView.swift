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
                    sheet.toggle()
                }
            }
            .navigationTitle("White Reef")
        }
        .sheet(isPresented: $sheet) {
            OrbitView($model)
                .edgesIgnoringSafeArea(.all)
                .presentationDetents([.medium, .large])
        }
    }
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
