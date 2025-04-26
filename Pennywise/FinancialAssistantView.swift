import SwiftUI
import Combine

struct FinancialAssistantView: View {
    // MARK: - State
    @StateObject private var viewModel = FinancialAssistantViewModel()
    @State private var messageText: String = ""
    @State private var scrollToBottom = false
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var plaidManager: PlaidManager
    
    // MARK: - UI Elements
    private let maxInputHeight: CGFloat = 120
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Messages list
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            // Empty view at end for auto-scrolling
                            Color.clear
                                .frame(height: 1)
                                .id("bottomAnchor")
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            scrollProxy.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                    .onChange(of: scrollToBottom) { _ in
                        withAnimation {
                            scrollProxy.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                }
                
                // Input area
                inputView
            }
            
            // Loading screen for context gathering
            if viewModel.isLoadingContext {
                loadingView(message: "Analyzing your financial data...")
            }
            
            // Settings sheet
            if viewModel.showingAPIKeyPrompt {
                apiKeyPrompt
            }
        }
        .alert(
            "Error",
            isPresented: $viewModel.showingError,
            actions: {
                Button("OK", role: .cancel) {}
                if viewModel.error is GeminiService.GeminiServiceError {
                    Button("Update API Key") {
                        viewModel.showingAPIKeyPrompt = true
                    }
                }
            },
            message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                } else {
                    Text("An unknown error occurred.")
                }
            }
        )
        .navigationTitle("Financial Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadFinancialContext()
            if viewModel.messages.isEmpty {
                viewModel.addWelcomeMessage()
            }
        }
    }
    
    // MARK: - Subviews
    
    // Header view with title and settings button
    private var headerView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                viewModel.showingAPIKeyPrompt = true
            }) {
                Image(systemName: "key.fill")
                    .foregroundColor(AppTheme.primaryGreen)
                    .padding(8)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // Input view at the bottom with message field and send button
    private var inputView: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Input field
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
                
                // Text editor
                if #available(iOS 16.0, *) {
                    // iOS 16+ uses the new TextField with axis
                    TextField("Ask about your finances...", text: $messageText, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(minHeight: 44, maxHeight: maxInputHeight)
                        .foregroundColor(AppTheme.textColor)
                } else {
                    // iOS 15 fallback
                    TextEditor(text: $messageText)
                        .focused($isTextFieldFocused)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minHeight: 44, maxHeight: maxInputHeight)
                        .foregroundColor(AppTheme.textColor)
                }
            }
            .frame(minHeight: 44, maxHeight: messageText.isEmpty ? 44 : maxInputHeight)
            
            // Send button
            Button(action: sendMessage) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryGreen)
                        .frame(width: 44, height: 44)
                        .shadow(color: AppTheme.primaryGreen.opacity(0.4), radius: 5, x: 0, y: 2)
                    
                    Image(systemName: viewModel.isLoading ? "hourglass" : "arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            .opacity((messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading) ? 0.5 : 1.0)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            BlurView(style: .systemUltraThinMaterialDark)
                .opacity(0.95)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    // API key prompt
    private var apiKeyPrompt: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    viewModel.showingAPIKeyPrompt = false
                }
            
            VStack(spacing: 20) {
                Text("Gemini API Key")
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor)
                
                Text("Enter your Gemini API key to access the AI assistant. You can get a key from Google AI Studio.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                SecureField("API Key", text: $viewModel.apiKey)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
                    .foregroundColor(AppTheme.textColor)
                
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.showingAPIKeyPrompt = false
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        viewModel.saveAPIKey()
                        viewModel.showingAPIKeyPrompt = false
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.primaryGreen)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                }
            }
            .padding(24)
            .background(AppTheme.backgroundColor)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
    
    // Loading view
    private func loadingView(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(AppTheme.backgroundColor.opacity(0.8))
            .cornerRadius(16)
            .padding(40)
        }
    }
    
    // MARK: - Actions
    
    /// Sends the current message text
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = messageText
        messageText = ""
        
        // Trigger scrolling
        scrollToBottom.toggle()
        
        // Send message through viewModel
        viewModel.sendMessage(userMessage)
    }
}

// MARK: - View Model

class FinancialAssistantViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Messages in the conversation
    @Published var messages: [ChatMessage] = []
    
    /// Indicates if a request is in progress
    @Published var isLoading = false
    
    /// Indicates if financial context is being loaded
    @Published var isLoadingContext = false
    
    /// Stored API key for Gemini
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "geminiApiKey") ?? ""
    
    /// Current error, if any
    @Published var error: Error? = nil
    
    /// Flag to show error alerts
    @Published var showingError = false
    
    /// Flag to show API key prompt
    @Published var showingAPIKeyPrompt = false
    
    // MARK: - Private Properties
    
    /// Service for Gemini API communication
    private let geminiService = GeminiService()
    
    /// Context provider for financial data
    private let contextProvider = FinancialContextProvider.shared
    
    /// Financial context data
    private var financialContext = FinancialContext()
    
    /// Set to store active cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Subscribe to geminiService's loading state
        geminiService.$isLoading
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        // Subscribe to geminiService's error state
        geminiService.$error
            .sink { [weak self] error in
                if let error = error {
                    self?.error = error
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Loads the financial context data
    func loadFinancialContext() {
        isLoadingContext = true
        
        contextProvider.getCurrentContext { [weak self] context in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.financialContext = context
                self.isLoadingContext = false
            }
        }
    }
    
    /// Adds a welcome message to start the conversation
    func addWelcomeMessage() {
        // Check if the user has already set up an API key
        let hasAPIKey = !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        let welcomeMessage: String
        
        if hasAPIKey {
            welcomeMessage = "Hi there! I'm your financial assistant powered by Gemini AI. I can help answer questions about your finances, provide personalized advice, or suggest ways to reach your financial goals. How can I help you today?"
        } else {
            welcomeMessage = "Welcome to your financial assistant! To get started, you'll need to set up your Gemini API key. Tap the key icon in the top-right to enter your API key from Google AI Studio."
            
            // Show API key prompt automatically if no key is set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showingAPIKeyPrompt = true
            }
        }
        
        let message = ChatMessage(
            text: welcomeMessage,
            role: .assistant
        )
        
        messages.append(message)
    }
    
    /// Saves the API key
    func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }
        
        // Save the API key securely
        UserDefaults.standard.set(trimmedKey, forKey: "geminiApiKey")
        
        // Update the Gemini service
        geminiService.updateAPIKey(trimmedKey)
    }
    
    /// Sends a user message and gets a response
    func sendMessage(_ text: String) {
        // Add user message to conversation
        let userMessage = ChatMessage(
            text: text,
            role: .user
        )
        
        messages.append(userMessage)
        
        // If no API key, prompt for one
        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let noKeyMessage = ChatMessage(
                text: "Please set up your Gemini API key first. Tap the key icon in the top-right corner to get started.",
                role: .assistant
            )
            
            messages.append(noKeyMessage)
            showingAPIKeyPrompt = true
            return
        }
        
        // Add a placeholder for the assistant's response
        let placeholderMessage = ChatMessage(
            text: "...",
            role: .assistant
        )
        
        messages.append(placeholderMessage)
        
        // Get response from Gemini
        geminiService.generateChatResponse(
            messages: convertMessagesForAPI(),
            financialContext: financialContext
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Remove the placeholder message
                self.messages.removeAll { $0.id == placeholderMessage.id }
                
                switch result {
                case .success(let response):
                    let assistantMessage = ChatMessage(
                        text: response,
                        role: .assistant
                    )
                    
                    self.messages.append(assistantMessage)
                    
                case .failure(let error):
                    self.error = error
                    
                    // Add an error message
                    let errorMessage = ChatMessage(
                        text: "Sorry, I encountered an error: \(error.localizedDescription)",
                        role: .assistant
                    )
                    
                    self.messages.append(errorMessage)
                }
            }
        }
    }
    
    /// Converts the view's messages to the format needed for the API
    private func convertMessagesForAPI() -> [ChatMessage] {
        // Filter out placeholder messages and system messages
        return messages.filter { message in
            message.text != "..." && message.role != .system
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                assistantAvatarView
                bubbleView
                Spacer(minLength: 60)
            } else {
                Spacer(minLength: 60)
                bubbleView
                userAvatarView
            }
        }
    }
    
    private var assistantAvatarView: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primaryGreen.opacity(0.2))
                .frame(width: 36, height: 36)
            
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.primaryGreen)
        }
    }
    
    private var userAvatarView: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accentPurple.opacity(0.2))
                .frame(width: 36, height: 36)
            
            Image(systemName: "person.fill")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.accentPurple)
        }
    }
    
    private var bubbleView: some View {
        Text(message.text)
            .foregroundColor(
                message.role == .assistant ? AppTheme.textColor : .white
            )
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                message.role == .assistant ?
                    AppTheme.cardBackground :
                    AppTheme.accentBlue
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        message.role == .assistant ?
                            AppTheme.cardStroke :
                            Color.clear,
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Previews

struct FinancialAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FinancialAssistantView()
                .environmentObject(PlaidManager.shared)
        }
        .preferredColorScheme(.dark)
    }
}
