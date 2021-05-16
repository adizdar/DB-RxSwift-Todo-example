//
//  ViewController.swift
//  DB-RxSwift-Todo-Example
//
//  Created by AhmedDizdar
//

import RxCocoa
import RxDataSources
import RxSwift
import UIKit

internal class TaskListViewController: UIViewController {
    @IBOutlet private weak var taskTitleTextField: UITextField!
    @IBOutlet private weak var createTaskButton: UIButton!
    @IBOutlet private weak var openTasksTableView: UITableView!
    @IBOutlet private weak var completedTasksTableView: UITableView!
    @IBOutlet private weak var tasksSummaryLabel: UILabel!
    
    private let viewModel: TaskListViewModel
    private let disposeBag: DisposeBag = .init()
    
    @available(*, unavailable)
    internal required init() {
        fatalError("init() has not been implemented, use stoaryboard initialization")
    }

    internal required init?(coder: NSCoder) {
        self.viewModel = .init()

        super.init(coder: coder)
    }
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setup()
        self.bindToViewModel()
    }
    
    @IBAction
    private func createTask(_ sender: UIButton) {
        self.viewModel.addTask(title: self.taskTitleTextField.text)
        self.taskTitleTextField.text = nil
        self.taskTitleTextField.resignFirstResponder()
    }
    
    private func setup() {
        self.openTasksTableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.defaultReuseIdentifier)
        self.completedTasksTableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.defaultReuseIdentifier)
        
    }
    
    private func bindToViewModel() {
        let openTasksDataSource = RxTableViewSectionedReloadDataSource<TaskListViewModel.SectionModel>(
            configureCell: { _, tableView, indexPath, task  in
                let cell = tableView.dequeueReusableCell(type: UITableViewCell.self, indexPath: indexPath)
                cell.accessibilityIdentifier = "taskTableViewCell_\(indexPath.section)_\(indexPath.row)"
                cell.textLabel?.text = task.title

                return cell
            }
        )
        
        let compleatedTasksDataSource = RxTableViewSectionedReloadDataSource<TaskListViewModel.SectionModel>(
            configureCell: { _, tableView, indexPath, task  in
                let cell = tableView.dequeueReusableCell(type: UITableViewCell.self, indexPath: indexPath)
                cell.accessibilityIdentifier = "taskTableViewCell_\(indexPath.section)_\(indexPath.row)"
                cell.textLabel?.text = task.title

                return cell
            }
        )
        
        self.viewModel.openSections
            .drive(self.openTasksTableView.rx.items(dataSource: openTasksDataSource))
            .disposed(by: self.disposeBag)
        
        self.viewModel.compleatedSections
            .drive(self.completedTasksTableView.rx.items(dataSource: compleatedTasksDataSource))
            .disposed(by: self.disposeBag)
        
        self.openTasksTableView.rx.itemSelected
            .bind { [unowned self] indexPath in
                let selectedTask = openTasksDataSource[indexPath]
                self.openTasksTableView.deselectRow(at: indexPath, animated: true)
                self.viewModel.changeTaskStatusViaId(selectedTask.id, status: .compleated)
            }
            .disposed(by: self.disposeBag)
        
        self.completedTasksTableView.rx.itemSelected
            .bind { [unowned self] indexPath in
                let selectedTask = compleatedTasksDataSource[indexPath]
                self.openTasksTableView.deselectRow(at: indexPath, animated: true)
                self.viewModel.changeTaskStatusViaId(selectedTask.id, status: .open)
            }
            .disposed(by: self.disposeBag)
        
        self.viewModel.tasksSummaryMessage
            .drive(self.tasksSummaryLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        self.taskTitleTextField.rx.text
            .map { !($0?.isEmpty ?? true) }
            .bind(to: self.createTaskButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
    }
}

extension UITableView {
    internal func dequeueReusableCell<Cell>(type: Cell.Type, indexPath: IndexPath) -> Cell where Cell: UITableViewCell {
        let cell = self.dequeueReusableCell(withIdentifier: Cell.defaultReuseIdentifier, for: indexPath)
        guard let typedCell = cell as? Cell else {
            fatalError("The dequeued table view cell is not of expected type \(type).")
        }

        return typedCell
    }
}

extension UITableViewCell {
    internal static var defaultReuseIdentifier: String {
        String(describing: self)
    }
}
