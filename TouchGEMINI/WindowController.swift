//GeminiTouch
import Cocoa
import GoogleGenerativeAI

class WindowController: NSWindowController {
    
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    private var clipboardTimer: Timer?
    var isShowingClipboard = false
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Start a timer to periodically check the clipboard content
        startClipboardPolling()
    }
    
    deinit {
        // Stop the timer when the window controller is deallocated
        stopClipboardPolling()
    }
    
    func startClipboardPolling() {
        // Create a timer to periodically check the clipboard content
        clipboardTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkClipboard), userInfo: nil, repeats: true)
    }
    
    func stopClipboardPolling() {
        // Stop the timer when the window controller is deallocated
        clipboardTimer?.invalidate()
        clipboardTimer = nil
    }
    
    @objc func checkClipboard() {
        // Get the current clipboard content
        let clipboard = NSPasteboard.general
        if let clipboardString = clipboard.string(forType: .string) {
            // Update the text shown in the Text Field with the clipboard content
            textField.stringValue = clipboardString
        } else {
            // Clear the text in the Text Field if the clipboard does not contain text
            textField.stringValue = ""
        }
    }
    
    @IBAction func geminiButtonClicked(_ sender: Any) {
        // Generate response from Generative Model
        guard let clipboardString = textField.stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        // Construct the prompt for the Generative Model
        let prompt = "Only return a single line of answer for the text after $ try to answer from options only if possible , limit response to 8 words , summarise if not a question$" + clipboardString
        
        // Initialize the Generative Model with the gemini-pro model
        let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyAvh9AbDKJ6E0DdOUll0f1p4qCSlerGvfs")
        
        // Update status label to indicate sending prompt
        statusLabel.stringValue = "Sending prompt..."
        
        // Generate content using the Generative Model
        Task {
            do {
                // Update status label to indicate generating
                statusLabel.stringValue = "Generating..."
                
                // Generate content asynchronously
                let response = try await model.generateContent(prompt)
                
                // Update status label to indicate response received
                statusLabel.stringValue = "Response Received"
                
                // Process and print the response
                if let text = response.text {
                    // Update textField with single-line response text
                    let singleLineText = text.components(separatedBy: .newlines).first ?? ""
                    DispatchQueue.main.async {
                        self.textField.stringValue = singleLineText
                        // Set clipboard text after response is shown
                        self.setClipboardText(singleLineText)
                    }
                    // Print the response
                    print("Response: \(singleLineText)")
                }
            } catch {
                // Update status label to indicate error
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "Error: \(error)"
                }
                // Log the error
                print("Error: \(error)")
            }
        }
    }
    
    func setClipboardText(_ text: String) {
        let clipboard = NSPasteboard.general
        clipboard.clearContents()
        clipboard.setString(text, forType: .string)
    }
}
