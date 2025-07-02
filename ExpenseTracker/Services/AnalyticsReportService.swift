import Foundation
import PDFKit
import SwiftUI

class AnalyticsReportService {
    // Helper methods for drawing charts
    private static func drawPieChart(context: CGContext, center: CGPoint, radius: CGFloat, values: [(String, Double)], colors: [UIColor], showPercentages: Bool = true) {
        var startAngle: CGFloat = 0
        let total = values.reduce(0) { $0 + $1.1 }
        
        // Draw pie slices
        for (index, (label, value)) in values.enumerated() {
            let endAngle = startAngle + (CGFloat(value) / CGFloat(total)) * .pi * 2
            let midAngle = startAngle + (endAngle - startAngle) / 2
            
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            path.close()
            
            colors[index % colors.count].setFill()
            path.fill()
            
            // Add percentage labels if enabled
            if showPercentages {
                let percentage = (value / total) * 100
                let percentageStr = String(format: "%.1f%%", percentage)
                
                // Calculate position for percentage label
                let labelRadius = radius * 0.7
                let x = center.x + cos(midAngle) * labelRadius
                let y = center.y + sin(midAngle) * labelRadius
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.white
                ]
                
                let textSize = percentageStr.size(withAttributes: attributes)
                percentageStr.draw(at: CGPoint(x: x - textSize.width/2, y: y - textSize.height/2),
                                 withAttributes: attributes)
            }
            
            startAngle = endAngle
        }
        
