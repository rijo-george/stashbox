import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    onboardingPage(
                        icon: "shield.checkered",
                        title: "Welcome to StashBox",
                        subtitle: "Track your purchases, warranties, and service records — all in one place.",
                        accentColor: Color(red: 0.35, green: 0.61, blue: 0.98)
                    )
                    .tag(0)

                    onboardingPage(
                        icon: "doc.text.viewfinder",
                        title: "Scan Receipts",
                        subtitle: "Point your camera at any receipt. On-device OCR extracts the details instantly — your data never leaves your phone.",
                        accentColor: Color(red: 0.58, green: 0.39, blue: 0.98)
                    )
                    .tag(1)

                    onboardingPage(
                        icon: "bell.badge",
                        title: "Never Miss an Expiry",
                        subtitle: "Smart reminders alert you before warranties expire — so you can claim what's yours.",
                        accentColor: Color(red: 1.0, green: 0.55, blue: 0.30)
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                // Get Started button
                Button {
                    if currentPage < 2 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < 2 ? "Next" : "Get Started")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.35, green: 0.61, blue: 0.98))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)

                if currentPage < 2 {
                    Button("Skip") {
                        onComplete()
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.60))
                    .padding(.bottom, 20)
                } else {
                    Spacer().frame(height: 40)
                }
            }
        }
    }

    private func onboardingPage(icon: String, title: String, subtitle: String, accentColor: Color) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(accentColor)

            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}
