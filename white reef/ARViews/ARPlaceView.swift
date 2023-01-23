//
//  ARPlaceView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/18.
//

import SwiftUI
import RealityKit
import ARKit
import ARCore

struct ARPlaceView: View {
    @AppStorage("localCoralCount") private var localCoralCount = 0
    @State private var worldMappingStatus: ARFrame.WorldMappingStatus = .notAvailable
    private let capsule: Capsule
    let onSaved: (_ newCoral: LocalCoral) -> Void
    
    init(objectData: ObjectData, onSaved: @escaping (_ newCoral: LocalCoral) -> Void) {
        capsule = Capsule(objectData: objectData)
        self.onSaved = onSaved
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ARViewRepresentable(
                capsule: capsule,
                worldMapingStatus: $worldMappingStatus)
            .ignoresSafeArea()
            HStack {
                Button("ローカルセーブ") {
                    capsule.localSave(index: localCoralCount) { newCoral in
                        onSaved(newCoral)
                        localCoralCount += 1
                    }
                }
                .disabled(
                    worldMappingStatus != .mapped
                    && worldMappingStatus != .extending)
                Button("グローバルセーブ") {
                    capsule.setUpGARSession()
                }
            }
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
        }
    }
}

private class Capsule: ARViewCapsule {
    private var garSession: GARSession?
    private var localizationState: LocalizationState = .failed
    private var lastStartLocalizationData = Date()
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
    
    /// GeospatialAPIのローカライゼーションステータス
    enum LocalizationState: Int {
        case pretracking = 0
        case localizing = 1
        case localized = 2
        case failed = -1
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
        
    }
    
    /// GeospatialAPIによる永続化
//    func globalSave() {
//
//    }
}

struct ARPlaceView_Previews: PreviewProvider {
    static var previews: some View {
        ARPlaceView(objectData: ObjectData.sample) { _ in }
    }
}
