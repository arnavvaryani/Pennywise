//
//import Foundation
//import SwiftUI
//import Combine
//import Accelerate
//
//// MARK: - LLM Model Enumeration
//
///// Supported on‑device model builds
//enum LLMModel: String, CaseIterable, Identifiable {
//    case llama2_7b = "llama-2-7b-chat-q4f16"
//    case tinyllama_1_1b = "tinyllama-1.1b-chat-q4f16_1"
//
//    var id: String { rawValue }
//
//    /// Human‑readable name + params
//    var displayName: String {
//        switch self {
//        case .llama2_7b: return "Llama 2 7B"
//        case .tinyllama_1_1b: return "TinyLlama 1.1B"
//        }
//    }
//
//    /// Memory estimate shown in UI (bytes)
//    var estimatedVRAM: Int {
//        switch self {
//        case .llama2_7b: return 5_500_000_000 // 5.5 GB on‑device
//        case .tinyllama_1_1b: return 1_800_000_000 // 1.8 GB
//        }
//    }
//}
//
//// MARK: - MLCLLMEngine
//
///// Lightweight wrapper around MLC LLM runtime
//@MainActor
//final class MLCLLMEngine {
//    static let shared = MLCLLMEngine()
//    private init() { }
//
//    // MARK: Engine state
//
//    private(set) var isModelLoaded = false
//    private(set) var isGenerating = false
//    private(set) var currentModel: LLMModel = .tinyllama_1_1b // default small build
//
//    // MARK: Callbacks
//
//    typealias ProgressCallback = (Float) -> Void
//    typealias GenerationCallback = (String) -> Void
//    typealias CompletionCallback = (Result<String, Error>) -> Void
//
//    // MARK: Errors
//
//    enum MLCLLMError: LocalizedError {
//        case modelNotFound, modelNotLoaded, tokenizerNotFound, engineInitFailed, generationFailed, invalidPrompt, cancelled
//        var errorDescription: String? {
//            switch self {
//            case .modelNotFound: "The language model was not found in the app bundle."
//            case .modelNotLoaded: "The language model has not been loaded yet."
//            case .tokenizerNotFound: "Tokenizer not found in the app bundle."
//            case .engineInitFailed: "Failed to initialize the LLM engine."
//            case .generationFailed: "Text generation failed."
//            case .invalidPrompt: "The provided prompt is invalid."
//            case .cancelled: "Text generation was cancelled."
//            }
//        }
//    }
//
//    // MARK: Paths
//
//    private var modelDirectory: URL {
//        Bundle.main.bundleURL.appendingPathComponent("Models/\(currentModel.rawValue)")
//    }
//    private let tokenizerPath: URL = Bundle.main.bundleURL.appendingPathComponent("Models/tokenizer.model")
//
//    // MARK: Public API
//
//    /// Change the active model (call before `loadModel`)
//    func setModel(_ model: LLMModel) {
//        if currentModel != model {
//            isModelLoaded = false // force reload
//            currentModel = model
//        }
//    }
//
//    /// Asynchronously load the model (simulated for now)
//    func loadModel(progress: @escaping ProgressCallback, completion: @escaping (Result<Void, Error>) -> Void) {
//        guard !isModelLoaded else { completion(.success(())); return }
//
//        let fm = FileManager.default
//        guard fm.fileExists(atPath: modelDirectory.path) else { completion(.failure(MLCLLMError.modelNotFound)); return }
//        guard fm.fileExists(atPath: tokenizerPath.path) else { completion(.failure(MLCLLMError.tokenizerNotFound)); return }
//
//        Task.detached {
//            await self.simulateModelLoading(progress: progress) { result in
//                if case .success = result { self.isModelLoaded = true }
//                completion(result)
//            }
//        }
//    }
//
//    /// Generate text from a prompt (simulated)
//    func generate(prompt: String, tokenCallback: @escaping GenerationCallback, completion: @escaping CompletionCallback) {
//        guard isModelLoaded else { completion(.failure(MLCLLMError.modelNotLoaded)); return }
//        guard !prompt.isEmpty else { completion(.failure(MLCLLMError.invalidPrompt)); return }
//
//        isGenerating = true
//        Task.detached {
//            await self.simulateTextGeneration(prompt: prompt, tokenCallback: tokenCallback) { result in
//                self.isGenerating = false
//                completion(result)
//            }
//        }
//    }
//
//    func cancelGeneration() { isGenerating = false }
//
//    // MARK: – Simulated internals (replace with MLC LLM runtime)
//
//    private func simulateModelLoading(progress: @escaping ProgressCallback, completion: @escaping (Result<Void, Error>) -> Void) async {
//        let phases: [(TimeInterval, Float)] = [(0.6,0.15),(2.5,0.65),(0.8,0.2)]
//        var total: Float = 0
//        for (dur, w) in phases {
//            let start = Date()
//            while Date().timeIntervalSince(start) < dur {
//                try? await Task.sleep(nanoseconds: 90_000_000)
//                let frac = Float(Date().timeIntervalSince(start)/dur)
//                progress(total + frac * w)
//            }
//            total += w
//            progress(total)
//        }
//        completion(.success(()))
//    }
//
//    private func simulateTextGeneration(prompt: String, tokenCallback: @escaping GenerationCallback, completion: @escaping CompletionCallback) async {
//        let words = "Thanks for trying \(currentModel.displayName)! Let me know how I can help you today with your budget, savings or investments.".components(separatedBy: " ")
//        var out = ""
//        for w in words {
//            guard isGenerating else { completion(.failure(MLCLLMError.cancelled)); return }
//            out += w + " "
//            tokenCallback(w + " ")
//            try? await Task.sleep(nanoseconds: 90_000_000)
//        }
//        completion(.success(out))
//    }
//
//    // MARK: – Prompt helper (unchanged)
//
//    func formatPromptForLlama2Chat(messages: [Message]) -> String {
//        var formatted = "<s>"
//        let system = messages.first { $0.role == .system }?.content ?? ""
//        var rest = messages.filter { $0.role != .system }
//        if let user = rest.first(where: { $0.role == .user }) {
//            formatted += "[INST] "
//            if !system.isEmpty { formatted += "<<SYS>>\n\(system)\n<</SYS>>\n\n" }
//            formatted += "\(user.content) [/INST] "
//            if let assistant = rest.first(where: { $0.role == .assistant }) {
//                formatted += "\(assistant.content) </s>"
//                rest.removeAll { $0.id == user.id || $0.id == assistant.id }
//            } else { rest.removeAll { $0.id == user.id } }
//        }
//        while !rest.isEmpty {
//            if let user = rest.first(where: { $0.role == .user }) {
//                formatted += "<s>[INST] \(user.content) [/INST] "
//                rest.removeAll { $0.id == user.id }
//                if let assistant = rest.first(where: { $0.role == .assistant }) {
//                    formatted += "\(assistant.content) </s>"
//                    rest.removeAll { $0.id == assistant.id }
//                }
//            } else { break }
//        }
//        return formatted
//    }
//}
//
//// MARK: - MLCLLMManager
//
//@MainActor
//final class MLCLLMManager: ObservableObject {
//    static let shared = MLCLLMManager()
//    private init() { loadEngine() }
//
//    // Published state for UI binding
//    @Published var isModelLoaded = false
//    @Published var isGenerating = false
//    @Published var generatedText = ""
//    @Published var loadingProgress: Float = 0
//    @Published var errorMessage: String?
//    @Published var selectedModel: LLMModel = MLCLLMEngine.shared.currentModel {
//        didSet { switchModel(selectedModel) }
//    }
//
//    private var history: [Message] = [Message(role: .system, content: systemPrompt)]
//    private let engine = MLCLLMEngine.shared
//
//    private static let systemPrompt = """
//    You are PennyGPT, a friendly AI assistant inside the Pennywise finance app. Offer concise, actionable tips in plain language. Avoid high‑risk recommendations.
//    """
//
//    // MARK: – Model management
//
//    private func loadEngine() {
//        engine.loadModel(progress: { [weak self] p in self?.loadingProgress = p }, completion: { [weak self] res in
//            guard let self else { return }
//            switch res {
//            case .success: self.isModelLoaded = true
//            case .failure(let err): self.errorMessage = err.localizedDescription
//            }
//        })
//    }
//
//    private func switchModel(_ model: LLMModel) {
//        isModelLoaded = false
//        generatedText = ""
//        engine.setModel(model)
//        loadEngine()
//    }
//
//    // MARK: – Chat
//
//    func send(_ prompt: String) {
//        guard isModelLoaded, !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
//        isGenerating = true
//        history.append(Message(role: .user, content: prompt))
//        let formatted = engine.formatPromptForLlama2Chat(messages: history)
//        var response = ""
//        engine.generate(prompt: formatted, tokenCallback: { tok in self.generatedText = response + tok }, completion: { [weak self] res in
//            guard let self else { return }
//            switch res {
//            case .success(let full):
//                response = full
//                self.history.append(Message(role: .assistant, content: full))
//            case .failure(let err):
//                self.errorMessage = err.localizedDescription
//            }
//            self.isGenerating = false
//        })
//    }
//
//    func reset() {
//        history = [Message(role: .system, content: Self.systemPrompt)]
//        generatedText = ""
//    }
//
//    func conversation() -> [Message] { history }
//}
//
//// MARK: - Message model
//
//struct Message: Identifiable {
//    var id = UUID()
//    var role: MessageRole
//    var content: String
//    var timestamp = Date()
//}
//
//enum MessageRole { case system, user, assistant }
//
//// MARK: - PennyGPTView (UI condensed for brevity)
//
//struct PennyGPTView: View {
//    @StateObject private var vm = MLCLLMManager.shared
//    @State private var prompt = ""
//
//    var body: some View {
//        VStack {
//            Picker("Model", selection: $vm.selectedModel) {
//                ForEach(LLMModel.allCases) { Text($0.displayName).tag($0) }
//            }
//            .pickerStyle(SegmentedPickerStyle())
//            .padding()
//
//            if !vm.isModelLoaded {
//                ProgressView(value: vm.loadingProgress) {
//                    Text("Loading \(vm.selectedModel.displayName)…")
//                }.padding()
//            } else {
//                ScrollView {
//                    ForEach(vm.conversation().filter { $0.role != .system }) { msg in
//                        HStack {
//                            if msg.role == .assistant { Text("🤖") }
//                            Text(msg.content).padding().background(msg.role == .assistant ? Color.gray.opacity(0.1) : Color.blue.opacity(0.3)).cornerRadius(10)
//                            if msg.role == .user { Text("🧑") }
//                        }.frame(maxWidth: .infinity, alignment: msg.role == .assistant ? .leading : .trailing).padding(.horizontal)
//                    }
//                    if vm.isGenerating { ProgressView() }
//                }
//                HStack {
//                    TextField("Ask PennyGPT…", text: $prompt).textFieldStyle(RoundedBorderTextFieldStyle())
//                    Button("Send") { vm.send(prompt); prompt = "" }.disabled(prompt.isEmpty || vm.isGenerating)
//                }.padding()
//            }
//        }
//    }
//}
