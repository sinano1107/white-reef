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
    @State private var newCoral: LocalCoral?
    @State private var sheetIsPresented = false
    @State private var arIsPresented = false
    
    var body: some View {
        NavigationStack {
            NavigationLink {
                ARLocalView()
            } label: {
                Text("ARLocalView")
            }
            MapContainer(newCoral: $newCoral)
                .ignoresSafeArea()
                .navigationTitle("White Reef")
                .navigationDestination(isPresented: $arIsPresented) {
                    ARPlaceView(objectData: objectData) { newCoral in
                        self.newCoral = newCoral
                    }
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
    @Binding var newCoral: LocalCoral?
    let defaults = UserDefaults()
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
                    latitudeDelta: 0.0001,
                    longitudeDelta: 0.0001)),
            animated: true)
        
        /// ローカルコーラルの個数
        let localCoralCount = defaults.integer(forKey: "localCoralCount")
        
        // ローカルコーラルの復元
        for index in 0 ..< localCoralCount {
            let key = "localCorals/\(index)"
            guard let data = defaults.data(forKey: key) else { fatalError("データがない") }
            print(data)
            do {
                guard let coral = try NSKeyedUnarchiver.unarchivedObject(ofClass: LocalCoral.self, from: data) else { fatalError("coralがnil") }
                /// アノテーション
                let annotation = MKPointAnnotation()
                annotation.coordinate = coral.coordinator
                view.addAnnotation(annotation)
                print("復元しました: \(coral.latitude), \(coral.longitude)")
            } catch {
                print("localCoralの復元エラー: key=\(key), error=\(error)")
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let coral = newCoral else { return }
        let annotation = MKPointAnnotation()
        annotation.coordinate = coral.coordinator
        view.addAnnotation(annotation)
        print("追加しました: \(coral.latitude), \(coral.longitude)")
    }
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
