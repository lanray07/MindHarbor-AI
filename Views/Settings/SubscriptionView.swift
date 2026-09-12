import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    hero
                    benefits
                    plans
                    legal
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
            .background(
                LinearGradient(
                    colors: [Color.teal.opacity(0.13), Color.white, Color(red: 0.96, green: 0.98, blue: 0.96)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("MindHarbor Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("MindHarbor Plus", isPresented: Binding(
                get: { subscriptionStore.errorMessage != nil },
                set: { if !$0 { subscriptionStore.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { subscriptionStore.errorMessage = nil }
            } message: {
                Text(subscriptionStore.errorMessage ?? "")
            }
        }
        .task {
            if subscriptionStore.products.isEmpty {
                await subscriptionStore.loadProducts()
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.14))
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.teal)
            }
            Text("A deeper place to reflect")
                .font(.system(.title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Text("Notice meaningful patterns and receive gentle AI-powered prompts, grounded in your own journal.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 18)
    }

    private var benefits: some View {
        VStack(spacing: 14) {
            benefit("Deeper personal patterns", icon: "chart.xyaxis.line")
            benefit("Weekly and monthly reflections", icon: "calendar.badge.clock")
            benefit("Unlimited AI reflection prompts", icon: "bubble.left.and.text.bubble.right")
            benefit("Your journal remains private by default", icon: "lock.shield")
        }
        .padding(18)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 22))
    }

    private var plans: some View {
        VStack(spacing: 12) {
            if subscriptionStore.products.isEmpty {
                fallbackPlan(title: "Annual", price: "£39.99 / year", detail: "Best value")
                fallbackPlan(title: "Monthly", price: "£4.99 / month", detail: "Flexible access")
            } else {
                ForEach(subscriptionStore.products, id: \.id) { product in
                    Button {
                        Task { await subscriptionStore.purchase(product) }
                    } label: {
                        planLabel(product)
                    }
                    .buttonStyle(.plain)
                    .disabled(subscriptionStore.isLoading)
                }
            }

            if subscriptionStore.isLoading {
                ProgressView()
                    .tint(.teal)
            }

            Button("Restore Purchases") {
                Task { await subscriptionStore.restorePurchases() }
            }
            .font(.callout.weight(.semibold))
            .disabled(subscriptionStore.isLoading)
        }
    }

    private var legal: some View {
        VStack(spacing: 10) {
            Text("Payment is charged to your Apple ID at confirmation. Subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in App Store account settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://github.com/lanray07/MindHarbor-AI/blob/main/PRIVACY.md")!)
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(.caption.weight(.semibold))
        }
    }

    private func benefit(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.teal)
                .frame(width: 24)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func planLabel(_ product: Product) -> some View {
        let annual = product.id == SubscriptionStore.annualProductID
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(annual ? "Annual" : "Monthly")
                    .font(.headline)
                Text(annual ? "Best value" : "Flexible access")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(product.displayPrice) / \(annual ? "year" : "month")")
                .font(.headline)
        }
        .padding(17)
        .background(annual ? Color.teal.opacity(0.14) : Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(annual ? Color.teal : Color.gray.opacity(0.2), lineWidth: annual ? 2 : 1)
        }
    }

    private func fallbackPlan(title: String, price: String, detail: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(price).font(.headline)
        }
        .padding(17)
        .background(title == "Annual" ? Color.teal.opacity(0.14) : Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(title == "Annual" ? Color.teal : Color.gray.opacity(0.2), lineWidth: title == "Annual" ? 2 : 1)
        }
    }
}
