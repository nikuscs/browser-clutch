import SwiftUI

struct RuleItem: Identifiable, Equatable {
    let id = UUID()
    var appName: String?
    var urlPattern: String?
    var browser: String
    var isPrivate: Bool = false
    var newWindow: Bool = false

    static func == (lhs: RuleItem, rhs: RuleItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.appName == rhs.appName &&
        lhs.urlPattern == rhs.urlPattern &&
        lhs.browser == rhs.browser &&
        lhs.isPrivate == rhs.isPrivate &&
        lhs.newWindow == rhs.newWindow
    }
}

struct RuleRow: View {
    @Binding var rule: RuleItem
    let apps: [AppInfo]
    let browsers: [BrowserInfo]
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            reorderButtons
            appPicker
            patternField
            arrow
            browserPicker
            optionButtons
            Spacer()
            deleteButton
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var optionButtons: some View {
        HStack(spacing: 4) {
            Button {
                rule.isPrivate.toggle()
            } label: {
                Image(systemName: rule.isPrivate ? "eye.slash.fill" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundColor(rule.isPrivate ? .purple : .secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Private/Incognito mode")

            Button {
                rule.newWindow.toggle()
            } label: {
                Image(systemName: rule.newWindow ? "macwindow.badge.plus" : "macwindow")
                    .font(.system(size: 11))
                    .foregroundColor(rule.newWindow ? .blue : .secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Open in new window")
        }
    }

    private var reorderButtons: some View {
        VStack(spacing: 2) {
            Button(action: onMoveUp) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 9, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(canMoveUp ? .secondary : .secondary.opacity(0.3))
            .disabled(!canMoveUp)

            Button(action: onMoveDown) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(canMoveDown ? .secondary : .secondary.opacity(0.3))
            .disabled(!canMoveDown)
        }
    }

    private var appPicker: some View {
        Picker("", selection: Binding(
            get: { rule.appName ?? "__any__" },
            set: { rule.appName = $0 == "__any__" ? nil : $0 }
        )) {
            Text("Any app").tag("__any__")
            Divider()
            ForEach(apps) { app in
                HStack(spacing: 6) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                    }
                    Text(app.name)
                }
                .tag(app.name)
            }
        }
        .labelsHidden()
        .frame(width: 110)
    }

    private var patternField: some View {
        TextField("*", text: Binding(
            get: { rule.urlPattern ?? "" },
            set: { rule.urlPattern = $0.isEmpty ? nil : $0 }
        ))
        .textFieldStyle(.roundedBorder)
        .frame(width: 100)
    }

    private var arrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.secondary.opacity(0.4))
    }

    private var browserPicker: some View {
        Picker("", selection: $rule.browser) {
            ForEach(browsers) { browser in
                HStack(spacing: 6) {
                    if let icon = browser.icon {
                        Image(nsImage: icon)
                    }
                    Text(browser.name)
                }
                .tag(browser.bundleId)
            }
        }
        .labelsHidden()
        .frame(width: 100)
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .opacity(0.5)
    }
}
