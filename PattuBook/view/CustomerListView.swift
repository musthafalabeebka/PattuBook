import SwiftUI
import CoreData

struct CustomerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: CustomerViewModel
    
    @State private var showDeleteAlert = false
    @State private var customerToDelete: Customer?
    
    var body: some View {
        List {
            ForEach(viewModel.filteredCustomers) { customer in
                CustomerRowView(customer: customer)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            customerToDelete = customer
                            showDeleteAlert = true
                        } label: {
                            Label(
                                LocalizedString.get("delete"),
                                systemImage: "trash"
                            )
                        }
                    }
            }
        }
        .alert(
            LocalizedString.get("delete_customer"),
            isPresented: $showDeleteAlert,
            presenting: customerToDelete
        ) { customer in
            
            Button(LocalizedString.get("delete"), role: .destructive) {
                viewModel.deleteCustomer(customer)
            }
            
            Button(LocalizedString.get("cancel"), role: .cancel) { }
            
        } message: { customer in
            Text("Are you sure you want to delete \(customer.name ?? "this customer")?")
        }
    }
}
