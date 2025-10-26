//
//  CustomerDetailView.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//
import SwiftUI
public import CoreData

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
    
    // Derived transactions array from Core Data relationship to avoid dynamic member lookup issues
    private var transactions: [Transaction] {
        let set = customer.transactions as? Set<Transaction> ?? []
        // Sort by date ascending; adjust as needed
        return set.sorted { (lhs, rhs) in
            let l = lhs.date ?? .distantPast
            let r = rhs.date ?? .distantPast
            return l < r
        }
    }
}
