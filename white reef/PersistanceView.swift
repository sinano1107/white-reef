//
//  PersistanceView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/06.
//

import SwiftUI
import RealityKit
import ARKit

private var arView = ARView(frame: .zero)

func setupARView(worldMap: ARWorldMap? = nil) {
    // config
    let config = ARWorldTrackingConfiguration()
    // LiDARによるシーンの再構築
    config.sceneReconstruction = .mesh
    // ワールドマップ
    config.initialWorldMap = worldMap
    // 環境テクスチャリング
    config.environmentTexturing = .automatic
    // run
    arView.session.run(config, options: [
        .resetTracking,
        .removeExistingAnchors,
        .resetSceneReconstruction
    ])
}

struct PersistanceView: View {
    @AppStorage("ar-world-map") private var arWorldMap = Data()
    @State private var worldMappingStatus: ARFrame.WorldMappingStatus?
    
    private func putBox(anchor: ARAnchor) {
#if targetEnvironment(simulator)
#else
        // anchorEntity
        let anchorEntity = AnchorEntity(anchor: anchor)

        // boxEntity
        let boxMesh = MeshResource.generateBox(size: 0.1)
        let boxMaterial = SimpleMaterial(color: .cyan, isMetallic: true)
        let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])

        // ボックスが埋まらないようにする
        boxEntity.setPosition([0, 0.05, 0], relativeTo: boxEntity)

        // add & append
        anchorEntity.addChild(boxEntity)
        arView.scene.addAnchor(anchorEntity)
#endif
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ARViewContainer(worldMappingStatus: $worldMappingStatus)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture(coordinateSpace: .global) { location in
                    // raycast
                    guard let first = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first
                    else { return }

                    // 古いBoxAnchorを削除
                    if let prevBoxAnchor = arView.session.currentFrame?.anchors.first(where: { $0.name == "Box" }) {
                        arView.session.remove(anchor: prevBoxAnchor)
                    }

                    // 新しいBoxAnchorを生成
                    let anchor = ARAnchor(name: "Box", transform: first.worldTransform)
                    // これしないとAnchorEntity(anchor: anchor)は機能しない
                    arView.session.add(anchor: anchor)
                    // ボックスを設置
                    putBox(anchor: anchor)
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

                        // リスタート
                        setupARView(worldMap: worldMap)

                        // ボックスを復元
                        guard let anchor = worldMap.anchors.first(where: { $0.name == "Box" })
                        else { return }
                        putBox(anchor: anchor)
                    } catch {
                        fatalError("worldMapの読み込みに失敗しました: \(error)")
                    }
                }
                Spacer()
                Text(worldMappingStatus?.description ?? "nil")
            }
            .padding()
        }
        .onDisappear {
            arView.session.pause()
        }
    }
}

private struct ARViewContainer: UIViewRepresentable {
    @Binding var worldMappingStatus: ARFrame.WorldMappingStatus?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
#if targetEnvironment(simulator)
#else
        // arViewの初期化
        arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        // セットアップ
        setupARView()
        // LiDARによるポリゴンを可視化
        // arView.debugOptions.insert(.showSceneUnderstanding)
        // LiDARによるポリゴンでオブジェクトを隠す
        arView.environment.sceneUnderstanding.options.insert(.occlusion)

        // Coordinator
        arView.session.delegate = context.coordinator
#endif
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

struct PersistanceView_Previews: PreviewProvider {
    static var previews: some View {
        PersistanceView()
    }
}
