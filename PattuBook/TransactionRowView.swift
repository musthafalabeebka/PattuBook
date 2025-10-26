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