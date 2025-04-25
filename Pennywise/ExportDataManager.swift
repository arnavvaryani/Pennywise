////
////  ExportDataManager.swift
////  Pennywise
////
////  Created by Arnav Varyani on 4/25/25.
////
//
//import SwiftUI
//import PDFKit
//import FirebaseAuth
//import FirebaseFirestore
//import Foundation
//
//
//// Error enum for export
//enum ExportError: Error {
//case notAuthenticated
//case dataFetchFailed
//case pdfGenerationFailed
//
//var localizedDescription: String {
//    switch self {
//    case .notAuthenticated:
//        return "User not logged in"
//    case .dataFetchFailed:
//        return "Failed to fetch financial data"
//    case .pdfGenerationFailed:
//        return "Unable to generate PDF export"
//    }
//}
//}
//
//// SwiftUI View for Export in Settings
//struct ExportDataView: View {
//@State private var isExporting = false
//@State private var exportURL: URL?
//@State private var errorMessage: String?
//
//var body: some View {
//    VStack(spacing: 20) {
//        Image(systemName: "doc.text.fill")
//            .font(.system(size: 50))
//            .foregroundColor(AppTheme.primaryGreen)
//        
//        Text("Export Financial Data")
//            .font(.title2)
//            .fontWeight(.bold)
//            .foregroundColor(AppTheme.textColor)
//        
//        Text("Generate a comprehensive PDF report of your financial data")
//            .multilineTextAlignment(.center)
//            .foregroundColor(AppTheme.textColor.opacity(0.7))
//            .padding(.horizontal)
//        
//        Button(action: exportData) {
//            HStack {
//                if isExporting {
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                } else {
//                    Image(systemName: "square.and.arrow.down")
//                    Text("Export PDF")
//            }
//            }
//            .frame(maxWidth: .infinity)
//            .padding()
//            .background(AppTheme.primaryGreen)
//            .foregroundColor(.white)
//            .cornerRadius(12)
//            .disabled(isExporting)
//        }
//        .padding(.horizontal)
//        
//        // Error message display
//        if let errorMessage = errorMessage {
//            Text(errorMessage)
//                .foregroundColor(AppTheme.expenseColor)
//                .font(.caption)
//        }
//        
//        // Share sheet for exported PDF
//        if let url = exportURL {
//            ShareLink(item: url) {
//                Label("Share Export", systemImage: "square.and.arrow.up")
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(AppTheme.accentBlue)
//                    .foregroundColor(.white)
//                    .cornerRadius(12)
//            }
//            .padding(.horizontal)
//        }
//    }
//    .padding()
//    .background(AppTheme.cardBackground)
//    .cornerRadius(20)
//    .overlay(
//        RoundedRectangle(cornerRadius: 20)
//            .stroke(AppTheme.cardStroke, lineWidth: 1)
//    )
//}
//
//private func exportData() {
//    isExporting = true
//    errorMessage = nil
//    exportURL = nil
//    
//    ExportDataManager.shared.exportAllData { result in
//        DispatchQueue.main.async {
//            isExporting = false
//            
//            switch result {
//            case .success(let url):
//                self.exportURL = url
//            case .failure(let error):
//                self.errorMessage = "Export failed: \(error.localizedDescription)"
//            }
//        }
//    }
//}
//}
