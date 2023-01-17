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
    @State var region = MKCoordinateRegion()
    @State private var sheetIsPresented = false
    @State private var arIsPresented = false
    
    var body: some View {
        NavigationStack {
            Map(coordinateRegion: $region,
                interactionModes: .zoom,
                showsUserLocation: true,
                userTrackingMode: .constant(.follow))
            .task {
                let manager = CLLocationManager()
                manager.requestWhenInUseAuthorization()
            }
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

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
