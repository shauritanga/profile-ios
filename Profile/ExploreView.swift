import SwiftUI

// MARK: - Content

private enum ExploreCategory: String, CaseIterable {
    case all = "All"
    case health = "Health"
    case fitness = "Fitness"
    case mind = "Mind"
    case focus = "Focus"
    case learning = "Learning"
    case sleep = "Sleep"
}

private struct Suggestion: Identifiable {
    let emoji: String
    let title: String
    let detail: String
    let category: ExploreCategory
    let minutes: Int   // suggested start time, minutes since midnight

    var id: String { title }

    func makeHabit() -> Habit {
        Habit(title: title, icon: emoji, startMinutes: minutes, endMinutes: nil)
    }
}

private struct Pack: Identifiable {
    let name: String
    let tagline: String
    let emoji: String
    let color: Color
    let titles: [String]

    var id: String { name }
}

private let suggestions: [Suggestion] = [
    Suggestion(emoji: "💧", title: "Drink water", detail: "A glass when you wake up", category: .health, minutes: 7 * 60 + 15),
    Suggestion(emoji: "🥗", title: "Healthy breakfast", detail: "Start the day with real food", category: .health, minutes: 8 * 60),
    Suggestion(emoji: "💊", title: "Take vitamins", detail: "Keep it next to your toothbrush", category: .health, minutes: 8 * 60 + 15),
    Suggestion(emoji: "🚶", title: "Walk 10,000 steps", detail: "Take a walk after lunch", category: .health, minutes: 13 * 60),
    Suggestion(emoji: "🏃", title: "Morning run", detail: "20 easy minutes outside", category: .fitness, minutes: 6 * 60 + 30),
    Suggestion(emoji: "💪", title: "Strength workout", detail: "Push-ups, squats, planks", category: .fitness, minutes: 18 * 60),
    Suggestion(emoji: "🤸", title: "Stretch", detail: "5 minutes to loosen up", category: .fitness, minutes: 7 * 60),
    Suggestion(emoji: "🚴", title: "Cycle", detail: "Commute or a short ride", category: .fitness, minutes: 17 * 60 + 30),
    Suggestion(emoji: "🧘", title: "Morning meditation", detail: "10 quiet minutes", category: .mind, minutes: 8 * 60),
    Suggestion(emoji: "📓", title: "Write in journal", detail: "Three lines about your day", category: .mind, minutes: 21 * 60),
    Suggestion(emoji: "🙏", title: "Gratitude", detail: "Name three good things", category: .mind, minutes: 21 * 60 + 30),
    Suggestion(emoji: "🌬️", title: "Breathing break", detail: "Box breathing for 2 minutes", category: .mind, minutes: 15 * 60),
    Suggestion(emoji: "🗓️", title: "Plan the day", detail: "Pick your top 3 tasks", category: .focus, minutes: 8 * 60 + 30),
    Suggestion(emoji: "🎯", title: "Deep work", detail: "One distraction-free hour", category: .focus, minutes: 9 * 60),
    Suggestion(emoji: "📵", title: "Phone-free hour", detail: "Leave it in another room", category: .focus, minutes: 19 * 60),
    Suggestion(emoji: "🧹", title: "Tidy up", detail: "10 minutes to reset your space", category: .focus, minutes: 18 * 60 + 30),
    Suggestion(emoji: "📖", title: "Read 20 pages", detail: "Keep a book within reach", category: .learning, minutes: 20 * 60),
    Suggestion(emoji: "🎧", title: "Listen to a podcast", detail: "Learn something on the go", category: .learning, minutes: 12 * 60 + 30),
    Suggestion(emoji: "🌍", title: "Practice a language", detail: "One short lesson", category: .learning, minutes: 12 * 60),
    Suggestion(emoji: "🎹", title: "Practice an instrument", detail: "15 focused minutes", category: .learning, minutes: 17 * 60),
    Suggestion(emoji: "😴", title: "Go to bed on time", detail: "Same hour every night", category: .sleep, minutes: 22 * 60 + 30),
    Suggestion(emoji: "🌙", title: "Wind-down routine", detail: "Dim the lights, no screens", category: .sleep, minutes: 21 * 60 + 45),
    Suggestion(emoji: "⏰", title: "Wake up", detail: "Get up without snoozing", category: .sleep, minutes: 6 * 60 + 30),
    Suggestion(emoji: "🫖", title: "Evening herbal tea", detail: "Caffeine-free and calming", category: .sleep, minutes: 21 * 60)
]

