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
    var body: some View {
        ARViewRepresentable()
    }
}

private struct ARViewRepresentable: UIViewRepresentable {
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
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
        
        override init() {
            let config = ARWorldTrackingConfiguration()
            arView.session.run(config)
        }
    }
}

struct ARPlaceView_Previews: PreviewProvider {
    static var previews: some View {
        ARPlaceView()
    }
}
