//
//  ARPlaceView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/18.
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

struct ARPlaceView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("localCoralCount") private var localCoralCount = 0
    @AppStorage("globalCoralCount") private var globalCoralCount = 0
    @State private var worldMappingStatus: ARFrame.WorldMappingStatus = .notAvailable
    /// グローバルセーブのステータス
    @State private var localizationState: LocalizationState?
    /// グローバルセーブ試行中で出た最も良い結果を表示する
    @State private var bestResultText = ""
    /// グローバルセーブ中かどうか
    @State private var globalSaving = false
    private let capsule: Capsule
    let onSaved: (_ newCoral: Coral) -> Void
    
    init(objectData: ObjectData, onSaved: @escaping (_ newCoral: Coral) -> Void) {
        capsule = Capsule(objectData: objectData)
        self.onSaved = onSaved
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            ARViewRepresentable(
                capsule: capsule,
                worldMapingStatus: $worldMappingStatus)
            .ignoresSafeArea()
            VStack(alignment: .leading) {
                Text(localizationState?.description ?? "")
                Text(bestResultText)
                Spacer()
                HStack {
                    Button("ローカルセーブ") {
                        capsule.localSave(index: localCoralCount) { newCoral in
                            onSaved(newCoral)
                            localCoralCount += 1
                            dismiss()
                        }
                    }
                    .disabled(
                        worldMappingStatus != .mapped
                        && worldMappingStatus != .extending)
                    Button("グローバルセーブ開始") {
                        globalSaving = true
                        bestResultText = "グローバルセーブ開始"
                        capsule.startGlobalSave { state in
                            localizationState = state
                        } _: { accuracy, coordinate in
                            bestResultText = "精度: \(accuracy)\n座標: (\(coordinate.latitude), \(coordinate.longitude))"
                        }
                    }
                    .disabled(globalSaving)
                    Button("グローバルセーブ終了") {
                        capsule.endGlobalSave(index: globalCoralCount) { newCoral in
                            onSaved(newCoral)
                            globalCoralCount += 1
                            dismiss()
                        }
                    }
                    .disabled(!globalSaving)
                }
            }
            .padding()
        }
        .onDisappear {
            capsule.discard()
        }
    }
}

private struct ARViewRepresentable: UIViewRepresentable {
    let capsule: Capsule
    let manager = CLLocationManager()
    @Binding var worldMapingStatus: ARFrame.WorldMappingStatus
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = capsule.make()
        manager.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        return arView
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
            // ワールドマッピングステータスを更新
            parent.worldMapingStatus = frame.worldMappingStatus
            // GARSessionのupdateを行う
            parent.capsule.updateGARSession(frame: frame)
        }
    }
}

private class Capsule: ARViewCapsule {
    private var garSession: GARSession?
    private var localizationState: LocalizationState = .failed {
        didSet {
            // localizationStateが変化した時にstateUpdatedを実行
            stateUpdated(localizationState)
        }
    }
    private var lastStartLocalizationData = Date()
    private var bestAccuracy: CLLocationAccuracy = 100
    private var bestTransform: GARGeospatialTransform?
    private var stateUpdated: (_ state: LocalizationState) -> Void = { _ in }
    private var bestUpdated: (_ accuracy: CLLocationAccuracy, _ coordinate: CLLocationCoordinate2D) -> Void = { _, _ in }
    private var anchor = AnchorEntity()
    private var object = ModelEntity()
    let objectData: ObjectData
    
    init(objectData: ObjectData) {
        self.objectData = objectData
    }
    
    func make() -> ARView {
        let arView = super.make()
#if targetEnvironment(simulator)
#else
        // objectを追加
        anchor = AnchorEntity(plane: .horizontal)
        object = objectData.generate(moveTheOriginDown: true)
        anchor.addChild(object)
        arView.scene.addAnchor(anchor)
        
        // objectをinstallGestureの対象に
        object.generateCollisionShapes(recursive: false)
        arView.installGestures(for: object)
        
        // gestureRecognizerを追加
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        arView.addGestureRecognizer(tapGesture)
#endif
        return arView
    }
    
