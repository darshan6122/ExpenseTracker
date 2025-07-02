import SwiftUI
import PhotosUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var category: Category = .other
    @State private var date = Date()
    @State private var isRecurring = false
    @State private var selectedAccountId: UUID?
    @State private var selectedItem: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var isProcessingImage = false
    @State private var showingImageError = false
    @State private var imageError: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    HStack {
                        Text("C$")
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Description", text: $description)
                    
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
                    Picker("Account", selection: $selectedAccountId) {
                        ForEach(expenseManager.accounts) { account in
                            Text(account.name)
                                .tag(Optional(account.id))
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Toggle("Recurring Expense", isOn: $isRecurring)
                }
                
                Section(header: Text("Receipt")) {
                    if let receiptImage = receiptImage {
                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                        
                        Button("Remove Receipt") {
                            self.receiptImage = nil
                        }
                        .foregroundColor(.red)
                    } else {
                        PhotosPicker(selection: $selectedItem,
                                   matching: .images) {
                            Label("Add Receipt", systemImage: "doc.text.image")
                        }
                    }
                }
                
                Section {
                    Button("Save Expense") {
                        saveExpense()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(amount.isEmpty || description.isEmpty || selectedAccountId == nil || isProcessingImage)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                if selectedAccountId == nil && !expenseManager.accounts.isEmpty {
                    selectedAccountId = expenseManager.accounts[0].id
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    await loadImage(from: newItem)
                }
            }
            .alert("Image Processing Error", isPresented: $showingImageError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(imageError ?? "Unknown error")
            }
        }
    }
    
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isProcessingImage = true
        defer { isProcessingImage = false }
        
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw ImageProcessingError.invalidImage
            }
            
            let (processedImage, text) = try await ImageProcessingService.shared.processReceiptImage(image)
            
            // If we got text from the receipt, try to extract amount and description
            if !text.isEmpty {
                await MainActor.run {
                    self.receiptImage = processedImage
                    // TODO: Implement receipt text parsing to extract amount and description
                }
            } else {
                await MainActor.run {
                    self.receiptImage = processedImage
                }
            }
        } catch {
            await MainActor.run {
                self.imageError = error.localizedDescription
                self.showingImageError = true
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount),
              let accountId = selectedAccountId else { return }
        
        let expense = Expense(
            amount: amountValue,
            description: description,
            category: category,
            date: date,
            isRecurring: isRecurring,
            accountId: accountId
        )
        
        do {
            try expenseManager.addExpense(expense)
            
            // Save receipt image if available
            if let receiptImage = receiptImage {
                Task {
                    do {
                        let imageURL = try ImageProcessingService.shared.saveImage(receiptImage, for: expense.id)
                        // Update expense with receipt image URL
                        var updatedExpense = expense
                        updatedExpense.receiptImageURL = imageURL
                        try expenseManager.updateExpense(updatedExpense)
                    } catch {
                        print("Failed to save receipt image: \(error)")
                    }
                }
            }
            
            dismiss()
        } catch {
            // TODO: Show error alert
            print("Failed to save expense: \(error)")
        }
    }
}

#Preview {
    AddExpenseView()
        .environmentObject(ExpenseManager())
} 