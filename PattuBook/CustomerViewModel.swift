class CustomerViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var customers: [Customer] = []
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .mostDue
    
    enum SortOrder {
        case mostDue, recentlyUpdated, nameAscending
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchCustomers()
    }
    
    var filteredCustomers: [Customer] {
        var result = customers
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.phone.contains(searchText)
            }
        }
        
        switch sortOrder {
        case .mostDue:
            result.sort { $0.totalDue > $1.totalDue }
        case .recentlyUpdated:
            result.sort { $0.lastUpdated > $1.lastUpdated }
        case .nameAscending:
            result.sort { $0.name < $1.name }
        }
        
        return result
    }
    
    var totalOutstanding: Double {
        customers.reduce(0) { $0 + $1.totalDue }
    }
    
    func fetchCustomers() {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Customer.name, ascending: true)]
        
        do {
            customers = try context.fetch(request)
        } catch {
            print("Error fetching customers: \(error)")
        }
    }
    
    func addCustomer(name: String, phone: String, address: String?, photoData: Data?) {
        let customer = Customer(context: context)
        customer.id = UUID()
        customer.name = name
        customer.phone = phone
        customer.address = address
        customer.photoData = photoData
        customer.totalDue = 0
        customer.createdDate = Date()
        customer.lastUpdated = Date()
        
        PersistenceController.shared.save()
        fetchCustomers()
    }
    
    func updateCustomer(_ customer: Customer, name: String, phone: String, address: String?, photoData: Data?) {
        customer.name = name
        customer.phone = phone
        customer.address = address
        if let photoData = photoData {
            customer.photoData = photoData
        }
        customer.lastUpdated = Date()
        
        PersistenceController.shared.save()
        fetchCustomers()
    }
    
    func deleteCustomer(_ customer: Customer) {
        context.delete(customer)
        PersistenceController.shared.save()
        fetchCustomers()
    }
}
