//
//  GeospatialView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/06.
//

import SwiftUI
import RealityKit
import ARKit

struct GeospatialView: View {
    var body: some View {
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

private struct ARViewContainer: UIViewRepresentable {
    let locationManager = CLLocationManager()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
#if targetEnvironment(simulator)
        let arView = ARView(frame: .zero)
#else
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
#endif
        let config = ARWorldTrackingConfiguration()
        
        // 座標系を設定
        config.worldAlignment = .gravity
        // 水平なplaneのみ検出
        config.planeDetection = .horizontal
        
        // locationManager
        locationManager.delegate = context.coordinator
        // arView
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    class Coordinator: NSObject, CLLocationManagerDelegate, ARSessionDelegate {
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func setUpGARSession() {
            // TODO: setUpARSessionの実装
            print("setUpGARSession()")
        }
        
        func checkVPSAvailabilityWithCoordinate(_ coordinate: CLLocationCoordinate2D) {
            // TODO: checkVPSAvailabilityWithCoordinateの実装（setUpGARSessionの実装後）
            print("checkVPSAvailabilityWithCoordinate()")
        }
        
        func checkLocationPermission() {
            let locationManager = parent.locationManager
            let authorizationStatus = locationManager.authorizationStatus
            print(authorizationStatus.hashValue)
            if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                if locationManager.accuracyAuthorization != .fullAccuracy {
                    fatalError("位置情報は完全な精度で許可されたものではありません。")
                }
                
#if targetEnvironment(simulator)
#else
                // VPSの可用性を確認するために、デバイスの位置をリクエストします
                locationManager.requestLocation()
#endif
                setUpGARSession()
            } else if authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            } else {
                print("位置情報の取得が拒否または制限されている")
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            checkLocationPermission()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            checkVPSAvailabilityWithCoordinate(location.coordinate)
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("locationの取得に失敗: \(error)")
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {}
    }
}

struct GeospatialView_Previews: PreviewProvider {
    static var previews: some View {
        GeospatialView()
    }
}
