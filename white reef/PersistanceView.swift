////
////  PersistanceView.swift
////  white reef
////
////  Created by 長政輝 on 2023/01/06.
////
//
//import SwiftUI
//import RealityKit
//import ARKit
//
///// configを設定しarViewを起動します
//func runARView(worldMap: ARWorldMap? = nil) {
//    arView.scene.anchors.removeAll()
//    // config
//    let config = ARWorldTrackingConfiguration()
//    // LiDARによるシーンの再構築
//    config.sceneReconstruction = .mesh
//    // ワールドマップ
//    config.initialWorldMap = worldMap
//    // 環境テクスチャリング
//    config.environmentTexturing = .automatic
//    // run
//    arView.session.run(config, options: [
//        .resetTracking,
//        .removeExistingAnchors,
//        .resetSceneReconstruction
//    ])
//}
//
//struct PersistanceView: View {
//    static private let objectAnchorName = "ObjectAnchor"
//    let objectData: ObjectData
//    @AppStorage("ar-world-map") private var arWorldMap = Data()
//    @State private var worldMappingStatus: ARFrame.WorldMappingStatus?
//    @State private var cameraTrackingState: ARCamera.TrackingState?
//    @State private var saveAnchor: SaveAnchor = SaveAnchor.sample
//    @State private var object = ModelEntity()
//    
//    var body: some View {
//        ZStack(alignment: .bottomTrailing) {
//            ARViewContainer(
//                worldMappingStatus: $worldMappingStatus,
//                cameraTrackingStatus: $cameraTrackingState,
//                saveAnchor: $saveAnchor
//            )
//                .edgesIgnoringSafeArea(.all)
//                .onTapGesture(coordinateSpace: .global, perform: onTapGesture(location:))
//            HStack {
//                Button("セーブ") {
//                    save()
//                }
//                Button("ロード") {
//                    load()
//                }
//                Spacer()
//                VStack {
//                    Text(worldMappingStatus?.description ?? "nil")
//                    Text(cameraTrackingState?.description ?? "nil")
//                }
//            }
//            .padding()
//        }
//        .onDisappear {
//            arView.session.pause()
//        }
//    }
//    
//    /// タップした場所にObjectを設置する
//    private func onTapGesture(location: CGPoint) {
//        #if targetEnvironment(simulator)
//        #else
//        // raycast
//        guard let first = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first
//        else { return }
//        
//        // 既存のAnchorを削除
//        if let prevAnchor = arView.session.currentFrame?.anchors.first(where: {
//            $0.name == Self.objectAnchorName
//        }) { arView.session.remove(anchor: prevAnchor) }
//        
//        // anchor
//        let anchor = ARAnchor(name: Self.objectAnchorName, transform: first.worldTransform)
//        // object
//        object = objectData.generate(moveTheOriginDown: true)
//        object.setScale([0.5, 0.5, 0.5], relativeTo: object)
//        // anchorEntity
//        let anchorEntity = AnchorEntity(anchor: anchor)
//        anchorEntity.addChild(object)
//        // session sceneに追加
//        arView.session.add(anchor: anchor)
//        arView.scene.addAnchor(anchorEntity)
//        #endif
//    }
//    
//    /// ARWorldMapを保存する
//    private func save() {
//        arView.session.getCurrentWorldMap { worldMap, error in
//            guard let map = worldMap else { print("[エラー] mapがありません"); return }
//            guard let objectAnchor = map.anchors.first(where: { $0.name == Self.objectAnchorName })
//            else { print("[エラー] objectAnchorがありません"); return }
//            map.anchors.removeAll()
//            map.anchors.append(SaveAnchor(objectData: objectData, scale: object.scale, transform: objectAnchor.transform))
//            do {
//                arWorldMap = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
//            } catch {
//                fatalError("[エラー] worldMapの保存に失敗しました: \(error)")
//            }
//        }
//    }
//    
//    /// ARWorldMapをロードしてBoxを復元する
//    private func load() {
//        do {
//            // worldMapの読み込み
//            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: arWorldMap)
//            else { throw ARError(.invalidWorldMap) }
//            // リスタート
//            runARView(worldMap: worldMap)
//            // saveAnchorを保存
//            saveAnchor = worldMap.anchors.first as! SaveAnchor
//        } catch {
//            fatalError("[エラー] worldMapの読み込みに失敗しました: \(error)")
//        }
//    }
//}
//
//private struct ARViewContainer: UIViewRepresentable {
//    @Binding var worldMappingStatus: ARFrame.WorldMappingStatus?
//    @Binding var cameraTrackingStatus: ARCamera.TrackingState?
//    @Binding var saveAnchor: SaveAnchor
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    func makeUIView(context: Context) -> ARView {
//        #if targetEnvironment(simulator)
//        return ARView(frame: .zero)
//        #else
//        // arViewの初期化
//        arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
//        runARView()
//        // LiDARによるポリゴンを可視化
//        // arView.debugOptions.insert(.showSceneUnderstanding)
//        // LiDARによるポリゴンでオブジェクトを隠す
//        arView.environment.sceneUnderstanding.options.insert(.occlusion)
//        arView.session.delegate = context.coordinator
//        return arView
//        #endif
//    }
//    
//    func updateUIView(_ arView: ARView, context: Context) {}
//    
//    class Coordinator: NSObject, ARSessionDelegate {
//        var parent: ARViewContainer
//        var relocalizing = false
//        
//        init(_ parent: ARViewContainer) {
//            self.parent = parent
//        }
//        
//        func session(_ session: ARSession, didUpdate frame: ARFrame) {
//            parent.worldMappingStatus = frame.worldMappingStatus
//            parent.cameraTrackingStatus = frame.camera.trackingState
//            
//            if frame.camera.trackingState == .limited(.relocalizing) {
//                // 再ローカライズに移ったらフラグを立てる
//                relocalizing = true
//            } else if relocalizing && frame.camera.trackingState == .normal {
//                // ローカライズ完了
//                // フラグを折る
//                relocalizing = false
//                // 1秒後にEntitySaveAnchorの再構築
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                    let anchor = self.parent.saveAnchor
//                    let anchorEntity = anchor.generateAnchorEntity()
//                    arView.scene.addAnchor(anchorEntity)
//                }
//            }
//        }
//    }
//}
//
//struct PersistanceView_Previews: PreviewProvider {
//    static var previews: some View {
//        PersistanceView(objectData: ObjectData.sample)
//    }
//}
