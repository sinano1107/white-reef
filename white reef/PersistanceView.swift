//
//  PersistanceView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/06.
//

import SwiftUI
import RealityKit
import ARKit

/// configを設定しarVIewを起動します
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
    
    /// タップした場所にBoxを設置する
    private func onTapGesture(location: CGPoint) {
        // raycast
        guard let first = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first
        else { return }
        // anchor
        let anchor = generateTetrahedronAnchor(transform: first.worldTransform)
        putTetrahedron(anchor: anchor)
    }
    
    /// 四面体を設置する
    private func putTetrahedron(anchor: EntitySaveAnchor) {
        #if targetEnvironment(simulator)
        #else
        // entityの生成
        guard let mesh = anchor.generateMeshResource() else { return }
        let material = SimpleMaterial(color: .cyan, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        // ポジション・スケールを調整
        entity.setPosition([0, 0.3, 0], relativeTo: entity)
        entity.setScale([0.25, 0.25, 0.25], relativeTo: entity)
        // anchorEntityにentityを追加
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        // anchor, anchorEntityを追加
        arView.session.add(anchor: anchor)
        arView.scene.addAnchor(anchorEntity)
        #endif
    }
    
    /// ARWorldMapを保存する
    private func save() {
        arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else { return }
            do {
                arWorldMap = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
            } catch {
                fatalError("[エラー] worldMapの保存に失敗しました: \(error)")
            }
        }
    }
    
    /// ARWorldMapをロードしてBoxを復元する
    private func load() {
        do {
            // worldMapの読み込み
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: arWorldMap)
            else { throw ARError(.invalidWorldMap) }
            // リスタート
            setupARView(worldMap: worldMap)
            // EntitySaveAnchorの再構築
            for anchor in worldMap.anchors {
                guard let anchor = anchor as? EntitySaveAnchor else { continue }
                putTetrahedron(anchor: anchor)
            }
        } catch {
            fatalError("[エラー] worldMapの読み込みに失敗しました: \(error)")
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ARViewContainer(worldMappingStatus: $worldMappingStatus)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture(coordinateSpace: .global, perform: onTapGesture(location:))
            HStack {
                Button("セーブ") {
                    save()
                }
                Button("ロード") {
                    load()
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
        return ARView(frame: .zero)
        #else
        // arViewの初期化
        arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        // セットアップ
        setupARView()
        // LiDARによるポリゴンを可視化
        // arView.debugOptions.insert(.showSceneUnderstanding)
        // LiDARによるポリゴンでオブジェクトを隠す
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        arView.session.delegate = context.coordinator
        return arView
        #endif
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
