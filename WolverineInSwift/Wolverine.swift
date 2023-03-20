import Foundation

struct GPT4Response: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

struct Change: Codable {
    let operation: String
    let line: Int
    let content: String?
    let explanation: String?
}

class Wolverine {
    private let openaiApiKey: String

    init(apiKey: String) {
        openaiApiKey = apiKey
    }
    
    func run() async {
        let scriptName = CommandLine.arguments[1]
        let args = Array(CommandLine.arguments[2...])

        let fileURL = URL(fileURLWithPath: scriptName)
        var fileContents = try! String(contentsOf: fileURL)

        while true {
            do {
                let (output, returnCode) = try await runScript(scriptName: scriptName, args: args)

                if returnCode == 0 {
                    print("Script ran successfully.")
                    print("Output:", output)
                    break
                } else {
                    print("Script crashed. Trying to fix...")
                    print("Output:", output)

                    let jsonChanges = try await sendErrorToGpt4(fileContents: fileContents, args: args, errorMessage: output)
                    applyChanges(fileContents: &fileContents, changesJson: jsonChanges)

                    try! fileContents.write(to: fileURL, atomically: true, encoding: .utf8)

                    print("Changes applied. Rerunning...")
                }
            } catch {
                print("Error:", error.localizedDescription)
                break
            }
        }
    }
    
    private func runScript(scriptName: String, args: [String]) async throws -> (String, Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", "run", "--package-path", scriptName] + args

        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""

        return (output, process.terminationStatus)
    }
    
    private func sendErrorToGpt4(fileContents: String, args: [String], errorMessage: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/engines/davinci-codex/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(openaiApiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = """
        {
            "prompt": "Your prompt here with fileContents, args, and errorMessage",
            "max_tokens": 150,
            "n": 1,
            "stop": ["\n"],
            "temperature": 1.0
        }
        """.data(using: .utf8)!
        request.httpBody = requestBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw NSError(domain: "GPT4", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }

        let decoder = JSONDecoder()
        let gpt4Response = try decoder.decode(GPT4Response.self, from: data)
        return gpt4Response.choices.first?.message.content ?? ""
    }

    private func applyChanges(fileContents: inout String, changesJson: String) {
        let decoder = JSONDecoder()
        let changes = try! decoder.decode([Change].self, from: changesJson.data(using: .utf8)!)

        let operationChanges = changes.filter { $0.operation != "" }
        let explanations = changes.compactMap { $0.explanation }

        let sortedChanges = operationChanges.sorted { $1.line < $0.line }

        var fileLines = fileContents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        for change in sortedChanges {
            let operation = change.operation
            let line = change.line
            let content = change.content

            switch operation {
            case "Replace":
                fileLines[line - 1] = content!
            case "Delete":
                fileLines.remove(at: line - 1)
            case "InsertAfter":
                fileLines.insert(content!, at: line)
            default:
                break
            }
        }

        fileContents = fileLines.joined(separator: "\n")

        print("Explanations:")
        for explanation in explanations {
            print("- \(explanation)")
        }
    }
}
