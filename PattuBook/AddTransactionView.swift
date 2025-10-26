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
