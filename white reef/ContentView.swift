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
    @State var tapLocation: CGPoint?
    
    var body: some View {
        ARViewContainer(tapLocation: tapLocation)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture(coordinateSpace: .global) { location in tapLocation = location }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let tapLocation: CGPoint?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        // LiDARによるポリゴンを可視化
        // arView.debugOptions.insert(.showSceneUnderstanding)
        // LiDARによるポリゴンでオブジェクトを隠す
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        return arView
    }
    
    func updateUIView(_ arView: ARView, context: Context) {
        guard let tapLocation = tapLocation else { return }
        // raycast
        let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any)
        guard let first = results.first else { return }
        let anchor = AnchorEntity(raycastResult: first)
        let box = ModelEntity(mesh: .generateBox(size: 0.1), materials: [SimpleMaterial(color: .cyan, isMetallic: true)])
        // boxはそのままだと埋まってしまうので、半分高さを足す
        box.setPosition([0, 0.05, 0], relativeTo: box)
        anchor.addChild(box)
        arView.scene.anchors.append(anchor)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
