class AppLockManager: ObservableObject {
    @Published var isUnlocked = false
    @AppStorage("isPINEnabled") var isPINEnabled = false
    @AppStorage("userPIN") private var userPIN = ""
    
    init() {
        isUnlocked = !isPINEnabled
    }
    
    func setupPIN(_ pin: String) {
        userPIN = pin
        isPINEnabled = true
    }
    
    func removePIN() {
        userPIN = ""
        isPINEnabled = false
        isUnlocked = true
    }
    
    func verifyPIN(_ pin: String) -> Bool {
        if pin == userPIN {
            isUnlocked = true
            return true
        }
        return false
    }
}
