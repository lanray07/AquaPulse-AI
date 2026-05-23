import SwiftData
import SwiftUI

struct DrinkLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DrinkEntry.date, order: .reverse) private var entries: [DrinkEntry]

    let profile: UserHydrationProfile
    @State private var showingAddSheet = false
    @State private var selectedEntry: DrinkEntry?

    var body: some View {
        List {
            if entries.isEmpty {
                ContentUnavailableView("No drink history", systemImage: "list.bullet.rectangle", description: Text("Your drinks will appear here."))
                    .listRowSeparator(.hidden)
            } else {
                ForEach(entries) { entry in
                    DrinkEntryRow(entry: entry, unit: profile.preferredUnit)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEntry = entry
                        }
                }
                .onDelete(perform: deleteEntries)
            }
        }
        .navigationTitle("Drink Log")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add drink")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddDrinkEntryView(defaultAmount: profile.preferredCupSize)
        }
        .sheet(item: $selectedEntry) { entry in
            EditDrinkEntryView(entry: entry)
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }

        try? modelContext.save()
    }
}

struct AddDrinkEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let defaultAmount: Double
    @State private var amount: Double
    @State private var drinkType: DrinkType = .water
    @State private var date: Date = .now

    private var favouriteAmounts: [Double] {
        Array(Set([100.0, 250.0, 500.0, defaultAmount])).sorted()
    }

    init(defaultAmount: Double) {
        self.defaultAmount = defaultAmount
        _amount = State(initialValue: defaultAmount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Drink") {
                    Stepper(value: $amount, in: 25...2000, step: 25) {
                        Text("Amount: \(Int(amount)) ml")
                    }
                    Picker("Type", selection: $drinkType) {
                        ForEach(DrinkType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    DatePicker("Date", selection: $date)
                }

                Section("Favourites") {
                    ForEach(favouriteAmounts, id: \.self) { favourite in
                        Button("\(Int(favourite)) ml") {
                            amount = favourite
                        }
                    }
                }
            }
            .navigationTitle("Add Drink")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(DrinkEntry(amount: amount, drinkType: drinkType, date: date))
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditDrinkEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var entry: DrinkEntry

    var body: some View {
        NavigationStack {
            Form {
                Section("Drink") {
                    Stepper(value: $entry.amount, in: 25...2000, step: 25) {
                        Text("Amount: \(Int(entry.amount)) ml")
                    }
                    Picker("Type", selection: Binding(get: { entry.drinkType }, set: { entry.drinkType = $0 })) {
                        ForEach(DrinkType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    DatePicker("Date", selection: $entry.date)
                }

                Section {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(entry)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Drink")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
