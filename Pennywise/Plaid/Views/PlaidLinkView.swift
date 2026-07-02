//
//  PlaidLinkView.swift
//  Pennywise
//
//  SwiftUI wrapper for Plaid Link
//

import SwiftUI
import LinkKit

struct PlaidLinkView: UIViewControllerRepresentable {
    let handler: Handler
    let onExit: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        PlaidPresenterViewController(handler: handler, onExit: onExit)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // no-op: presentation handled in viewDidAppear
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var hasOpened = false
    }
}

private final class PlaidPresenterViewController: UIViewController {
    private let handler: Handler
    private let onExit: () -> Void
    private var hasOpened = false

    init(handler: Handler, onExit: @escaping () -> Void) {
        self.handler = handler
        self.onExit = onExit
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasOpened else { return }
        hasOpened = true

        // Present LinkKit after we're on-screen (prevents blank controller).
        handler.open(presentUsing: .viewController(self))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // If the sheet gets dismissed externally, ensure caller can clean up.
        onExit()
    }
}
