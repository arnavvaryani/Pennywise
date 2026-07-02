import SwiftUI

struct ErrorPresenter: ViewModifier {
    @Binding var error: AppError?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                Text(error?.errorDescription ?? "")
            }
    }
}

extension View {
    func presentAppError(_ error: Binding<AppError?>) -> some View {
        self.modifier(ErrorPresenter(error: error))
    }
}


