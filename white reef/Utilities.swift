//
//  Utilities.swift
//  white reef
//
//  Created by 長政輝 on 2022/12/31.
//

import ARKit

extension ARFrame.WorldMappingStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notAvailable:
            return "Not Available（利用不可）"
        case .limited:
            return "Limited（限定的）"
        case .extending:
            return "Extending（拡張中）"
        case .mapped:
            return "Mapped（マッピング完了）"
        @unknown default:
            return "Unknown（不明）"
        }
    }
}

//extension ARFrame.WorldMappingStatus: CustomStringConvertible {
//    public var description: String {
//        switch self {
//        case .notAvailable:
//            return "Not Available"
//        case .limited:
//            return "Limited"
//        case .extending:
//            return "Extending"
//        case .mapped:
//            return "Mapped"
//        @unknown default:
//            return "Unknown"
//        }
//    }
//}
