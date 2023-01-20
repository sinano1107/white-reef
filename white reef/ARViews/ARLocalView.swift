//
//  ARLocalView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/20.
//

import SwiftUI
import RealityKit
import ARKit

struct ARLocalView: View {
    private let capsule = Capsule()
    
    var body: some View {
        ARViewRepresentable(capsule: capsule)
            .onDisappear {
                capsule.discard()
            }
    }
}

private struct ARViewRepresentable: UIViewRepresentable {
    @AppStorage("saved") private var archivedMap = Data()
    let capsule: Capsule
    
    func makeUIView(context: Context) -> ARView {
        capsule.make(archivedMap: archivedMap)
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

private class Capsule: ARViewCapsule {
    private var localizing = true
    private var saveAnchor: SaveAnchor?
    
    func make(archivedMap: Data) -> ARView {
        let initialWorldMap = try! NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: archivedMap)
        if let first = initialWorldMap?.anchors.first {
            saveAnchor = SaveAnchor(anchor: first)
        }
        return super.make(initialWorldMap: initialWorldMap)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if localizing && frame.camera.trackingState == .normal {
            localizing = false
            guard let saveAnchor = saveAnchor else { return }
            let anchorEntity = saveAnchor.generateAnchorEntity()
            arView?.scene.addAnchor(anchorEntity)
        }
    }
}

struct ARLocalView_Previews: PreviewProvider {
    static var previews: some View {
        ARLocalView()
    }
}
