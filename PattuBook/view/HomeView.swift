//
//  HomeView.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//

import SwiftUI
import Foundation
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: CustomerViewModel
    @State private var showingAddCustomer = false
    @State private var showingSettings = false
    @State private var showingReports = false
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: CustomerViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary Card
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString.get("total_outstanding"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("₹\(String(format: "%.2f", viewModel.totalOutstanding))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(viewModel.totalOutstanding > 0 ? .red : .green)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Text(LocalizedString.get("total_customers"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.customers.count)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Search and Filter
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(LocalizedString.get("search_customers"), text: $viewModel.searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                Picker(LocalizedString.get("sort_by"), selection: $viewModel.sortOrder) {
                    Text(LocalizedString.get("most_due")).tag(CustomerViewModel.SortOrder.mostDue)
                    Text(LocalizedString.get("recently_updated")).tag(CustomerViewModel.SortOrder.recentlyUpdated)
                    Text(LocalizedString.get("name")).tag(CustomerViewModel.SortOrder.nameAscending)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Customer List
                List {
                    ForEach(viewModel.filteredCustomers) { customer in
                        NavigationLink(destination: CustomerDetailView(customer: customer)) {
                            CustomerRowView(customer: customer)
                        }
                    }
                    .onDelete(perform: deleteCustomers)
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle(LocalizedString.get("app_name"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingReports = true }) {
                        Image(systemName: "chart.bar.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCustomer = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomer) {
                AddCustomerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingReports) {
                ReportView()
            }
            .onAppear {
                viewModel.fetchCustomers()
            }
        }
    }
    
    private func deleteCustomers(offsets: IndexSet) {
        withAnimation {
            offsets.map { viewModel.filteredCustomers[$0] }.forEach(viewModel.deleteCustomer)
        }
    }
}

#Preview {
    HomeView()
}
