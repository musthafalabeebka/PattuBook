//
//  AddCustomerView.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//
import SwiftUI

struct AddCustomerView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CustomerViewModel
    
    @State private var name = ""
    @State private var phone = ""
    
    var body: some View {
        NavigationView {
            VStack{
                Form {
                    Section(header: Text(LocalizedString.get("customer_info"))) {
                        TextField(LocalizedString.get("name"), text: $name)
                        TextField(LocalizedString.get("address"), text: $phone)
                        .keyboardType(.phonePad)                }
                }
                
                Button(LocalizedString.get("save")) {
                    viewModel.addCustomer(
                        name: name,
                        phone: phone
                    )
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty || phone.isEmpty)
            }
            }
            .navigationTitle(LocalizedString.get("add_customer"))
            .navigationBarItems(
                leading: Button(LocalizedString.get("cancel")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            }
        }

