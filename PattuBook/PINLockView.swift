//
//  PINLockView.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//
import SwiftUI

struct PINLockView: View {
    @EnvironmentObject var appLockManager: AppLockManager
    @State private var pin = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(LocalizedString.get("enter_pin"))
                .font(.title2)
                .fontWeight(.semibold)
            
            SecureField(LocalizedString.get("pin"), text: $pin)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .onChange(of: pin) { newValue in
                    if newValue.count == 4 {
                        verifyPIN()
                    }
                }
            
            if showError {
                Text(LocalizedString.get("incorrect_pin"))
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            
            Button(action: verifyPIN) {
                Text(LocalizedString.get("unlock"))
                    .fontWeight(.semibold)
                    .frame(width: 200)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(pin.count < 4)
        }
        .padding()
    }
    
    private func verifyPIN() {
        if appLockManager.verifyPIN(pin) {
            showError = false
        } else {
            showError = true
            pin = ""
        }
    }
}
