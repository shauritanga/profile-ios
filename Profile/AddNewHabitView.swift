import SwiftUI

struct AddHabitView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var habitName = ""
    @State private var emoji = "✅"
    @State private var time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var repeatDays: Set<Int> = []


    let onSave: (Habit) -> Void

    private var canSave: Bool {
        !habitName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    nameRow
                    timeWheel
                    repeatRow
                    EmojiPicker(selection: $emoji)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color(.systemGray6))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveHabit() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Rows

    private var nameRow: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 26))
                .frame(width: 52, height: 52)
                .background(Color.card)
                .clipShape(Circle())

            TextField("Habit name", text: $habitName)
                .font(.system(size: 18))
                .padding(.horizontal, 18)
                .frame(height: 52)
                .background(Color.card)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var timeWheel: some View {
        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .clipped()
    }

    private var repeatRow: some View {
        NavigationLink {
            RepeatDaysView(selected: $repeatDays)
        } label: {
            HStack {
                Text("Repeat")
                    .font(.system(size: 17, weight: .medium))

                Spacer()

                Text(Habit.repeatText(repeatDays))
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func saveHabit() {
        let newHabit = Habit(
            title: habitName.trimmingCharacters(in: .whitespaces),
            icon: emoji,
            startMinutes: Habit.minutes(from: time),
            endMinutes: nil,
            repeatDays: repeatDays.sorted()
        )

        onSave(newHabit)
        dismiss()
    }
}

// MARK: - Repeat days

struct RepeatDaysView: View {

    @Binding var selected: Set<Int>

    /// Calendar weekday numbers (1 = Sunday), Monday first.
    private let weekdays = [2, 3, 4, 5, 6, 7, 1]

    var body: some View {
        List {
            ForEach(weekdays, id: \.self) { day in
                Button {
                    if selected.contains(day) {
                        selected.remove(day)
                    } else {
                        selected.insert(day)
                    }
                } label: {
                    HStack {
                        Text(Calendar.current.weekdaySymbols[day - 1])
                            .foregroundStyle(.primary)
                        Spacer()
                        if selected.contains(day) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            Section {} footer: {
                Text("Leave everything unselected to repeat every day.")
            }
        }
        .navigationTitle("Repeat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Emoji picker

enum EmojiCategory: CaseIterable {
    case people, nature, food, activity, travel, objects, symbols

    var icon: String {
        switch self {
        case .people: return "face.smiling"
        case .nature: return "pawprint"
        case .food: return "fork.knife"
        case .activity: return "soccerball"
        case .travel: return "car"
        case .objects: return "lightbulb"
        case .symbols: return "heart"
        }
    }

    /// Approximate grouping by Unicode block (Apple's exact grouping isn't exposed by the system).
    private var ranges: [ClosedRange<UInt32>] {
        switch self {
        case .people:
            return [0x1F600...0x1F64F, 0x1F466...0x1F487, 0x1F910...0x1F93F, 0x1F970...0x1F97F,
                    0x1F9D0...0x1F9FF, 0x1F440...0x1F465, 0x261D...0x261D, 0x270A...0x270D]
        case .nature:
            return [0x1F400...0x1F43F, 0x1F980...0x1F9AF, 0x1F331...0x1F344, 0x1F300...0x1F30C,
                    0x1F31D...0x1F336, 0x2600...0x26C8]
        case .food:
            return [0x1F345...0x1F37F, 0x1F950...0x1F96F, 0x1F9C0...0x1F9CB, 0x2615...0x2615]
        case .activity:
            return [0x1F380...0x1F3CA, 0x1F3CF...0x1F3D3, 0x1F94A...0x1F94F, 0x1F3AD...0x1F3AF,
                    0x26BD...0x26BE, 0x1F3A0...0x1F3AC]
        case .travel:
            return [0x1F680...0x1F6FF, 0x1F3D4...0x1F3DF, 0x1F3E0...0x1F3F0, 0x1F30D...0x1F30F]
        case .objects:
            return [0x1F4A1...0x1F4FF, 0x1F50B...0x1F525, 0x1F5A5...0x1F5FF, 0x231A...0x23F3,
                    0x1F9E0...0x1F9FF, 0x2702...0x2709]
        case .symbols:
            return []
        }
    }

    static func of(_ v: UInt32) -> EmojiCategory {
        allCases.first { $0.ranges.contains { $0.contains(v) } } ?? .symbols
    }
}

/// In-app emoji grid with search and a category bar (the system emoji keyboard's search
/// can't be used from a custom field).
struct EmojiPicker: View {

    @Binding var selection: String
    @State private var query = ""
    @State private var category: EmojiCategory = .people

    private struct Entry: Hashable {
        let emoji: String
        let name: String
        let category: EmojiCategory
    }

    private static let all: [Entry] = {
        var entries: [Entry] = []
        for v in UInt32(0x203C)...UInt32(0x1FAFF) {
            guard let scalar = Unicode.Scalar(v), scalar.properties.isEmoji else { continue }
            let props = scalar.properties
            guard props.isEmojiPresentation || v >= 0x2190 else { continue }
            let text = props.isEmojiPresentation ? String(scalar) : String(scalar) + "\u{FE0F}"
            entries.append(Entry(emoji: text, name: (props.name ?? "").lowercased(), category: .of(v)))
        }
        // Group by category in bar order, keeping code point order inside each group.
        let order = EmojiCategory.allCases
        return order.flatMap { cat in entries.filter { $0.category == cat } }
    }()

    private var filtered: [Entry] {
        let words = query.lowercased().split(separator: " ")
        guard !words.isEmpty else { return Self.all }
        return Self.all.filter { entry in words.allSatisfy { entry.name.contains($0) } }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search Emoji", text: $query)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background(Color.card)
            .clipShape(Capsule())

            ScrollViewReader { proxy in
                VStack(spacing: 8) {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 6) {
                            ForEach(filtered, id: \.self) { entry in
                                Button {
                                    selection = entry.emoji
                                } label: {
                                    Text(entry.emoji)
                                        .font(.system(size: 30))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selection == entry.emoji ? Color.card : Color.clear
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                                .id(entry)
                            }
                        }
                    }
                    .frame(height: 260)

                    categoryBar(proxy: proxy)
                }
            }
        }
    }

    private func categoryBar(proxy: ScrollViewProxy) -> some View {
        HStack {
            ForEach(EmojiCategory.allCases, id: \.self) { cat in
                Button {
                    category = cat
                    query = ""
                    if let first = Self.all.first(where: { $0.category == cat }) {
                        withAnimation { proxy.scrollTo(first, anchor: .top) }
                    }
                } label: {
                    Image(systemName: cat.icon)
                        .font(.system(size: 17))
                        .foregroundStyle(category == cat ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(category == cat ? Color(.systemGray4).opacity(0.6) : .clear)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
