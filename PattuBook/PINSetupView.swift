struct PINSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var appLockManager: AppLockManager
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var step = 1
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text(step == 1 ? LocalizedString.get("create_pin") : LocalizedString.get("confirm_pin"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                SecureField(LocalizedString.get("pin"), text: step == 1 ? $pin : $confirmPin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                if showError {
                    Text(LocalizedString.get("pins_dont_match"))
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                
                Button(action: handleNext) {
                    Text(step == 1 ? LocalizedString.get("next") : LocalizedString.get("done"))
                        .fontWeight(.semibold)
                        .frame(width: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(step == 1 ? pin.count < 4 : confirmPin.count < 4)
            }
            .padding()
            .navigationBarItems(leading: Button(LocalizedString.get("cancel")) {
                appLockManager.isPINEnabled = false
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func handleNext() {
        if step == 1 {
            step = 2
        } else {
            if pin == confirmPin {
                appLockManager.setupPIN(pin)
                presentationMode.wrappedValue.dismiss()
            } else {
                showError = true
                confirmPin = ""
            }
        }
    }
}
