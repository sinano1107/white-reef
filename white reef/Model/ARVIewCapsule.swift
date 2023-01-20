//
//  ARVIewCapsule.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/20.
//

import RealityKit
import ARKit

class ARViewCapsule: NSObject, ARSessionDelegate {
    private (set) var arView: ARView?
    
    /// arVIewを設定し代入する
    func make(initialWorldMap: ARWorldMap? = nil) -> ARView {
#if targetEnvironment(simulator)
        
        return ARView(frame: .zero)
        
#else
        
        arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        let arView = arView!
        
        // config
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.environmentTexturing = .automatic
        config.initialWorldMap = initialWorldMap
        
        // 再構築されたシーンの視覚化と操作の設定
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
        }
        
        // delegateを自身に設定
        arView.session.delegate = self
        
        arView.session.run(config)
        return arView
        
#endif
    }
    
    /// arVIewを破棄する
    func discard() {
        arView = nil
    }
}
