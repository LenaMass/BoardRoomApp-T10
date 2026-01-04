import SwiftUI
import Combine


@MainActor
final class LoginViewModel: ObservableObject {
    @Published var loginError: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var user: logindata? = nil

    func login(employeeNumberInput: String, passwordInput: String) async {
        loginError = ""
        isLoggedIn = false

        guard let employeeNumber = Int(employeeNumberInput.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            loginError = "Invalid job number"
            return
        }

        do {
            let loggedUser = try await logindata.login(
                employeeNumber: employeeNumber,
                password: passwordInput
            )
            user = loggedUser
            isLoggedIn = true
        } catch {
            loginError = "Invalid number or password"
        }
    }
}
