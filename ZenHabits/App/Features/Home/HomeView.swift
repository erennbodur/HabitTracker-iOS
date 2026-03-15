//
//  HomeView.swift
//  HabitTracker
//
//  Main dashboard showing all active habits
//  Design: "Alive Minimalism" - warm, breathing UI inspired by Apple Health
//

import SwiftUI
import SwiftData

struct HomeView: View {
    
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - ViewModel
    @State private var viewModel: HomeViewModel?
    
    // MARK: - Sleep State
    @State private var showingSleepEntry = false
    @Query private var todaysSleepLogs: [SleepLog]
    
    // MARK: - Init
    init() {
        // Query for today's sleep log
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()
        
        _todaysSleepLogs = Query(
            filter: #Predicate<SleepLog> { log in
                log.date >= startOfToday && log.date < endOfToday
            },
            sort: [SortDescriptor(\SleepLog.date, order: .reverse)]
        )
    }
    
    // MARK: - Computed
    private var todaysSleepLog: SleepLog? {
        todaysSleepLogs.first
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content based on state
                if let viewModel {
                    contentView(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: showingAddHabitBinding) {
                AddHabitView()
                    .onDisappear {
                        Task { await viewModel?.loadHabits() }
                    }
            }
            .sheet(isPresented: $showingSleepEntry) {
                SleepEntryView()
            }
        }
        .task {
            if viewModel == nil {
                let service = HabitService(modelContext: modelContext)
                viewModel = HomeViewModel(habitService: service)
            }
            // Clear badge when app opens
            await NotificationManager.shared.clearBadge()
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private func contentView(viewModel: HomeViewModel) -> some View {
        switch viewModel.viewState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .success:
            if viewModel.habits.isEmpty {
                emptyStateView
            } else {
                habitListView(viewModel: viewModel)
            }
            
        case .error(let message):
            errorView(message: message, viewModel: viewModel)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Dynamic greeting
            Text(greeting)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // Today's date
            Text(formattedDate)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    /// Dynamic greeting based on time of day
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }
    
    /// Formatted date string (e.g., "Monday, Jan 12")
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Habit List View
    private func habitListView(viewModel: HomeViewModel) -> some View {
        // Split habits into essentials and routine
        let essentials = viewModel.habits.filter { $0.isCritical }
        let routine = viewModel.habits.filter { !$0.isCritical }
        
        return ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                headerSection
                
                // Sleep Summary Card (if logged today)
                if let sleepLog = todaysSleepLog {
                    sleepSummaryCard(log: sleepLog)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
                
                // Progress summary card
                progressSummaryCard(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Essentials Section (if any)
                if !essentials.isEmpty {
                    habitSection(
                        title: "Essentials",
                        icon: "star.fill",
                        iconColor: .yellow,
                        habits: essentials,
                        viewModel: viewModel,
                        isEssential: true
                    )
                }
                
                // Daily Goals Section
                if !routine.isEmpty {
                    habitSection(
                        title: essentials.isEmpty ? "Today's Habits" : "Daily Goals",
                        icon: "target",
                        iconColor: .blue,
                        habits: routine,
                        viewModel: viewModel,
                        isEssential: false
                    )
                }
                
                // Bottom padding
                Spacer()
                    .frame(height: 100)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .navigationDestination(for: Habit.self) { habit in
            HabitDetailView(habit: habit)
                .onDisappear {
                    Task { await viewModel.loadHabits() }
                }
        }
    }
    
    // MARK: - Sleep Summary Card
    private func sleepSummaryCard(log: SleepLog) -> some View {
        Button {
            showingSleepEntry = true
        } label: {
            HStack(spacing: 16) {
                // Moon icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "5E5CE6").opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: "5E5CE6"))
                }
                
                // Sleep info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Night's Sleep")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(log.formattedDuration)
                                .fontWeight(.semibold)
                        }
                        
                        // Quality
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            Text("\(log.quality)/10")
                                .fontWeight(.semibold)
                        }
                        
                        // Mood
                        Text(log.sleepMood.rawValue)
                    }
                    .font(.subheadline)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .shadow(
                        color: colorScheme == .dark ? .clear : Color(hex: "5E5CE6").opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(hex: "5E5CE6").opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Habit Section
    private func habitSection(
        title: String,
        icon: String,
        iconColor: Color,
        habits: [Habit],
        viewModel: HomeViewModel,
        isEssential: Bool
    ) -> some View {
        VStack(spacing: 0) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(habits.filter { viewModel.isCompletedToday($0) }.count)/\(habits.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // Habit cards
            LazyVStack(spacing: 12) {
                ForEach(habits) { habit in
                    NavigationLink(value: habit) {
                        HabitCardView(
                            habit: habit,
                            streak: viewModel.streak(for: habit),
                            isCompletedToday: viewModel.isCompletedToday(habit),
                            onToggle: {
                                Task { await viewModel.toggleHabit(habit) }
                            },
                            onTap: {}
                        )
                        .overlay(alignment: .topTrailing) {
                            // Badges overlay
                            HStack(spacing: 4) {
                                if habit.isCritical {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                }
                                if habit.hasReminder {
                                    Image(systemName: "bell.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(8)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Progress Summary Card
    private func progressSummaryCard(viewModel: HomeViewModel) -> some View {
        let completedCount = viewModel.habits.filter { viewModel.isCompletedToday($0) }.count
        let totalCount = viewModel.habits.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        
        // Count essentials completed
        let essentials = viewModel.habits.filter { $0.isCritical }
        let essentialsCompleted = essentials.filter { viewModel.isCompletedToday($0) }.count
        let allEssentialsDone = !essentials.isEmpty && essentialsCompleted == essentials.count
        
        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(completedCount) of \(totalCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 6)
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress == 1.0 ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                    
                    if progress == 1.0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.green)
                    } else {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Motivational message
            if progress == 1.0 {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Perfect day! Keep it going!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if allEssentialsDone && progress < 1.0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Essentials done! Bonus goals remain.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if !essentials.isEmpty && essentialsCompleted < essentials.count {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("\(essentials.count - essentialsCompleted) essential\(essentials.count - essentialsCompleted == 1 ? "" : "s") remaining")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if progress >= 0.5 {
                Text("You're doing great! Almost there.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(
                    color: colorScheme == .dark ? .clear : .black.opacity(0.05),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            VStack(spacing: 8) {
                Text("No Habits Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Start your journey by creating\nyour first habit")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel?.showingAddHabit = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First Habit")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.green)
                )
            }
            .padding(.top, 8)
            
            Spacer()
            Spacer()
        }
        .padding(32)
    }
    
    // MARK: - Error View
    private func errorView(message: String, viewModel: HomeViewModel) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task { await viewModel.loadHabits() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Sleep button (left)
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showingSleepEntry = true
            } label: {
                Image(systemName: todaysSleepLog != nil ? "moon.stars.fill" : "moon.stars")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(todaysSleepLog != nil ? Color(hex: "5E5CE6") : .secondary)
            }
            .accessibilityLabel(todaysSleepLog != nil ? "Edit sleep log" : "Log sleep")
        }
        
        // Add habit button (right)
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel?.showingAddHabit = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel("Add new habit")
        }
    }
    
    // MARK: - Bindings
    private var showingAddHabitBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.showingAddHabit ?? false },
            set: { viewModel?.showingAddHabit = $0 }
        )
    }
}

// MARK: - Preview
#Preview("With Sample Data") {
    HomeView()
        .modelContainer(PreviewContainer.sample)
}

#Preview("Empty State") {
    HomeView()
        .modelContainer(PreviewContainer.empty)
}

