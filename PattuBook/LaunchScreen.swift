//
//  LaunchScreen.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 29/10/25.
//


import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Image("AppName")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .cornerRadius(24)
                
                Text("Pattu Book")
                    .font(.title)
                    .fontWeight(.semibold)            }
        }
    }
}
#Preview {
    LaunchScreen()
}
