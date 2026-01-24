import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            VStack(spacing: 4) {
                Text("Browser Clutch")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Version \(version) (\(build))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text("Route URLs to different browsers based on rules.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .frame(width: 200)

            VStack(spacing: 4) {
                Text("© 2024")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Link("View on GitHub", destination: URL(string: "https://github.com")!)
                    .font(.caption)
            }
        }
        .padding(32)
        .frame(width: 300)
    }
}
