//
//  ContentView.swift
//  white reef
//
//  Created by 長政輝 on 2022/12/29.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    let arView = ARView(frame: .zero)
    @State var worldMappingStatus: ARFrame.WorldMappingStatus?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ARViewContainer(arView: arView, worldMappingStatus: $worldMappingStatus)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture(coordinateSpace: .global) { location in
                    #if targetEnvironment(simulator)
                    #else
                    // raycast
                    let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
                    guard let first = results.first else { return }
                    let anchor = AnchorEntity(raycastResult: first)
                    let box = ModelEntity(mesh: .generateBox(size: 0.1), materials: [SimpleMaterial(color: .cyan, isMetallic: true)])
                    // boxはそのままだと埋まってしまうので、半分高さを足す
                    box.setPosition([0, 0.05, 0], relativeTo: box)
                    anchor.addChild(box)
                    arView.scene.anchors.append(anchor)
                    #endif
                }
            Text(worldMappingStatus?.description ?? "nil")
                .padding(18)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let arView: ARView
    @Binding var worldMappingStatus: ARFrame.WorldMappingStatus?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        // LiDARによるポリゴンを可視化
        // arView.debugOptions.insert(.showSceneUnderstanding)
        // LiDARによるポリゴンでオブジェクトを隠す
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        // Coordinator
        arView.session.delegate = context.coordinator
        return arView
    }
    
    func updateUIView(_ arView: ARView, context: Context) {}
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            parent.worldMappingStatus = frame.worldMappingStatus
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
