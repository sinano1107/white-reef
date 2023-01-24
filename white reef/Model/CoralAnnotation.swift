//
//  CoralAnnotation.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/21.
//

import MapKit

class CoralAnnotation: MKPointAnnotation {
    private (set) var index: Int
    private (set) var type: CoralType
    
    enum CoralType {
        case local
        case global
    }
    
    init(index: Int, type: CoralType) {
        self.index = index
        self.type = type
        super.init()
    }
}
