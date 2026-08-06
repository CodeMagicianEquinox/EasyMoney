import SwiftUI

struct HeaderView: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 0) {
            // icon
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(.white.opacity(0.2))
                        .overlay(
                            Circle()
                                .stroke(.black.opacity(0.5), lineWidth: 1)
                        )
                )

            // title
            Text(title)
                .font(.system(size: 25, weight: .bold, design: .rounded))

            // subtitle
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HeaderView(
        title: "Test",
        subtitle: "This is a test",
        icon: "wallet.bifold.fill"
    )
}
