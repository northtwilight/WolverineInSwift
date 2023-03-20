//
//  BuggyScript.swift
//  WolverineInSwift
//
//  Created by Massimo Savino on 2023-03-20.
//

import Foundation

func addNumbers(a: Double, b: Double) -> Double {
    return a + b
}

func subtractNumbers(a: Double, b: Double) -> Double {
    return a - b
}

func multiplyNumbers(a: Double, b: Double) -> Double {
    return a * b
}

func divideNumbers(a: Double, b: Double) -> Double {
    return a / b
}

enum Operation: String {
    case add
    case subtract
    case multiply
    case divide
}

func calculate(operation: Operation, num1: Double, num2: Double) -> Double? {
    var result: Double?

    switch operation {
    case .add:
        result = addNumbers(a: num1, b: num2)
    case .subtract:
        result = subtractNumbers(a: num1, b: num2)
    case .multiply:
        result = multiplyNumbers(a: num1, b: num2)
    case .divide:
        result = divideNumbers(a: num1, b: num2)
    }

    return result
}

/**
// Example usage:

if let operation = Operation(rawValue: "add") {
    let result = calculate(operation: operation, num1: 3, num2: 4)
    print(result) // This will print Optional(7)
}
 */
