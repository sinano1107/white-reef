//
//  ARPlaceView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/18.
//

import SwiftUI
import RealityKit
import ARKit

struct ARPlaceView: View {
    private let capsule: ARViewCapsule
    
    init(objectData: ObjectData) {
        capsule = ARViewCapsule(objectData: objectData)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ARViewRepresentable(capsule: capsule)
                .ignoresSafeArea()
            Button("ローカルセーブ") {
                capsule.localSave()
            }
        }
        .onDisappear {
            capsule.discard()
        }
    }
}

private struct ARViewRepresentable: UIViewRepresentable {
    let capsule: ARViewCapsule
    
    func makeUIView(context: Context) -> ARView {
        capsule.make()
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

private class ARViewCapsule {
    private var arView: ARView?
    private var anchor = AnchorEntity()
    private var object = ModelEntity()
    let objectData: ObjectData
    
    init(objectData: ObjectData) {
        self.objectData = objectData
    }
    
    func make() -> ARView {
#if targetEnvironment(simulator)
        return ARView(frame: .zero)
#else
        arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        let arView = arView!
        
        // config
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
        }
        arView.session.run(config)
        
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
        
        return arView
#endif
    }
    
    /// タップされた時objectを移動する
    @objc func handleTap(sender: UITapGestureRecognizer) {
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
    }
    
    /// ARkitの標準機能による永続化
    func localSave() {
        arView?.session.getCurrentWorldMap { worldMap, error in
            guard let worldMap = worldMap
            else { fatalError("[エラー] worldMapがnil: \(String(describing: error))") }
            
            // アンカーをセーブアンカーのみにする
            worldMap.anchors.removeAll()
            worldMap.anchors.append(SaveAnchor(
                objectData: self.objectData,
                scale: self.object.scale,
                transform: self.object.transformMatrix(relativeTo: nil)))
            
            // アーカイブとセーブを実行
            do {
                let archivedMap = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
                UserDefaults().set(archivedMap, forKey: "saved")
            } catch {
                fatalError("[エラー] mapの保存に失敗: \(error)")
            }
        }
    }
    
    /// arViewを破棄する
    func discard() {
        arView = nil
    }
}

struct ARPlaceView_Previews: PreviewProvider {
    static var previews: some View {
        ARPlaceView(objectData: ObjectData.sample)
    }
}
