import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for Firestore operations
@MainActor
public final class FirestoreService {
    private let db: Firestore
    
    public init() {
        self.db = Firestore.firestore()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        // Use modern cache settings
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Collections
    
    private func userTransactionsCollection(userId: String) -> CollectionReference {
        db.collection(AppConstants.Firestore.users)
          .document(userId)
          .collection(AppConstants.Firestore.transactions)
    }
    
    private func userAccountsCollection(userId: String) -> CollectionReference {
        db.collection(AppConstants.Firestore.users)
          .document(userId)
          .collection(AppConstants.Firestore.accounts)
    }
    
    private func userBudgetCategoriesCollection(userId: String) -> CollectionReference {
        db.collection(AppConstants.Firestore.users)
          .document(userId)
          .collection(AppConstants.Firestore.budgetCategories)
    }
    
    private func usersCollection() -> CollectionReference {
        db.collection(AppConstants.Firestore.users)
    }

    // MARK: - Bug Reports
    
    public func submitBugReport(description: String, email: String?) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let doc = db.collection("bugReports").document()
        let data: [String: Any] = [
            "userId": userId,
            "email": email ?? "",
            "description": description,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await doc.setData(data)
    }
    
    // MARK: - Bulk Deletes (for disconnect/delete-account)
    
    public func deleteAllTransactions(userId: String) async throws {
        let collectionRef = userTransactionsCollection(userId: userId)
        let snapshot = try await collectionRef.getDocuments()
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }

    /// Fetches only user-authored (manual) transactions. Firestore is the
    /// source of truth for these; Plaid transactions are never persisted here.
    public func fetchManualTransactions() async throws -> [Transaction] {
        guard let userId = currentUserId else { return [] }
        let snapshot = try await userTransactionsCollection(userId: userId)
            .whereField("isManual", isEqualTo: true)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            (try? doc.data(as: FirestoreTransactionDTO.self))?.toEntity()
        }
    }

    /// Removes any non-manual transactions (Plaid/sample rows) that older builds
    /// wrote into Firestore. Manual transactions (`isManual == true`) are kept.
    public func purgeNonManualTransactions() async throws {
        guard let userId = currentUserId else { return }
        let snapshot = try await userTransactionsCollection(userId: userId)
            .whereField("isManual", isEqualTo: false)
            .getDocuments()
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }

    public func deleteAllBudgetCategories(userId: String) async throws {
        let collectionRef = userBudgetCategoriesCollection(userId: userId)
        let snapshot = try await collectionRef.getDocuments()
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }
    
    public func deleteUserDocument(userId: String) async throws {
        try await usersCollection().document(userId).delete()
    }
    
    public func deleteAllUserData(userId: String) async throws {
        // Attempt all deletes and collect failures so partial data removal is surfaced to the caller.
        var errors: [Error] = []
        do { try await deleteAllTransactions(userId: userId) } catch { errors.append(error) }
        do { try await deleteAllAccounts(userId: userId) } catch { errors.append(error) }
        do { try await deleteAllBudgetCategories(userId: userId) } catch { errors.append(error) }
        do { try await deleteUserDocument(userId: userId) } catch { errors.append(error) }
        if let first = errors.first {
            throw first
        }
    }
    
    // MARK: - Transactions
    
    public func saveTransaction(_ transaction: Transaction) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let dto = FirestoreTransactionDTO(from: transaction)
        let docRef = userTransactionsCollection(userId: userId).document(transaction.id)
        
