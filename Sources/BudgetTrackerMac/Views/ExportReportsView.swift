import SwiftUI
import UniformTypeIdentifiers

struct ExportReportsView: View {
    @ObservedObject var dataStore: BudgetDataStore
    @State private var showingSavePanel = false
    @State private var exportFormat: ExportFormat = .csv
    @State private var exportType: ExportType = .transactions
    @State private var monthRange: Int = 12
    @State private var exportMessage = ""

    enum ExportType: String, CaseIterable {
        case transactions = "All Transactions"
        case monthlyReport = "Monthly Summary Report"
        case jsonExport = "JSON Export (All Data)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("📤 Export Reports")
                        .font(.title2.bold())
                    Spacer()
                }

                Divider()

                // Export Configuration
                settingsSection("Export Settings") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Export Type", selection: $exportType) {
                            ForEach(ExportType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }

                        if exportType == .monthlyReport {
                            HStack {
                                Text("Month Range")
                                Spacer()
                                Picker("", selection: $monthRange) {
                                    Text("3 months").tag(3)
                                    Text("6 months").tag(6)
                                    Text("12 months").tag(12)
                                    Text("24 months").tag(24)
                                    Text("All").tag(999)
                                }
                                .frame(width: 150)
                            }
                        }

                        Picker("Format", selection: $exportFormat) {
                            Text("CSV").tag(ExportFormat.csv)
                            Text("JSON").tag(ExportFormat.json)
                            if exportType == .monthlyReport {
                                Text("Text Report").tag(ExportFormat.pdf)
                            }
                        }
                    }
                }

                // Preview
                settingsSection("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(previewText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.appBackground)
                            .cornerRadius(8)

                        Text("\(dataStore.transactions.count) transactions available")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                // Export Buttons
                VStack(spacing: 12) {
                    Button(action: exportData) {
                        Label("Export & Save", systemImage: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if !exportMessage.isEmpty {
                        Text(exportMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.green)
                    }
                }

                // Quick Export Buttons
                settingsSection("Quick Export") {
                    HStack(spacing: 12) {
                        Button("CSV - All Transactions") {
                            exportFormat = .csv
                            exportType = .transactions
                            quickExportCSV()
                        }
                        .buttonStyle(.bordered)

                        Button("JSON - All Data") {
                            exportFormat = .json
                            exportType = .jsonExport
                            quickExportJSON()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(30)
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    private var previewText: String {
        switch exportType {
        case .transactions:
            return "Date,Description,Amount,Category,Merchant,Notes,Source,Is Income\n2026-04-06,\"Sample Transaction\",50.00,Groceries,...\n..."
        case .monthlyReport:
            return "Monthly Financial Report\nGenerated: April 2026\n============================================\n\nApril 2026\n  Income:   $0.00\n  Expenses: $0.00\n  Net:      $0.00\n..."
        case .jsonExport:
            return "[\n  {\n    \"amount\": 50.00,\n    \"category\": \"Groceries\",\n    \"date\": \"2026-04-06T...\",\n    ...\n  }\n]"
        }
    }

    private func exportData() {
        let content: String
        let fileExt: String

        switch exportType {
        case .transactions:
            if exportFormat == .json {
                content = dataStore.exportToJSON()
                fileExt = "json"
            } else {
                content = dataStore.exportToCSV()
                fileExt = "csv"
            }
        case .monthlyReport:
            content = dataStore.exportMonthlyReport(months: monthRange)
            fileExt = "txt"
        case .jsonExport:
            content = dataStore.exportToJSON()
            fileExt = "json"
        }

        saveFile(content: content, fileExtension: fileExt)
    }

    private func quickExportCSV() {
        let content = dataStore.exportToCSV()
        saveFile(content: content, fileExtension: "csv")
    }

    private func quickExportJSON() {
        let content = dataStore.exportToJSON()
        saveFile(content: content, fileExtension: "json")
    }

    private func saveFile(content: String, fileExtension ext: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: ext) ?? .plainText]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        panel.nameFieldStringValue = "BudgetAutopilot_Export_\(dateFormatter.string(from: Date())).\(ext)"
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                    exportMessage = "Exported successfully to \(url.lastPathComponent)"
                } catch {
                    exportMessage = "Export failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
}
