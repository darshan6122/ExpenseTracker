import SwiftUI

struct ExpenseListView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @State private var selectedExpense: Expense?
    @State private var showingEditSheet = false
    @State private var showingReceiptImage = false
    @State private var receiptImage: UIImage?
    @State private var showingImageError = false
    @State private var imageError: String?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(expenseManager.expenses.sorted(by: { $0.date > $1.date })) { expense in
                    ExpenseRow(expense: expense) {
                        selectedExpense = expense
                        showingEditSheet = true
                    } onReceiptTap: {
                        loadReceiptImage(for: expense)
                    }
                }
                .onDelete(perform: deleteExpenses)
            }
            .navigationTitle("Expenses")
            .overlay {
                if expenseManager.expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "dollarsign.circle",
                        description: Text("Add your first expense by tapping the + button")
                    )
                }
            }
            .sheet(item: $selectedExpense) { expense in
                EditExpenseView(expense: expense)
            }
            .sheet(isPresented: $showingReceiptImage) {
                if let receiptImage = receiptImage {
                    NavigationView {
                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .navigationTitle("Receipt")
                            .navigationBarItems(trailing: Button("Done") {
                                showingReceiptImage = false
                            })
                    }
                }
            }
            .alert("Image Loading Error", isPresented: $showingImageError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(imageError ?? "Unknown error")
            }
        }
    }
    
    private func deleteExpenses(at offsets: IndexSet) {
        offsets.forEach { index in
            let expense = expenseManager.expenses.sorted(by: { $0.date > $1.date })[index]
            expenseManager.deleteExpense(expense)
        }
    }
    
    private func loadReceiptImage(for expense: Expense) {
        Task {
            do {
                if let receiptURL = expense.receiptImageURL {
                    let image = try ImageProcessingService.shared.loadImage(from: receiptURL)
                    await MainActor.run {
                        self.receiptImage = image
                        self.showingReceiptImage = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.imageError = error.localizedDescription
                    self.showingImageError = true
                }
            }
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    let onEdit: () -> Void
    let onReceiptTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: expense.category.icon)
                .foregroundColor(.blue)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(expense.description)
                    .font(.headline)
                Text(expense.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(expense.amount, format: .currency(code: "CAD"))
                    .font(.headline)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if expense.receiptImageURL != nil {
                Button {
                    onReceiptTap()
                } label: {
                    Image(systemName: "doc.text.image")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .padding(.leading, 8)
            }
            
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExpenseListView()
        .environmentObject(ExpenseManager())
} 
