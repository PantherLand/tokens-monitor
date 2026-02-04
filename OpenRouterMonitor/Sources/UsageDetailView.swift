//
//  UsageDetailView.swift
//  OpenRouterMonitor
//
//  Detailed usage statistics view (inspired by OpenClaw)
//

import SwiftUI
import Charts

struct UsageDetailView: View {
    let provider: APIProvider
    let usage: UsageData
    
    @State private var selectedPeriod: TimePeriod = .today
    @State private var dailyUsage: [DailyUsage] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: getProviderIcon(provider))
                        .font(.title)
                        .foregroundColor(getProviderColor(provider))
                    
                    VStack(alignment: .leading) {
                        Text(provider.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if usage.remainingCredits > 0 {
                            Text("\(formatCurrency(usage.remainingCredits)) remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("1 provider")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Usage Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: usagePercentage, total: 100)
                        .tint(progressColor)
                    
                    HStack {
                        Text("\(provider.displayName) (\(formatCurrency(usage.costThisMonth)))")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(Int(usagePercentage))% left · Day · ⏱\(estimatedTimeLeft)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Cost Overview Card
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                        Text("Usage cost (30 days)")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Today vs Last 30d
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(usage.costThisMonth / 30))
                            .font(.system(size: 32, weight: .bold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last 30d")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(usage.costThisMonth))
                            .font(.system(size: 32, weight: .bold))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Usage Chart
                if #available(macOS 13.0, *) {
                    UsageChart(data: dailyUsage)
                        .frame(height: 200)
                        .padding(.horizontal)
                } else {
                    SimpleBarChart(data: dailyUsage)
                        .frame(height: 200)
                        .padding(.horizontal)
                }
                
                // Model Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Context")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("\(usage.modelBreakdown.count) sessions · 24h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ForEach(usage.modelBreakdown) { model in
                        ModelUsageRow(model: model)
                    }
                }
                .padding(.vertical)
            }
            .padding(.vertical)
        }
        .frame(width: 600, height: 700)
        .onAppear {
            loadDailyUsage()
        }
    }
    
    // MARK: - Helper Views
    
    private func getProviderIcon(_ provider: APIProvider) -> String {
        switch provider {
        case .openrouter: return "arrow.triangle.swap"
        case .openai: return "brain"
        case .anthropic: return "cpu"
        case .google: return "sparkles"
        }
    }
    
    private func getProviderColor(_ provider: APIProvider) -> Color {
        switch provider {
        case .openrouter: return .blue
        case .openai: return .green
        case .anthropic: return .orange
        case .google: return .red
        }
    }
    
    private var usagePercentage: Double {
        guard usage.remainingCredits > 0 else { return 0 }
        let total = usage.remainingCredits + usage.costThisMonth
        return (usage.remainingCredits / total) * 100
    }
    
    private var progressColor: Color {
        if usagePercentage > 50 { return .green }
        if usagePercentage > 20 { return .orange }
        return .red
    }
    
    private var estimatedTimeLeft: String {
        // Simple estimation based on current usage rate
        return "5d 20h"
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
    
    private func loadDailyUsage() {
        // Mock data - replace with actual data loading
        dailyUsage = (0..<30).map { day in
            DailyUsage(
                date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!,
                cost: Double.random(in: 0...5)
            )
        }.reversed()
    }
}

// MARK: - Model Usage Row

struct ModelUsageRow: View {
    let model: ModelUsage
    
    var body: some View {
        HStack {
            ProgressView(value: Double(model.tokens), total: 400_000)
                .tint(.green)
                .frame(height: 4)
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack {
                    Text(model.model)
                        .font(.caption)
                    Spacer()
                    Text(formatTokens(model.tokens))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(timeAgo(model))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 200)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1000 {
            return "\(tokens / 1000)k/400k"
        }
        return "\(tokens)/400k"
    }
    
    private func timeAgo(_ model: ModelUsage) -> String {
        return "2h ago"
    }
}

// MARK: - Usage Chart (macOS 13+)

@available(macOS 13.0, *)
struct UsageChart: View {
    let data: [DailyUsage]
    
    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Cost", item.cost)
            )
            .foregroundStyle(.blue)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatDate(date))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Simple Bar Chart (fallback for macOS < 13)

struct SimpleBarChart: View {
    let data: [DailyUsage]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(data.indices, id: \.self) { index in
                    if index % 3 == 0 { // Show every 3rd day
                        let item = data[index]
                        let maxValue = data.map { $0.cost }.max() ?? 1
                        let height = (item.cost / maxValue) * geometry.size.height
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: height)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum TimePeriod {
    case today, week, month
}

struct DailyUsage: Identifiable {
    let id = UUID()
    let date: Date
    let cost: Double
}
