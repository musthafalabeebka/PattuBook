// MARK: - App Entry Point
import SwiftUI

@main
struct PattuBookApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appLockManager = AppLockManager()
    
    var body: some Scene {
        WindowGroup {
            if appLockManager.isUnlocked {
                HomeView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(appLockManager)
            } else {
                PINLockView()
                    .environmentObject(appLockManager)
            }
        }
    }
}

// MARK: - Core Data Models
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

// MARK: - Persistence Controller
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PattuBook")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}

// MARK: - Customer ViewModel
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

// MARK: - Transaction ViewModel
class TransactionViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func addTransaction(to customer: Customer, type: String, amount: Double, note: String?) {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.type = type
        transaction.amount = amount
        transaction.date = Date()
        transaction.note = note
        transaction.customer = customer
        
        // Update customer balance
        if type == "credit" {
            customer.totalDue += amount
        } else if type == "payment" {
            customer.totalDue -= amount
        }
        customer.lastUpdated = Date()
        
        PersistenceController.shared.save()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        guard let customer = transaction.customer else { return }
        
        // Reverse the balance update
        if transaction.type == "credit" {
            customer.totalDue -= transaction.amount
        } else if transaction.type == "payment" {
            customer.totalDue += transaction.amount
        }
        customer.lastUpdated = Date()
        
        context.delete(transaction)
        PersistenceController.shared.save()
    }
}

// MARK: - App Lock Manager
class AppLockManager: ObservableObject {
    @Published var isUnlocked = false
    @AppStorage("isPINEnabled") var isPINEnabled = false
    @AppStorage("userPIN") private var userPIN = ""
    
    init() {
        isUnlocked = !isPINEnabled
    }
    
    func setupPIN(_ pin: String) {
        userPIN = pin
        isPINEnabled = true
    }
    
    func removePIN() {
        userPIN = ""
        isPINEnabled = false
        isUnlocked = true
    }
    
    func verifyPIN(_ pin: String) -> Bool {
        if pin == userPIN {
            isUnlocked = true
            return true
        }
        return false
    }
}

// MARK: - Localization Helper
enum LocalizedString {
    static func get(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

// MARK: - PDF Export Helper
import PDFKit

class PDFExportHelper {
    static func generateCustomerStatement(customer: Customer) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Pattu Book",
            kCGPDFContextAuthor: "Shop Owner",
            kCGPDFContextTitle: "Customer Statement - \(customer.name)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            let title = "Customer Statement"
            title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Customer Info
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14)
            ]
            "Name: \(customer.name)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: infoAttributes)
            yPosition += 20
            "Phone: \(customer.phone)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: infoAttributes)
            yPosition += 20
            "Total Due: ₹\(String(format: "%.2f", customer.totalDue))".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: infoAttributes)
            yPosition += 40
            
            // Transactions
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12)
            ]
            "Date\t\tType\t\tAmount\t\tNote".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: headerAttributes)
            yPosition += 25
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            
            for transaction in customer.transactionsArray {
                let dateStr = dateFormatter.string(from: transaction.date)
                let typeStr = transaction.type.capitalized
                let amountStr = String(format: "%.2f", transaction.amount)
                let noteStr = transaction.note ?? "-"
                
                let line = "\(dateStr)\t\(typeStr)\t₹\(amountStr)\t\(noteStr)"
                line.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: infoAttributes)
                yPosition += 20
                
                if yPosition > pageHeight - 50 {
                    context.beginPage()
                    yPosition = 50
                }
            }
        }
        
        return data
    }
}

// MARK: - Views

