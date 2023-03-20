// Wolverine in Swift
// NOTE: Only done as a proof of concept _so far_, so it doesn't quite work yet
// 
// Created by Massimo Savino / GPT-4 from an original implementation in Python
//      by biobootloader at
//      https://github.com/biobootloader/wolverine

import AppKit
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

class OldWolverine {
    private let openaiApiKey: String

    init(apiKey: String) {
        openaiApiKey = apiKey
    }
    
    func run() async {
        // Implement main logic here
        let scriptName = CommandLine.arguments[1]
        let args = CommandLine.arguments.count > 2 ? Array(CommandLine.arguments[2...]) : []

        let fileURL = URL(fileURLWithPath: scriptName)
        var fileContents = try! String(contentsOf: fileURL)

        while true {
            do {
                print("Running script...")
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
        // Implement running the script here
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python", scriptName] + args

        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""

        return (output, process.terminationStatus)
    }
    
    private func sendErrorToGpt4(fileContents: String, args: [String], errorMessage: String) async throws -> String {
        // Implement sending the error to GPT-4 here
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
            throw NSError(domain: "APIError", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: nil)
        }

        let gpt4Response = try JSONDecoder().decode(GPT4Response.self, from: data)

        return gpt4Response.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private func applyChanges(fileContents: inout String, changesJson: String) {
        // Implement applying the changes here
        let changes = try! JSONDecoder().decode([Change].self, from: changesJson.data(using: .utf8)!)

        var lines = fileContents.split(separator: "\n", omittingEmptySubsequences: false)

        for change in changes {
            let index = change.line - 1

            switch change.operation {
            case "Replace":
                if let content = change.content, index >= 0 && index < lines.count {
                    lines[index] = Substring(content)
                } else {
                    print("Replace operation failed for index: \(index)")
                }
            case "Delete":
                if index >= 0 && index < lines.count {
                    lines.remove(at: index)
                } else {
                    print("Delete operation failed for index: \(index)")
                }
            case "InsertAfter":
                if let content = change.content, index >= 0 && index < lines.count {
                    lines.insert(Substring(content), at: index + 1)
                } else {
                    print("InsertAfter operation failed for index: \(index)")
                }
            default:
                break
            }
        }

        fileContents = lines.joined(separator: "\n")
    }
}
// LOL - needs additional work for Swift source code instead of Python, soon...
autoreleasepool {
    let oldWolverine = OldWolverine(apiKey: "your-api-key")
    let group = DispatchGroup()
    group.enter()
    Task {
        do {
            try await oldWolverine.run()
        } catch {
            print("Error in run(): \(error.localizedDescription)")
        }
        group.leave()
    }
    group.wait()
}
