import SwiftUI
struct LoginTextField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder)
                .foregroundColor(.txtgray)
            
        )
        .font(.system(size: 20))
        .padding(.horizontal, 12)
        .padding(.vertical, 17)
        .frame(width: 358)
        .background (
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                )
            
        )
    }
}

