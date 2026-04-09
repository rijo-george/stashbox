import SwiftUI

struct ToastOverlay: View {
    let message: String
    let icon: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let tc = themeManager.colors

        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(message)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(tc.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(tc.surface)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - Toast state manager

class ToastState: ObservableObject {
    @Published var isShowing = false
    @Published var message = ""
    @Published var icon = "checkmark.circle.fill"

    func show(_ message: String, icon: String = "checkmark.circle.fill") {
        self.message = message
        self.icon = icon
        withAnimation(.spring(response: 0.3)) {
            isShowing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3)) {
                self.isShowing = false
            }
        }
    }
}

// MARK: - Toast view modifier

struct ToastModifier: ViewModifier {
    @ObservedObject var toast: ToastState

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if toast.isShowing {
                ToastOverlay(message: toast.message, icon: toast.icon)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

extension View {
    func toast(_ state: ToastState) -> some View {
        modifier(ToastModifier(toast: state))
    }
}