private let packs: [Pack] = [
    Pack(name: "Morning Boost", tagline: "Start the day with energy",
         emoji: "🌅", color: Color(red: 1.00, green: 0.91, blue: 0.74),
         titles: ["Wake up", "Drink water", "Stretch", "Morning meditation"]),
    Pack(name: "Healthy Body", tagline: "Move, eat and hydrate",
         emoji: "🥦", color: Color(red: 0.84, green: 0.95, blue: 0.80),
         titles: ["Drink water", "Healthy breakfast", "Walk 10,000 steps", "Strength workout"]),
    Pack(name: "Calm Mind", tagline: "Slow down and reflect",
         emoji: "🧠", color: Color(red: 0.86, green: 0.88, blue: 1.00),
         titles: ["Breathing break", "Gratitude", "Write in journal", "Wind-down routine"]),
    Pack(name: "Deep Focus", tagline: "Get meaningful work done",
         emoji: "🎯", color: Color(red: 0.98, green: 0.86, blue: 0.88),
         titles: ["Plan the day", "Deep work", "Phone-free hour", "Tidy up"])
]

private let tips = [
    "Start tiny. A habit you do for two minutes beats one you skip for an hour.",
    "Attach a new habit to one you already have, like stretching right after brushing your teeth.",
    "Missing once is fine. Missing twice is how a habit slips away, so get back on the next day.",
    "Make it obvious: put your book on your pillow and your water bottle on your desk.",
    "Track it. Seeing a streak grow is a reward in itself.",
    "Pick a time and a place. Habits stick to cues, not good intentions."
]

// MARK: - View

struct ExploreView: View {

    @EnvironmentObject private var store: HabitStore

    @State private var query = ""
    @State private var category: ExploreCategory = .all

    private let ink = Color(red: 0.01, green: 0.12, blue: 0.16)

    private var searching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    private var filtered: [Suggestion] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return suggestions.filter { s in
            (category == .all || s.category == category)
            && (q.isEmpty || s.title.lowercased().contains(q) || s.detail.lowercased().contains(q))
        }
    }

    private var tip: String {
        tips[(Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0) % tips.count]
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    searchBar

                    if !searching {
                        tipCard
                        packsSection
                    }

                    suggestionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Explore")
                    .font(.system(size: 30, weight: .bold))

                Text("Build habits that stick")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 5) {
                Text("\(store.streak)")
                    .fontWeight(.semibold)
                Text("🔥")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.card)
            .clipShape(Capsule())
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search habits", text: $query)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if searching {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 54)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: Tip

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("💡")
                .font(.system(size: 24))
                .frame(width: 46, height: 46)
                .background(Color(.systemGray6))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Tip of the day")
                    .font(.system(size: 17, weight: .semibold))

                Text(tip)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    // MARK: Packs

    private var packsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Starter packs")
                .font(.system(size: 22, weight: .bold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(packs) { pack in
                        packCard(pack)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    private func packCard(_ pack: Pack) -> some View {
        let missing = pack.titles.filter { !isAdded($0) }

        return VStack(alignment: .leading, spacing: 10) {
            Text(pack.emoji)
                .font(.system(size: 34))

            Text(pack.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(ink)

            Text(pack.tagline)
                .font(.system(size: 14))
                .foregroundStyle(ink.opacity(0.65))

            Spacer(minLength: 0)

            HStack {
                Text("\(pack.titles.count) habits")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ink.opacity(0.65))

                Spacer()

                Button {
                    for title in missing {
                        if let s = suggestions.first(where: { $0.title == title }) {
                            store.add(s.makeHabit())
                        }
                    }
                } label: {
                    Text(missing.isEmpty ? "Added ✓" : "Add all")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(missing.isEmpty ? ink : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(missing.isEmpty ? Color.white.opacity(0.7) : ink)
                        .clipShape(Capsule())
                }
                .disabled(missing.isEmpty)
            }
        }
        .padding(18)
        .frame(width: 250, height: 190, alignment: .topLeading)
        .background(pack.color)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    // MARK: Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(searching ? "Results" : "Suggested habits")
                .font(.system(size: 22, weight: .bold))

            categoryBar

            VStack(spacing: 0) {
                if filtered.isEmpty {
                    Text("No habits match your search.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                }

                ForEach(filtered) { item in
                    suggestionRow(item)

                    if item.id != filtered.last?.id {
                        Divider().padding(.leading, 62)
                    }
                }
            }
            .padding(.horizontal, 20)
            .background(Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ExploreCategory.allCases, id: \.self) { cat in
                    Button {
                        category = cat
                    } label: {
                        Text(cat.rawValue)
                            .font(.system(size: 14))
                            .foregroundStyle(category == cat ? .white : .primary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(category == cat ? ink : Color.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }

    private func suggestionRow(_ item: Suggestion) -> some View {
        let added = isAdded(item.title)

        return HStack(spacing: 13) {
            Text(item.emoji)
                .font(.system(size: 22))
                .frame(width: 46, height: 46)
                .background(Color(.systemGray6))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 17, weight: .medium))

                Text("\(item.detail) · \(Habit.format(item.minutes, withSuffix: true))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                store.add(item.makeHabit())
            } label: {
                Image(systemName: added ? "checkmark" : "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(added ? Color.green : ink)
                    .clipShape(Circle())
            }
            .disabled(added)
        }
        .padding(.vertical, 12)
    }

    private func isAdded(_ title: String) -> Bool {
        store.habits.contains { $0.title.lowercased() == title.lowercased() }
    }
}
