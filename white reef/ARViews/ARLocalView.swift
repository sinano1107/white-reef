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
    @Binding var coral: LocalCoral?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ARViewRepresentable(capsule: capsule, coral: coral)
                    .ignoresSafeArea()
                    .onDisappear {
                        capsule.discard()
                    }
                Group {
                    if coral != nil {
                        Image(uiImage: UIImage(data: coral!.imageData)!)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: geometry.size.width * 0.3,
                                   maxHeight: geometry.size.height * 0.5,
                                   alignment: .topLeading)
                    } else {
                        Rectangle()
                            .foregroundColor(.blue)
                            .frame(width: geometry.size.width * 0.3,
                                   height: geometry.size.height * 0.3)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ARViewRepresentable: UIViewRepresentable {
    let capsule: Capsule
    let coral: LocalCoral?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
#if targetEnvironment(simulator)
        return ARView(frame: .zero)
#else
        let arView = capsule.make(coral: coral!)
        arView.session.delegate = context.coordinator
        return arView
#endif
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
    
    func make(coral: LocalCoral) -> ARView {
        let initialWorldMap = coral.armap
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
        ARLocalView(coral: .constant(nil))
    }
}
