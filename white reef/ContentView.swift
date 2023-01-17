//
//  ContentView.swift
//  white reef
//
//  Created by 長政輝 on 2022/12/29.
//

import SwiftUI
import RealityKit
import MapKit

var arView = ARView(frame: .zero)

struct ContentView : View {
    private let objectData = ObjectData.sample
    @State private var sheetIsPresented = false
    @State private var arIsPresented = false
    
    var body: some View {
        NavigationStack {
            MapContainer()
                .ignoresSafeArea()
                .navigationTitle("White Reef")
                .navigationDestination(isPresented: $arIsPresented) {
                    PersistanceView(objectData: objectData)
                }
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: {
                            sheetIsPresented.toggle()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.largeTitle)
                        }
                    }
                }
        }
        .sheet(isPresented: $sheetIsPresented) {
            ObjectSheet(arIsPresented: $arIsPresented, objectData: objectData)
        }
    }
}

struct MapContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> some MKMapView {
        return MKMapView()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
