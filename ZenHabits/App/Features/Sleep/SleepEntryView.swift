//
//  SleepEntryView.swift
//  ZenHabits
//
//  Form for logging sleep data with rich input options
//  Design: Dark indigo theme for a "nighttime" feel
//

import SwiftUI
import SwiftData

struct SleepEntryView: View {
    
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Query existing log for today
    @Query private var todaysLogs: [SleepLog]
    
    // MARK: - Form State
    @State private var bedTime: Date
    @State private var wakeTime: Date
    @State private var quality: Double = 5
    @State private var hasDreamed: Bool = false
    @State private var dreamContent: String = ""
    @State private var selectedMood: SleepMood = .okay
    
    // MARK: - UI State
    @State private var isSaving = false
    @State private var showingDeleteConfirmation = false
    
    // MARK: - Theme
    private let themeColor = Color(hex: "5E5CE6") // Indigo
    private let darkBackground = Color(hex: "1C1C1E")
    
    // MARK: - Computed
    private var existingLog: SleepLog? {
        todaysLogs.first
    }
    
    private var isEditing: Bool {
        existingLog != nil
    }
    
    private var duration: TimeInterval {
        wakeTime.timeIntervalSince(bedTime)
    }
    
    private var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if duration < 0 {
            return "Invalid"
        } else if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var isValidDuration: Bool {
        duration > 0 && duration < 24 * 3600 // Between 0 and 24 hours
    }
    
    // MARK: - Init
    init() {
        // Default times: Last night 11 PM to this morning 7 AM
        let calendar = Calendar.current
        let now = Date()
        
        var bedComponents = calendar.dateComponents([.year, .month, .day], from: now)
        bedComponents.day! -= 1 // Yesterday
        bedComponents.hour = 23
        bedComponents.minute = 0
        let defaultBedTime = calendar.date(from: bedComponents) ?? now
        
        var wakeComponents = calendar.dateComponents([.year, .month, .day], from: now)
        wakeComponents.hour = 7
        wakeComponents.minute = 0
        let defaultWakeTime = calendar.date(from: wakeComponents) ?? now
        
        _bedTime = State(initialValue: defaultBedTime)
        _wakeTime = State(initialValue: defaultWakeTime)
        
        // Query for today's log
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        _todaysLogs = Query(
            filter: #Predicate<SleepLog> { log in
                log.date >= startOfToday && log.date < endOfToday
            },
            sort: [SortDescriptor(\SleepLog.date, order: .reverse)]
        )
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background gradient
                LinearGradient(
                    colors: [
                        colorScheme == .dark ? darkBackground : Color(.systemBackground),
                        colorScheme == .dark ? Color(hex: "2C2C3E") : Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Timing Section
                        timingSection
                        
                        // Duration Display
                        durationDisplay
                        
                        // Quality Section
                        qualitySection
                        
                        // Mood Section
                        moodSection
                        
                        // Dreams Section
                        dreamsSection
                        
                        // Delete Button (if editing)
                        if isEditing {
                            deleteSection
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .confirmationDialog(
                "Delete Sleep Log",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteLog()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete today's sleep log.")
            }
            .onAppear {
                loadExistingLog()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(themeColor)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            Text(isEditing ? "Edit Sleep Log" : "Log Your Sleep")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Timing Section
    private var timingSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Sleep Time", icon: "bed.double.fill")
            
            VStack(spacing: 12) {
                // Bed Time
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(themeColor)
                        Text("Bed Time")
                    }
                    
                    Spacer()
                    
                    DatePicker(
                        "",
                        selection: $bedTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .tint(themeColor)
                }
                .padding()
                .background(cardBackground)
                
                // Wake Time
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(.orange)
                        Text("Wake Time")
                    }
                    
                    Spacer()
                    
                    DatePicker(
                        "",
                        selection: $wakeTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .tint(themeColor)
                }
                .padding()
                .background(cardBackground)
            }
        }
    }
    
