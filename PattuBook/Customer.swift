import CoreData

@objc(Customer)
public class Customer: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var phone: String
    @NSManaged public var address: String?
    @NSManaged public var photoData: Data?
    @NSManaged public var totalDue: Double
    @NSManaged public var createdDate: Date
    @NSManaged public var lastUpdated: Date
    @NSManaged public var transactions: NSSet?
    
    public var transactionsArray: [Transaction] {
        let set = transactions as? Set<Transaction> ?? []
        return set.sorted { $0.date > $1.date }
    }
}

@objc(Transaction)
public class Transaction: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var type: String // "credit" or "payment"
    @NSManaged public var amount: Double
    @NSManaged public var date: Date
    @NSManaged public var note: String?
    @NSManaged public var customer: Customer?
}
