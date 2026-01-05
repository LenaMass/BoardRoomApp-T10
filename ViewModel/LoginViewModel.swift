import SwiftUI
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var loginError: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var user: logindata? = nil

    @AppStorage("employeeNumber") private var storedEmployeeNumber: Int = 0
    @AppStorage("employeeRecordID") private var storedEmployeeRecordID: String = ""
    @AppStorage("employeeID") private var storedEmployeeID: String = ""

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

            guard let recID = loggedUser.recordID, !recID.isEmpty else {
                loginError = "Employee id missing"
                return
            }

            user = loggedUser
            storedEmployeeNumber = loggedUser.employeeNumber
            storedEmployeeRecordID = recID
            storedEmployeeID = recID
            isLoggedIn = true

        } catch {
            loginError = "Invalid number or password"
        }
    }
}

