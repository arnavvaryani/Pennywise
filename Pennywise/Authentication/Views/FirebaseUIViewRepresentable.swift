//
//  FirebaseUIViewRepresentable.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI
import FirebaseAuth

struct FirebaseUIViewRepresentable: UIViewControllerRepresentable {
    var signInCompletion: ((Result<FirebaseAuth.User, Error>) -> Void)

    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func signInWithGoogle() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        
        AuthenticationService.shared.signInWithGoogle(from: rootViewController) { result in
            signInCompletion(result)
        }
    }
}
