//
//  ObjectSheet.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/14.
//

import SwiftUI
import RealityKit

struct ObjectSheet: View {
    @AppStorage("localCoralCount") private var localCoralCount = 0
    @AppStorage("globalCoralCount") private var globalCoralCount = 0
    @Environment(\.dismiss) var dismiss
    @State private var model = ObjectData.sample.generate()
    @Binding var arIsPresented: Bool
    let objectData: ObjectData
    
    var body: some View {
        ZStack {
            OrbitView(entity: model, firstRadius: 1.5)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Button("リセット") {
                        localCoralCount = 0
                        globalCoralCount = 0
                    }
                    Spacer()
                    Button(action: {
                        setModel()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title)
                    }
                }
                Spacer()
                Button("choose and place") {
                    dismiss()
                    arIsPresented.toggle()
                }
                .font(.title3)
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            setModel()
        }
    }
    
    /// modelを設定
    func setModel() {
        let (positions, normals) = generateRandomObject()
        objectData.update(positions: positions, normals: normals)
        model = objectData.generate()
    }
}

struct ObjectSheet_Previews: PreviewProvider {
    static var previews: some View {
        VStack {}
            .sheet(isPresented: .constant(true)) {
                ObjectSheet(arIsPresented: .constant(false), objectData: ObjectData.sample)
            }
    }
}
