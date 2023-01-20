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
                .onTapGesture(coordinateSpace: .global) { location in
//                    command = .handleTapGesture(location: location)
                }
            Button("ローカルセーブ") {
//                command = .localSave
            }
        }
        .onDisappear {
            capsule.discard()
        }
    }
}

private struct ARViewRepresentable: UIViewRepresentable {
    let capsule: ARViewCapsule
//    let objectData: ObjectData
//    @AppStorage("ar-world-map") private var arWorldMap = Data()
    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
    
    func makeUIView(context: Context) -> ARView {
        capsule.make()
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
//    class Coordinator: NSObject {
//        let parent: ARViewRepresentable
//#if targetEnvironment(simulator)
//        let arView = ARView(frame: .zero)
//#else
//        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
//#endif
//        var anchor: AnchorEntity
//        let object: ModelEntity
//
//        init(_ parent: ARViewRepresentable) {
//            self.parent = parent
//#if targetEnvironment(simulator)
//            anchor = AnchorEntity()
//            object = ModelEntity()
//#else
//            // config
//            let config = ARWorldTrackingConfiguration()
//            config.planeDetection = .horizontal
//            config.environmentTexturing = .automatic
//            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
//                config.sceneReconstruction = .mesh
//                arView.environment.sceneUnderstanding.options.insert(.occlusion)
//            }
//            arView.session.run(config)
//
//            // objectを追加
//            anchor = AnchorEntity(plane: .horizontal)
//            object = parent.objectData.generate(moveTheOriginDown: true)
//            anchor.addChild(object)
//            arView.scene.addAnchor(anchor)
//
//            // objectをinstallGestureの対象に
//            object.generateCollisionShapes(recursive: false)
//            arView.installGestures(for: object)
//#endif
//        }
        
        /// タップされた時
//        func handleTapGesture(location: CGPoint) {
//#if targetEnvironment(simulator)
//#else
//            // レイキャスト
//            guard let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first
//            else { return }
//
//            // ARAnchorを追加
//            let arAnchor = ARAnchor(transform: result.worldTransform)
//            arView.session.add(anchor: arAnchor)
//
//            // 既存のアンカーを削除
//            arView.scene.removeAnchor(anchor)
//            // 新しくアンカーを生成
//            anchor = AnchorEntity(anchor: arAnchor)
//            // objectのポジションのみリセット
//            object.setPosition([0, 0, 0], relativeTo: anchor)
//            anchor.addChild(object)
//            arView.scene.addAnchor(anchor)
//#endif
//        }
        
        /// ARkitの標準機能による永続化
//        func localSave() {
//            arView.session.getCurrentWorldMap { worldMap, _ in
//                guard let worldMap = worldMap else { fatalError("[エラー] worldMapがnil") }
//                worldMap.anchors.removeAll()
//                worldMap.anchors.append(SaveAnchor(
//                    objectData: self.parent.objectData,
//                    scale: self.object.scale,
//                    transform: self.object.transformMatrix(relativeTo: nil)))
//                do {
//                    let archivedMap = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
//                    self.parent.arWorldMap = archivedMap
//                    print("セーブ完了しました")
//                } catch {
//                    fatalError("[エラー] mapのアーカイブに失敗: \(error)")
//                }
//            }
//        }
//    }
}

private class ARViewCapsule {
    private var arView: ARView?
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
        let anchor = AnchorEntity(plane: .horizontal)
        object = objectData.generate(moveTheOriginDown: true)
        anchor.addChild(object)
        arView.scene.addAnchor(anchor)
        
        // objectをinstallGestureの対象に
        object.generateCollisionShapes(recursive: false)
        arView.installGestures(for: object)
        
        return arView
#endif
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
