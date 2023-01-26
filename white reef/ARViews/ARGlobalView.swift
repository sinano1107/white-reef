//
//  ARGlobalView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/24.
//

import SwiftUI
import RealityKit
import ARKit
import ARCoreGeospatial

private let kHorizontalAccuracyLowThreshold: CLLocationAccuracy = 10
private let kHorizontalAccuracyHighThreshold: CLLocationAccuracy = 20
private let kOrientationYawAccuracyLowThreshold: CLLocationDirectionAccuracy = 15
private let kOrientationYawAccuracyHighThreshold: CLLocationDirectionAccuracy = 25
/// 十分な精度が得られない場合、アプリが諦めるまでの時間。
private let kLocalizationFailureTime = 60.0 * 3

struct ARGlobalView: View {
    private let capsule = Capsule()
    @Binding var coral: GlobalCoral?
    
    var body: some View {
        ARViewRepresentable(capsule: capsule, coral: coral)
            .ignoresSafeArea()
            .onDisappear {
                capsule.discard()
            }
    }
}

private struct ARViewRepresentable: UIViewRepresentable {
    let capsule: Capsule
    let coral: GlobalCoral?
    let manager = CLLocationManager()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
#if targetEnvironment(simulator)
        return ARView(frame: .zero)
#else
        let view = capsule.make(coral: coral!)
        view.session.delegate = context.coordinator
        manager.delegate = context.coordinator
        return view
#endif
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    class Coordinator: NSObject, CLLocationManagerDelegate, ARSessionDelegate {
        let parent: ARViewRepresentable
        
        init(_ parent: ARViewRepresentable) {
            self.parent = parent
        }
        
        /// 位置情報が更新された時
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            parent.capsule.checkVPSAvailability(location.coordinate)
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // GARSessionのupdateを行う
            parent.capsule.updateGARSession(frame: frame)
        }
    }
}

private class Capsule: ARViewCapsule {
    private var garSession: GARSession?
    private var localizationState: LocalizationState = .failed
    private var lastStartLocalizationData = Date()
    private var bestAccuracy: CLLocationAccuracy = 100
    private var object = ModelEntity()
    
    func make(coral: GlobalCoral) -> ARView {
        // objectを生成
        object = coral.objectData.generate(moveTheOriginDown: true)
        object.isEnabled = false
        // GARSessionをセットアップ
        setUpGARSession(coral: coral)
        // オブジェクトをシーンに追加
        let view = super.make()
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(object)
        view.scene.addAnchor(anchor)
        return view
    }
    
    /// GARSessionをセットアップします
    func setUpGARSession(coral: GlobalCoral) {
        // すでにGARSessionが作成されているならば離脱
        if garSession != nil { return }
        
        // garSessionを作成
        garSession = try! GARSession(apiKey: apiKey, bundleIdentifier: nil)
        
        // アンラップ
        guard let garSession = garSession else { return }
        
        // GeospatialModeがサポートされているか確認
        if !garSession.isGeospatialModeSupported(.enabled) {
            fatalError("GARGeospatialModeEnabledは、このデバイスではサポートされていません。")
        }
        
        /// config
        let config = GARSessionConfiguration()
        config.geospatialMode = .enabled
        
        // configをセット
        var error: NSError?
        garSession.setConfiguration(config, error: &error)
        if (error != nil) {
            fatalError("GARSessionの設定に失敗しました: \(error!.code)")
        }
        
        // .failed => .pretracking
        localizationState = .pretracking
        
        // スタートタイムに現在時刻を代入
        lastStartLocalizationData = Date()
        
        // アンカーを生成
        try! garSession.createAnchor(coordinate: coral.coordinator, altitude: coral.altitude, eastUpSouthQAnchor: coral.eastUpSouthQTarget)
    }
    
    /// 位置情報からVPSが利用可能かチェックします
    func checkVPSAvailability(_ coordinate: CLLocationCoordinate2D) {
        garSession?.checkVPSAvailability(coordinate: coordinate) { availability in
            if availability != .available { fatalError("VPS利用不可") }
        }
    }
    
    /// ARFrameをgarSessionに提供し、各種更新処理を行います
    func updateGARSession(frame: ARFrame) {
        if localizationState == .failed { return }
        guard let garSession = garSession else { return }
        do {
            let garFrame = try garSession.update(frame)
            updateLocalizationState(garFrame)
            placeObject(garFrame)
        } catch {
            fatalError("garFrameのアップデートに失敗: \(error)")
        }
    }
    
    /// ローカライゼーションステータスを適切に更新します
    func updateLocalizationState(_ garFrame: GARFrame) {
        // トラッキングを行なっていない場合はnilとなる
        let geospatialTransform = garFrame.earth?.cameraGeospatialTransform
        let now = Date()
        
        // earthStateが有効でなければ失敗
        if garFrame.earth?.earthState != .enabled {
            localizationState = .failed
        }
        
        // トラッキングできていなければ.pretrackingに設定
        else if garFrame.earth?.trackingState != .tracking {
            localizationState = .pretracking
        }
        
        // トラッキング中の処理
        else {
            
            // .pretracking => .localizing
            if localizationState == .pretracking {
                localizationState = .localizing
            }
            
            // ローカライズ中の処理
            else if localizationState == .localizing {
                // 閾値を下回れば.localizing => .localized
                if (
                    geospatialTransform != nil
                    && geospatialTransform!.horizontalAccuracy <= kHorizontalAccuracyLowThreshold
                    && geospatialTransform!.orientationYawAccuracy <= kOrientationYawAccuracyLowThreshold
                ) {
                    localizationState = .localized
                }
                
                // .localizingになってから指定時間経過したら.failed
                else if now.timeIntervalSince(lastStartLocalizationData) >= kLocalizationFailureTime {
                    localizationState = .failed
                }
            }
            
            // ローカライズ完了時の処理
            else {
                // 閾値を上回れば、.localized => .localizing
                if (
                    geospatialTransform == nil
                    || geospatialTransform!.horizontalAccuracy > kHorizontalAccuracyHighThreshold
                    || geospatialTransform!.orientationYawAccuracy > kOrientationYawAccuracyHighThreshold
                ) {
                    localizationState = .localizing
                    lastStartLocalizationData = now
                }
            }
        }
    }
    
    /// 精度が最も良かった時にアンカーの場所にオブジェクトを置く
    func placeObject(_ frame: GARFrame) {
        #if targetEnvironment(simulator)
        #else
        guard
            localizationState == .localized,
            let accuracy = frame.earth?.cameraGeospatialTransform?.horizontalAccuracy
        else { return }
        
        if bestAccuracy > accuracy {
            bestAccuracy = accuracy
            let GARAnchor = frame.anchors.first!
            guard GARAnchor.trackingState == .tracking else { return }
            
            object.isEnabled = true
            object.setTransformMatrix(GARAnchor.transform, relativeTo: nil)
            
            print("移動しました", object.transform.translation, object.transform.scale)
        }
        #endif
    }
}

struct ARGlobalView_Previews: PreviewProvider {
    static var previews: some View {
        ARGlobalView(coral: .constant(nil))
    }
}