        try docRef.setData(from: dto, merge: true)
    }
    
    public func syncTransactions(_ transactions: [Transaction]) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let batch = db.batch()
        let collection = userTransactionsCollection(userId: userId)
        
        for transaction in transactions {
            let dto = FirestoreTransactionDTO(from: transaction)
            let docRef = collection.document(transaction.id)
            
            // Note: Batch doesn't support setData(from:) directly without extensions
            // So we convert to dictionary for the batch
            if let data = try? Firestore.Encoder().encode(dto) {
                batch.setData(data, forDocument: docRef, merge: true)
            }
        }
        
        try await batch.commit()
    }
    
    public func fetchTransactions() async throws -> [Transaction] {
        try await fetchTransactions(limit: 100)
    }
    
    public func fetchTransactions(limit: Int) async throws -> [Transaction] {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await userTransactionsCollection(userId: userId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> Transaction? in
            let dto = try? doc.data(as: FirestoreTransactionDTO.self)
            return dto?.toEntity()
        }
    }
    
    public func updateTransaction(_ transaction: Transaction) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let docRef = userTransactionsCollection(userId: userId).document(transaction.id)
        
        // Only update specific fields if needed, or update the whole object
        let data: [String: Any] = [
            "name": transaction.name,
            "amount": transaction.amount,
            "category": transaction.category,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await docRef.updateData(data)
    }
    
    public func deleteTransaction(id: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let docRef = userTransactionsCollection(userId: userId).document(id)
        try await docRef.delete()
    }
    
    // MARK: - Accounts
    
    public func syncAccounts(_ accounts: [Account]) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let batch = db.batch()
        let collection = userAccountsCollection(userId: userId)
        
        for account in accounts {
            let docRef = collection.document(account.id)
            
            let data: [String: Any] = [
                "id": account.id,
                "name": account.name,
                "type": account.type,
                "balance": account.balance,
                "institutionName": account.institutionName,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            batch.setData(data, forDocument: docRef, merge: true)
        }
        
        try await batch.commit()
    }
    
    public func fetchAccounts() async throws -> [Account] {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await userAccountsCollection(userId: userId).getDocuments()
        
        return snapshot.documents.compactMap { doc -> Account? in
            guard
                let name = doc.data()["name"] as? String,
                let type = doc.data()["type"] as? String,
                let balance = doc.data()["balance"] as? Double,
                let institutionName = doc.data()["institutionName"] as? String
            else { return nil }
            
            return Account(
                id: doc.documentID,
                name: name,
                type: type,
                balance: balance,
                institutionName: institutionName,
                institutionLogo: nil,
                isPlaceholder: false
            )
        }
    }
    
    public func deleteAccount(id: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let docRef = userAccountsCollection(userId: userId).document(id)
        try await docRef.delete()
    }
    
    public func deleteAllAccounts() async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await deleteAllAccounts(userId: userId)
    }
    
    public func deleteAllAccounts(userId: String) async throws {
        let collectionRef = userAccountsCollection(userId: userId)
        let snapshot = try await collectionRef.getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }
    
    // MARK: - Budget Categories
    
    public func saveBudgetCategory(_ category: BudgetCategory) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let dto = FirestoreBudgetCategoryDTO(from: category)
        let docRef = userBudgetCategoriesCollection(userId: userId).document(category.id)
        
        try docRef.setData(from: dto, merge: true)
    }
    
    public func fetchBudgetCategories() async throws -> [BudgetCategory] {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await userBudgetCategoriesCollection(userId: userId).getDocuments()
        
        return snapshot.documents.compactMap { doc -> BudgetCategory? in
            let dto = try? doc.data(as: FirestoreBudgetCategoryDTO.self)
            return dto?.toEntity()
        }
    }
    
    public func deleteBudgetCategory(id: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let docRef = userBudgetCategoriesCollection(userId: userId).document(id)
        try await docRef.delete()
    }
    
    // MARK: - User Profile
    
    public func saveUserProfile(_ user: User) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let dto = FirestoreUserDTO(from: user)
        let docRef = usersCollection().document(userId)
        
        try docRef.setData(from: dto, merge: true)
    }
    
    public func fetchUserProfile() async throws -> User? {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let doc = try await usersCollection().document(userId).getDocument()
        let dto = try? doc.data(as: FirestoreUserDTO.self)
        return dto?.toEntity()
    }
    
    public func getMonthlyIncome() async throws -> Double {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let doc = try await usersCollection().document(userId).getDocument()
        let dto = try? doc.data(as: FirestoreUserDTO.self)
        return dto?.monthlyIncome ?? 0
    }
    
    public func saveMonthlyIncome(_ amount: Double) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let docRef = usersCollection().document(userId)
        try await docRef.updateData([
            "monthlyIncome": amount,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
}


