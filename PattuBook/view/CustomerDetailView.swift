import SwiftUI
import CoreData

struct CustomerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var customer: Customer
    
    @StateObject private var transactionVM: TransactionViewModel
    @State private var showingAddTransaction = false
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    @State private var selectedTransactionType: String = "credit"
    
    init(customer: Customer) {
        _customer = ObservedObject(wrappedValue: customer)
        _transactionVM = StateObject(
            wrappedValue: TransactionViewModel(
                context: PersistenceController.shared.container.viewContext
            )
        )
    }
    
    private var transactions: [Transaction] {
        let set = customer.transactions as? Set<Transaction> ?? []
        return set.sorted {
            ($0.date ?? .distantPast) > ($1.date ?? .distantPast)
        }
    }
    
    var body: some View {
        List {
            // MARK: Balance
            Section(header: Text(LocalizedString.get("balance"))) {
                HStack {
                    Text(LocalizedString.get("total_due"))
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("₹\(String(format: "%.2f", customer.totalDue))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(
                            customer.totalDue > 0 ? .red : .green
                        )
                }
            }
            
            // MARK: Action Buttons
            Section {
                HStack(spacing: 12) {
                    Button {
                        selectedTransactionType = "credit"
                        showingAddTransaction = true
                    } label: {
                        Text(LocalizedString.get("credit"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        selectedTransactionType = "payment"
                        showingAddTransaction = true
                    } label: {
                        Text(LocalizedString.get("payment"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                }
            }
            
            // MARK: Transactions
            Section(header: Text(LocalizedString.get("transactions"))) {
                if transactions.isEmpty {
                    Text(LocalizedString.get("no_transactions"))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(transactions) { transaction in
                        TransactionRowView(transaction: transaction)
                    }
                }
            }
        }
        .navigationTitle(customer.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportPDF) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(
                customer: customer,
                transactionVM: transactionVM,
                type: selectedTransactionType
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
    }
    
    // MARK: PDF Export
    private func exportPDF() {
        pdfData = PDFExportHelper.generateCustomerStatement(customer: customer)
        showingShareSheet = true
    }
}
