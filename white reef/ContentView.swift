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
            }
            .navigationTitle("White Reef")
        }
    }
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
