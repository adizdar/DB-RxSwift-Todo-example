//
//  Task.swift
//  DB-RxSwift-Todo-Example
//
//  Created by AhmedDizdar
//

import Foundation

internal struct Task: Equatable {    
    internal let id: UUID = UUID()
    internal let title: String
    internal var isCompleated: Bool
    
    internal init(title: String) {
        self.title = title
        self.isCompleated = false
    }
    
    internal init(title: String, isCompleated: Bool) {
        self.title = title
        self.isCompleated = isCompleated
    }
    
    // MARK: - Equatable

    internal static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}
