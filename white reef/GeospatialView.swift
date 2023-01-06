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

private let kHorizontalAccuracyLowThreshold: CLLocationAccuracy = 10
private let kHorizontalAccuracyHighThreshold: CLLocationAccuracy = 20
private let kOrientationYawAccuracyLowThreshold: CLLocationDirectionAccuracy = 15
private let kOrientationYawAccuracyHighThreshold: CLLocationDirectionAccuracy = 25
/// 十分な精度が得られない場合、アプリが諦めるまでの時間。
private let kLocalizationFailureTime = 60.0 * 3
private let kGeospatialTransformFormat =
"""
LAT/LONG（緯度/経度）: %.6f°, %.6f°\nACCURACY（精度）: %.2fm
ALTITUDE（高度）: %.2fm\n    ACCURACY（精度）: %.2fm
HEADING（方位）: %.1f°\n    ACCURACY（精度）: %.1f°
"""

struct GeospatialView: View {
    @State private var message: String?
    @State private var trackingLabelText: String = ""
    
    var body: some View {
        let bindingMessage = Binding(
            get: { message != nil },
            set: { _ in message = nil }
        )
        
        return ZStack(alignment: .topLeading) {
            ARViewContainer(message: $message, trackingLabelText: $trackingLabelText)
                .edgesIgnoringSafeArea(.all)
                .alert("メッセージ", isPresented: bindingMessage) {
                    Button("OK") {}
                } message: {
                    Text(message ?? "")
                }
            
            Text(trackingLabelText)
                .font(.caption)
                .padding()
        }
    }
}

private struct ARViewContainer: UIViewRepresentable {
    @Binding var message: String?
    @Binding var trackingLabelText: String
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
        /// ローカライズの試行を開始した最後の時間。失敗時のタイムアウトを実装するために使用します。
        var lastStartLocalizationDate = Date()
        
