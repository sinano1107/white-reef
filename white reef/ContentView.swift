//
//  ContentView.swift
//  white reef
//
//  Created by 長政輝 on 2022/12/29.
//

import SwiftUI
import RealityKit
import MapKit

//var arView = ARView(frame: .zero)

struct ContentView : View {
    private let objectData = ObjectData.sample
    @State private var sheetIsPresented = false
    @State private var arIsPresented = false
    
    var body: some View {
        NavigationStack {
            NavigationLink {
                ARLocalView()
            } label: {
                Text("ARLocalView")
            }
            MapContainer()
                .ignoresSafeArea()
                .navigationTitle("White Reef")
                .navigationDestination(isPresented: $arIsPresented) {
                    ARPlaceView(objectData: objectData)
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
    let manager = CLLocationManager()
    let view = MKMapView()
    
    func makeUIView(context: Context) -> some MKMapView {
        // ユーザーの現在位置を表示
        view.showsUserLocation = true
        
        // 現在位置を取得できればそこを中心に据える
        // 取得できなければ新宿御苑を表示する
        let location = manager.location
        let center = location != nil
        ? location!.coordinate
        : CLLocationCoordinate2D(
            latitude: 35.68478,
            longitude:  139.71)
        view.setRegion(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.0025,
                    longitudeDelta: 0.0025)),
            animated: true)
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
