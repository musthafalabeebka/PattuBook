//
//  CustomerRowView.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//
import SwiftUI

struct CustomerRowView: View {
    @ObservedObject var customer: Customer
    
    var body: some View {
        HStack(spacing: 12) {
            Text(customer.name!.prefix(1).uppercased())
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(customer.name!)
                    .font(.headline)
                Text(customer.phone!)
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
