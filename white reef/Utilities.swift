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

extension ARCamera.TrackingState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .normal:
            return "Normal（ノーマル）"
        case .notAvailable:
            return "Not Availbale（入手不可能）"
        case .limited(.initializing):
            return "Initializing（初期化中）"
        case .limited(.excessiveMotion):
            return "Excessive Motion（過度な動作）"
        case .limited(.insufficientFeatures):
            return "Insufficient Features（特徴点の不足）"
        case .limited(.relocalizing):
            return "Relocalizing（再ローカライズ中）"
        case .limited:
            return "Unspecified Reason（理由なし）"
        }
    }
}
