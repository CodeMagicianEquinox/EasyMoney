//
//  OnboardingView.swift
//  EasyMoney
//
//  Created by Tim Terrance on 8/11/26.
//

import SwiftUI

struct OnboardingView: View {
    private struct Page {
        let icon: String
        let title: String
        let description: String
    }

    @AppStorage("seenWelcomeView") private var seenWelcomeView = false
    @State private var selectedPage = 0

    private let pages = [
        Page(
            icon: "wallet.bifold.fill",
            title: "Welcome to EasyMoney",
            description: "A simple, friendly way to understand where your money goes."
        ),
        Page(
            icon: "chart.pie.fill",
            title: "See the full picture",
            description: "Track spending, organize transactions, and keep your balances in one place."
        ),
        Page(
            icon: "target",
            title: "Reach your goals",
            description: "Create budgets and build better money habits one decision at a time."
        )
    ]

    var body: some View {
        ZStack {
            Backgrounds.gradient3
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    if selectedPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation {
                                selectedPage = pages.count - 1
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, 24)

                TabView(selection: $selectedPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        onboardingPage(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))

                Button {
                    if selectedPage < pages.count - 1 {
                        withAnimation {
                            selectedPage += 1
                        }
                    } else {
                        withAnimation {
                            seenWelcomeView = true
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(selectedPage == pages.count - 1 ? "Get Started" : "Continue")

                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "#176B5B"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
    }

    private func onboardingPage(_ page: Page) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 128, height: 128)
                .background(.white.opacity(0.16), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 34)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
