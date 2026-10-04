import SwiftUI

struct PrivacyView: View {
    var body: some View {
        List {
            Section("Auf deinem Gerät") {
                Text("Die App speichert den gewählten Player und die Bestätigung zum Katalogdownload in ihren Einstellungen. Folgenkatalog und angesehene Cover werden lokal gespeichert. Der Auswahlverlauf bleibt nur während der aktuellen App-Sitzung erhalten.")
                Text("Cover bleiben gespeichert, bis du sie in den Einstellungen löschst oder die App entfernst. Angezeigte Bilder können bis zum Schließen der Ansicht im Arbeitsspeicher bleiben. Beim erneuten Ansehen werden gelöschte Cover wieder geladen. Die heruntergeladenen Dateien werden von der App von Gerätebackups ausgeschlossen.")
            }
            Section("Internetverbindungen") {
                Text("Zum Laden des Katalogs verbindet sich die App mit dreimetadaten.de. Cover werden von den im Katalog angegebenen Anbietern geladen, beispielsweise Apple oder der offiziellen Hörspiel-Website. Dabei erhalten diese Anbieter technisch notwendige Verbindungsdaten wie deine IP-Adresse und die angefragte Datei. Deren Verarbeitung richtet sich nach den jeweiligen Datenschutzbestimmungen.")
                Text("Beim Öffnen einer Folge oder Suche wird der ausgewählte Dienst (Apple Music oder Spotify) geöffnet. Dort gelten die Bedingungen und Datenschutzbestimmungen dieses Dienstes. Die App greift nicht auf dein Konto oder deine Musikbibliothek zu.")
            }
            Section("Zwischenablage") {
                Text("Beim Öffnen einer Folge kopiert die App ihren Link oder, falls er fehlt, den Folgentitel in die Zwischenablage. Vorhandene Inhalte werden dabei ersetzt. Die App liest die Zwischenablage nicht aus.")
            }
            Section("Analyse und Werbung") {
                Text("Die App enthält keine Werbe- oder Analyse-SDKs und führt kein appübergreifendes Tracking durch. Sie betreibt kein eigenes Benutzerkonto und sendet deinen Auswahlverlauf nicht an einen eigenen Server.")
            }
        }
        .navigationTitle("Datenschutz")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreditsView: View {
    var body: some View {
        List {
            Section("Metadaten") {
                Link("dreimetadaten.de", destination: URL(string: "https://dreimetadaten.de/")!)
                Link("Creative Commons Namensnennung 4.0", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
                Text("Die App stellt einen gefilterten Ausschnitt der nummerierten Folgen dar und blendet zukünftige Veröffentlichungen aus. Coverbilder und Beschreibungstexte sind von der Datenlizenz ausgenommen.")
            }
            Section("Über diese App") {
                Text("Ein unabhängiger Folgenfinder. Keine offizielle App der Rechteinhaber von Die drei ???, Apple oder Spotify.")
            }
        }
        .navigationTitle("Quellen & Hinweise")
        .navigationBarTitleDisplayMode(.inline)
    }
}
