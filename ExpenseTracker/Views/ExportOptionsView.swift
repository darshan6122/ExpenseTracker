import SwiftUI
import UniformTypeIdentifiers

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var expenseManager: ExpenseManager
    
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var showingExportResult = false
    @State private var showingDateError = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    
    private var filteredExpenses: [Expense] {
        expenseManager.expenses.filter { expense in
            let afterStart = Calendar.current.startOfDay(for: expense.date) >= Calendar.current.startOfDay(for: startDate)
            let beforeEnd = Calendar.current.startOfDay(for: expense.date) <= Calendar.current.startOfDay(for: endDate)
            return afterStart && beforeEnd
        }
    }
    
    private var dateError: Bool {
        Calendar.current.startOfDay(for: startDate) > Calendar.current.startOfDay(for: endDate)
    }
    
    private var fileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let baseFileName = "expenses_\(dateFormatter.string(from: startDate))_to_\(dateFormatter.string(from: endDate))"
        switch selectedFormat {
        case .pdf:
            return baseFileName + ".pdf"
        case .csv:
            return baseFileName + ".csv"
        case .analytics:
            return "expense_analysis_\(dateFormatter.string(from: startDate))_to_\(dateFormatter.string(from: endDate)).pdf"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    if dateError {
                        Text("Start date must be before end date")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section("Export Format") {
                    Picker("Format", selection: $selectedFormat) {
                        Text("PDF Statement").tag(ExportFormat.pdf)
                        Text("CSV Data").tag(ExportFormat.csv)
                        Text("Analytics Report").tag(ExportFormat.analytics)
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedFormat == .analytics {
                        Text("The analytics report includes spending trends, category breakdown, and key statistics.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(filteredExpenses.count) expenses will be analyzed")
                        Text("File name: \(fileName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: exportExpenses) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text(selectedFormat == .analytics ? "Generate Report" : "Export Expenses")
                        }
                    }
                    .disabled(dateError || filteredExpenses.isEmpty)
                }
            }
            .navigationTitle(selectedFormat == .analytics ? "Generate Analytics" : "Export Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid Date Range", isPresented: $showingDateError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please ensure the start date is not after the end date.")
            }
            .alert("Export Complete", isPresented: $showingExportResult) {
                Button("Share", role: .none) {
                    showingShareSheet = true
                }
                Button("Done", role: .cancel) {
                    dismiss()
                }
            } message: {
                if exportedFileURL != nil {
                    Text("Your expenses have been exported to '\(fileName)'. Choose 'Share' to save or share the file.")
                } else {
                    Text("Failed to export expenses. Please try again.")
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func exportExpenses() {
        // Double-check date validation
        guard !dateError else {
            showingDateError = true
            return
        }
        
        exportedFileURL = ExportService.exportExpenses(
            expenseManager.expenses,
            accounts: expenseManager.accounts,
            format: selectedFormat,
            startDate: startDate,
            endDate: endDate
        )
        
        showingExportResult = true
    }
}

#Preview {
    ExportOptionsView()
        .environmentObject(ExpenseManager())
} 