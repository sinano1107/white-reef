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
    private let objectData = ObjectData.sample
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
                .padding(.bottom)
                
                Button("print") {
                    print(objectData.positions)
                    print(objectData.normals)
                }
            }
            .navigationTitle("White Reef")
        }
        .sheet(isPresented: $sheet) {
            ObjectSheet(objectData: objectData)
        }
    }
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