        enum LocalizationState: Int {
            case pretracking = 0
            case localizing = 1
            case localized = 2
            case failed = -1
        }
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        /// GARSessionをセットアップします
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
            // laststartLocalizationStateへ現在時刻を代入
            lastStartLocalizationDate = Date()
        }
        
        /// 位置情報からVPSが利用可能かチェックします
        func checkVPSAvailabilityWithCoordinate(_ coordinate: CLLocationCoordinate2D) {
            garSession?.checkVPSAvailability(coordinate: coordinate) { availability in
                if availability != .available {
                    self.parent.message = "VPSが利用できません"
                }
            }
        }
        
        /// 位置情報の権限をチェックします
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
        
        /// LocalizationStateを更新します
        func updateLocalizationState(_ garFrame: GARFrame) {
            // 現在トラッキングを行っていない場合はnilとなる
            let geospatialTransform = garFrame.earth?.cameraGeospatialTransform
            let now = Date()
            
            // earthStateが.enabled以外の場合は.failedに設定
            if garFrame.earth?.earthState != .enabled {
                localizationState = .failed
            }
            // trackingStateが.tracking以外の場合は.pretrackingに設定
            else if garFrame.earth?.trackingState != .tracking {
                localizationState = .pretracking
            }
            // earthStateが.enabled かつ trackingStateが.tracking の正常な場合の処理
            else {
                // 現在のlocalizationStateが.pretrackingの場合は.localizingに変更する
                if localizationState == .pretracking {
                    localizationState = .localizing
                }
                // 現在のlocalizationStateが.localizingの場合
                else if localizationState == .localizing {
                    // 精度が厳しめの閾値を下回った場合.lozalizedに設定
                    if (
                        geospatialTransform != nil
                        && geospatialTransform!.horizontalAccuracy <= kHorizontalAccuracyLowThreshold
                        && geospatialTransform!.orientationYawAccuracy <= kOrientationYawAccuracyLowThreshold
                    ) {
                        localizationState = .localized
                    }
                    // ローカライズの試行を開始してから指定時間経過していたら.failedに設定
                    else if now.timeIntervalSince(lastStartLocalizationDate) >= kLocalizationFailureTime {
                        localizationState = .failed
                    }
                }
                // 現在のlocalizationStateが.localizedの場合
                // （.failedの時はそもそもこの関数が呼ばれないため）
                else {
                    // 状態から抜け出す際に高いしきい値を使用することで、状態の変化がちらつくのを防ぐことができます。
                    //　精度が緩めの閾値を上回った場合.lozalizingに設定し、lastStartLocalizationDateを現在時刻に更新
                    if (
                        geospatialTransform == nil
                        || geospatialTransform!.horizontalAccuracy > kHorizontalAccuracyHighThreshold
                        || geospatialTransform!.orientationYawAccuracy > kOrientationYawAccuracyHighThreshold
                    ) {
                        localizationState = .localizing
                        lastStartLocalizationDate = now
                    }
                }
            }
        }
        
        /// earthStateを文字列に変換します
        func stringFromGAREarthState(_ earthState: GAREarthState) -> String {
            switch (earthState) {
            case .errorInternal:
                return "ERROR_INTERNAL"
            case .errorNotAuthorized:
                return "ERROR_NOT_AUTHORIZED"
            case .errorResourceExhausted:
                return "ERROR_RESOURCE_EXHAUSTED"
            default:
                return "ENABLED"
            }
        }
        
        /// トラッキングラベルを更新します
        func updateTrackingLabel(_ garFrame: GARFrame) {
            guard let earth = garFrame.earth else { return }
            
            if localizationState == .failed {
                if earth.earthState != .enabled {
                    let earthState = stringFromGAREarthState(earth.earthState)
                    parent.trackingLabelText = "Bad Earthstate: \(earthState)"
                } else {
                    parent.trackingLabelText = ""
                }
                return
            }
            
            if (earth.trackingState == .paused) {
                parent.trackingLabelText = "Not tracking."
                return
            }
            
            // 現在トラッキング中で、かつ良好なEarthStateであれば、これはゼロにはなりえません。
            guard let geospatialTransform = earth.cameraGeospatialTransform else { return }
            
            let cameraQuaternion = geospatialTransform.eastUpSouthQTarget
            
            // 注意：ここでの高度の値は、WGS84楕円体に対する相対値です（以下と同等）。|CLLocation.ellipsoidalAltitude|) に相当します。
            parent.trackingLabelText = String.init(
                format: kGeospatialTransformFormat,
                geospatialTransform.coordinate.latitude, geospatialTransform.coordinate.longitude,
                geospatialTransform.horizontalAccuracy, geospatialTransform.altitude,
                geospatialTransform.verticalAccuracy, cameraQuaternion.vector[0],
                cameraQuaternion.vector[1], cameraQuaternion.vector[2],
                cameraQuaternion.vector[3], geospatialTransform.orientationYawAccuracy
            )
        }
        
        /// 各種更新処理を実行します
        func updateWithGARFrame(_ garFrame: GARFrame) {
            updateLocalizationState(garFrame)
            updateTrackingLabel(garFrame)
        }
        
        /// 位置情報の許可が変更された時
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            checkLocationPermission()
        }
        
        /// 位置情報が更新された（移動した）時
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            checkVPSAvailabilityWithCoordinate(location.coordinate)
        }
        
        /// 位置情報の取得に失敗した時
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            parent.message = "locationの取得に失敗: \(error)"
        }
        
        /// ARFrameが更新される度に実行される
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            if localizationState == .failed { return }
            guard let garSession = garSession else { return }
            do {
                let garFrame = try garSession.update(frame)
                updateWithGARFrame(garFrame)
            } catch {
                parent.message = "garFrameのアップデートに失敗しました"
            }
        }
    }
}

struct GeospatialView_Previews: PreviewProvider {
    static var previews: some View {
        GeospatialView()
    }
}