    // MARK: - Duration Display
    private var durationDisplay: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Duration")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(formattedDuration)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(isValidDuration ? themeColor : .red)
            }
            
            Spacer()
            
            // Sleep quality indicator
            if isValidDuration {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(durationQualityLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: durationQualityIcon)
                        .font(.title2)
                        .foregroundStyle(durationQualityColor)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    private var durationQualityLabel: String {
        let hours = duration / 3600
        switch hours {
        case ..<5: return "Too short"
        case 5..<7: return "Light"
        case 7..<9: return "Optimal"
        default: return "Extended"
        }
    }
    
    private var durationQualityIcon: String {
        let hours = duration / 3600
        switch hours {
        case ..<5: return "exclamationmark.triangle.fill"
        case 5..<7: return "moon.fill"
        case 7..<9: return "checkmark.circle.fill"
        default: return "zzz"
        }
    }
    
    private var durationQualityColor: Color {
        let hours = duration / 3600
        switch hours {
        case ..<5: return .red
        case 5..<7: return .orange
        case 7..<9: return .green
        default: return .blue
        }
    }
    
    // MARK: - Quality Section
    private var qualitySection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Sleep Quality", icon: "star.fill")
            
            VStack(spacing: 12) {
                // Quality value display
                HStack {
                    Text("Rating")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(quality))/10")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(qualityColor)
                }
                
                // Slider
                Slider(value: $quality, in: 1...10, step: 1) {
                    Text("Quality")
                } minimumValueLabel: {
                    Text("1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("10")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tint(qualityColor)
                
                // Quality description
                Text(qualityDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(cardBackground)
        }
    }
    
    private var qualityColor: Color {
        switch Int(quality) {
        case 1...3: return .red
        case 4...5: return .orange
        case 6...7: return .yellow
        case 8...9: return .green
        default: return themeColor
        }
    }
    
    private var qualityDescription: String {
        switch Int(quality) {
        case 1...2: return "Very poor sleep"
        case 3...4: return "Below average"
        case 5...6: return "Average quality"
        case 7...8: return "Good, restful sleep"
        case 9...10: return "Excellent! Well rested"
        default: return ""
        }
    }
    
    // MARK: - Mood Section
    private var moodSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Morning Mood", icon: "face.smiling.fill")
            
            VStack(spacing: 12) {
                Text("How do you feel this morning?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Mood selector
                HStack(spacing: 12) {
                    ForEach(SleepMood.allCases, id: \.self) { mood in
                        moodButton(mood)
                    }
                }
                
                // Selected mood label
                Text(selectedMood.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(hex: selectedMood.color))
            }
            .padding()
            .background(cardBackground)
        }
    }
    
    private func moodButton(_ mood: SleepMood) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedMood = mood
            }
            HapticManager.selection()
        } label: {
            Text(mood.rawValue)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(selectedMood == mood 
                              ? Color(hex: mood.color).opacity(0.2)
                              : Color(.systemGray6))
                )
                .overlay(
                    Circle()
                        .stroke(
                            selectedMood == mood ? Color(hex: mood.color) : Color.clear,
                            lineWidth: 2
                        )
                )
                .scaleEffect(selectedMood == mood ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mood.label)
    }
    
    // MARK: - Dreams Section
    private var dreamsSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Dreams", icon: "cloud.fill")
            
            VStack(spacing: 12) {
                // Dream toggle
                Toggle(isOn: $hasDreamed) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                        Text("I had dreams")
                    }
                }
                .tint(themeColor)
                
                // Dream content (shown when toggle is on)
                if hasDreamed {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What did you dream about?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $dreamContent)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(cardBackground)
            .animation(.spring(response: 0.3), value: hasDreamed)
        }
    }
    
    // MARK: - Delete Section
    private var deleteSection: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete This Log")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
        }
        .foregroundStyle(.red)
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(themeColor)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(isEditing ? "Update" : "Save") {
                saveLog()
            }
            .fontWeight(.semibold)
            .disabled(!isValidDuration || isSaving)
        }
    }
    
    // MARK: - Actions
    
    private func loadExistingLog() {
        guard let log = existingLog else { return }
        
        bedTime = log.bedTime
        wakeTime = log.wakeTime
        quality = Double(log.quality)
        hasDreamed = log.hasDreamed
        dreamContent = log.dreamContent ?? ""
        selectedMood = log.sleepMood
    }
    
    private func saveLog() {
        guard isValidDuration else { return }
        
        isSaving = true
        
        if let log = existingLog {
            // Update existing
            log.bedTime = bedTime
            log.wakeTime = wakeTime
            log.quality = Int(quality)
            log.hasDreamed = hasDreamed
            log.dreamContent = hasDreamed ? (dreamContent.isEmpty ? nil : dreamContent) : nil
            log.sleepMood = selectedMood
        } else {
            // Create new
            let log = SleepLog(
                date: Date(),
                bedTime: bedTime,
                wakeTime: wakeTime,
                quality: Int(quality),
                hasDreamed: hasDreamed,
                dreamContent: hasDreamed ? (dreamContent.isEmpty ? nil : dreamContent) : nil,
                mood: selectedMood
            )
            modelContext.insert(log)
        }
        
        do {
            try modelContext.save()
            HapticManager.success()
            dismiss()
        } catch {
            print("Failed to save sleep log: \(error)")
            isSaving = false
        }
    }
    
    private func deleteLog() {
        guard let log = existingLog else { return }
        
        modelContext.delete(log)
        
        do {
            try modelContext.save()
            HapticManager.warning()
            dismiss()
        } catch {
            print("Failed to delete sleep log: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    SleepEntryView()
        .modelContainer(for: [SleepLog.self], inMemory: true)
}
