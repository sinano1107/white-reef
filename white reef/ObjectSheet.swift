//
//  ObjectSheet.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/14.
//

import SwiftUI
import RealityKit

struct ObjectSheet: View {
    let objectData: ObjectData
    @State private var model = ObjectData.sample.generate()
    
    var body: some View {
        VStack(alignment: .trailing) {
            Button(action: {
                setModel()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title)
            }
            .padding([.top, .trailing])
            OrbitView($model, radius: 1.5)
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
                ObjectSheet(objectData: ObjectData.sample)
            }
    }
}
