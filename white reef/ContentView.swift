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
    @AppStorage("ar-world-map") var arWorldMap = Data()
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
                    
                    let anchor = ARAnchor(name: "Box", transform: first.worldTransform)
                    
                    // これしないとAnchorEntity(anchor: anchor)は機能しない
                    arView.session.add(anchor: anchor)
                    let anchorEntity = AnchorEntity(anchor: anchor)
                    
                    let box = ModelEntity(mesh: .generateBox(size: 0.1), materials: [SimpleMaterial(color: .cyan, isMetallic: true)])
                    // boxはそのままだと埋まってしまうので、半分高さを足す
                    box.setPosition([0, 0.05, 0], relativeTo: box)
                    anchorEntity.addChild(box)
                    arView.scene.anchors.append(anchorEntity)
                    #endif
                }
            HStack {
                Button("セーブ") {
                    arView.session.getCurrentWorldMap { worldMap, error in
                        guard let map = worldMap else { return }
                        do {
                            arWorldMap = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                        } catch {
                            fatalError("worldMapの保存に失敗しました: \(error)")
                        }
                    }
                }
                Button("ロード") {
                    do {
                        guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: arWorldMap)
                        else { throw ARError(.invalidWorldMap) }
                        print(worldMap.anchors)
                    } catch {
                        fatalError("worldMapの読み込みに失敗しました: \(error)")
                    }
                }
                Text(worldMappingStatus?.description ?? "nil")
            }
            .padding()
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
        arView.debugOptions.insert(.showSceneUnderstanding)
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
