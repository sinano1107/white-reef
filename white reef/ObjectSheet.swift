//
//  ObjectSheet.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/14.
//

import SwiftUI
import RealityKit

struct ObjectSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var model = ObjectData.sample.generate()
    @Binding var arIsPresented: Bool
    let objectData: ObjectData
    
    var body: some View {
        ZStack {
            OrbitView($model, radius: 1.5)
                .ignoresSafeArea()
            VStack {
                HStack {
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
