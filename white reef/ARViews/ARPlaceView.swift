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
    let objectData: ObjectData
    @State private var command: ARViewRepresentable.Command = .none
    
    var body: some View {
        ARViewRepresentable(objectData: objectData, command: $command)
            .ignoresSafeArea()
            .onTapGesture(coordinateSpace: .global) { location in
                command = .handleTapGesture(location: location)
            }
    }
}

private struct ARViewRepresentable: UIViewRepresentable {
    let objectData: ObjectData
    @Binding var command: Command
    
    enum Command {
        case handleTapGesture(location: CGPoint)
        case none
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(objectData: objectData)
    }
    
    func makeUIView(context: Context) -> ARView {
        context.coordinator.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        switch command {
        case let .handleTapGesture(location):
            context.coordinator.handleTapGesture(location: location)
        case .none: break
        }
    }
    
    class Coordinator: NSObject {
#if targetEnvironment(simulator)
        let arView = ARView(frame: .zero)
#else
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
#endif
        var anchor: AnchorEntity
        let object: ModelEntity
        
        init(objectData: ObjectData) {
#if targetEnvironment(simulator)
            anchor = AnchorEntity()
            object = ModelEntity()
#else
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
#endif
        }
        
        /// タップされた時
        func handleTapGesture(location: CGPoint) {
#if targetEnvironment(simulator)
#else
            // レイキャスト
            guard let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first
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
            anchor.addChild(object)
            arView.scene.addAnchor(anchor)
#endif
        }
    }
}

struct ARPlaceView_Previews: PreviewProvider {
    static var previews: some View {
        ARPlaceView(objectData: ObjectData.sample)
    }
}
