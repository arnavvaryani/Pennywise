import Foundation

struct PlaidTransaction: Identifiable, Decodable {
    let id: String
    let name: String
    let amount: Double
    let date: Date
    let category: String
    let merchantName: String
    let accountId: String
    let pending: Bool
}

extension PlaidTransaction {
    // Maps Plaid's `/transactions/get` response. The decoder uses
    // `.convertFromSnakeCase`, so JSON keys arrive camelCased:
    // `transaction_id` -> `transactionId`, `merchant_name` -> `merchantName`,
    // `account_id` -> `accountId`. Plaid has no `id` field, which is why the
    // previous auto-synthesized decoder threw "Key 'id' not found".
    private enum CodingKeys: String, CodingKey {
        case transactionId
        case name
        case amount
        case date
        case category
        case merchantName
        case accountId
        case pending
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .transactionId)
        name = try c.decode(String.self, forKey: .name)
        amount = try c.decode(Double.self, forKey: .amount)
        date = try c.decode(Date.self, forKey: .date)

        // Plaid returns `category` as an array (general -> specific), e.g.
        // ["Travel", "Taxi"]. Older sample data used a single string. Support both.
        if let categories = try? c.decode([String].self, forKey: .category),
           let primary = categories.first {
            category = primary
        } else {
            category = (try? c.decode(String.self, forKey: .category)) ?? "Other"
        }

        // `merchant_name` is frequently null in Plaid; fall back to the name.
        merchantName = (try? c.decode(String.self, forKey: .merchantName)) ?? name
        accountId = try c.decode(String.self, forKey: .accountId)
        pending = (try? c.decode(Bool.self, forKey: .pending)) ?? false
    }
}