// Home View
struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: CustomerViewModel
    @State private var showingAddCustomer = false
    @State private var showingSettings = false
    @State private var showingReports = false
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: CustomerViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary Card
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString.get("total_outstanding"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("₹\(String(format: "%.2f", viewModel.totalOutstanding))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(viewModel.totalOutstanding > 0 ? .red : .green)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Text(LocalizedString.get("total_customers"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.customers.count)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Search and Filter
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(LocalizedString.get("search_customers"), text: $viewModel.searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                Picker(LocalizedString.get("sort_by"), selection: $viewModel.sortOrder) {
                    Text(LocalizedString.get("most_due")).tag(CustomerViewModel.SortOrder.mostDue)
                    Text(LocalizedString.get("recently_updated")).tag(CustomerViewModel.SortOrder.recentlyUpdated)
                    Text(LocalizedString.get("name")).tag(CustomerViewModel.SortOrder.nameAscending)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Customer List
                List {
                    ForEach(viewModel.filteredCustomers) { customer in
                        NavigationLink(destination: CustomerDetailView(customer: customer)) {
                            CustomerRowView(customer: customer)
                        }
                    }
                    .onDelete(perform: deleteCustomers)
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle(LocalizedString.get("app_name"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingReports = true }) {
                        Image(systemName: "chart.bar.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCustomer = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomer) {
                AddCustomerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingReports) {
                ReportView()
            }
            .onAppear {
                viewModel.fetchCustomers()
            }
        }
    }
    
    private func deleteCustomers(offsets: IndexSet) {
        withAnimation {
            offsets.map { viewModel.filteredCustomers[$0] }.forEach(viewModel.deleteCustomer)
        }
    }
}

// Customer Row View
struct CustomerRowView: View {
    let customer: Customer
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image or Initial
            if let photoData = customer.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Text(customer.name.prefix(1).uppercased())
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(customer.name)
                    .font(.headline)
                Text(customer.phone)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(String(format: "%.2f", customer.totalDue))")
                    .font(.headline)
                    .foregroundColor(customer.totalDue > 0 ? .red : .green)
                Text(customer.totalDue > 0 ? LocalizedString.get("due") : LocalizedString.get("clear"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Add Customer View
struct AddCustomerView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CustomerViewModel
    
    @State private var name = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedString.get("customer_info"))) {
                    TextField(LocalizedString.get("name"), text: $name)
                    TextField(LocalizedString.get("phone"), text: $phone)
                        .keyboardType(.phonePad)
                    TextField(LocalizedString.get("address_optional"), text: $address)
                }
                
                Section(header: Text(LocalizedString.get("photo_optional"))) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    Button(LocalizedString.get("select_photo")) {
                        showingImagePicker = true
                    }
                }
            }
            .navigationTitle(LocalizedString.get("add_customer"))
            .navigationBarItems(
                leading: Button(LocalizedString.get("cancel")) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(LocalizedString.get("save")) {
                    let photoData = selectedImage?.jpegData(compressionQuality: 0.8)
                    viewModel.addCustomer(
                        name: name,
                        phone: phone,
                        address: address.isEmpty ? nil : address,
                        photoData: photoData
                    )
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty || phone.isEmpty)
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
}

// Customer Detail View
struct CustomerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var customer: Customer
    @StateObject private var transactionVM: TransactionViewModel
    @State private var showingAddTransaction = false
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    
    init(customer: Customer) {
        self.customer = customer
        _transactionVM = StateObject(wrappedValue: TransactionViewModel(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        List {
            Section(header: Text(LocalizedString.get("balance"))) {
                HStack {
                    Text(LocalizedString.get("total_due"))
                        .font(.headline)
                    Spacer()
                    Text("₹\(String(format: "%.2f", customer.totalDue))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(customer.totalDue > 0 ? .red : .green)
                }
            }
            
            Section(header: HStack {
                Text(LocalizedString.get("transactions"))
                Spacer()
                Button(action: { showingAddTransaction = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }) {
                if customer.transactionsArray.isEmpty {
                    Text(LocalizedString.get("no_transactions"))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(customer.transactionsArray) { transaction in
                        TransactionRowView(transaction: transaction)
                    }
                }
            }
        }
        .navigationTitle(customer.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportPDF) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(customer: customer, transactionVM: transactionVM)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
    }
    
    private func exportPDF() {
        pdfData = PDFExportHelper.generateCustomerStatement(customer: customer)
        showingShareSheet = true
    }
}

// Transaction Row View
struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type == "credit" ? LocalizedString.get("credit") : LocalizedString.get("payment"))
                    .font(.headline)
                    .foregroundColor(transaction.type == "credit" ? .red : .green)
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("₹\(String(format: "%.2f", transaction.amount))")
                .font(.headline)
                .foregroundColor(transaction.type == "credit" ? .red : .green)
        }
        .padding(.vertical, 4)
    }
}

// Add Transaction View
struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    let customer: Customer
    @ObservedObject var transactionVM: TransactionViewModel
    
    @State private var type = "credit"
    @State private var amount = ""
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedString.get("transaction_type"))) {
                    Picker(LocalizedString.get("type"), selection: $type) {
                        Text(LocalizedString.get("credit")).tag("credit")
                        Text(LocalizedString.get("payment")).tag("payment")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text(LocalizedString.get("details"))) {
                    TextField(LocalizedString.get("amount"), text: $amount)
                        .keyboardType(.decimalPad)
                    TextField(LocalizedString.get("note_optional"), text: $note)
                }
            }
            .navigationTitle(LocalizedString.get("add_transaction"))
            .navigationBarItems(
                leading: Button(LocalizedString.get("cancel")) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(LocalizedString.get("save")) {
                    if let amountValue = Double(amount) {
                        transactionVM.addTransaction(
                            to: customer,
                            type: type,
                            amount: amountValue,
                            note: note.isEmpty ? nil : note
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(amount.isEmpty)
            )
        }
    }
}

