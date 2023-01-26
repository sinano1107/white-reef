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

extension CGImagePropertyOrientation {
    /// iOSデバイスのカメラのネイティブセンサーの向きを考慮した、好ましい画像の表示方向です。
    init(cameraOrientation: UIDeviceOrientation) {
        switch cameraOrientation {
        case .portrait:
            self = .right
        case .portraitUpsideDown:
            self = .left
        case .landscapeLeft:
            self = .up
        case .landscapeRight:
            self = .down
        default:
            self = .right
        }
    }
}

enum CoralType {
    case local
    case global
}

/// GeospatialAPIのローカライゼーションステータス
enum LocalizationState: Int {
    case pretracking = 0
    case localizing = 1
    case localized = 2
    case failed = -1
    
    public var description: String {
        switch self {
        case .pretracking:
            return "プリトラッキング"
        case .localizing:
            return "ローカライズ中"
        case .localized:
            return "ローカライズ済み"
        case .failed:
            return "失敗"
        }
    }
}
