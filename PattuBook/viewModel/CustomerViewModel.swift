//
//  CustomerViewModel.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//

import Foundation
internal import Combine
import SwiftUI
import CoreData

class CustomerViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    
    @Published var customers: [Customer] = []
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .mostDue
    
    enum SortOrder {
        case mostDue
        case recentlyUpdated
        case nameAscending
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchCustomers()
    }
    
    // MARK: - Filtered & Sorted Customers (SAFE)
    var filteredCustomers: [Customer] {
        var result = customers
        
        // Search
        if !searchText.isEmpty {
            result = result.filter {
                ($0.name ?? "")
                    .localizedCaseInsensitiveContains(searchText) ||
                ($0.phone ?? "")
                    .contains(searchText)
            }
        }
        
        // Sorting
        switch sortOrder {
        case .mostDue:
            result.sort { $0.totalDue > $1.totalDue }
            
        case .recentlyUpdated:
            result.sort {
                ($0.lastUpdated ?? .distantPast) >
                ($1.lastUpdated ?? .distantPast)
            }
            
        case .nameAscending:
            result.sort {
                ($0.name ?? "") <
                ($1.name ?? "")
            }
        }
        
        return result
    }
    
    // MARK: - Total Outstanding
    var totalOutstanding: Double {
        customers.reduce(0) { $0 + $1.totalDue }
    }
    
    // MARK: - Fetch
    func fetchCustomers() {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Customer.name, ascending: true)
        ]
        
        do {
            customers = try context.fetch(request)
        } catch {
            print("❌ Error fetching customers: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Add
    func addCustomer(name: String, phone: String) {
        let customer = Customer(context: context)
        customer.id = UUID()
        customer.name = name
        customer.phone = phone
        customer.totalDue = 0
        customer.createDate = Date()
        customer.lastUpdated = Date()
        
        saveAndRefresh()
    }
    
    // MARK: - Update
    func updateCustomer(_ customer: Customer, name: String, phone: String) {
        customer.name = name
        customer.phone = phone
        customer.lastUpdated = Date()
        
        saveAndRefresh()
    }
    
    // MARK: - Delete
    func deleteCustomer(_ customer: Customer) {
        context.delete(customer)
        saveAndRefresh()
    }
    
    // MARK: - Save Helper
    private func saveAndRefresh() {
        do {
            try context.save()
            fetchCustomers()
        } catch {
            print("❌ CoreData save failed: \(error.localizedDescription)")
        }
    }
}
