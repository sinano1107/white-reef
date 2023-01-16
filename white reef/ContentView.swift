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
    @State private var sheetIsPresented = false
    @State private var arIsPresented = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("PersistanceView") {
                    arIsPresented.toggle()
                }
                .padding(.bottom)
                
                NavigationLink {
                    GeospatialView()
                } label: {
                    Text("GeospatialView")
                }
                .padding(.bottom)
                
                Button("Sheet") {
                    sheetIsPresented.toggle()
                }
                .padding(.bottom)
                
                Button("print") {
                    print(objectData.positions)
                    print(objectData.normals)
                }
            }
            .navigationTitle("White Reef")
            .navigationDestination(isPresented: $arIsPresented) {
                PersistanceView(objectData: objectData)
            }
        }
        .sheet(isPresented: $sheetIsPresented) {
            ObjectSheet(arIsPresented: $arIsPresented, objectData: objectData)
        }
    }
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
