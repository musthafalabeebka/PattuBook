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
    @State private var address = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedString.get("customer_info"))) {
                    TextField(LocalizedString.get("name"), text: $name)
                    TextField(LocalizedString.get("phone"), text: $phone)
                        .keyboardType(.phonePad)
                    TextField(LocalizedString.get("address_optional"), text: $address)
                }
                
                Section(header: Text(LocalizedString.get("photo_optional"))) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    Button(LocalizedString.get("select_photo")) {
                        showingImagePicker = true
                    }
                }
            }
            .navigationTitle(LocalizedString.get("add_customer"))
            .navigationBarItems(
                leading: Button(LocalizedString.get("cancel")) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(LocalizedString.get("save")) {
                    let photoData = selectedImage?.jpegData(compressionQuality: 0.8)
                    viewModel.addCustomer(
                        name: name,
                        phone: phone,
                    )
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty || phone.isEmpty)
            )
            }
        }
    }