// Report View
struct ReportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @State private var period: Period = .thisMonth
    @State private var totalCredits: Double = 0
    @State private var totalPayments: Double = 0
    
    enum Period: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Picker("Period", selection: $period) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                VStack(spacing: 16) {
                    ReportCardView(
                        title: LocalizedString.get("total_credits"),
                        amount: totalCredits,
                        color: .red,
                        icon: "arrow.up.circle.fill"
                    )
                    
                    ReportCardView(
                        title: LocalizedString.get("total_payments"),
                        amount: totalPayments,
                        color: .green,
                        icon: "arrow.down.circle.fill"
                    )
                    
                    ReportCardView(
                        title: LocalizedString.get("net_change"),
                        amount: totalCredits - totalPayments,
                        color: .blue,
                        icon: "equal.circle.fill"
                    )
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle(LocalizedString.get("reports"))
            .navigationBarItems(trailing: Button(LocalizedString.get("done")) {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear(perform: calculateReports)
            .onChange(of: period) { _ in calculateReports() }
        }
    }
    
    private func calculateReports() {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        
        switch period {
        case .today:
            startDate = calendar.startOfDay(for: now)
        case .thisWeek:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        case .thisMonth:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        }
        
        request.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        
        do {
            let transactions = try viewContext.fetch(request)
            totalCredits = transactions.filter { $0.type == "credit" }.reduce(0) { $0 + $1.amount }
            totalPayments = transactions.filter { $0.type == "payment" }.reduce(0) { $0 + $1.amount }
        } catch {
            print("Error fetching transactions: \(error)")
        }
    }
}

struct ReportCardView: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("₹\(String(format: "%.2f", amount))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Settings View
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appLockManager: AppLockManager
    @AppStorage("appLanguage") private var appLanguage = "en"
    @State private var showingPINSetup = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedString.get("security"))) {
                    Toggle(LocalizedString.get("enable_pin"), isOn: $appLockManager.isPINEnabled)
                        .onChange(of: appLockManager.isPINEnabled) { enabled in
                            if enabled {
                                showingPINSetup = true
                            } else {
                                appLockManager.removePIN()
                            }
                        }
                }
                
                Section(header: Text(LocalizedString.get("language"))) {
                    Picker(LocalizedString.get("select_language"), selection: $appLanguage) {
                        Text("English").tag("en")
                        Text("മലയാളം").tag("ml")
                    }
                }
                
                Section(header: Text(LocalizedString.get("about"))) {
                    HStack {
                        Text(LocalizedString.get("version"))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(LocalizedString.get("settings"))
            .navigationBarItems(trailing: Button(LocalizedString.get("done")) {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingPINSetup) {
                PINSetupView(appLockManager: appLockManager)
            }
        }
    }
}

