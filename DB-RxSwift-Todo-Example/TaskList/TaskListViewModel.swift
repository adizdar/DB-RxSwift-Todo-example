//
//  TaskListViewModel.swift
//  DB-RxSwift-Todo-Example
//
//  Created by AhmedDizdar
//

import Differentiator
import RxCocoa
import RxRelay
import RxSwift

internal class TaskListViewModel {
    internal struct SectionModel: SectionModelType {
        internal let title: String
        
        internal init(title: String, items: [Task]) {
            self.title = title
            self.items = items
        }

        // MARK: - SectionModelType

        internal private(set) var items: [Task]

        internal init(original: Self, items: [Task]) {
            self = original
            self.items = items
        }
    }
    
    internal let taskSections: Driver<[SectionModel]>
    internal let tasksSummaryMessage: Driver<String>

    private let tasks: BehaviorRelay<[Task]> = .init(value: [
        Task(title: "New Task"),
        Task(title: "HoM task", isCompleated: true)
    ])
    
    internal init() {
        self.taskSections = self.tasks
            .map { tasks in
                [
                    SectionModel(title: "Open Tasks", items: tasks.filter { !$0.isCompleated }),
                    SectionModel(title: "Compleated Tasks", items: tasks.filter { $0.isCompleated }),
                ]
            }
            .asDriverElevatingErrorsToFatal()
        
        let tasksCount = self.tasks.map { $0.count }.asDriverElevatingErrorsToFatal()
        let openTasksCount = self.tasks.map { $0.filter { !$0.isCompleated }.count }.asDriverElevatingErrorsToFatal()
        let compleatedTasksCount = self.tasks.map { $0.filter { $0.isCompleated }.count }.asDriverElevatingErrorsToFatal()
        
        self.tasksSummaryMessage = Driver
            .combineLatest(tasksCount, openTasksCount, compleatedTasksCount)
            .map { tasksCount, openTasksCount, compleatedTasksCount in
                "\(tasksCount) Tasks; \(openTasksCount) open, \(compleatedTasksCount) compleated"
            }
    }
    
    internal func addTask(title: String?) {
        guard let title = title else {
            fatalError("Task title can't be empty.")
        }
        
        self.tasks.accept(adding: Task(title: title))
    }
    
    internal func changeTaskStatusViaId(_ taskId: UUID) {
        var tasks = self.tasks.value
        guard let row = tasks.firstIndex(where: { $0.id == taskId }) else {
            fatalError("Task item not found.")
        }
        
        tasks[row].isCompleated.toggle()
        
        self.tasks.accept(tasks)
    }
}

extension ObservableConvertibleType {
    internal func asDriverElevatingErrorsToFatal() -> Driver<Element> {
        self.asDriver { fatalError("Error received in reactive driver: \($0.localizedDescription)") }
    }
}

extension BehaviorRelay where Element: RangeReplaceableCollection {
    internal func accept(adding element: Element.Element) {
        var value = self.value
        value.append(element)
        self.accept(value)
    }
}
