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
#if targetEnvironment(simulator)
    private let arView = ARView(frame: .zero)
#else
    private let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
#endif
    @State private var garSession: GARSession?
    @State private var message: String?
    @State private var trackingLabelText: String = ""
    @State private var statusLabel: String = ""
    
    /// 緯度軽度諸々の情報を受け取りボックスをおく
    func addAnchorWithCoordinate(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance, eastUpSouthQTarget: simd_quatf, boxColor: UIColor) {
#if targetEnvironment(simulator)
#else
        guard let garSession = garSession else { return }
        
        do {
            let garAnchor = try garSession.createAnchor(coordinate: coordinate, altitude: altitude, eastUpSouthQAnchor: eastUpSouthQTarget)
            guard garAnchor.hasValidTransform else { return }
            
            let arAnchor = ARAnchor(transform: garAnchor.transform)
            arView.session.add(anchor: arAnchor)
            
            let anchorEntity = AnchorEntity(anchor: arAnchor)
            
            let boxMesh = MeshResource.generateBox(size: 0.1)
            let boxMaterial = SimpleMaterial(color: boxColor, isMetallic: true)
            let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
            
            // ボックスが埋まらないようにする
            boxEntity.setPosition([0, 0.05, 0], relativeTo: boxEntity)
            
            // add & append
            anchorEntity.addChild(boxEntity)
            arView.scene.addAnchor(anchorEntity)
        } catch {
            message = "アンカーの追加に失敗"
            return
        }
#endif
    }
    
    var body: some View {
        let bindingMessage = Binding(
            get: { message != nil },
            set: { _ in message = nil }
        )
        
        return ZStack(alignment: .leading) {
            ARViewContainer(
                arView: arView,
                garSession: $garSession,
                message: $message,
                trackingLabelText: $trackingLabelText,
                statusLabel: $statusLabel
            )
            .edgesIgnoringSafeArea(.all)
            .onTapGesture(coordinateSpace: .global) { location in
                guard let garSession = garSession else { return }
                guard let first = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal).first
                else { return }
                
                do {
                    let geospatialTransform = try garSession.geospatialTransform(transform: first.worldTransform)
                    addAnchorWithCoordinate(coordinate: geospatialTransform.coordinate, altitude: geospatialTransform.altitude, eastUpSouthQTarget: geospatialTransform.eastUpSouthQTarget, boxColor: .red)
                    
                    let defaults = UserDefaults.standard
                    
                    let data: [String: NSNumber] = [
                        "latitude": NSNumber(value: geospatialTransform.coordinate.latitude),
                        "longitude": NSNumber(value: geospatialTransform.coordinate.longitude),
                        "altitude": NSNumber(value: geospatialTransform.altitude),
                        "x": NSNumber(value: geospatialTransform.eastUpSouthQTarget.vector[0]),
                        "y": NSNumber(value: geospatialTransform.eastUpSouthQTarget.vector[1]),
                        "z": NSNumber(value: geospatialTransform.eastUpSouthQTarget.vector[2]),
                        "w": NSNumber(value: geospatialTransform.eastUpSouthQTarget.vector[3])
                    ]
                    defaults.set(data, forKey: "anchor")
                } catch {
                    message = "geospatialAnchorの生成に失敗しました"
                    return
                }
            }
            
            VStack(alignment: .leading) {
                Text(trackingLabelText)
                    .font(.caption)
                Spacer()
                HStack {
                    Text(statusLabel)
                    Button("ロードして復元") {
                        let defaults = UserDefaults.standard
                        guard let savedAnchor = defaults.object(forKey: "anchor") as? [String: NSNumber]
                        else { return }
                        
                        let latitude: CLLocationDegrees = savedAnchor["latitude"]!.doubleValue
                        let longitude: CLLocationDegrees = savedAnchor["longitude"]!.doubleValue
                        let eastUpSourceQTarget = simd_quaternion(
                            savedAnchor["x"]!.floatValue,
                            savedAnchor["y"]!.floatValue,
                            savedAnchor["z"]!.floatValue,
                            savedAnchor["w"]!.floatValue
                        )
                        let altitude: CLLocationDistance = savedAnchor["altitude"]!.doubleValue
                        
                        addAnchorWithCoordinate(
                            coordinate: CLLocationCoordinate2D(
                                latitude: latitude,
                                longitude: longitude
                            ),
                            altitude: altitude,
                            eastUpSouthQTarget: eastUpSourceQTarget,
                            boxColor: .white
                        )
                    }
                }
            }
            .padding()
        }
        .alert("メッセージ", isPresented: bindingMessage) {
            Button("OK") {}
        } message: {
            Text(message ?? "")
        }
    }
}

private struct ARViewContainer: UIViewRepresentable {
    let arView: ARView
    @Binding var garSession: GARSession?
    @Binding var message: String?
    @Binding var trackingLabelText: String
    @Binding var statusLabel: String
    private let locationManager = CLLocationManager()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
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
        // var garSession: GARSession?
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
            if parent.garSession != nil { return }
            
            // garSessionを作成
            do {
                parent.garSession = try GARSession(apiKey: apiKey, bundleIdentifier: nil)
            } catch {
                parent.message = "GARSessionの作成に失敗しました: \(error)"
                return
            }
            
            // parent.garSessionをアンラップ
            guard let garSession = parent.garSession else { return }
            
            // GeospatialModeがサポートされているか確認
            if !garSession.isGeospatialModeSupported(.enabled) {
                parent.message = "GARGeospatialModeEnabled は、このデバイスではサポートされていません"
                return
            }
            
            // config
            let config = GARSessionConfiguration()
            config.geospatialMode = .enabled
            
            // configをセット
            var error: NSError?
            garSession.setConfiguration(config, error: &error)
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
            parent.garSession?.checkVPSAvailability(coordinate: coordinate) { availability in
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
        
        /// ステータスラベルを更新します
        func updateStatusLabel(_ garFrame: GARFrame) {
            switch (localizationState) {
            case .localized:
                parent.statusLabel = "ローカライズ完了"
            case .pretracking:
                parent.statusLabel = "ローカライズします"
            case .localizing:
                parent.statusLabel = "身近な建物やお店、看板などにカメラを向けてみましょう"
            case .failed:
                parent.statusLabel = "ローカライズに失敗しました"
            }
        }
        
        /// 各種更新処理を実行します
        func updateWithGARFrame(_ garFrame: GARFrame) {
            updateLocalizationState(garFrame)
            updateTrackingLabel(garFrame)
            updateStatusLabel(garFrame)
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
            guard let garSession = parent.garSession else { return }
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
