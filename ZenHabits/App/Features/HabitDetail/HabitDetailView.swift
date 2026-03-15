//
//  HabitDetailView.swift
//  HabitTracker
//
//  Deep-dive view for individual habit statistics and calendar
//  Features: Stats cards, calendar heatmap, monthly bar chart, edit/delete
//

import SwiftUI
import SwiftData
import Charts

struct HabitDetailView: View {
    
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Properties
    let habit: Habit
    
    // MARK: - ViewModel
    @State private var viewModel: HabitDetailViewModel?
    
    // MARK: - Local State
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            if let viewModel {
                VStack(spacing: 24) {
                    // Header with emoji and title
                    headerSection
                    
                    // Stats row
                    statsSection(viewModel: viewModel)
                    
                    // Calendar heatmap
                    calendarSection(viewModel: viewModel)
                    
                    // Monthly chart
                    chartSection(viewModel: viewModel)
                    
                    // Danger zone
                    dangerSection
                }
                .padding()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingEditSheet) {
            AddHabitView(habitToEdit: habit)
                .onDisappear {
                    // Refresh stats after editing
                    Task { await viewModel?.calculateAllStats() }
                }
        }
        .confirmationDialog(
            "Delete Habit",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Archive", role: .none) {
                Task {
                    try? await viewModel?.archiveHabit()
                    dismiss()
                }
            }
            
            Button("Delete Permanently", role: .destructive) {
                Task {
                    try? await viewModel?.deleteHabit()
                    dismiss()
                }
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Archive keeps your history for statistics. Delete permanently removes all data.")
        }
        .task {
            if viewModel == nil {
                let service = HabitService(modelContext: modelContext)
                viewModel = HabitDetailViewModel(habit: habit, habitService: service)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Large emoji
            Text(habit.emoji)
                .font(.system(size: 64))
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(habit.color.opacity(0.15))
                )
            
            // Title
            Text(habit.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Created date
            Text("Started \(habit.createdAt.formatted(.dateTime.month().day().year()))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Stats Section
    private func statsSection(viewModel: HabitDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "flame.fill",
                    value: "\(viewModel.currentStreak)",
                    label: "Current",
                    color: .orange
                )
                
                StatCard(
                    icon: "trophy.fill",
                    value: "\(viewModel.bestStreak)",
                    label: "Best",
                    color: .yellow
                )
                
                StatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(viewModel.totalCompletions)",
                    label: "Total",
                    color: habit.color
                )
            }
        }
    }
    
    // MARK: - Calendar Section
    private func calendarSection(viewModel: HabitDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with navigation
            HStack {
                Text("Calendar")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Month navigation
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.previousMonth()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(viewModel.displayedMonthString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 120)
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.nextMonth()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(viewModel.canGoToNextMonth ? Color.secondary : Color.secondary.opacity(0.3))
                    }
                    .disabled(!viewModel.canGoToNextMonth)
                }
            }
            
            // Calendar heatmap
            CalendarHeatmap(
                days: viewModel.calendarDays,
                accentColor: habit.color,
                onDayTap: { date in
                    Task { await viewModel.toggleCompletion(for: date) }
                }
            )
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            )
        }
    }
    
    // MARK: - Chart Section
    private func chartSection(viewModel: HabitDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Progress")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Chart(viewModel.monthlyStats) { stat in
                BarMark(
                    x: .value("Month", stat.monthName),
                    y: .value("Completions", stat.completionCount)
                )
                .foregroundStyle(habit.color.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let intValue = value.as(Int.self) {
                        AxisValueLabel {
                            Text("\(intValue)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let month = value.as(String.self) {
                            Text(month)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            )
        }
    }
    
    // MARK: - Danger Section
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manage")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            // Edit button
            Button {
                showingEditSheet = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Habit")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                )
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            
            // Delete button
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Habit")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                )
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit Habit", systemImage: "pencil")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

// MARK: - Preview
#Preview("With Data") {
    NavigationStack {
        HabitDetailView(habit: SampleHabits.meditation)
    }
    .modelContainer(PreviewContainer.sample)
}

#Preview("New Habit") {
    NavigationStack {
        HabitDetailView(
            habit: Habit(
                title: "New Habit",
                emoji: "✨",
                colorHex: "AF52DE"
            )
        )
    }
    .modelContainer(PreviewContainer.empty)
}

