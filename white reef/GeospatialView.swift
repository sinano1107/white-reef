//
//  GeospatialView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/06.
//

import SwiftUI
import RealityKit
import ARKit
import ARCore

struct GeospatialView: View {
    @State private var message: String?
    
    var body: some View {
        let bindingMessage = Binding(
            get: { message != nil },
            set: { _ in message = nil }
        )
        
        return ARViewContainer(message: $message)
            .edgesIgnoringSafeArea(.all)
            .alert("メッセージ", isPresented: bindingMessage) {
                Button("OK") {}
            } message: {
                Text(message ?? "")
            }
    }
}

private struct ARViewContainer: UIViewRepresentable {
    @Binding var message: String?
    private let locationManager = CLLocationManager()
    
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
        var garSession: GARSession?
        var localizationState: LocalizationState = .failed
        
        enum LocalizationState: Int {
            case pretracking = 0
            case localizing = 1
            case localized = 2
            case failed = -1
        }
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func setUpGARSession() {
            // すでにGARSessionが作成されているならば離脱
            if garSession != nil { return }
            
            // garSessionを作成
            do {
                garSession = try GARSession(apiKey: apiKey, bundleIdentifier: nil)
            } catch {
                parent.message = "GARSessionの作成に失敗しました: \(error)"
                return
            }
            
            // GeospatialModeがサポートされているか確認
            if !garSession!.isGeospatialModeSupported(.enabled) {
                parent.message = "GARGeospatialModeEnabled は、このデバイスではサポートされていません"
                return
            }
            
            // config
            let config = GARSessionConfiguration()
            config.geospatialMode = .enabled
            
            // configをセット
            var error: NSError?
            garSession!.setConfiguration(config, error: &error)
            if (error != nil) {
                parent.message = "GARSessionのコンフィグレーションに失敗しました: \(error!.code)"
                return
            }
            
            // localizationStateを.failedから.pretrackingへ変更
            localizationState = .pretracking
        }
        
        func checkVPSAvailabilityWithCoordinate(_ coordinate: CLLocationCoordinate2D) {
            // TODO: checkVPSAvailabilityWithCoordinateの実装（setUpGARSessionの実装後）
            print("checkVPSAvailabilityWithCoordinate()")
        }
        
        func checkLocationPermission() {
            let locationManager = parent.locationManager
            let authorizationStatus = locationManager.authorizationStatus
            if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                if locationManager.accuracyAuthorization != .fullAccuracy {
                    parent.message = "位置情報は完全な精度で許可されたものではありません"
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
                parent.message = "位置情報の取得が拒否または制限されている"
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
            parent.message = "locationの取得に失敗: \(error)"
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {}
    }
}

struct GeospatialView_Previews: PreviewProvider {
    static var previews: some View {
        GeospatialView()
    }
}