        // Draw white circle in center for better appearance
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: center.x - radius/4, y: center.y - radius/4, width: radius/2, height: radius/2))
    }
    
    private static func drawBarChart(context: CGContext, rect: CGRect, values: [(String, Double)], maxValue: Double, showValues: Bool = true) {
        let barSpacing: CGFloat = 10
        let barWidth = (rect.width - (CGFloat(values.count - 1) * barSpacing)) / CGFloat(values.count)
        let labelHeight: CGFloat = 15 // Height reserved for labels
        let chartRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - labelHeight)
        
        // Draw background grid
        context.setStrokeColor(UIColor.gray.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(0.5)
        
        let gridLines = 5
        for i in 0...gridLines {
            let y = chartRect.maxY - (chartRect.height / CGFloat(gridLines)) * CGFloat(i)
            context.move(to: CGPoint(x: chartRect.minX, y: y))
            context.addLine(to: CGPoint(x: chartRect.maxX, y: y))
            context.strokePath()
            
            // Draw amount labels on y-axis
            let amount = (maxValue / Double(gridLines)) * Double(i)
            let amountStr = String(format: "%.0f", amount)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.gray
            ]
            let textSize = amountStr.size(withAttributes: attributes)
            amountStr.draw(
                at: CGPoint(x: chartRect.minX - textSize.width - 5,
                           y: y - textSize.height/2),
                withAttributes: attributes
            )
        }
        
        // Draw axes
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: chartRect.minX, y: chartRect.minY))
        context.addLine(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
        context.addLine(to: CGPoint(x: chartRect.maxX, y: chartRect.maxY))
        context.strokePath()
        
        // Draw bars with gradient and labels
        for (index, (label, value)) in values.enumerated() {
            let barHeight = CGFloat(value / maxValue) * chartRect.height
            let barRect = CGRect(
                x: chartRect.minX + (CGFloat(index) * (barWidth + barSpacing)),
                y: chartRect.maxY - barHeight,
                width: barWidth,
                height: barHeight
            )
            
            // Create gradient
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemBlue.withAlphaComponent(0.7).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors as CFArray,
                                    locations: [0.0, 1.0])!
            
            context.saveGState()
            context.addRect(barRect)
            context.clip()
            context.drawLinearGradient(gradient,
                                     start: CGPoint(x: barRect.midX, y: barRect.minY),
                                     end: CGPoint(x: barRect.midX, y: barRect.maxY),
                                     options: [])
            context.restoreGState()
            
            // Draw value on top of bar if enabled
            if showValues {
                let valueStr = String(format: "%.0f", value)
                let valueAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: UIColor.black
                ]
                let valueSize = valueStr.size(withAttributes: valueAttributes)
                valueStr.draw(
                    at: CGPoint(x: barRect.midX - valueSize.width/2,
                               y: barRect.minY - valueSize.height - 2),
                    withAttributes: valueAttributes
                )
            }
            
            // Draw x-axis label
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.black
            ]
            let labelSize = label.size(withAttributes: labelAttributes)
            
            // Calculate label position and rotation if needed
            let labelX = barRect.minX + (barWidth - labelSize.width)/2
            let labelY = chartRect.maxY + 5
            
            // If label is too wide, draw it at an angle
            if labelSize.width > barWidth {
                context.saveGState()
                context.translateBy(x: labelX + labelSize.width/2,
                                  y: labelY + labelSize.height/2)
                context.rotate(by: -CGFloat.pi/6) // Rotate by 30 degrees
                label.draw(at: CGPoint(x: -labelSize.width/2,
                                     y: -labelSize.height/2),
                          withAttributes: labelAttributes)
                context.restoreGState()
            } else {
                label.draw(at: CGPoint(x: labelX, y: labelY),
                          withAttributes: labelAttributes)
            }
        }
    }
    
    private static func drawLineChart(context: CGContext, rect: CGRect, values: [(Date, Double)], maxValue: Double) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        
        let pointSpacing = rect.width / CGFloat(values.count - 1)
        var points: [CGPoint] = []
        
        // Create points array
        for (index, (_, value)) in values.enumerated() {
            let x = rect.minX + (CGFloat(index) * pointSpacing)
            let y = rect.maxY - (CGFloat(value / maxValue) * rect.height)
            points.append(CGPoint(x: x, y: y))
        }
        
        // Draw background grid
        context.setStrokeColor(UIColor.gray.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(0.5)
        
        let gridLines = 5
        for i in 0...gridLines {
            let y = rect.maxY - (rect.height / CGFloat(gridLines)) * CGFloat(i)
            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            context.strokePath()
        }
        
        // Draw axes
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: rect.minX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.strokePath()
        
        // Draw line
        let path = UIBezierPath()
        path.move(to: points[0])
        
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2)
        path.stroke()
        
        // Draw points
        for point in points {
            context.setFillColor(UIColor.white.cgColor)
            context.fillEllipse(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
            context.setStrokeColor(UIColor.systemBlue.cgColor)
            context.setLineWidth(1)
            context.strokeEllipse(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
        }
        
        // Draw date labels
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8)
        ]
        
        for (index, (date, _)) in values.enumerated() {
            let x = rect.minX + (CGFloat(index) * pointSpacing)
            let dateStr = dateFormatter.string(from: date)
            let textSize = dateStr.size(withAttributes: labelAttributes)
            dateStr.draw(at: CGPoint(x: x - textSize.width/2,
                                   y: rect.maxY + 5),
                        withAttributes: labelAttributes)
        }
    }
    
    private static func drawLegend(at point: CGPoint, items: [(String, Double)], colors: [UIColor], attributes: [NSAttributedString.Key: Any], currencyFormatter: NumberFormatter) {
        var currentY = point.y
        let bulletSize: CGFloat = 8
        let spacing: CGFloat = 5
        
        for (index, (label, value)) in items.enumerated() {
            // Draw color bullet
            let bulletRect = CGRect(x: point.x, y: currentY + 3, width: bulletSize, height: bulletSize)
            let path = UIBezierPath(ovalIn: bulletRect)
            colors[index % colors.count].setFill()
            path.fill()
            
            // Draw label and value
            let text = "\(label): \(currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value))"
            text.draw(at: CGPoint(x: point.x + bulletSize + spacing, y: currentY), withAttributes: attributes)
            
            currentY += 20
        }
    }

    private static func drawWeekdayChart(context: CGContext, rect: CGRect, values: [(String, Double)], maxValue: Double) {
        let barSpacing: CGFloat = 10
        let barWidth = (rect.width - (CGFloat(values.count - 1) * barSpacing)) / CGFloat(values.count)
        let labelHeight: CGFloat = 15
        let chartRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - labelHeight)
        
        // Draw background grid
        context.setStrokeColor(UIColor.gray.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(0.5)
        
        let gridLines = 5
        for i in 0...gridLines {
            let y = chartRect.maxY - (chartRect.height / CGFloat(gridLines)) * CGFloat(i)
            context.move(to: CGPoint(x: chartRect.minX, y: y))
            context.addLine(to: CGPoint(x: chartRect.maxX, y: y))
            context.strokePath()
        }
        
        // Draw axes
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: chartRect.minX, y: chartRect.minY))
        context.addLine(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
        context.addLine(to: CGPoint(x: chartRect.maxX, y: chartRect.maxY))
        context.strokePath()
        
        // Draw bars
        for (index, (day, value)) in values.enumerated() {
            let barHeight = CGFloat(value / maxValue) * chartRect.height
            let barRect = CGRect(
                x: chartRect.minX + (CGFloat(index) * (barWidth + barSpacing)),
                y: chartRect.maxY - barHeight,
                width: barWidth,
                height: barHeight
            )
            
            // Use different colors for weekends
            let isWeekend = day == "Sat" || day == "Sun"
            let color = isWeekend ? UIColor.systemOrange : UIColor.systemBlue
            
            // Create gradient
            let colors = [color.cgColor, color.withAlphaComponent(0.7).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors as CFArray,
                                    locations: [0.0, 1.0])!
            
            context.saveGState()
            context.addRect(barRect)
            context.clip()
            context.drawLinearGradient(gradient,
                                     start: CGPoint(x: barRect.midX, y: barRect.minY),
                                     end: CGPoint(x: barRect.midX, y: barRect.maxY),
                                     options: [])
            context.restoreGState()
            
            // Draw value
            let valueStr = String(format: "%.0f", value)
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.black
            ]
            let valueSize = valueStr.size(withAttributes: valueAttributes)
            valueStr.draw(
                at: CGPoint(x: barRect.midX - valueSize.width/2,
                           y: barRect.minY - valueSize.height - 2),
                withAttributes: valueAttributes
            )
            
            // Draw day label
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.black
            ]
            let labelSize = day.size(withAttributes: labelAttributes)
            day.draw(
                at: CGPoint(x: barRect.minX + (barWidth - labelSize.width)/2,
                           y: chartRect.maxY + 5),
                withAttributes: labelAttributes
            )
        }
    }

    static func generateReport(expenses: [Expense], accounts: [Account], startDate: Date? = nil, endDate: Date? = nil) -> URL? {
        // Filter expenses by date range if provided
        let filteredExpenses = expenses.filter { expense in
            let afterStart = startDate.map { Calendar.current.startOfDay(for: expense.date) >= Calendar.current.startOfDay(for: $0) } ?? true
            let beforeEnd = endDate.map { Calendar.current.startOfDay(for: expense.date) <= Calendar.current.startOfDay(for: $0) } ?? true
            return afterStart && beforeEnd
        }.sorted { $0.date > $1.date }
        
        // Create PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "ExpenseTracker Analytics",
            kCGPDFContextAuthor: "Generated by ExpenseTracker"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Standard US Letter size (8.5 x 11 inches)
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Define margins
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("expense_analysis.pdf")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM yy"
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        
        // Calculate analytics data
        let totalExpenses = filteredExpenses.reduce(0.0) { $0 + $1.amount }
        let expensesByCategory = Dictionary(grouping: filteredExpenses, by: { $0.category })
            .mapValues { expenses in
                expenses.reduce(0.0) { $0 + $1.amount }
            }
            .sorted { $0.value > $1.value }
        
        let expensesByMonth = Dictionary(grouping: filteredExpenses) { expense in
            Calendar.current.startOfMonth(for: expense.date)
        }
        .mapValues { expenses in
            expenses.reduce(0.0) { $0 + $1.amount }
        }
        .sorted { $0.key > $1.key }
        
        let averageExpense = totalExpenses / Double(filteredExpenses.count)
        let maxExpense = filteredExpenses.max(by: { $0.amount < $1.amount })
        let minExpense = filteredExpenses.min(by: { $0.amount < $1.amount })
        
        // Define chart colors
        let chartColors: [UIColor] = [
            .systemBlue,
            .systemGreen,
            .systemOrange,
            .systemPurple,
            .systemPink,
            .systemTeal,
            .systemIndigo,
            .systemYellow
        ]
        
        // Additional analytics calculations
        let calendar = Calendar.current
        
        // Daily expenses calculation
        let expensesByDay = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        .mapValues { expenses in
            expenses.reduce(0.0) { $0 + $1.amount }
        }
        .sorted { $0.key < $1.key }
        
        let dailyAverage = totalExpenses / Double(Set(filteredExpenses.map { calendar.startOfDay(for: $0.date) }).count)
        
        // Account-wise spending
        let expensesByAccount = Dictionary(grouping: filteredExpenses) { expense in
            accounts.first { $0.id == expense.accountId }?.name ?? "Unknown"
        }
        .mapValues { expenses in
            expenses.reduce(0.0) { $0 + $1.amount }
        }
        .sorted { $0.value > $1.value }
        
        // Spending by day of week
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"
        let expensesByWeekday = Dictionary(grouping: filteredExpenses) { expense in
            weekdayFormatter.string(from: expense.date)
        }
        .mapValues { expenses in
            expenses.reduce(0.0) { $0 + $1.amount }
        }
        
        // Sort by day of week (Sun-Sat)
        let daysOrder = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let weekdayData = daysOrder.map { day in
            (day, expensesByWeekday[day] ?? 0.0)
        }
        
        // Month-over-month growth
        var monthlyGrowth: [(Date, Double)] = []
        if expensesByMonth.count >= 2 {
            for i in 1..<expensesByMonth.count {
                let currentMonth = expensesByMonth[i].value
                let previousMonth = expensesByMonth[i-1].value
                let growth = ((currentMonth - previousMonth) / previousMonth) * 100
                monthlyGrowth.append((expensesByMonth[i].key, growth))
            }
        }
        
        // Spending forecast (simple linear regression)
        var forecast: Double?
        if let lastDate = filteredExpenses.first?.date {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: lastDate)!
            let xValues = expensesByMonth.map { Double(calendar.component(.month, from: $0.key)) }
            let yValues = expensesByMonth.map { $0.value }
            
            if xValues.count >= 2 {
                let xMean = xValues.reduce(0.0, +) / Double(xValues.count)
                let yMean = yValues.reduce(0.0, +) / Double(yValues.count)
                
                var numerator: Double = 0
                var denominator: Double = 0
                
                for i in 0..<xValues.count {
                    numerator += (xValues[i] - xMean) * (yValues[i] - yMean)
                    denominator += pow(xValues[i] - xMean, 2)
                }
                
                let slope = numerator / denominator
                let intercept = yMean - slope * xMean
                
                let nextMonthValue = Double(calendar.component(.month, from: nextMonth))
                forecast = slope * nextMonthValue + intercept
            }
        }
        
        do {
            try pdfRenderer.writePDF(to: fileURL) { context in
                // First page - Overview and Category Analysis
                context.beginPage()
                var currentY: CGFloat = margin
                
                // Title
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24)
                ]
                "Expense Analysis Report".draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
                currentY += 40
                
                // Date Range
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12)
                ]
                let dateRange = "Period: \(dateFormatter.string(from: startDate ?? filteredExpenses.last?.date ?? Date())) to \(dateFormatter.string(from: endDate ?? filteredExpenses.first?.date ?? Date()))"
                dateRange.draw(at: CGPoint(x: margin, y: currentY), withAttributes: dateAttributes)
                currentY += 30
                
                // Summary Section
                let summaryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14)
                ]
                "Summary".draw(at: CGPoint(x: margin, y: currentY), withAttributes: summaryAttributes)
                currentY += 25
                
                let detailAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12)
                ]
                
                // Total Expenses
                "Total Expenses: \(currencyFormatter.string(from: NSNumber(value: totalExpenses)) ?? "")".draw(
                    at: CGPoint(x: margin + 20, y: currentY),
                    withAttributes: detailAttributes
                )
                currentY += 20
                
                // Average Expense
                "Average Expense: \(currencyFormatter.string(from: NSNumber(value: averageExpense)) ?? "")".draw(
                    at: CGPoint(x: margin + 20, y: currentY),
                    withAttributes: detailAttributes
                )
                currentY += 20
                
                // Largest Expense
                if let max = maxExpense {
                    "Largest Expense: \(currencyFormatter.string(from: NSNumber(value: max.amount)) ?? "") (\(max.description))".draw(
                        at: CGPoint(x: margin + 20, y: currentY),
                        withAttributes: detailAttributes
                    )
                }
                currentY += 20
                
                // Smallest Expense
                if let min = minExpense {
                    "Smallest Expense: \(currencyFormatter.string(from: NSNumber(value: min.amount)) ?? "") (\(min.description))".draw(
                        at: CGPoint(x: margin + 20, y: currentY),
                        withAttributes: detailAttributes
                    )
                }
                currentY += 40
                
                // Enhanced Category Breakdown with Pie Chart
                "Spending by Category".draw(at: CGPoint(x: margin, y: currentY), withAttributes: summaryAttributes)
                currentY += 25
                
                let chartSize: CGFloat = 200
                let chartCenter = CGPoint(x: margin + chartSize/2, y: currentY + chartSize/2)
                drawPieChart(
                    context: context.cgContext,
                    center: chartCenter,
                    radius: chartSize/2,
                    values: expensesByCategory.prefix(8).map { ($0.key.rawValue, $0.value) },
                    colors: chartColors,
                    showPercentages: true
                )
                
                // Draw category legend
                drawLegend(
                    at: CGPoint(x: margin + chartSize + 40, y: currentY),
                    items: expensesByCategory.prefix(8).map { ($0.key.rawValue, $0.value) },
                    colors: chartColors,
                    attributes: detailAttributes,
                    currencyFormatter: currencyFormatter
                )
                
                currentY += chartSize + 40
                
                // Account Distribution
                "Spending by Account".draw(at: CGPoint(x: margin, y: currentY), withAttributes: summaryAttributes)
                currentY += 25
                
                let accountChartRect = CGRect(x: margin, y: currentY, width: contentWidth - 40, height: 100)
                drawBarChart(
                    context: context.cgContext,
                    rect: accountChartRect,
                    values: expensesByAccount.map { ($0.key, $0.value) },
                    maxValue: expensesByAccount.map { $0.value }.max() ?? 0,
                    showValues: true
                )
                
                currentY += 125
                
                // Second page - Time-based Analysis
                context.beginPage()
                currentY = margin
                
                "Expense Trends".draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
                currentY += 40
                
                // Monthly Trend with enhanced Bar Chart
                "Monthly Spending".draw(at: CGPoint(x: margin, y: currentY), withAttributes: summaryAttributes)
                currentY += 25
                
                let monthlyData = expensesByMonth.prefix(6).map { (monthFormatter.string(from: $0.key), $0.value) }
                let maxMonthlyAmount = expensesByMonth.map { $0.value }.max() ?? 0
                
                let monthlyChartRect = CGRect(x: margin, y: currentY, width: contentWidth - 40, height: 150)
                drawBarChart(
                    context: context.cgContext,
                    rect: monthlyChartRect,
                    values: monthlyData,
                    maxValue: maxMonthlyAmount,
                    showValues: true
                )
                
                currentY += 200
                
                // Daily Spending Pattern
                "Daily Spending Pattern".draw(at: CGPoint(x: margin, y: currentY), withAttributes: summaryAttributes)
                currentY += 25
                
                // Add daily average line
                "Daily Average: \(currencyFormatter.string(from: NSNumber(value: dailyAverage)) ?? "")".draw(
                    at: CGPoint(x: margin, y: currentY),
                    withAttributes: detailAttributes
                )
                currentY += 25
                
                let dailyChartRect = CGRect(x: margin, y: currentY, width: contentWidth - 40, height: 150)
                drawLineChart(
                    context: context.cgContext,
                    rect: dailyChartRect,
                    values: expensesByDay.suffix(14).map { ($0.key, $0.value) },
                    maxValue: expensesByDay.map { $0.value }.max() ?? 0
                )
                
                // Third page - Advanced Analytics
                context.beginPage()
                currentY = margin
                
                "Advanced Analytics".draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
                currentY += 40
                
                // Spending by Day of Week
                "Spending Patterns by Day".draw(at: CGPoint(x: margin, y: currentY), withAttributes: summaryAttributes)
                currentY += 25
                
                let weekdayChartRect = CGRect(x: margin, y: currentY, width: contentWidth - 40, height: 150)
                drawWeekdayChart(
                    context: context.cgContext,
                    rect: weekdayChartRect,
                    values: weekdayData,
                    maxValue: weekdayData.map { $0.1 }.max() ?? 0
                )
                
                currentY += 200
                
                // Month-over-Month Analysis
                "Month-over-Month Analysis".draw(at: CGPoint(x: margin, y: currentY), withAttributes: summaryAttributes)
                currentY += 25
                
                for (date, growth) in monthlyGrowth {
                    let growthText = "\(monthFormatter.string(from: date)): \(String(format: "%.1f%%", growth)) change"
                    let color: UIColor = growth >= 0 ? .systemGreen : .systemRed
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: color
                    ]
                    growthText.draw(at: CGPoint(x: margin + 20, y: currentY), withAttributes: attributes)
                    currentY += 20
                }
                
                currentY += 40
                
                // Spending Forecast
                "Spending Forecast".draw(at: CGPoint(x: margin, y: currentY), withAttributes: summaryAttributes)
                currentY += 25
                
                if let forecastAmount = forecast {
                    let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
                    let forecastText = "Projected spending for \(monthFormatter.string(from: nextMonth)): \(currencyFormatter.string(from: NSNumber(value: forecastAmount)) ?? "")"
                    forecastText.draw(at: CGPoint(x: margin + 20, y: currentY), withAttributes: detailAttributes)
                    
                    currentY += 20
                    let disclaimer = "* Based on historical spending patterns"
                    disclaimer.draw(
                        at: CGPoint(x: margin + 20, y: currentY),
                        withAttributes: [.font: UIFont.italicSystemFont(ofSize: 10),
                                       .foregroundColor: UIColor.gray]
                    )
                }
                
                // Draw footer
                let footerText = "Generated on \(dateFormatter.string(from: Date()))"
                let footerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10)
                ]
                footerText.draw(at: CGPoint(x: margin, y: pageHeight - margin), withAttributes: footerAttributes)
            }
            return fileURL
        } catch {
            print("Error creating PDF: \(error)")
            return nil
        }
    }
} 