//
//  CustomerRowView.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//
import SwiftUI

struct CustomerRowView: View {
    @ObservedObject var customer: Customer
    
    private var name: String {
        let value = customer.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? LocalizedString.get("unknown") : value
    }
    
    private var phone: String {
        customer.phone ?? ""
    }
    
    private var initials: String {
        String(name.prefix(1)).uppercased()
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .pink, .teal, .indigo]
        return colors[abs(name.hashValue) % colors.count]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(initials)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(avatarColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                if !phone.isEmpty {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(String(format: "%.2f", customer.totalDue))")
                    .font(.headline)
                    .foregroundColor(customer.totalDue > 0 ? .red : .green)
                
                Text(customer.totalDue > 0
                     ? LocalizedString.get("due")
                     : LocalizedString.get("clear"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
