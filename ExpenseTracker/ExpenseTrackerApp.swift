//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Darshan Bodara on 2025-03-13.
//

import SwiftUI

@main
struct ExpenseTrackerApp: App {
    let persistenceController = CoreDataManager.shared
    @StateObject private var expenseManager = ExpenseManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(expenseManager)
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .onAppear {
                    expenseManager.processRecurringExpenses()
                }
        }
    }
}