// PIN Lock View
struct PINLockView: View {
    @EnvironmentObject var appLockManager: AppLockManager
    @State private var pin = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(LocalizedString.get("enter_pin"))
                .font(.title2)
                .fontWeight(.semibold)
            
            SecureField(LocalizedString.get("pin"), text: $pin)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .onChange(of: pin) { newValue in
                    if newValue.count == 4 {
                        verifyPIN()
                    }
                }
            
            if showError {
                Text(LocalizedString.get("incorrect_pin"))
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            
            Button(action: verifyPIN) {
                Text(LocalizedString.get("unlock"))
                    .fontWeight(.semibold)
                    .frame(width: 200)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(pin.count < 4)
        }
        .padding()
    }
    
    private func verifyPIN() {
        if appLockManager.verifyPIN(pin) {
            showError = false
        } else {
            showError = true
            pin = ""
        }
    }
}

// PIN Setup View
struct PINSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var appLockManager: AppLockManager
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var step = 1
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text(step == 1 ? LocalizedString.get("create_pin") : LocalizedString.get("confirm_pin"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                SecureField(LocalizedString.get("pin"), text: step == 1 ? $pin : $confirmPin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                if showError {
                    Text(LocalizedString.get("pins_dont_match"))
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                
                Button(action: handleNext) {
                    Text(step == 1 ? LocalizedString.get("next") : LocalizedString.get("done"))
                        .fontWeight(.semibold)
                        .frame(width: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(step == 1 ? pin.count < 4 : confirmPin.count < 4)
            }
            .padding()
            .navigationBarItems(leading: Button(LocalizedString.get("cancel")) {
                appLockManager.isPINEnabled = false
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func handleNext() {
        if step == 1 {
            step = 2
        } else {
            if pin == confirmPin {
                appLockManager.setupPIN(pin)
                presentationMode.wrappedValue.dismiss()
            } else {
                showError = true
                confirmPin = ""
            }
        }
    }
}

// Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Core Data Model Definition
// Create a file named "PattuBook.xcdatamodeld" with the following entities:

/*
 Entity: Customer
 Attributes:
 - id: UUID
 - name: String
 - phone: String
 - address: String (Optional)
 - photoData: Binary Data (Optional)
 - totalDue: Double
 - createdDate: Date
 - lastUpdated: Date
 Relationships:
 - transactions: To-Many relationship to Transaction (inverse: customer)
 
 Entity: Transaction
 Attributes:
 - id: UUID
 - type: String
 - amount: Double
 - date: Date
 - note: String (Optional)
 Relationships:
 - customer: To-One relationship to Customer (inverse: transactions)
*/

// MARK: - Localizable.strings Files

// Create "en.lproj/Localizable.strings":
/*
"app_name" = "Pattu Book";
"total_outstanding" = "Total Outstanding";
"total_customers" = "Total Customers";
"search_customers" = "Search customers...";
"sort_by" = "Sort By";
"most_due" = "Most Due";
"recently_updated" = "Recently Updated";
"name" = "Name";
"add_customer" = "Add Customer";
"customer_info" = "Customer Information";
"phone" = "Phone Number";
"address_optional" = "Address (Optional)";
"photo_optional" = "Photo (Optional)";
"select_photo" = "Select Photo";
"cancel" = "Cancel";
"save" = "Save";
"balance" = "Balance";
"total_due" = "Total Due";
"transactions" = "Transactions";
"no_transactions" = "No transactions yet";
"add_transaction" = "Add Transaction";
"transaction_type" = "Transaction Type";
"type" = "Type";
"credit" = "Credit";
"payment" = "Payment";
"details" = "Details";
"amount" = "Amount";
"note_optional" = "Note (Optional)";
"due" = "Due";
"clear" = "Clear";
"reports" = "Reports";
"total_credits" = "Total Credits";
"total_payments" = "Total Payments";
"net_change" = "Net Change";
"done" = "Done";
"settings" = "Settings";
"security" = "Security";
"enable_pin" = "Enable PIN Lock";
"language" = "Language";
"select_language" = "Select Language";
"about" = "About";
"version" = "Version";
"enter_pin" = "Enter PIN";
"pin" = "PIN";
"incorrect_pin" = "Incorrect PIN. Try again.";
"unlock" = "Unlock";
"create_pin" = "Create 4-digit PIN";
"confirm_pin" = "Confirm PIN";
"pins_dont_match" = "PINs don't match";
"next" = "Next";
*/

// Create "ml.lproj/Localizable.strings":
/*
"app_name" = "പറ്റു ബുക്ക്";
"total_outstanding" = "മൊത്തം കുടിശ്ശിക";
"total_customers" = "മൊത്തം കസ്റ്റമേഴ്സ്";
"search_customers" = "കസ്റ്റമേഴ്സ് തിരയുക...";
"sort_by" = "ക്രമീകരിക്കുക";
"most_due" = "ഏറ്റവും കൂടുതൽ കുടിശ്ശിക";
"recently_updated" = "അടുത്തിടെ അപ്ഡേറ്റ് ചെയ്തത്";
"name" = "പേര്";
"add_customer" = "കസ്റ്റമർ ചേർക്കുക";
"customer_info" = "കസ്റ്റമർ വിവരങ്ങൾ";
"phone" = "ഫോൺ നമ്പർ";
"address_optional" = "വിലാസം (ഓപ്ഷണൽ)";
"photo_optional" = "ഫോട്ടോ (ഓപ്ഷണൽ)";
"select_photo" = "ഫോട്ടോ തിരഞ്ഞെടുക്കുക";
"cancel" = "റദ്ദാക്കുക";
"save" = "സേവ് ചെയ്യുക";
"balance" = "ബാലൻസ്";
"total_due" = "മൊത്തം കുടിശ്ശിക";
"transactions" = "ഇടപാടുകൾ";
"no_transactions" = "ഇതുവരെ ഇടപാടുകൾ ഇല്ല";
"add_transaction" = "ഇടപാട് ചേർക്കുക";
"transaction_type" = "ഇടപാട് തരം";
"type" = "തരം";
"credit" = "കടം";
"payment" = "പണം നൽകൽ";
"details" = "വിശദാംശങ്ങൾ";
"amount" = "തുക";
"note_optional" = "കുറിപ്പ് (ഓപ്ഷണൽ)";
"due" = "കുടിശ്ശിക";
"clear" = "ക്ലിയർ";
"reports" = "റിപ്പോർട്ടുകൾ";
"total_credits" = "മൊത്തം കടം";
"total_payments" = "മൊത്തം പേയ്മെന്റ്";
"net_change" = "നെറ്റ് മാറ്റം";
"done" = "പൂർത്തിയായി";
"settings" = "ക്രമീകരണങ്ങൾ";
"security" = "സുരക്ഷ";
"enable_pin" = "പിൻ ലോക്ക് പ്രവർത്തനക്ഷമമാക്കുക";
"language" = "ഭാഷ";
"select_language" = "ഭാഷ തിരഞ്ഞെടുക്കുക";
"about" = "കുറിച്ച്";
"version" = "പതിപ്പ്";
"enter_pin" = "പിൻ നൽകുക";
"pin" = "പിൻ";
"incorrect_pin" = "തെറ്റായ പിൻ. വീണ്ടും ശ്രമിക്കുക.";
"unlock" = "അൺലോക്ക് ചെയ്യുക";
"create_pin" = "4 അക്ക പിൻ സൃഷ്ടിക്കുക";
"confirm_pin" = "പിൻ സ്ഥിരീകരിക്കുക";
"pins_dont_match" = "പിൻ പൊരുത്തപ്പെടുന്നില്ല";
"next" = "അടുത്തത്";
*/

// MARK: - Info.plist Additions
/*
Add to Info.plist:
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to add customer photos.</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take customer photos.</string>
*/
