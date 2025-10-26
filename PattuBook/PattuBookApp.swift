// MARK: - App Entry Point
import SwiftUI
public import CoreData

@main
struct PattuBookApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appLockManager = AppLockManager()
    
    var body: some Scene {
        WindowGroup {
            if appLockManager.isUnlocked {
                HomeView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(appLockManager)
            } else {
                PINLockView()
                    .environmentObject(appLockManager)
            }
        }
    }
}

// MARK: - Core Data Models

// MARK: - Persistence Controller

// MARK: - Customer ViewModel

// MARK: - Transaction ViewModel

// MARK: - App Lock Manager

// MARK: - Localization Helper
enum LocalizedString {
    static func get(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

// MARK: - PDF Export Helper

// MARK: - Views

// Home View

// Customer Row View

// Add Customer View

// Customer Detail View

// Transaction Row View


// Add Transaction View

// Report View

// Settings View

// PIN Lock View

// PIN Setup View

// Image Picker

// Share Sheet


// MARK: - Core Data Model Definition
// Create a file named "PattuBook.xcdatamodeld" with the following entities:

/*
 Entity: Customer
 Attributes:
 - id: UUID
 - name: String
 - phone: String
 - address: String (Optional)
 - photoData: Binary Data (Optional)
 - totalDue: Double
 - createdDate: Date
 - lastUpdated: Date
 Relationships:
 - transactions: To-Many relationship to Transaction (inverse: customer)
 
 Entity: Transaction
 Attributes:
 - id: UUID
 - type: String
 - amount: Double
 - date: Date
 - note: String (Optional)
 Relationships:
 - customer: To-One relationship to Customer (inverse: transactions)
*/

// MARK: - Localizable.strings Files

// Create "en.lproj/Localizable.strings":
/*
"app_name" = "Pattu Book";
"total_outstanding" = "Total Outstanding";
"total_customers" = "Total Customers";
"search_customers" = "Search customers...";
"sort_by" = "Sort By";
"most_due" = "Most Due";
"recently_updated" = "Recently Updated";
"name" = "Name";
"add_customer" = "Add Customer";
"customer_info" = "Customer Information";
"phone" = "Phone Number";
"address_optional" = "Address (Optional)";
"photo_optional" = "Photo (Optional)";
"select_photo" = "Select Photo";
"cancel" = "Cancel";
"save" = "Save";
"balance" = "Balance";
"total_due" = "Total Due";
"transactions" = "Transactions";
"no_transactions" = "No transactions yet";
"add_transaction" = "Add Transaction";
"transaction_type" = "Transaction Type";
"type" = "Type";
"credit" = "Credit";
"payment" = "Payment";
"details" = "Details";
"amount" = "Amount";
"note_optional" = "Note (Optional)";
"due" = "Due";
"clear" = "Clear";
"reports" = "Reports";
"total_credits" = "Total Credits";
"total_payments" = "Total Payments";
"net_change" = "Net Change";
"done" = "Done";
"settings" = "Settings";
"security" = "Security";
"enable_pin" = "Enable PIN Lock";
"language" = "Language";
"select_language" = "Select Language";
"about" = "About";
"version" = "Version";
"enter_pin" = "Enter PIN";
"pin" = "PIN";
"incorrect_pin" = "Incorrect PIN. Try again.";
"unlock" = "Unlock";
"create_pin" = "Create 4-digit PIN";
"confirm_pin" = "Confirm PIN";
"pins_dont_match" = "PINs don't match";
"next" = "Next";
*/

// Create "ml.lproj/Localizable.strings":
/*
"app_name" = "പറ്റു ബുക്ക്";
"total_outstanding" = "മൊത്തം കുടിശ്ശിക";
"total_customers" = "മൊത്തം കസ്റ്റമേഴ്സ്";
"search_customers" = "കസ്റ്റമേഴ്സ് തിരയുക...";
"sort_by" = "ക്രമീകരിക്കുക";
"most_due" = "ഏറ്റവും കൂടുതൽ കുടിശ്ശിക";
"recently_updated" = "അടുത്തിടെ അപ്ഡേറ്റ് ചെയ്തത്";
"name" = "പേര്";
"add_customer" = "കസ്റ്റമർ ചേർക്കുക";
"customer_info" = "കസ്റ്റമർ വിവരങ്ങൾ";
"phone" = "ഫോൺ നമ്പർ";
"address_optional" = "വിലാസം (ഓപ്ഷണൽ)";
"photo_optional" = "ഫോട്ടോ (ഓപ്ഷണൽ)";
"select_photo" = "ഫോട്ടോ തിരഞ്ഞെടുക്കുക";
"cancel" = "റദ്ദാക്കുക";
"save" = "സേവ് ചെയ്യുക";
"balance" = "ബാലൻസ്";
"total_due" = "മൊത്തം കുടിശ്ശിക";
"transactions" = "ഇടപാടുകൾ";
"no_transactions" = "ഇതുവരെ ഇടപാടുകൾ ഇല്ല";
"add_transaction" = "ഇടപാട് ചേർക്കുക";
"transaction_type" = "ഇടപാട് തരം";
"type" = "തരം";
"credit" = "കടം";
"payment" = "പണം നൽകൽ";
"details" = "വിശദാംശങ്ങൾ";
"amount" = "തുക";
"note_optional" = "കുറിപ്പ് (ഓപ്ഷണൽ)";
"due" = "കുടിശ്ശിക";
"clear" = "ക്ലിയർ";
"reports" = "റിപ്പോർട്ടുകൾ";
"total_credits" = "മൊത്തം കടം";
"total_payments" = "മൊത്തം പേയ്മെന്റ്";
"net_change" = "നെറ്റ് മാറ്റം";
"done" = "പൂർത്തിയായി";
"settings" = "ക്രമീകരണങ്ങൾ";
"security" = "സുരക്ഷ";
"enable_pin" = "പിൻ ലോക്ക് പ്രവർത്തനക്ഷമമാക്കുക";
"language" = "ഭാഷ";
"select_language" = "ഭാഷ തിരഞ്ഞെടുക്കുക";
"about" = "കുറിച്ച്";
"version" = "പതിപ്പ്";
"enter_pin" = "പിൻ നൽകുക";
"pin" = "പിൻ";
"incorrect_pin" = "തെറ്റായ പിൻ. വീണ്ടും ശ്രമിക്കുക.";
"unlock" = "അൺലോക്ക് ചെയ്യുക";
"create_pin" = "4 അക്ക പിൻ സൃഷ്ടിക്കുക";
"confirm_pin" = "പിൻ സ്ഥിരീകരിക്കുക";
"pins_dont_match" = "പിൻ പൊരുത്തപ്പെടുന്നില്ല";
"next" = "അടുത്തത്";
*/

// MARK: - Info.plist Additions
/*
Add to Info.plist:
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to add customer photos.</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take customer photos.</string>
*/
