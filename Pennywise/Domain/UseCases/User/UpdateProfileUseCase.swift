import Foundation

/// Use case to update user profile information
@MainActor
public class UpdateProfileUseCase {
    private let userRepository: UserRepository
    
    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    public func execute(
        displayName: String? = nil,
        monthlyIncome: Double? = nil,
        currency: String? = nil,
        notificationsEnabled: Bool? = nil
    ) async throws {
        try await userRepository.updateUserProfile(
            displayName: displayName,
            monthlyIncome: monthlyIncome,
            currency: currency,
            notificationsEnabled: notificationsEnabled
        )
    }
}
