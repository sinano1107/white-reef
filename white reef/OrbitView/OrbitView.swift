//
//  OrbitView.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/13.
//

import SwiftUI
import RealityKit

struct OrbitView: View {
    @Binding var model: ModelEntity
    
    private let camera = PerspectiveCamera()
    private let dragspeed: Float = 0.01
    
    @State private var radius: Float
    @State private var magnify_start_radius: Float
    @State private var rotationAngle: Float = 0
    @State private var inclinationAngle: Float = 0
    @State private var dragstart_rotation: Float = 0
    @State private var dragstart_inclination: Float = 0
    
    init(_ model: Binding<ModelEntity>, radius: Float = 6) {
        self._model = model
        self.radius = radius
        self.magnify_start_radius = radius
    }
    
    private struct ARViewContainer: UIViewRepresentable {
        let entity: Entity
        let camera: PerspectiveCamera
        let firstRadius: Float
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        func makeUIView(context: Context) -> ARView {
            context.coordinator.arView
        }
        
        func updateUIView(_ uiView: ARView, context: Context) {
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
            let parent: ARViewContainer
            let camera = PerspectiveCamera()
            
            init(_ parent: ARViewContainer) {
                self.parent = parent
                // 背景色を透明に設定
                arView.environment.background = .color(.clear)
                // アンカーを生成
                let anchor = AnchorEntity(world: .zero)
                // カメラのポジションを変更
                camera.position = [0, 0, parent.firstRadius]
                // アンカーにカメラを追加
                anchor.addChild(camera)
                // シーンにアンカーを追加
                arView.scene.addAnchor(anchor)
            }
        }
    }
    
    @MainActor private func updateCamera() {
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
    
    var body: some View {
        ARViewContainer(entity: model, camera: camera, firstRadius: radius)
            // ドラッグ
            .gesture(DragGesture().onChanged({ value in
                let deltaX = Float(value.location.x - value.startLocation.x)
                let deltaY = Float(value.location.y - value.startLocation.y)
                rotationAngle = dragstart_rotation - deltaX * dragspeed
                inclinationAngle = dragstart_inclination - deltaY * dragspeed
                // 傾きが90度以下、-90度以上になるようにクランプ
                if inclinationAngle > Float.pi / 2 {
                    inclinationAngle = Float.pi / 2
                } else if inclinationAngle < -Float.pi / 2 {
                    inclinationAngle = -Float.pi / 2
                }
                
                updateCamera()
            }).onEnded({ _ in
                dragstart_rotation = rotationAngle
                dragstart_inclination = inclinationAngle
            }))
            // 拡大・縮小
            .gesture(MagnificationGesture().onChanged({ value in
                radius = magnify_start_radius / Float(value)
                updateCamera()
            }).onEnded({ _ in
                magnify_start_radius = radius
            }))
    }
}

struct OrbitView_Previews: PreviewProvider {
    @State static var model = ModelEntity(mesh: .generateBox(size: 1), materials: [SimpleMaterial()])
    
    static var previews: some View {
        OrbitView($model)
    }
}