    /// タップされた時objectを移動する
    @objc func handleTap(sender: UITapGestureRecognizer) {
#if targetEnvironment(simulator)
#else
        guard let arView = arView else { return }
        
        // raycast
        let location = sender.location(in: arView)
        guard let result = arView.raycast(
            from: location,
            allowing: .estimatedPlane,
            alignment: .horizontal
        ).first
        else { return }
        
        // ARAnchorを追加
        let arAnchor = ARAnchor(transform: result.worldTransform)
        arView.session.add(anchor: arAnchor)
        
        // 既存のアンカーを削除
        arView.scene.removeAnchor(anchor)
        
        // 新しくアンカーを生成
        anchor = AnchorEntity(anchor: arAnchor)
        
        // objectのポジションのみリセット
        object.setPosition([0, 0, 0], relativeTo: anchor)
        
        // アンカーにobjectを追加して、シーンに追加
        anchor.addChild(object)
        arView.scene.addAnchor(anchor)
#endif
    }
    
    /// ARkitの標準機能による永続化
    func localSave(index: Int, onSaved: @escaping (_ newCoral: LocalCoral) -> Void) {
        arView?.session.getCurrentWorldMap { worldMap, error in
            guard let worldMap = worldMap
            else { fatalError("[エラー] worldMapがnil: \(String(describing: error))") }
            
            // アンカーをセーブアンカーのみにする
            worldMap.anchors.removeAll()
            worldMap.anchors.append(SaveAnchor(
                objectData: self.objectData,
                transform: self.object.transformMatrix(relativeTo: nil)))
            
            do {
                // 必要な情報
                let defaults = UserDefaults()
                guard let coordinate = CLLocationManager().location?.coordinate else { fatalError("位置情報が不明") }
                
                // コーラルを生成してアーカイブ
                guard let newCoral = LocalCoral(capturing: self.arView!, index: index, coordinator: coordinate, armap: worldMap)
                else { fatalError("コーラルの生成に失敗") }
                let archivedCoral = try NSKeyedArchiver.archivedData(withRootObject: newCoral, requiringSecureCoding: true)
                
                // 保存
                let key = "localCorals/\(index)"
                defaults.set(archivedCoral, forKey: key)
                
                // onSavedを実行
                onSaved(newCoral)
            } catch {
                fatalError("[エラー] mapの保存に失敗: \(error)")
            }
        }
    }
    
    /// GeospatialAPIによる永続化を開始
    func startGlobalSave(
        _ stateUpdated: @escaping (_ state: LocalizationState) -> Void,
        _ bestUpdated: @escaping (_ accuracy: CLLocationAccuracy, _ coordinate: CLLocationCoordinate2D) -> Void)
    {
        setUpGARSession()
        self.stateUpdated = stateUpdated
        self.bestUpdated = bestUpdated
    }
    
    /// GeospatialAPIによる永続化を終了
    func endGlobalSave(index: Int, onSaved: @escaping (_ newCoral: GlobalCoral) -> Void) {
        garSession = nil
        
        guard let bestTransform = bestTransform else { return }
        
        // コーラルを生成してアーカイブ
        let newCoral = GlobalCoral(index: index, transform: bestTransform, objectData: objectData)
        let archivedCoral = try! NSKeyedArchiver.archivedData(withRootObject: newCoral, requiringSecureCoding: true)
        
        // 保存
        let key = "globalCorals/\(index)"
        UserDefaults().set(archivedCoral, forKey: key)
        
        // コールバックを実行
        onSaved(newCoral)
    }
    
    /// GARSessionをセットアップします
    func setUpGARSession() {
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
            saveObjectCoordinate(garFrame)
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
    
    /// 精度が最も良いものだった時にObjectの座標を算出し保存する
    func saveObjectCoordinate(_ frame: GARFrame) {
        guard
            let garSession = garSession,
            localizationState == .localized,
            anchor.isAnchored,
            let accuracy =
                frame.earth?.cameraGeospatialTransform?.horizontalAccuracy
        else { return }
        
        if bestAccuracy > accuracy {
            bestAccuracy = accuracy
            let objectTransform = object.transformMatrix(relativeTo: nil)
            bestTransform = try! garSession.geospatialTransform(transform: objectTransform)
            // ベスト精度更新時のコールバックを実行
            bestUpdated(bestAccuracy, bestTransform!.coordinate)
        }
    }
}

struct ARPlaceView_Previews: PreviewProvider {
    static var previews: some View {
        ARPlaceView(objectData: ObjectData.sample) { _ in }
    }
}
