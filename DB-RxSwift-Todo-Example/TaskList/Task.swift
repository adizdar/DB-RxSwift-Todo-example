//
//  Task.swift
//  DB-RxSwift-Todo-Example
//
//  Created by AhmedDizdar
//

import Foundation

internal struct Task: Equatable {
    internal enum Status {
        case open
        case compleated
    }
    
    internal let id: UUID = UUID()
    internal let title: String
    internal var status: Status
    
    // MARK: - Equatable

    internal static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}
