//
//  ContentView.swift
//  WolverineInSwift
//
//  Created by Massimo Savino on 2023-03-19.
//

import SwiftUI
import Foundation
import Crypto
import ArgumentParser

struct ContentView: View {
    @State private var scriptName: String = ""
    @State private var arguments: String = ""
    @State private var output: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(Color.red)
                
                Text("Wolverine in Swift")
                    .font(.largeTitle)
                    .padding()
            }
            
            
            VStack(alignment: .leading) {
                Text("Script name:")
                TextField("Enter script name", text: $scriptName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("Arguments:")
                TextField("Enter arguments separated by space", text: $arguments)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            
            Button("Run Script") {
                runScript()
            }
            .padding()
            
            ScrollView {
                Text(output)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
    
    func runScript() {
        // Implementation for running the script, calling the OpenAI API, and applying changes
        // using URLSession and Swift Concurrency features like async/await, Task, and Actors.
        let scriptName = "BuggyScript.swift"
        let arguments = ["subtract", "20", "3"]
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
