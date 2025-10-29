//
//  SettingsView.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//
import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appLockManager: AppLockManager
    @AppStorage("appLanguage") private var appLanguage = "en"
    @State private var showingPINSetup = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedString.get("security"))) {
                    Toggle(LocalizedString.get("enable_pin"), isOn: $appLockManager.isPINEnabled)
                        .onChange(of: appLockManager.isPINEnabled) { enabled,disabled in
                            if enabled {
                                showingPINSetup = true
                            } else {
                                appLockManager.removePIN()
                            }
                        }
                }
                
                Section(header: Text(LocalizedString.get("language"))) {
                    Picker(LocalizedString.get("select_language"), selection: $appLanguage) {
                        Text("English").tag("en")
                        Text("മലയാളം").tag("ml")
                    }
                }
                
                Section(header: Text(LocalizedString.get("about"))) {
                    HStack {
                        Text(LocalizedString.get("version"))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(LocalizedString.get("settings"))
            .navigationBarItems(trailing: Button(LocalizedString.get("done")) {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingPINSetup) {
                PINSetupView(appLockManager: appLockManager)
            }
        }
    }
}
