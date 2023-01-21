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
    @Binding var selectCoral: Int?
    
    var body: some View {
        ARViewRepresentable(capsule: capsule, selectCoral: $selectCoral)
            .ignoresSafeArea()
            .onDisappear {
                capsule.discard()
            }
    }
}

private struct ARViewRepresentable: UIViewRepresentable {
    let capsule: Capsule
    @Binding var selectCoral: Int?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let data = UserDefaults().data(forKey: "localCorals/\(selectCoral!)")!
        let arView = capsule.make(data: data)
        arView.session.delegate = context.coordinator
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    class Coordinator: NSObject, ARSessionDelegate {
        let parent: ARViewRepresentable
        
        init(_ parent: ARViewRepresentable) {
            self.parent = parent
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            parent.capsule.reconstruction(trackingState: frame.camera.trackingState)
        }
    }
}

private class Capsule: ARViewCapsule {
    private var localizing = true
    private var saveAnchor: SaveAnchor?
    
    func make(data: Data) -> ARView {
        let localCoral = try! NSKeyedUnarchiver.unarchivedObject(
            ofClass: LocalCoral.self, from: data)!
        let initialWorldMap = localCoral.armap
        if let first = initialWorldMap.anchors.first {
            saveAnchor = SaveAnchor(anchor: first)
        }
        return super.make(initialWorldMap: initialWorldMap)
    }
    
    /// ローカライズに成功した時に復元したオブジェクトを設置する
    func reconstruction(trackingState: ARCamera.TrackingState) {
        if localizing && trackingState == .normal {
            // フラグを折る
            localizing = false
            guard let saveAnchor = saveAnchor else { return }
            let anchorEntity = saveAnchor.generateAnchorEntity()
            // 1秒後にanchorEntityを追加
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.arView?.scene.addAnchor(anchorEntity)
            }
        }
    }
    
    override func discard() {
        super.discard()
        localizing = true
    }
}

struct ARLocalView_Previews: PreviewProvider {
    static var previews: some View {
        ARLocalView(selectCoral: .constant(0))
    }
}
