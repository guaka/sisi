import SafariServices
import SwiftUI
import UIKit

/// Presents an `SFSafariViewController` over the current window scene.
enum SafariPresenter {
    
    @MainActor
    static func open(_ url: URL) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? scene.windows.first?.rootViewController else {
            UIApplication.shared.open(url)
            return
        }
        
        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = UIColor(named: "accent") ?? .systemBlue
        presenter.present(safari, animated: true)
    }
}
