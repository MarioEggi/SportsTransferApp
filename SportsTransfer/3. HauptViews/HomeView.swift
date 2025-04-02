//
//  HomeView.swift

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var transferProcessViewModel: TransferProcessViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Willkommen bei SportsTransfer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()

                Text("Bitte melde dich an, um fortzufahren.")
                    .font(.title3)
                    .foregroundColor(.gray)

                if !authManager.isLoggedIn {
                    NavigationLink(destination: LoginView()) {
                        Text("Zum Login")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Home")
            .foregroundColor(.white)
        }
        .environmentObject(authManager)
        .environmentObject(transferProcessViewModel)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
        .environmentObject(TransferProcessViewModel(authManager: AuthManager()))
}
