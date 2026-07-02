import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.enhancedBackgroundGradient
            
            VStack(spacing: 25) {
                // App logo
                Image(systemName: "dollarsign.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(AppTheme.primaryGreen)
                    .padding(.top, 40)
                
                Text("Pennywise")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textColor)
                
                Text("Version 1.1.0")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                
                Spacer(minLength: 30)
                
                PWGlassCard {
                    VStack(alignment: .leading, spacing: 20) {
                    aboutSectionTitle("About")
                    
                    Text("Pennywise is a comprehensive financial tracking and budget planning app designed to help you take control of your finances and achieve your financial goals.")
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                    
                    aboutSectionTitle("Team")
                    
                    Text("Developed by Arnav Varyani.")
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                    
                    aboutSectionTitle("Contact")
                    
                    Text("arnavvaryani@gmail.com")
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .font(.body)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func aboutSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(AppTheme.primaryGreen)
    }
}
