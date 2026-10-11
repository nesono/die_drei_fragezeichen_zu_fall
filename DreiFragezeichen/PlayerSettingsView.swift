import SwiftUI

struct PlayerSettingsView: View {
    @AppStorage("suggestionPool") private var suggestionPool: SuggestionPool = .all
    @EnvironmentObject private var listening: ListeningStore
    @State private var exclusionDaysText = ""
    private var validExclusionDays: Int? {
        guard let days = Int(exclusionDaysText), ListeningStore.exclusionDayRange.contains(days) else { return nil }
        return days
    }
    @Binding var player: PlaybackService
    @State private var confirmClear = false
    @State private var clearing = false
    @State private var cacheMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Player", selection: $player) {
                        ForEach(PlaybackService.allCases) { service in
                            Text(service.name).tag(service)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Wiedergabe")
                } footer: {
                    Text("Deine Auswahl wird gespeichert. Folgen werden im gewählten Dienst geöffnet. Die Wiedergabe und Geräteauswahl steuerst du dort. Wenn ein direkter Link fehlt, öffnen wir die Suche und kopieren den Folgentitel.")
                }
                Section {
                    Picker("Auswahl", selection: $suggestionPool) {
                        ForEach(SuggestionPool.allCases) { Text($0.title(excludingDays: listening.exclusionDays)).tag($0) }
                    }
                } header: {
                    Text("Zufallsauswahl")
                } footer: {
                    Text("Gilt für den nächsten Zufallsvorschlag. Die aktuelle Folge, der Verlauf und die Folgenliste bleiben verfügbar. Eine leere Auswahl wird nicht automatisch durch andere Folgen ersetzt.")
                }
                Section {
                    HStack {
                        Text("Gehörte Folgen ausschließen")
                        Spacer()
                        TextField("Tage", text: $exclusionDaysText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                            .accessibilityLabel("Ausschlussdauer in Tagen")
                            .accessibilityIdentifier("exclusionDays")
                        Text("Tage").foregroundStyle(.secondary)
                    }
                    if validExclusionDays == nil {
                        Text("Bitte eine ganze Zahl von 1 bis 3650 eingeben.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Wieder in die Auswahl")
                } footer: {
                    Text("Gilt nur für die Auswahl „Seit … nicht gehört“. Nach dieser Anzahl an Tagen seit dem letzten Hören kann eine Folge wieder vorgeschlagen werden. Ungehörte Folgen bleiben verfügbar. Standard: 30 Tage.")
                }
                Section("Speicher") {
                    Button("Cover-Cache löschen", role: .destructive) { confirmClear = true }
                        .disabled(clearing)
                    if let cacheMessage { Text(cacheMessage).font(.footnote) }
                }
                Section("Informationen") {
                    NavigationLink("Datenschutz") { PrivacyView() }
                    NavigationLink("Quellen & Hinweise") { CreditsView() }
                }
            }
            .onAppear { exclusionDaysText = String(listening.exclusionDays) }
            .onChange(of: exclusionDaysText) { _, _ in
                if let days = validExclusionDays { listening.setExclusionDays(days) }
            }
            .confirmationDialog("Gespeicherte Cover löschen?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Cover löschen", role: .destructive) {
                    clearing = true
                    Task {
                        do {
                            try await ArtworkCache.shared.clear()
                            cacheMessage = "Gespeicherte Cover gelöscht. Beim erneuten Ansehen werden sie wieder geladen."
                        } catch {
                            cacheMessage = "Die Cover konnten nicht vollständig gelöscht werden. Bitte versuche es erneut."
                        }
                        clearing = false
                    }
                }
            } message: {
                Text("Folgenkatalog und Player-Auswahl bleiben erhalten.")
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .disabled(validExclusionDays == nil)
                }
            }
        }
    }
}
