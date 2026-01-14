//
//  AddCustomerView.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 05/01/26.
//
import SwiftUI

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let customer: Customer
    @ObservedObject var transactionVM: TransactionViewModel
    let type: String
    
    @State private var amount = ""
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section {
                        Text(
                            type == "credit"
                            ? "Add Credit"
                            : "Add Payment"
                        )
                        .font(.headline)
                        .foregroundColor(type == "credit" ? .red : .green)
                    }
                    
                    Section(header: Text(LocalizedString.get("details"))) {
                        TextField(
                            LocalizedString.get("amount"),
                            text: $amount
                        )
                        .keyboardType(.decimalPad)
                        
                        TextField(
                            LocalizedString.get("note_optional"),
                            text: $note
                        )
                    }
                }
                
                // MARK: Bottom Save Button
                VStack {
                    Button {
                        if let amountValue = Double(amount) {
                            transactionVM.addTransaction(
                                to: customer,
                                type: type,
                                amount: amountValue,
                                note: note.isEmpty ? nil : note
                            )
                            presentationMode.wrappedValue.dismiss()
                        }
                    } label: {
                        Text(LocalizedString.get("save"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                type == "credit"
                                ? Color.red
                                : Color.green
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                    }
                    .disabled(amount.isEmpty)
                    .opacity(amount.isEmpty ? 0.5 : 1)
                }
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle(
                type == "credit"
                ? LocalizedString.get("credit")
                : LocalizedString.get("payment")
            )
            .navigationBarItems(
                leading: Button(LocalizedString.get("cancel")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
