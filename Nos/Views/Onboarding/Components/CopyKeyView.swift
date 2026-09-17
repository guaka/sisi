import SwiftUI
import UIKit

/// A bordered view that shows a key and a button to copy it. When the user taps the copy button,
/// its title changes to "Copied!".
struct CopyKeyView: View {
    let buttonTitle: LocalizedStringKey
    let isPrivateKey: Bool

    @Binding var keyString: String
    @Binding var copyButtonState: CopyButtonState

    init(
        _ buttonTitle: LocalizedStringKey,
        keyString: Binding<String>,
        copyButtonState: Binding<CopyButtonState>,
        isPrivateKey: Bool = false
    ) {
        self.buttonTitle = buttonTitle
        self.isPrivateKey = isPrivateKey
        _keyString = keyString
        _copyButtonState = copyButtonState
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(keyString)
            HStack {
                if copyButtonState == .copy {
                    Image.copyIcon
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "checkmark")
                        .frame(width: 20, height: 20)
                }
                Button {
                    Task { @MainActor in
                        await copyKey()
                    }
                } label: {
                    Text(copyButtonState == .copy ? buttonTitle : "copied")
                }
                Spacer()
            }
            .foregroundStyle(Color.actionTertiary)
        }
        .padding()
        .withStyledBorder()
    }
    
    @MainActor
    private func copyKey() async {
        if isPrivateKey {
            guard await PrivateKeyAuthentication.authenticateForPrivateKeyAccess() else {
                return
            }
            SecurePasteboard.copyPrivateKey(keyString)
        } else {
            UIPasteboard.general.string = keyString
        }
        
        copyButtonState = .copied
        try? await Task.sleep(for: .seconds(10))
        copyButtonState = .copy
    }
}

#Preview {
    @State var privateKey = KeyFixture.nsec
    @State var privateCopyButtonState = CopyButtonState.copy

    @State var publicKey = KeyFixture.npub
    @State var publicCopyButtonState = CopyButtonState.copied

    return VStack(spacing: 40) {
        CopyKeyView(
            "copyPrivateKey",
            keyString: $privateKey,
            copyButtonState: $privateCopyButtonState,
            isPrivateKey: true
        )
        CopyKeyView("copyPublicKey", keyString: $publicKey, copyButtonState: $publicCopyButtonState)
    }
}

enum KeyType {
    case `public`
    case `private`
}
