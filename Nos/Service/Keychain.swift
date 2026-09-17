import Logger
import Security
import UIKit

@MainActor protocol Keychain {
    
    var keychainPrivateKey: String { get }
    
    func save(key: String, data: Data) -> OSStatus 
    func load(key: String) -> Data? 
    func delete(key: String) -> OSStatus 
}

/// Don't use this outside CurrentUser
final class SystemKeychain: Keychain {
    
    let keychainPrivateKey = "privateKey"
    
    /// Restricts the private key to this device and keeps it available after first unlock for background work.
    private let preferredAccessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    
    @discardableResult
    func save(key: String, data: Data) -> OSStatus {
        let query =
        [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: preferredAccessibility,
            kSecValueData as String: data
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    func load(key: String) -> Data? {
        let query =
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == noErr, let data = dataTypeRef as? Data else {
            return nil
        }
        
        migrateAccessibilityIfNeeded(key: key, data: data)
        return data
    }
    
    func delete(key: String) -> OSStatus {
        let query =
        [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
        ] as [String: Any]
        
        return SecItemDelete(query as CFDictionary)
    }
    
    /// Rewrites existing items that were saved with a weaker accessibility class.
    private func migrateAccessibilityIfNeeded(key: String, data: Data) {
        let attributesQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var attributesRef: AnyObject?
        let status = SecItemCopyMatching(attributesQuery as CFDictionary, &attributesRef)
        guard status == noErr,
            let attributes = attributesRef as? [String: Any],
            let accessibility = attributes[kSecAttrAccessible as String] as? String else {
            return
        }
        
        guard accessibility != (preferredAccessibility as String) else {
            return
        }
        
        let rewriteStatus = save(key: key, data: data)
        if rewriteStatus == errSecSuccess {
            Log.info("Migrated keychain item accessibility for private key")
        } else {
            Log.error("Failed to migrate keychain item accessibility: \(rewriteStatus)")
        }
    }
}

final class InMemoryKeychain: Keychain {
    
    let keychainPrivateKey = "privateKey"
    
    private var keychain = [String: Data]()
    
    func save(key: String, data: Data) -> OSStatus {
        keychain[key] = data
        return 0
    }
    
    func load(key: String) -> Data? {
        keychain[key]
    }
    
    func delete(key: String) -> OSStatus {
        keychain.removeValue(forKey: key)
        return 0
    }
}
