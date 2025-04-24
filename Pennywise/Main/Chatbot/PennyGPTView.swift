////
////  PennyGPTView.swift
////  Pennywise
////
////  Created by Arnav Varyani on 4/22/25.
////
//
//import SwiftUI
//
//struct PennyGPTView: View {
//   // @StateObject private var llmManager = MLCLLMManager.shared
//    @State private var userPrompt = ""
//    @State private var scrollProxy: ScrollViewProxy? = nil
//    @State private var showingModelInfo = false
//    @State private var lastMessageId: UUID? = nil
//    
//    private let maxInputHeight: CGFloat = 120
//    
//    var body: some View {
//        ZStack {
//            // Background gradient
//            AppTheme.backgroundGradient
//                .edgesIgnoringSafeArea(.all)
//            
//            VStack(spacing: 0) {
//                // Header with PennyGPT title
//                headerView
//                
//                if !llmManager.isModelLoaded {
//                    modelLoadingView
//                }
////                else {
////                    // Chat content
////                    chatContentView
////                    
////                    // Input area
////                    messageInputView
////                }
//            }
//        }
//        .sheet(isPresented: $showingModelInfo) {
//            modelInfoView
//        }
//        .navigationTitle("PennyGPT")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//    
//    // MARK: - Header View
//    
//    private var headerView: some View {
//        HStack {
//            Text("PennyGPT")
//                .font(.title2)
//                .fontWeight(.bold)
//                .foregroundColor(AppTheme.textColor)
//            
//            Spacer()
//            
//            Button(action: {
//                showingModelInfo = true
//            }) {
//                Image(systemName: "info.circle")
//                    .font(.system(size: 20))
//                    .foregroundColor(AppTheme.textColor)
//                    .padding(8)
//                    .background(
//                        Circle()
//                            .fill(AppTheme.accentPurple.opacity(0.3))
//                    )
//            }
//            .buttonStyle(ScaleButtonStyle())
//        }
//        .padding(.horizontal)
//        .padding(.top, 8)
//    }
//    
//    // MARK: - Model Loading View
//    
//    private var modelLoadingView: some View {
//        VStack(spacing: 20) {
//            Spacer()
//            
//            ZStack {
//                Circle()
//                    .fill(AppTheme.accentPurple.opacity(0.2))
//                    .frame(width: 120, height: 120)
//                
//                Image(systemName: "brain")
//                    .font(.system(size: 50))
//                    .foregroundColor(AppTheme.accentPurple)
//            }
//            
//            Text("Loading PennyGPT")
//                .font(.title2)
//                .fontWeight(.bold)
//                .foregroundColor(AppTheme.textColor)
//            
//            Text("Setting up your personal financial assistant...")
//                .font(.subheadline)
//                .foregroundColor(AppTheme.textColor.opacity(0.7))
//                .multilineTextAlignment(.center)
//                .padding(.horizontal, 40)
//            
//            // Progress bar
//            VStack(spacing: 8) {
//                ProgressView(value: llmManager.modelLoadingProgress)
//                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primaryGreen))
//                    .frame(width: 250)
//                
//                Text("\(Int(llmManager.modelLoadingProgress * 100))%")
//                    .font(.caption)
//                    .foregroundColor(AppTheme.textColor.opacity(0.7))
//            }
//            .padding(.top)
//            
//            Spacer()
//        }
//        .padding()
//    }
//    
//    // MARK: - Chat Content View
//    
//    private var chatContentView: View {
//        ScrollView {
//            ScrollViewReader { proxy in
//                LazyVStack(spacing: 16) {
//                    // Welcome message if no messages
//                    if llmManager.getConversationHistory().isEmpty {
//                        welcomeMessage
//                    }
//                    
//                    // Messages
//                    ForEach(llmManager.getConversationHistory()) { message in
//                        messageView(for: message)
//                            .id(message.id)
//                            .onAppear {
//                                // Save the last message ID to scroll to it
//                                lastMessageId = message.id
//                            }
//                    }
//                    
//                    // Show thinking indicator when generating
//                    if llmManager.isGenerating {
//                        typingIndicator
//                    }
//                }
//                .padding(.horizontal)
//                .padding(.top, 16)
//                .padding(.bottom, 8)
//                .onChange(of: lastMessageId) { id in
//                    if let id = id {
//                        withAnimation {
//                            proxy.scrollTo(id, anchor: .bottom)
//                        }
//                    }
//                }
//                .onAppear {
//                    scrollProxy = proxy
//                    // Scroll to the last message if there is one
//                    if let lastID = llmManager.getConversationHistory().last?.id {
//                        withAnimation {
//                            proxy.scrollTo(lastID, anchor: .bottom)
//                        }
//                    }
//                }
//            }
//        }
//        .background(AppTheme.backgroundColor.opacity(0.2))
//    }
//    
//    // MARK: - Welcome Message
//    
//    private var welcomeMessage: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            HStack(spacing: 15) {
//                // Assistant icon
//                ZStack {
//                    Circle()
//                        .fill(AppTheme.primaryGreen.opacity(0.2))
//                        .frame(width: 40, height: 40)
//                    
//                    Image(systemName: "brain.head.profile")
//                        .font(.system(size: 20))
//                        .foregroundColor(AppTheme.primaryGreen)
//                }
//                
//                Text("PennyGPT")
//                    .font(.headline)
//                    .foregroundColor(AppTheme.primaryGreen)
//                
//                Spacer()
//                
//                Text("Just now")
//                    .font(.caption)
//                    .foregroundColor(AppTheme.textColor.opacity(0.5))
//            }
//            
//            Text("👋 Hi there! I'm PennyGPT, your personal financial assistant. I can help you with budgeting advice, saving strategies, expense analysis, and more. What financial questions can I help you with today?")
//                .font(.body)
//                .foregroundColor(AppTheme.textColor)
//                .padding()
//                .background(AppTheme.cardBackground)
//                .cornerRadius(16)
//            
//            // Sample questions
//            VStack(alignment: .leading, spacing: 10) {
//                Text("Try asking:")
//                    .font(.subheadline)
//                    .foregroundColor(AppTheme.textColor.opacity(0.7))
//                
//                ForEach(sampleQuestions, id: \.self) { question in
//                    Button(action: {
//                        userPrompt = question
//                        sendMessage()
//                    }) {
//                        Text(question)
//                            .font(.subheadline)
//                            .foregroundColor(AppTheme.accentBlue)
//                            .padding(.vertical, 8)
//                            .padding(.horizontal, 12)
//                            .background(AppTheme.accentBlue.opacity(0.1))
//                            .cornerRadius(8)
//                    }
//                }
//            }
//            .padding(.vertical, 10)
//        }
//        .padding()
//        .background(AppTheme.cardBackground.opacity(0.5))
//        .cornerRadius(16)
//    }
//    
//    // Sample questions for the user
//    private let sampleQuestions = [
//        "How can I improve my budget?",
//        "What's a good saving strategy for me?",
//        "Analyze my spending patterns",
//        "Tips to reduce my expenses"
//    ]
//    
//    // MARK: - Message View
//    
//    private func messageView(for message: Message) -> some View {
//        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
//            HStack(spacing: 15) {
//                if message.role == .assistant {
//                    // Assistant icon
//                    ZStack {
//                        Circle()
//                            .fill(AppTheme.primaryGreen.opacity(0.2))
//                            .frame(width: 40, height: 40)
//                        
//                        Image(systemName: "brain.head.profile")
//                            .font(.system(size: 20))
//                            .foregroundColor(AppTheme.primaryGreen)
//                    }
//                    
//                    Text("PennyGPT")
//                        .font(.headline)
//                        .foregroundColor(AppTheme.primaryGreen)
//                } else {
//                    Spacer()
//                    
//                    Text("You")
//                        .font(.headline)
//                        .foregroundColor(AppTheme.accentBlue)
//                    
//                    // User icon
//                    ZStack {
//                        Circle()
//                            .fill(AppTheme.accentBlue.opacity(0.2))
//                            .frame(width: 40, height: 40)
//                        
//                        Image(systemName: "person.fill")
//                            .font(.system(size: 20))
//                            .foregroundColor(AppTheme.accentBlue)
//                    }
//                }
//            }
//            
//            HStack {
//                if message.role == .user {
//                    Spacer()
//                }
//                
//                Text(message.content)
//                    .font(.body)
//                    .foregroundColor(message.role == .assistant ? AppTheme.textColor : .white)
//                    .padding()
//                    .background(
//                        message.role == .assistant ?
//                        AppTheme.cardBackground :
//                        AppTheme.accentBlue
//                    )
//                    .cornerRadius(16)
//                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: message.role == .assistant ? .leading : .trailing)
//                
//                if message.role == .assistant {
//                    Spacer()
//                }
//            }
//            
//            // Timestamp
//            Text(formatTimestamp(message.timestamp))
//                .font(.caption2)
//                .foregroundColor(AppTheme.textColor.opacity(0.5))
//                .padding(.horizontal, 8)
//        }
//    }
//    
//    // Typing indicator for when the assistant is generating
//    private var typingIndicator: some View {
//        HStack(spacing: 15) {
//            // Assistant icon
//            ZStack {
//                Circle()
//                    .fill(AppTheme.primaryGreen.opacity(0.2))
//                    .frame(width: 40, height: 40)
//                
//                Image(systemName: "brain.head.profile")
//                    .font(.system(size: 20))
//                    .foregroundColor(AppTheme.primaryGreen)
//            }
//            
//            Text("PennyGPT is typing")
//                .font(.subheadline)
//                .foregroundColor(AppTheme.primaryGreen)
//            
//            // Animated dots
//            HStack(spacing: 2) {
//                ForEach(0..<3) { i in
//                    Circle()
//                        .fill(AppTheme.primaryGreen)
//                        .frame(width: 6, height: 6)
//                        .opacity(0.5)
//                        .animation(
//                            Animation.easeInOut(duration: 0.5)
//                                .repeatForever()
//                                .delay(Double(i) * 0.2),
//                            value: llmManager.isGenerating
//                        )
//                }
//            }
//            
//            Spacer()
//        }
//        .padding(.vertical, 8)
//    }
//    
//    // MARK: - Message Input View
//    
//    private var messageInputView: some View {
//        VStack(spacing: 0) {
//            Divider()
//                .background(AppTheme.cardStroke)
//            
//            HStack(alignment: .bottom, spacing: 8) {
//                // Input field with dynamic height
//                ZStack(alignment: .topLeading) {
//                    // Placeholder
//                    if userPrompt.isEmpty {
//                        Text("Ask PennyGPT...")
//                            .font(.body)
//                            .foregroundColor(AppTheme.textColor.opacity(0.5))
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 12)
//                    }
//                    
//                    // Text editor
//                    TextEditor(text: $userPrompt)
//                        .font(.body)
//                        .foregroundColor(AppTheme.textColor)
//                        .padding(4)
//                        .scrollContentBackground(.hidden)
//                        .background(Color.clear)
//                        .frame(minHeight: 44, maxHeight: min(UIScreen.main.bounds.height * 0.15, maxInputHeight))
//                }
//                .padding(4)
//                .background(AppTheme.cardBackground)
//                .cornerRadius(20)
//                
//                // Send button
//                Button(action: sendMessage) {
//                    ZStack {
//                        Circle()
//                            .fill(userPrompt.isEmpty ? AppTheme.primaryGreen.opacity(0.5) : AppTheme.primaryGreen)
//                            .frame(width: 44, height: 44)
//                        
//                        Image(systemName: "arrow.up")
//                            .font(.system(size: 20, weight: .semibold))
//                            .foregroundColor(.white)
//                    }
//                }
//                .disabled(userPrompt.isEmpty || llmManager.isGenerating)
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(AppTheme.backgroundColor)
//        }
//    }
//    
//    // MARK: - Model Info View
//    
//    private var modelInfoView: some View {
//        NavigationView {
//            ZStack {
//                AppTheme.backgroundGradient
//                    .ignoresSafeArea()
//                
//                ScrollView {
//                    VStack(spacing: 24) {
//                        // Model icon
//                        ZStack {
//                            Circle()
//                                .fill(AppTheme.accentBlue.opacity(0.2))
//                                .frame(width: 100, height: 100)
//                            
//                            Image(systemName: "brain.head.profile")
//                                .font(.system(size: 50))
//                                .foregroundColor(AppTheme.accentBlue)
//                        }
//                        .padding(.top, 24)
//                        
//                        Text("About PennyGPT")
//                            .font(.title)
//                            .fontWeight(.bold)
//                            .foregroundColor(AppTheme.textColor)
//                        
//                        // Model information
//                        VStack(alignment: .leading, spacing: 16) {
//                            infoSection(title: "Model", content: "Llama 2 (7B parameters)")
//                            
//                            infoSection(title: "Description", content: "PennyGPT is an on-device financial assistant powered by Llama 2. It provides personalized financial advice based on your spending habits and financial goals, all while keeping your data private and secure on your device.")
//                            
//                            infoSection(title: "Privacy", content: "PennyGPT runs entirely on your device. Your conversations and financial data are never sent to external servers, ensuring your financial information remains private.")
//                            
//                            infoSection(title: "Capabilities", content: "• Analyze spending patterns\n• Provide budgeting advice\n• Suggest saving strategies\n• Offer debt management tips\n• Give personalized financial insights")
//                            
//                            infoSection(title: "Limitations", content: "PennyGPT is not a certified financial advisor and should not replace professional financial advice for important decisions. It works with the data available in the Pennywise app and may not have access to all relevant factors for complex financial planning.")
//                        }
//                        .padding()
//                        .background(AppTheme.cardBackground)
//                        .cornerRadius(16)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 16)
//                                .stroke(AppTheme.cardStroke, lineWidth: 1)
//                        )
//                        .padding(.horizontal)
//                        
//                        // Reset conversation button
//                        Button(action: {
//                            llmManager.resetConversation()
//                            showingModelInfo = false
//                        }) {
//                            Text("Reset Conversation")
//                                .font(.headline)
//                                .foregroundColor(.white)
//                                .padding()
//                                .frame(maxWidth: .infinity)
//                                .background(AppTheme.expenseColor)
//                                .cornerRadius(12)
//                        }
//                        .padding(.horizontal)
//                        .padding(.top, 16)
//                        
//                        Spacer()
//                    }
//                }
//            }
//            .navigationTitle("About")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        showingModelInfo = false
//                    }
//                    .foregroundColor(AppTheme.primaryGreen)
//                }
//            }
//        }
//    }
//    
//    private func infoSection(title: String, content: String) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(title)
//                .font(.headline)
//                .foregroundColor(AppTheme.primaryGreen)
//            
//            Text(content)
//                .font(.body)
//                .foregroundColor(AppTheme.textColor)
//        }
//    }
//    
//    // MARK: - Action Methods
//    
//    private func sendMessage() {
//        guard !userPrompt.isEmpty else { return }
//        
//        let prompt = userPrompt
//        userPrompt = ""
//        
//        // Generate response
//        llmManager.generateResponse(to: prompt) { result in
//            // The conversation history is updated inside the manager
//            // so we just need to scroll to the new message
//            if let lastID = llmManager.getConversationHistory().last?.id {
//                lastMessageId = lastID
//            }
//        }
//    }
//    
//    // MARK: - Helper Methods
//    
//    private func formatTimestamp(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        return formatter.string(from: date)
//    }
//}
//
//struct PennyGPTView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            PennyGPTView()
//        }
//        .preferredColorScheme(.dark)
//    }
//}
