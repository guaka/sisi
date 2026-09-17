import LocalAuthentication
import UIKit

/// Helpers for copying sensitive material without leaving it on the pasteboard indefinitely.
enum SecurePasteboard {
    
    /// Copies a private key to the pasteboard for a short time, and only for local paste.
    /// - Parameters:
    ///   - string: The private key string (nsec or hex).
    ///   - expirationSeconds: How long the value remains available. Defaults to 60 seconds.
    static func copyPrivateKey(_ string: String, expirationSeconds: TimeInterval = 60) {
        UIPasteboard.general.setItems(
            [[UIPasteboard.typeAutomatic: string]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(expirationSeconds)
            ]
        )
    }
}

/// Authenticates the device owner before revealing or copying a private key.
enum PrivateKeyAuthentication {
    
    /// Prompts for biometrics or the device passcode.
    /// - Returns: `true` when authentication succeeds.
    @MainActor
    static func authenticateForPrivateKeyAccess() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No passcode/biometrics configured — allow copy so the user is not locked out of backup.
            return true
        }
        
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "authenticateToCopyPrivateKey")
            )
        } catch {
            return false
        }
    }
}
