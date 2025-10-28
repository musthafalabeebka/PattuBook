//
//  TransactionViewModel.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//

import Foundation
import CoreData
internal import Combine



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
