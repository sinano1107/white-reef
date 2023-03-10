//
//  ContentView.swift
//  white reef
//
//  Created by 長政輝 on 2022/12/29.
//

import SwiftUI
import RealityKit
import MapKit

struct ContentView : View {
    private let objectData = ObjectData.sample
    @State private var newCoral: Coral?
    @State private var selectLocalCoral: LocalCoral?
    @State private var selectGlobalCoral: GlobalCoral?
    @State private var sheetIsPresented = false
    @State private var arIsPresented = false
    @State private var localIsPresented = false
    @State private var globalIsPresented = false
    
    var body: some View {
        NavigationStack {
            MapContainer(newCoral: $newCoral) { index, type in
                if type == .local {
                    localIsPresented = true
                    selectLocalCoral = LocalCoral.unarchive(index: index)
                } else {
                    globalIsPresented = true
                    selectGlobalCoral = GlobalCoral.unarchive(index: index)
                }
            }
            .ignoresSafeArea()
            .navigationTitle("White Reef")
            .navigationDestination(isPresented: $arIsPresented) {
                ARPlaceView(objectData: objectData) { newCoral in
                    self.newCoral = newCoral
                }
            }
            .navigationDestination(isPresented: $localIsPresented) {
                ARLocalView(coral: $selectLocalCoral)
            }
            .navigationDestination(isPresented: $globalIsPresented) {
                ARGlobalView(coral: $selectGlobalCoral)
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
    @Binding var newCoral: Coral?
    let handleSelect: (_ index: Int, _ type: CoralType) -> Void
    let defaults = UserDefaults()
    let manager = CLLocationManager()
    let view = MKMapView()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> some MKMapView {
        // delegateを設定
        view.delegate = context.coordinator
        
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
            let coral = LocalCoral.unarchive(index: index)
            /// アノテーション
            let annotation = CoralAnnotation(index: index, type: .local)
            annotation.coordinate = coral.coordinator
            view.addAnnotation(annotation)
            print("ローカルコーラル復元しました: \(coral.latitude), \(coral.longitude)")
        }
        
        // グローバルコーラルの個数
        let globalCoralCount = defaults.integer(forKey: "globalCoralCount")
        
        // グローバルコーラルの復元
        for index in 0 ..< globalCoralCount {
            let coral = GlobalCoral.unarchive(index: index)
            /// アノテーション
            let annotation = CoralAnnotation(index: index, type: .global)
            annotation.coordinate = coral.coordinator
            view.addAnnotation(annotation)
            print("グローバルコーラル復元しました: \(coral.latitude), \(coral.longitude)")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        let coordinator = context.coordinator
        guard let coral = newCoral else { return }
        if coordinator.prevCoral == coral {
            print("このコーラルはマップに追加済みなのでスキップします");
            return
        }
        let annotation = CoralAnnotation(index: coral.index, coral: coral)
        annotation.coordinate = coral.coordinator
        view.addAnnotation(annotation)
        coordinator.prevCoral = coral
        print("追加しました: \(coral.latitude), \(coral.longitude)")
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MapContainer
        var prevCoral: Coral?
        
        init(_ parent: MapContainer) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            guard annotation is CoralAnnotation else { return nil }
            let annotation = annotation as! CoralAnnotation
            
            let identifier = "annotation"
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView.annotation = annotation
                return annotationView
            } else {
                let annotationView = MKMarkerAnnotationView(
                    annotation: annotation,
                    reuseIdentifier: identifier
                )
                annotationView.markerTintColor = annotation.type == .local ? .red : .cyan
                return annotationView
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            guard let coralAnnotation = annotation as? CoralAnnotation else { return }
            parent.handleSelect(coralAnnotation.index, coralAnnotation.type)
        }
    }
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
