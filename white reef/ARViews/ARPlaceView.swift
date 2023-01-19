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
    
    var body: some View {
        ARViewRepresentable(objectData: objectData)
            .ignoresSafeArea()
    }
}

private struct ARViewRepresentable: UIViewRepresentable {
    let objectData: ObjectData
    
    func makeCoordinator() -> Coordinator {
        Coordinator(objectData: objectData)
    }
    
    func makeUIView(context: Context) -> ARView {
        context.coordinator.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    class Coordinator: NSObject {
        #if targetEnvironment(simulator)
        let arView = ARView(frame: .zero)
        #else
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        #endif
        
        init(objectData: ObjectData) {
            #if targetEnvironment(simulator)
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
            let anchor = AnchorEntity(plane: .horizontal)
            let object = objectData.generate(moveTheOriginDown: true)
            anchor.addChild(object)
            arView.scene.addAnchor(anchor)
            
            // objectをinstallGestureの対象に
            object.generateCollisionShapes(recursive: false)
            arView.installGestures(for: object)
            #endif
        }
    }
}

struct ARPlaceView_Previews: PreviewProvider {
    static var previews: some View {
        ARPlaceView(objectData: ObjectData.sample)
    }
}
