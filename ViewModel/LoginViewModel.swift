import SwiftUI
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var user : logindata?
    @Published var loginError: String = ""
    
    func login (
        employeeNumberInput: String,
        passwordInput: String
    ) async {
        loginError = ""
        
        guard let employeeNumber = Int(employeeNumberInput),
        !passwordInput.isEmpty
        else {
            loginError = "Employee number must be a number"
            return
        }
        do {
            user = try await logindata.login(
                employeeNumber: employeeNumber,
                password:passwordInput
            )
            print("Login success", user?.name ?? "")
        } catch {
            loginError = "Invalid employee number or password"
        }
    }
}

