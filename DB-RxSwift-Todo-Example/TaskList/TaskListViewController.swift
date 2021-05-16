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
    @IBOutlet private weak var tableView: UITableView!
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
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.defaultReuseIdentifier)
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 60
    }
    
    private func bindToViewModel() {
        let dataSource = RxTableViewSectionedReloadDataSource<TaskListViewModel.SectionModel>(
            configureCell: { _, tableView, indexPath, task in
                let cell = tableView.dequeueReusableCell(type: UITableViewCell.self, indexPath: indexPath)
                cell.accessibilityIdentifier = "taskTableViewCell_\(indexPath.section)_\(indexPath.row)"
                cell.textLabel?.text = task.title

                return cell
            }
        )
        
        dataSource.titleForHeaderInSection = { dataSource, index in
            dataSource.sectionModels[index].title
        }

        self.viewModel.taskSections
            .drive(self.tableView.rx.items(dataSource: dataSource))
            .disposed(by: self.disposeBag)
        
        self.tableView.rx.itemSelected
            .bind { [unowned self] indexPath in
                let selectedTask = dataSource[indexPath]
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.viewModel.changeTaskStatusViaId(selectedTask.id)
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
