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
        internal init(items: [Task]) {
            self.items = items
        }

        // MARK: - SectionModelType

        internal private(set) var items: [Task]

        internal init(original: Self, items: [Task]) {
            self = original
            self.items = items
        }
    }
    
    internal let openSections: Driver<[SectionModel]>
    internal let compleatedSections: Driver<[SectionModel]>
    internal let tasksSummaryMessage: Driver<String>
    private let openTasks: BehaviorRelay<[Task]> = .init(value: [])
    private let compleatedTasks: BehaviorRelay<[Task]> = .init(value: [])
    private let disposeBag: DisposeBag = .init()

    private let tasks: BehaviorRelay<[Task]> = .init(value: [
        Task(title: "New Task", status: .open),
        Task(title: "HoM task", status: .compleated)
    ])
    
    internal init() {
        self.tasks
            .map { tasks in tasks.filter { $0.status == .open } }
            .bind(to: self.openTasks)
            .disposed(by: self.disposeBag)
        
        self.openSections = self.openTasks
            .map { [SectionModel(items: $0)] }
            .asDriverElevatingErrorsToFatal()
        
        self.tasks
            .map { tasks in tasks.filter { $0.status == .compleated } }
            .bind(to: self.compleatedTasks)
            .disposed(by: self.disposeBag)
        
//        Observable
//            .combineLatest(self.tasks, self.openTasks)
//            .map { tasks, openTasks in
//                tasks.filter { $0.status == .compleated } + openTasks.filter { $0.status == .compleated }
//            }
//            .bind(to: self.compleatedTasks)
//            .disposed(by: self.disposeBag)

        self.compleatedSections = self.compleatedTasks
            .map { [SectionModel(items: $0)] }
            .asDriverElevatingErrorsToFatal()
        
        let tasksCount = self.tasks.map { $0.count }.asDriverElevatingErrorsToFatal()
        let openTasksCount = self.openTasks.map { $0.count }.asDriverElevatingErrorsToFatal()
        let compleatedTasksCount = self.compleatedTasks.map { $0.count }.asDriverElevatingErrorsToFatal()
        
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
        
        self.tasks.accept(adding: Task(title: title, status: .open))
    }
    
    internal func changeTaskStatusViaId(_ taskId: UUID, status: Task.Status) {
        var tasks = self.tasks.value
        guard let row = tasks.firstIndex(where: { $0.id == taskId }) else {
            fatalError("Task item not found.")
        }
        
        tasks[row].status = status
        
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
