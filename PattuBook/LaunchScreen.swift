import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Image("AppLogo") // Put your logo image in Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .cornerRadius(24)
                
                Text("Pattu Book")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
    }
}
