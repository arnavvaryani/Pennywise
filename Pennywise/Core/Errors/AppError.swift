import Foundation

public enum AppError: LocalizedError, Equatable {
    case network
    case unauthorized
    case notFound
    case validation(String)
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .network: return "Network error. Please check your connection."
        case .unauthorized: return "You are not authorized to perform this action."
        case .notFound: return "Requested resource was not found."
        case .validation(let msg): return msg
        case .unknown: return "Something went wrong. Please try again."
        }
    }
}





