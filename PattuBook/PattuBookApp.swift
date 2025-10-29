
import SwiftUI
import CoreData

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


enum LocalizedString {
    static func get(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

// MARK: - Info.plist Additions
/*
Add to Info.plist:
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to add customer photos.</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take customer photos.</string>
*/
