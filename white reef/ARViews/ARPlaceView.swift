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
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = .horizontal
            config.environmentTexturing = .automatic
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                config.sceneReconstruction = .mesh
                arView.environment.sceneUnderstanding.options.insert(.occlusion)
            }
            arView.session.run(config)
            
            let anchor = AnchorEntity(plane: .horizontal)
            anchor.addChild(objectData.generate(moveTheOriginDown: true))
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
