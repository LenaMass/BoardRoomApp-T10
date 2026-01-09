import SwiftUI

struct login: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var employeeNumberInput = ""
    @State private var passwordInput = ""
    var body: some View {
        NavigationStack{
            ZStack {
                Color.screenBG
                    .ignoresSafeArea()
                
                Image(.backG)
                    .aspectRatio(contentMode: .fit)
                    .padding(.top, -440)
                
                
                
                VStack(spacing: 16) {
                    
                    
                    //  Spacer().frame(height: 120)
                    
                    Text("Welcome back! Glad to see you, Again!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.OR_1)
                        .padding(.horizontal)
                    
                    LoginTextField(
                        placeholder: "Enter your job number",
                        text: $employeeNumberInput
                    )
                    
                    LoginTextField(
                        placeholder: "Enter your password",
                        text: $passwordInput
                    )
                    
                    if !viewModel.loginError.isEmpty {
                        Text(viewModel.loginError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button {
                        Task {
                            await viewModel.login(
                                employeeNumberInput: employeeNumberInput,
                                passwordInput: passwordInput
                            )
                        }
                    } label: {
                        Text("Log In")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 358)
                            .padding(.vertical, 17)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blueButton)
                            )
                    }
                }
                
                Spacer()
            }
            .navigationDestination(isPresented: $viewModel.isLoggedIn) {
                BoardRoomsView()
                    .navigationBarBackButtonHidden(true)

               }
            
            }
        }
    }

#Preview {
    login()
}


