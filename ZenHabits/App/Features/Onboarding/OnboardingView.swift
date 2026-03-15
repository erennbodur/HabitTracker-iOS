//
//  OnboardingView.swift
//  ZenHabits
//
//  Welcome flow for new users - explains core features
//  Design: Clean, minimal pages with SF Symbol illustrations
//

import SwiftUI

// MARK: - Onboarding Page Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}

// MARK: - OnboardingView
struct OnboardingView: View {
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    // MARK: - Callback
    let onComplete: () -> Void
    
    // MARK: - Pages
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "target",
            iconColor: .purple,
            title: "Track",
            subtitle: "Build habits that stick",
            description: "Create daily or weekly habits and track your progress with a simple tap."
        ),
        OnboardingPage(
            icon: "flame.fill",
            iconColor: .orange,
            title: "Streak",
            subtitle: "Stay motivated",
            description: "Watch your streak grow day by day. Don't break the chain!"
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            iconColor: .green,
            title: "Visualize",
            subtitle: "See your progress",
            description: "Calendar heatmaps and charts show how far you've come."
        )
    ]
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    pageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            // Bottom section
            bottomSection
        }
        .background(
            backgroundGradient
                .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Page View
    private func pageView(page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 180, height: 180)
                
                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(page.iconColor)
                    .symbolEffect(.pulse, options: .repeating)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            
            // Text content
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 24) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            
            // Buttons
            if currentPage == pages.count - 1 {
                // Last page: Get Started button
                Button {
                    HapticManager.success()
                    onComplete()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.horizontal, 32)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                // Other pages: Continue button
                HStack {
                    // Skip button
                    Button {
                        HapticManager.selection()
                        onComplete()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Next button
                    Button {
                        HapticManager.selection()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Continue")
                                .font(.headline)
                            
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.primary.opacity(0.9))
                        )
                    }
                }
                .padding(.horizontal, 32)
            }
        }
        .padding(.bottom, 48)
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(.systemBackground), Color(.systemGray6)]
                : [Color(.systemBackground), Color(.systemGray6).opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Preview
#Preview {
    OnboardingView {
        print("Onboarding completed!")
    }
}
