//
//  AddHabitView.swift
//  HabitTracker
//
//  Form for creating OR editing a habit
//  Design: Native iOS form with custom color/day pickers
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    // MARK: - Properties
    /// Optional habit to edit. If nil, creates a new habit.
    let habitToEdit: Habit?
    
    // MARK: - ViewModel
    @State private var viewModel: AddHabitViewModel?
    
    // MARK: - Focus State
    @FocusState private var isTitleFocused: Bool
    
    // MARK: - Init
    /// Creates the view in Add or Edit mode
    /// - Parameter habitToEdit: Pass a habit to enable edit mode, or nil for add mode
    init(habitToEdit: Habit? = nil) {
        self.habitToEdit = habitToEdit
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    formContent(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(viewModel?.mode.navigationTitle ?? "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Error", isPresented: showingErrorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel?.errorMessage ?? "An error occurred")
            }
            .alert("Notifications Disabled", isPresented: showingNotificationDeniedBinding) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        openURL(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("To receive habit reminders, please enable notifications in Settings.")
            }
            .onChange(of: viewModel?.didSaveSuccessfully) { _, success in
                if success == true {
                    // Haptic success feedback via centralized manager
                    HapticManager.success()
                    dismiss()
                }
            }
        }
        .interactiveDismissDisabled(viewModel?.isSaving ?? false)
        .onAppear {
            if viewModel == nil {
                let service = HabitService(modelContext: modelContext)
                viewModel = AddHabitViewModel(habitService: service, habitToEdit: habitToEdit)
            }
        }
    }
    
    // MARK: - Form Content
    private func formContent(viewModel: AddHabitViewModel) -> some View {
        Form {
            // MARK: Title Section
            Section {
                TextField("Habit name", text: Binding(
                    get: { viewModel.title },
                    set: { viewModel.title = $0 }
                ))
                .focused($isTitleFocused)
                .submitLabel(.done)
                .onSubmit { isTitleFocused = false }
            } header: {
                Text(viewModel.mode.isEditing ? "Habit Name" : "What do you want to build?")
            }
            
            // MARK: Emoji Section
            Section {
                emojiPicker(viewModel: viewModel)
            } header: {
                Text("Icon")
            }
            
            // MARK: Color Section
            Section {
                colorPicker(viewModel: viewModel)
            } header: {
                Text("Color")
            }
            
            // MARK: Schedule Section
            Section {
                frequencyPicker(viewModel: viewModel)
            } header: {
                Text("Schedule")
            } footer: {
                Text("Choose which days you want to practice this habit")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            // MARK: Settings Section
            Section {
                settingsSection(viewModel: viewModel)
            } header: {
                Text("Settings")
            } footer: {
                if viewModel.isCritical {
                    Text("Essential habits appear at the top of your daily list")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            // MARK: Preview Section
            Section {
                habitPreview(viewModel: viewModel)
            } header: {
                Text("Preview")
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    // MARK: - Settings Section
    private func settingsSection(viewModel: AddHabitViewModel) -> some View {
        Group {
            // Essential toggle
            Toggle(isOn: Binding(
                get: { viewModel.isCritical },
                set: { newValue in
                    viewModel.isCritical = newValue
                    HapticManager.selection()
                }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mark as Essential")
                            .font(.body)
                        Text("Priority habit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(.yellow)
            
            // Reminder toggle
            Toggle(isOn: Binding(
                get: { viewModel.hasReminder },
                set: { newValue in
                    viewModel.hasReminder = newValue
                    HapticManager.selection()
                    if newValue {
                        Task { await viewModel.onReminderToggled() }
                    }
                }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.blue)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                            .font(.body)
                        Text("Get notified")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(.blue)
            
            // Time picker (shown only when reminder is enabled)
            if viewModel.hasReminder {
                DatePicker(
                    selection: Binding(
                        get: { viewModel.reminderTime },
                        set: { viewModel.reminderTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                            .font(.body)
                        
                        Text("Reminder Time")
                    }
                }
            }
        }
    }
    
    // MARK: - Emoji Picker
    private func emojiPicker(viewModel: AddHabitViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(HabitEmoji.presets.enumerated()), id: \.offset) { index, emoji in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedEmoji = emoji
                        }
                        // Light haptic via centralized manager
                        HapticManager.selection()
                    } label: {
                        Text(emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(viewModel.selectedEmoji == emoji 
                                          ? Color(hex: viewModel.selectedColorHex).opacity(0.2)
                                          : Color(.systemGray6))
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        viewModel.selectedEmoji == emoji 
                                            ? Color(hex: viewModel.selectedColorHex)
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Emoji \(emoji)")
                    .accessibilityAddTraits(viewModel.selectedEmoji == emoji ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
    
    // MARK: - Color Picker
    private func colorPicker(viewModel: AddHabitViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HabitColor.presets) { habitColor in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedColorHex = habitColor.hex
                        }
                        HapticManager.selection()
                    } label: {
                        Circle()
                            .fill(habitColor.color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .opacity(viewModel.selectedColorHex == habitColor.hex ? 1 : 0)
                            )
                            .overlay(
                                Circle()
                                    .stroke(habitColor.color, lineWidth: 2)
                                    .scaleEffect(1.3)
                                    .opacity(viewModel.selectedColorHex == habitColor.hex ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(habitColor.name)
                    .accessibilityAddTraits(viewModel.selectedColorHex == habitColor.hex ? .isSelected : [])
                }
            }
            .padding(.vertical, 8)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
    
    // MARK: - Frequency Picker
    private func frequencyPicker(viewModel: AddHabitViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quick select buttons
            HStack(spacing: 8) {
                quickSelectButton("Every day", isActive: viewModel.selectedDays.count == 7) {
                    viewModel.selectAllDays()
                }
                
                quickSelectButton("Weekdays", isActive: viewModel.selectedDays == [.monday, .tuesday, .wednesday, .thursday, .friday]) {
                    viewModel.selectWeekdays()
                }
                
                quickSelectButton("Weekends", isActive: viewModel.selectedDays == [.saturday, .sunday]) {
                    viewModel.selectWeekends()
                }
            }
            
            // Day selector
            HStack(spacing: 8) {
                ForEach(Weekday.orderedCases) { day in
                    dayButton(day: day, viewModel: viewModel)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }
    
    private func quickSelectButton(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
            HapticManager.selection()
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isActive ? Color(hex: viewModel?.selectedColorHex ?? "007AFF") : Color(.systemGray5))
                )
                .foregroundStyle(isActive ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    private func dayButton(day: Weekday, viewModel: AddHabitViewModel) -> some View {
        let isSelected = viewModel.isDaySelected(day)
        let accentColor = Color(hex: viewModel.selectedColorHex)
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.toggleDay(day)
            }
            HapticManager.selection()
        } label: {
            Text(day.letter)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? accentColor : Color(.systemGray6))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.shortName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    // MARK: - Preview
    private func habitPreview(viewModel: AddHabitViewModel) -> some View {
        HStack(spacing: 16) {
            // Emoji badge
            Text(viewModel.selectedEmoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color(hex: viewModel.selectedColorHex).opacity(0.15))
                )
            
            // Title and badges
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(viewModel.title.isEmpty ? "Habit name" : viewModel.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(viewModel.title.isEmpty ? .secondary : .primary)
                    
                    if viewModel.isCritical {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    
                    if viewModel.hasReminder {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                
                Text(scheduleDescription(for: viewModel))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Mock completion circle
            Circle()
                .stroke(Color(hex: viewModel.selectedColorHex).opacity(0.3), lineWidth: 2)
                .frame(width: 32, height: 32)
        }
        .padding(.vertical, 4)
    }
    
    private func scheduleDescription(for viewModel: AddHabitViewModel) -> String {
        var parts: [String] = []
        
        // Days
        if viewModel.selectedDays.count == 7 {
            parts.append("Every day")
        } else if viewModel.selectedDays == [.monday, .tuesday, .wednesday, .thursday, .friday] {
            parts.append("Weekdays")
        } else if viewModel.selectedDays == [.saturday, .sunday] {
            parts.append("Weekends")
        } else {
            let sorted = viewModel.selectedDays.sorted { $0.rawValue < $1.rawValue }
            parts.append(sorted.map { $0.shortName }.joined(separator: ", "))
        }
        
        // Reminder time
        if viewModel.hasReminder {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            parts.append("at \(formatter.string(from: viewModel.reminderTime))")
        }
        
        return parts.joined(separator: " ")
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
            .disabled(viewModel?.isSaving ?? false)
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(viewModel?.mode.saveButtonTitle ?? "Save") {
                Task { await viewModel?.saveHabit() }
            }
            .fontWeight(.semibold)
            .disabled(!(viewModel?.isValid ?? false) || (viewModel?.isSaving ?? false))
        }
    }
    
    // MARK: - Bindings
    private var showingErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.errorMessage != nil },
            set: { if !$0 { viewModel?.errorMessage = nil } }
        )
    }
    
    private var showingNotificationDeniedBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.showingNotificationDeniedAlert ?? false },
            set: { viewModel?.showingNotificationDeniedAlert = $0 }
        )
    }
}

// MARK: - Preview
#Preview("Add Mode") {
    AddHabitView()
        .modelContainer(for: [Habit.self, Completion.self], inMemory: true)
}

#Preview("Edit Mode") {
    let habit = Habit(
        title: "Morning Meditation",
        emoji: "🧘",
        colorHex: "5E5CE6",
        isCritical: true,
        reminderTime: Date()
    )
    
    return AddHabitView(habitToEdit: habit)
        .modelContainer(for: [Habit.self, Completion.self], inMemory: true)
}

