//
//  OrbitView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/13.
//

import SwiftUI
import RealityKit

struct OrbitView: View {
    @State private var command: ARViewContainer.Command = .none
    @Binding var model: ModelEntity
    let radius: Float
    
    init(_ model: Binding<ModelEntity>, radius: Float = 6) {
        self._model = model
        self.radius = radius
    }
    
    var body: some View {
        ARViewContainer(command: $command, entity: model, firstRadius: radius)
            .gesture(MagnificationGesture()
                .onChanged({ value in command = .handleMagnificationChanged(value: Float(value))})
                .onEnded({ _ in command = .handleMagnificationEnded }))
    }
}

private struct ARViewContainer: UIViewRepresentable {
    @Binding var command: Command
    let entity: Entity
    let firstRadius: Float
    
    func makeCoordinator() -> Coordinator {
        Coordinator(firstRadius: firstRadius)
    }
    
    func makeUIView(context: Context) -> ARView {
        context.coordinator.addGestures()
        return context.coordinator.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // command
        switch command {
        case let .handleMagnificationChanged(value):
            context.coordinator.handleMagnificationChanged(value: value)
        case .handleMagnificationEnded:
            context.coordinator.handleMagnificationEnded()
        case .none: break
        }
        
        // entityが変化した時に切り替える
        // commandが送られてきても同じentityならばaddChildされないので大丈夫
        let anchor = uiView.scene.anchors.first!
        anchor.addChild(entity)
        if anchor.children.count == 3 {
            anchor.children.remove(at: 1)
        }
    }
    
    class Coordinator: NSObject {
#if targetEnvironment(simulator)
        let arView = ARView(frame: .zero)
#else
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
#endif
        let camera = PerspectiveCamera()
        
        let dragspeed: Float = 0.01
        private var radius: Float
        private var magnify_start_radius: Float
        private var rotationAngle: Float = 0
        private var inclinationAngle: Float = 0
        private var dragstart_rotation: Float = 0
        private var dragstart_inclination: Float = 0
        
        init(firstRadius: Float) {
            self.radius = firstRadius
            self.magnify_start_radius = firstRadius
            // 背景色を透明に設定
            arView.environment.background = .color(.clear)
            // アンカーを生成
            let anchor = AnchorEntity(world: .zero)
            // カメラのポジションを変更
            camera.position = [0, 0, firstRadius]
            // アンカーにカメラを追加
            anchor.addChild(camera)
            // シーンにアンカーを追加
            arView.scene.addAnchor(anchor)
        }
        
        func addGestures() {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(sender:)))
            arView.addGestureRecognizer(panGesture)
        }
        
        @MainActor @objc func handlePan(sender: UIPanGestureRecognizer) {
            // 終了時
            if sender.state == .ended {
                dragstart_rotation = rotationAngle
                dragstart_inclination = inclinationAngle
                return
            }
            /// パンのスタートからの移動距離
            let res = sender.translation(in: arView)
            rotationAngle = dragstart_rotation - Float(res.x) * dragspeed
            inclinationAngle = dragstart_inclination - Float(res.y) * dragspeed
            // 傾きが90度以下、-90度以上になるようにクランプ
            if inclinationAngle > Float.pi / 2 {
                inclinationAngle = Float.pi / 2
            } else if inclinationAngle < -Float.pi / 2 {
                inclinationAngle = -Float.pi / 2
            }
            // アップデート
            updateCamera()
        }
        
        /// カメラを更新
        @MainActor func updateCamera() {
            let translationTransform = Transform(
                scale: .one,
                rotation: simd_quatf(),
                translation: SIMD3<Float>(0, 0, radius))
            let combinedRotationTransform: Transform = .init(
                pitch: inclinationAngle,
                yaw: rotationAngle,
                roll: 0)
            let computed_transform = matrix_identity_float4x4 * combinedRotationTransform.matrix * translationTransform.matrix
            camera.transform = Transform(matrix: computed_transform)
        }
        
        /// 拡大・縮小
        @MainActor func handleMagnificationChanged(value: Float) {
            radius = magnify_start_radius / value
            updateCamera()
        }
        
        /// 拡大・縮小終了
        func handleMagnificationEnded() {
            magnify_start_radius = radius
        }
    }
    
    enum Command {
        case handleMagnificationChanged(value: Float)
        case handleMagnificationEnded
        case none
    }
}

struct OrbitView_Previews: PreviewProvider {
    @State static var model = ModelEntity(mesh: .generateBox(size: 1), materials: [SimpleMaterial()])
    
    static var previews: some View {
        OrbitView($model)
    }
}
