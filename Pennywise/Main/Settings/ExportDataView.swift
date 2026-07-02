import SwiftUI

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: SettingsViewModel
    
    @State private var isExporting = false
    @State private var exportCompleteMessage: String? = nil
    @State private var showingShareSheet = false
    @State private var fileURLToShare: URL? = nil
    
    var body: some View {
        ZStack {
            AppTheme.enhancedBackgroundGradient
            
            VStack(spacing: 20) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.primaryGreen)
                    .padding(.top, 30)
                
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textColor)
                
                Text("Choose what data you would like to export. The data will be exported as CSV files that you can open in Excel or other spreadsheet applications.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .padding(.horizontal, 20)
                
                PWGlassCard {
                    VStack(spacing: 12) {
                    exportOptionButton(title: "Transactions", icon: "list.bullet.rectangle")
                    exportOptionButton(title: "Budget Categories", icon: "chart.pie")
                    exportOptionButton(title: "Accounts Summary", icon: "building.columns")
                    exportOptionButton(title: "Export All Data", icon: "square.and.arrow.down")
                    }
                }
                .padding(.top, 20)
                
                if isExporting {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
                            .scaleEffect(1.5)
                        
                        Text("Preparing your data...")
                            .foregroundColor(AppTheme.textColor)
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Export Error", isPresented: Binding<Bool>(
            get: { exportCompleteMessage != nil },
            set: { _ in exportCompleteMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportCompleteMessage ?? "")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let fileURL = fileURLToShare {
                ShareSheet(items: [fileURL])
            }
        }
        .disabled(isExporting)
    }
    
    private func exportOptionButton(title: String, icon: String) -> some View {
        Button(action: {
            exportDataAsCSV(type: title)
        }) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.primaryGreen)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.primaryGreen.opacity(0.2))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.primaryGreen)
            }
            .padding()
            .pwGlassSurface(cornerRadius: 12)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isExporting)
    }
    
    private func exportDataAsCSV(type: String) {
        isExporting = true
        
        Task {
            do {
                let url = try await viewModel.exportData(type: type)
                self.fileURLToShare = url
                self.isExporting = false
                self.showingShareSheet = true
            } catch {
                self.isExporting = false
                self.exportCompleteMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }
}
