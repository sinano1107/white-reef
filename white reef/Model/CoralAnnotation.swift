//
//  CoralAnnotation.swift
//  white reef
//
//  Created by 長政輝 on 2023/01/21.
//

import MapKit

class CoralAnnotation: MKPointAnnotation {
    var index: Int
    
    init(index: Int) {
        self.index = index
        super.init()
    }
}
