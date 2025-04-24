//
//  BiometricType.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//


enum BiometricType {
    case faceID
    case touchID
    case none
    
    var name: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "biometric authentication"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.fill"
        }
    }
}