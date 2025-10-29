//
//  ReportView.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//
import SwiftUI
import CoreData

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
            .onChange(of: period) { oldValue, newValue in calculateReports() }
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
