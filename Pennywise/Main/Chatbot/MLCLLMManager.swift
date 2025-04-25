//import Foundation
//import SwiftUI
//import Combine
//import Accelerate
//
///// Manager class for handling the MLC LLM integration in the app
//class MLCLLMManager: ObservableObject {
//    static let shared = MLCLLMManager()
//    
//    // Published properties to update the UI
//    @Published var isModelLoaded = false
//    @Published var isGenerating = false
//    @Published var generatedText = ""
//    @Published var modelLoadingProgress: Float = 0.0
//    @Published var errorMessage: String? = nil
//    
//    // Current conversation context
//    private var conversationHistory: [Message] = []
//    private var cancellables = Set<AnyCancellable>()
//    
//    // Reference to the MLC LLM engine
//    private let llmEngine = MLCLLMEngine.shared
//    
//    // System prompt for financial advising
//    private let systemPrompt = """
//    You are PennyGPT, a helpful AI assistant integrated into the Pennywise finance app. 
//    You offer friendly, personalized financial advice based on the user's financial data, spending patterns, and goals.
//    Your advice should be clear, actionable, and focused on helping users improve their financial habits. 
//    Always maintain a positive, encouraging tone and avoid financial jargon unless necessary.
//    If asked about specific financial data, refer to what's visible in the Pennywise app.
//    Never provide financial advice that involves high-risk investments or that could be harmful to the user's financial health.
//    """
//    
//    private init() {
//        // Initialize the MLC LLM engine when this manager is created
//        setupLLM()
//        
//        // Add the system message to the conversation history
//        let systemMessage = Message(role: .system, content: systemPrompt)
//        conversationHistory.append(systemMessage)
//    }
//    
//    /// Setup the LLM by initializing the model and engine
//    private func setupLLM() {
//        llmEngine.loadModel(progressCallback: { [weak self] progress in
//            self?.modelLoadingProgress = progress
//        }, completion: { [weak self] result in
//            switch result {
//            case .success:
//                self?.isModelLoaded = true
//            case .failure(let error):
//                self?.errorMessage = error.localizedDescription
//            }
//        })
//    }
//    
//    /// Generate a response to the given prompt
//    func generateResponse(to prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
//        guard isModelLoaded else {
//            let error = NSError(domain: "MLCLLMManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded yet"])
//            completion(.failure(error))
//            return
//        }
//        
//        isGenerating = true
//        
//        // Add the user message to the conversation history
//        let userMessage = Message(role: .user, content: prompt)
//        conversationHistory.append(userMessage)
//        
//        // Format conversation for Llama 2
//        let formattedPrompt = llmEngine.formatPromptForLlama2Chat(messages: conversationHistory)
//        
//        // Call the LLM engine
//        var responseText = ""
//        llmEngine.generateText(
//            prompt: formattedPrompt,
//            tokenCallback: { token in
//                responseText += token
//                DispatchQueue.main.async {
//                    self.generatedText = responseText
//                }
//            },
//            completion: { [weak self] result in
//                guard let self = self else { return }
//                
//                switch result {
//                case .success(let response):
//                    let assistantMessage = Message(role: .assistant, content: response)
//                    self.conversationHistory.append(assistantMessage)
//                    completion(.success(response))
//                case .failure(let error):
//                    self.errorMessage = error.localizedDescription
//                    completion(.failure(error))
//                }
//                
//                self.isGenerating = false
//            }
//        )
//    }
//    
//    /// Reset the conversation history
//    func resetConversation() {
//        conversationHistory.removeAll()
//        
//        // Add the system message back to the conversation history
//        let systemMessage = Message(role: .system, content: systemPrompt)
//        conversationHistory.append(systemMessage)
//    }
//    
//    /// Get the current conversation history
//    func getConversationHistory() -> [Message] {
//        return conversationHistory
//    }
//}
//
///// Message structure for conversation history
//struct Message: Identifiable {
//    var id = UUID()
//    var role: MessageRole
//    var content: String
//    var timestamp = Date()
//}
//
//enum MessageRole {
//    case system
//    case user
//    case assistant
//}
