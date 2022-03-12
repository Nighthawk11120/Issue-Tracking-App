//
//  SectionDetailViewController.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 6/20/21.
//

import UIKit
import CoreData
import SwiftUI
import Combine

enum TableViewSection {
    case main
}

enum TaskList: Hashable, Equatable {
    case header(ToDoHeader)
    case task(ToDo)
}

class SectionDetailViewController: UIViewController, UISearchResultsUpdating {

    var startingIndexPath = IndexPath(item: 0, section: 0)
    var section: HeaderSection
    var storageProvider: ProjectProvider
    var dataSourceSnapshot = NSDiffableDataSourceSnapshot<ToDoHeader, TaskList>()
    var isDraggingHeader = false
    
    var selectedTaskIndexPath: IndexPath? = nil
    
    var sectionTasksItemsToUpdate: [ToDoHeader]? = nil
    
    var searchController = UISearchController(searchResultsController: nil)
    var tasksToShowUnderSearch = [ToDoHeader]()
    
    // MARK: - Context Menu
    var textFieldHeader: ToDoHeader? = nil
    var textField = UITextField()
    var textFieldTask: ToDo? = nil
    var cellToChangeIndexPath: IndexPath? = nil
    
    init?(section: HeaderSection, storageProvider: ProjectProvider) {
        self.section = section
        self.storageProvider = storageProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<ToDoHeader, TaskList>!
    
    var taskCellThatChanged: ToDo? = nil
    
    var didScrollSearch: Bool = false
    @Published var searchText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = section.sectionTitle
        view.backgroundColor = .systemGroupedBackground
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController?.navigationBar.prefersLargeTitles = false
            
            navigationController?.navigationItem.largeTitleDisplayMode = .never
        } else {
            navigationController?.navigationBar.prefersLargeTitles = true
            
            navigationController?.navigationItem.largeTitleDisplayMode = .always
        }
        
        // MARK: Create list layout
        var layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        layoutConfig.headerMode = .firstItemInSection
        
        layoutConfig.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self = self else { return nil }
            
            guard let item = self.dataSource.itemIdentifier(for: indexPath) else {
                return nil
            }
            
            switch item {
            case .task(let section):
                let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, completion in
                    completion(true)
                    var snapShot = self.dataSource.snapshot()
                    snapShot.deleteItems([item])
                    self.dataSource.apply(snapShot)
                    
                    self.storageProvider.persistentContainer.viewContext.delete(section)
                    try? self.storageProvider.persistentContainer.viewContext.save()
                    NotificationCenter.default.post(name: .DidUpdateTaskCell, object: nil)
                    print("deleted section")
                }
                return UISwipeActionsConfiguration(actions: [delete])
                
            case .header(let header):
                let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, completion in
                    completion(true)
                    
                    let ac = UIAlertController(title: "Are you sure you want to delete this project", message: "It will also delete all associated sections", preferredStyle: .alert)
                    
                    ac.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                        var snapshot = self.dataSource.snapshot()
                        snapshot.deleteSections([header])
                        for task in header.headerTasks {
                            snapshot.deleteItems([.task(task)])
                        }
                        self.dataSource.apply(snapshot)
                        
                        self.storageProvider.persistentContainer.viewContext.delete(header)
                        try? self.storageProvider.persistentContainer.viewContext.save()
                        NotificationCenter.default.post(name: .DidUpdateTaskCell, object: nil)
                        
                    }))
                    
                    ac.addAction(UIAlertAction(title: "Cancel", style: .default))
                    
                    self.present(ac, animated: true)
                    
                }
                return UISwipeActionsConfiguration(actions: [delete])
            }
        }
        
        let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
        
        // MARK: Configure collection view
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: listLayout)
        view.addSubview(collectionView)
        
        // Make collection view take up the entire view
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 0.0),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0.0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0),
        ])
        
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.delegate = self
        
        //        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewTask))
        
        let settings = UIAction(title: "Section Settings",
                                image: UIImage(systemName: "gear")) { [self] _ in
            let hostingController = UIHostingController(rootView: SectionSettingsView(storageProvider: storageProvider, section: self.section))
            
            if UIDevice.current.userInterfaceIdiom == .phone || windowMode() == "iPad slide over" {
                splitViewController?.showDetailViewController(UINavigationController(rootViewController: hostingController), sender: nil)
            } else {
                splitViewController?.setViewController(UINavigationController(rootViewController: hostingController), for: .secondary)
            }
        }
        
        let addTask = UIAction(title: "Add Task Header",
                               image: UIImage(systemName: "plus")) { _ in
            self.addNewTask()
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "More", image: UIImage(systemName: "ellipsis.circle"), menu: UIMenu(title: "", children: [settings, addTask]))
        //        UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showSectionSettings))
        // MARK: Cell registration
        let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ToDoHeader> {
            (cell, indexPath, cellItem) in
            
            // Configure cell content
            var configuration = cell.defaultContentConfiguration()
            configuration.text = "\(cellItem.headerTitle) \(cellItem.userOrder)"
            cell.contentConfiguration = configuration
            
            let favoriteAction = UIAction(image: UIImage(systemName: "ellipsis"),
                                          handler: { [weak self] _ in
                guard let self = self else { return }
                self.showSettings(header: cellItem)
            })
            
            let addNewTask = UIAction(title: "Add New Task", image: UIImage(systemName: "square.and.pencil"), identifier: nil) { _ in
                self.showSettings(header: cellItem)
            }
            
            let favoriteButton = UIButton(primaryAction: favoriteAction)
            favoriteButton.showsMenuAsPrimaryAction = true
            favoriteButton.menu = UIMenu(children: [addNewTask])
            
            
            let favoriteAccessory = UICellAccessory.CustomViewConfiguration(
                customView: favoriteButton,
                placement: .trailing(displayed: .always)
            )
            
            cell.accessories = [.customView(configuration: favoriteAccessory), .outlineDisclosure()]
            
            let contextInteraction = UIContextMenuInteraction(delegate: self)
            cell.addInteraction(contextInteraction)
        }
        
        let taskCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ToDo> { (cell, indexPath, cellItem) in
            // Configure cell content
            var configuration = cell.defaultContentConfiguration()
            configuration.text = "\(cellItem.todoName) \(cellItem.id!.uuidString.first!)\(cellItem.id!.uuidString.last!) \(cellItem.userOrder)"
            cell.contentConfiguration = configuration
            
            var checkImage = UIImage(systemName: cellItem.closed ? "checkmark.square.fill" : "square")
            
            let checkmarkAction = UIAction(image: UIImage(systemName: "checkmark"),
                                           handler: { [weak self] _ in
                guard let self = self else { return }
                
                cellItem.closed = !cellItem.closed
                try? self.storageProvider.persistentContainer.viewContext.save()
                
                
                UIView.transition(with: cell, duration: 0.1, options: .curveEaseInOut) {
                    checkImage = UIImage(systemName: cellItem.closed ? "checkmark.square.fill" : "square")
                } completion: { complete in
                    self.taskCellThatChanged = cellItem
                    NotificationCenter.default.post(name: .DidUpdateTaskCell, object: nil, userInfo: ["cell": cellItem])
                    
                }
            })
            
            let checkmarkButton = UIButton(primaryAction: checkmarkAction)
            checkmarkButton.setImage(checkImage, for: .normal)
            checkmarkButton.tintColor = cellItem.closed ? .systemBlue : .gray
            
            let checkmarkAccessory = UICellAccessory.CustomViewConfiguration(
                customView: checkmarkButton,
                placement: .leading(displayed: .always)
            )
            
            cell.accessories = [.customView(configuration: checkmarkAccessory)]
            
            let contextInteraction = UIContextMenuInteraction(delegate: self)
            cell.addInteraction(contextInteraction)
        }
        
        // MARK: Initialize data source
        dataSource = UICollectionViewDiffableDataSource<ToDoHeader, TaskList>(collectionView: collectionView) {
            (collectionView, indexPath, cellItem) -> UICollectionViewCell? in
            
            switch cellItem {
            case .header(let header):
                // Dequeue symbol cell
                let cell = collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration,
                                                                        for: indexPath,
                                                                        item: header)
                return cell
            case .task(let task):
                // Dequeue symbol cell
                let cell = collectionView.dequeueConfiguredReusableCell(using: taskCellRegistration,
                                                                        for: indexPath,
                                                                        item: task)
                return cell
            }
        }
        
        // Create collection view section based on number of HeaderItem in modelObjects
        dataSourceSnapshot.appendSections(section.sectionTasksDefaultSorted)
        dataSource.apply(dataSourceSnapshot)
        
        for header in section.sectionTasksDefaultSorted {
            var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
            let headerItem = TaskList.header(header)
            dataSourceSnapshot.append([headerItem])
            
            for task in header.headerTasksDefaultSorted {
                dataSourceSnapshot.append([.task(task)], to: headerItem)
            }
            
            dataSourceSnapshot.expand([headerItem])
            
            dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
            
        }
        
        configureSearchBar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateSectionTasksForAllAppWindows), name: .SectionsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSectionAfterDragDropForAllWindows), name: .SectionDragDropUpdated, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTaskCellForAllWindows(_:)), name: .DidUpdateTaskCell, object: nil)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            collectionView.contentInset = .zero
        } else {
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        collectionView.scrollIndicatorInsets = collectionView.contentInset
        
    }
    
    @objc func updateTaskCellForAllWindows(_ notification: NSNotification) {
        //
        if self.searchText != "" {
            var snap = self.dataSource.snapshot()
            snap.deleteAllItems()
            self.dataSource.apply(snap)
            
            for header in self.tasksToShowUnderSearch {
                var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
                let headerItem = TaskList.header(header)
                dataSourceSnapshot.append([headerItem])
                
                for task in header.headerTasksDefaultSorted where task.title!.lowercased().contains(self.searchText.lowercased()) || task.todoBodyText.lowercased().contains(self.searchText.lowercased())  {
                    dataSourceSnapshot.append([.task(task)], to: headerItem)
                }
                
                dataSourceSnapshot.expand([headerItem])
                
                self.dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
            }
        } else {
            
            var snap = dataSource.snapshot()
            snap.deleteAllItems()
            dataSource.apply(snap)
            
            for header in section.sectionTasksDefaultSorted {
                var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
                let headerItem = TaskList.header(header)
                dataSourceSnapshot.append([headerItem])
                
                for task in header.headerTasksDefaultSorted {
                    dataSourceSnapshot.append([.task(task)], to: headerItem)
                }
                
                dataSourceSnapshot.expand([headerItem])
                
                self.dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
            }
        }
        print("the other window was updated")
    }
    
    @objc func updateSectionAfterDragDropForAllWindows() {
        var snap = dataSource.snapshot()
        snap.deleteAllItems()
        dataSource.apply(snap)
        
        for header in section.sectionTasksDefaultSorted {
            var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
            let headerItem = TaskList.header(header)
            dataSourceSnapshot.append([headerItem])
            
            for task in header.headerTasksDefaultSorted {
                dataSourceSnapshot.append([.task(task)], to: headerItem)
            }
            
            dataSourceSnapshot.expand([headerItem])
            
            self.dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
        }
        print("the other window was updated")
        
    }
    
    @objc func updateSectionTasksForAllAppWindows() {
        title = section.sectionTitle
        for header in section.sectionTasksDefaultSorted {
            var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
            let headerItem = TaskList.header(header)
            dataSourceSnapshot.append([headerItem])
            
            for task in header.headerTasksDefaultSorted {
                dataSourceSnapshot.append([.task(task)], to: headerItem)
            }
            
            dataSourceSnapshot.expand([headerItem])
            
            dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: true)
            
        }
    }
    
    @objc func showSettings(header: ToDoHeader) {
        var userOrder: Double = 0
        
        if section.sectionTasksDefaultSorted.count > 0 && section.sectionTasksDefaultSorted.first(where: {$0.id == header.id })?.headerTasksDefaultSorted.count ?? 0 > 0 {
            userOrder = section.sectionTasksDefaultSorted.first {$0.id == header.id }!.headerTasksDefaultSorted.last!.userOrder + 25.0
            print("count was greater than zero \(section.sectionHeaders.count)")
        } else {
            userOrder = 100.0
            print("count was less than zero")
        }
        
        let task = ToDo(context: self.storageProvider.persistentContainer.viewContext)
        task.todoName = "ToDo"
        task.id = UUID()
        task.userOrder = userOrder
        task.header = header
        task.dueDate = Date()
        task.dueDateEnabled = false
        try? self.storageProvider.persistentContainer.viewContext.save()
        
        for header in section.sectionTasksDefaultSorted {
            var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
            let headerItem = TaskList.header(header)
            dataSourceSnapshot.append([headerItem])
            
            for task in header.headerTasksDefaultSorted {
                dataSourceSnapshot.append([.task(task)], to: headerItem)
            }
            
            dataSourceSnapshot.expand([headerItem])
            
            dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
            
        }
        NotificationCenter.default.post(name: .SectionsUpdated, object: nil)
        
        if let indexPath = dataSource.indexPath(for: .task(task)) {
            
            let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
            
            var content = cell.defaultContentConfiguration()
            content.text = ""
            
            cell.contentConfiguration = content
            self.textField = UITextField(frame: cell.bounds)
            self.textField.text = ""
            self.textField.translatesAutoresizingMaskIntoConstraints = false
            self.textField.isEnabled = true
            self.textField.becomeFirstResponder()
            self.textField.delegate = self
            self.textField.placeholder = "Task Name"
            self.textField.borderStyle = UITextField.BorderStyle.roundedRect
            self.textField.returnKeyType = UIReturnKeyType.done
            self.textField.clearButtonMode = UITextField.ViewMode.whileEditing
            self.textField.backgroundColor = .white
            self.textFieldTask = task
            self.cellToChangeIndexPath = indexPath
            cell.contentView.addSubview(self.textField)
        }
        
        
    }
    func configureSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Projects"
        navigationItem.searchController = searchController
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        if searchController.searchBar.text == "" {
            self.collectionView.dragInteractionEnabled = true
            
            var snap = dataSource.snapshot()
            snap.deleteAllItems()
            dataSource.apply(snap)
            
            for header in section.sectionTasksDefaultSorted {
                var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
                let headerItem = TaskList.header(header)
                dataSourceSnapshot.append([headerItem])
                
                for task in header.headerTasksDefaultSorted {
                    dataSourceSnapshot.append([.task(task)], to: headerItem)
                }
                
                dataSourceSnapshot.expand([headerItem])
                
                dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
                
            }
            
        } else {
            self.collectionView.dragInteractionEnabled = false
        }
        
        searchText = searchController.searchBar.text ?? ""
        tasksToShowUnderSearch = filteredTasks(for: searchController.searchBar.text)
        
    }
    
    
    
    func filteredTasks(for queryOrNil: String?) -> [ToDoHeader] {
        guard
            let query = queryOrNil,
            !query.isEmpty
        else {
            return section.sectionTasksDefaultSorted
        }
        
        if query == "" {
            var snap = dataSource.snapshot()
            snap.deleteAllItems()
            dataSource.apply(snap)
            
            for header in section.sectionTasksDefaultSorted {
                var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
                let headerItem = TaskList.header(header)
                dataSourceSnapshot.append([headerItem])
                
                for task in header.headerTasksDefaultSorted {
                    dataSourceSnapshot.append([.task(task)], to: headerItem)
                }
                
                dataSourceSnapshot.expand([headerItem])
                
                dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
            }
        } else {
            for header in tasksToShowUnderSearch {
                var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
                let headerItem = TaskList.header(header)
                dataSourceSnapshot.append([headerItem])
                
                for task in header.headerTasksDefaultSorted where task.title!.lowercased().contains(query.lowercased()) || task.todoBodyText.lowercased().contains(query.lowercased()) {
                    dataSourceSnapshot.append([.task(task)], to: headerItem)
                }
                
                dataSourceSnapshot.expand([headerItem])
                
                dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: true)
            }
        }
        
        return section.sectionTasksDefaultSorted.filter { taskHeader in
            let tasks = taskHeader.headerTasksDefaultSorted.filter { $0.title!.lowercased().contains(query.lowercased()) || $0.todoBodyText.lowercased().contains(query.lowercased())}
            var matches = false
            
            if !tasks.isEmpty {
                matches = true
            }
            
            return matches
        }
    }
    
    var reloadTask = CurrentValueSubject<ToDo?, Never>(nil)
    
    @objc func addNewTask() {
        var userOrder: Double = 0
        
        if section.sectionTasksDefaultSorted.count > 0 {
            userOrder = section.sectionTasksDefaultSorted.last!.userOrder + 25.0
            print("count was greater than zero \(section.sectionHeaders.count)")
        } else {
            userOrder = 100.0
            print("count was less than zero")
        }
        
        let header = ToDoHeader(context: self.storageProvider.persistentContainer.viewContext)
        header.title = "Task Group"
        header.section = section
        header.id = UUID()
        header.userOrder = userOrder
        try? self.storageProvider.persistentContainer.viewContext.save()
        print(section.sectionHeaders.count)
        
        var snapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
        
        dataSourceSnapshot.appendSections([header])
        
        let headerItem = TaskList.header(header)
        snapshot.append([headerItem])
        
        //        snapshot.append([.task(task)], to: headerItem)
        snapshot.expand([headerItem])
        
        dataSource.apply(snapshot, to: header, animatingDifferences: false)
        
        
        dataSource.reorderingHandlers.canReorderItem = { item in
            switch item {
            case .header(_):
                return false
            case .task(_):
                return true
            }
        }
        
        print("The notification was posted in SectionDetailViewController")
        NotificationCenter.default.post(name: .SectionsUpdated, object: nil)
        
        if let indexPath = dataSource.indexPath(for: .header(header)) {
            let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
            var content = cell.defaultContentConfiguration()
            content.text = ""
            
            cell.contentConfiguration = content
            self.textField = UITextField(frame: cell.bounds)
            self.textField.text = ""
            self.textField.translatesAutoresizingMaskIntoConstraints = false
            self.textField.isEnabled = true
            self.textField.becomeFirstResponder()
            self.textField.delegate = self
            self.textField.placeholder = "Task Header Name"
            self.textField.borderStyle = UITextField.BorderStyle.roundedRect
            self.textField.returnKeyType = UIReturnKeyType.done
            self.textField.clearButtonMode = UITextField.ViewMode.whileEditing
            self.textField.backgroundColor = .white
            self.textFieldHeader = header
            cell.contentView.addSubview(self.textField)
            self.cellToChangeIndexPath = indexPath
            self.collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
}

extension SectionDetailViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let topPadding = UIApplication.shared.windows[0].safeAreaInsets.top
        if scrollView.contentOffset.y + topPadding < -55 {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            didScrollSearch = true
        } else {
            didScrollSearch = false
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if didScrollSearch {
            searchController.isActive = true
            searchController.searchBar.becomeFirstResponder()
            
            didScrollSearch = false
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let fromTask = dataSource.itemIdentifier(for: sourceIndexPath),
              sourceIndexPath != destinationIndexPath else { return }
        
        var snap = NSDiffableDataSourceSectionSnapshot<TaskList>()
        let header = dataSource.sectionIdentifier(for: destinationIndexPath.section)!
        
        
        switch fromTask {
        case .header(_):
            print("cannot reorder headers")
        case .task(let fromTodo):
            snap.delete([.task(fromTodo)])
            
            if let toTask = dataSource.itemIdentifier(for: destinationIndexPath) {
                switch toTask {
                case .header(_):
                    print("cannot reorder headers")
                    
                case .task(let toTodo):
                    let isAfter = destinationIndexPath.row > sourceIndexPath.row
                    
                    if isAfter {
                        snap.insert([.task(fromTodo)], after: .task(toTodo))
                    } else {
                        snap.insert([.task(fromTodo)], before: .task(toTodo))
                    }
                }
                
            } else {
                //                let header = dataSource.sectionIdentifier(for: destinationIndexPath.section)!
                snap.append([.task(fromTodo)], to: .header(header))
            }
            
            dataSource.apply(snap, to: header, animatingDifferences: false)
            
            var upper: Double
            var lower: Double
            
            let allSectionTasks = section.sectionTasksDefaultSorted[destinationIndexPath.section].headerTasksDefaultSorted
            //                         If the destination is at the end of the list, or the beginning we do something different
            if destinationIndexPath.item == section.sectionTasksDefaultSorted.count {
                print("Appending to the end of the list")
                lower = allSectionTasks.last!.userOrder
                upper = allSectionTasks.last!.userOrder + 100.0
            } else if destinationIndexPath.item == 0 {
                print("Inserting into the begining")
                lower = 0.0
                upper = allSectionTasks.first?.userOrder ?? 100.0
            } else {
                print("Inserting into the middle of the list")
                // Find the upper and lower sort around the destination and make some sort orders
                upper = allSectionTasks[destinationIndexPath.item
                                        - 1].userOrder
                lower = allSectionTasks[destinationIndexPath.item].userOrder
            }
            
            allSectionTasks[sourceIndexPath.item].userOrder = stride(from: lower, to: upper, by: (upper - lower) / Double(2)).map{ $0 }[1]
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let taskItem = self.dataSource.itemIdentifier(for: indexPath)
        //
        if case let .task(task) = taskItem {
            let hostingController = UIHostingController(rootView: SectionDetailView(todo: task, reloadTask: reloadTask, storageProvider: storageProvider))
            present(hostingController, animated: true)
            
        }
        
    }
}

extension SectionDetailViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        for header in section.sectionTasksDefaultSorted {
            var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
            let headerItem = TaskList.header(header)
            dataSourceSnapshot.append([headerItem])
            
            for task in header.headerTasksDefaultSorted {
                dataSourceSnapshot.append([.task(task)], to: headerItem)
            }
            
            dataSourceSnapshot.expand([headerItem])
            
            dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
            
        }
        searchController.isEditing = false
        
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return [UIDragItem]()
        }
        
        startingIndexPath = indexPath
        
        switch item {
        case .header(let header):
            print("dragging ONE header")
            let itemProvider = NSItemProvider(object: DataTypeDragItem(id: header.objectID.uriRepresentation().absoluteString, type: DataType.todoHeader.rawValue))
            
            if let sec = dataSource.sectionIdentifier(for: indexPath.section) {
                for header in section.sectionTasksDefaultSorted {
                    var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
                    let headerItem = TaskList.header(header)
                    dataSourceSnapshot.append([headerItem])
                    for task in header.headerTasksDefaultSorted {
                        dataSourceSnapshot.append([.task(task)], to: headerItem)
                    }
                    dataSourceSnapshot.expand([.header(header)])
                    dataSourceSnapshot.collapse([.header(sec)])
                    dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
                }
            }
            
            isDraggingHeader = true
            
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            
            return [dragItem]
        case .task(let task):
            print("dragging ONE task")
            let itemProvider = NSItemProvider(object: DataTypeDragItem(id: task.objectID.uriRepresentation().absoluteString, type: DataType.todo.rawValue))
            
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = "task"
            
            return [dragItem]
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        print("the drag session was ended")
        if isDraggingHeader {
            
            for header in section.sectionTasksDefaultSorted {
                var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
                let headerItem = TaskList.header(header)
                dataSourceSnapshot.append([headerItem])
                for task in header.headerTasksDefaultSorted {
                    dataSourceSnapshot.append([.task(task)], to: headerItem)
                }
                dataSourceSnapshot.expand([.header(header)])
                dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
            }
        }
        isDraggingHeader = false
    }
    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        print("Drop session was ended")
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return [UIDragItem]()
        }
        
        switch item {
        case .header(_):
            print("dragging multiple headers")
            return [UIDragItem]()
        case .task(let task):
            print("dragging multiple tasks")
            let itemProvider = NSItemProvider(object: DataTypeDragItem(id: task.objectID.uriRepresentation().absoluteString, type: DataType.todo.rawValue))
            
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            
            print("the drag item is \(task)")
            
            return [dragItem]
        }
    }
}

// 4
extension SectionDetailViewController: UICollectionViewDropDelegate {
    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath {
            var destIndexPath = destinationIndexPath
            if destIndexPath.item >= collectionView.numberOfItems(inSection: destIndexPath.section) {
                destIndexPath.item = collectionView.numberOfItems(inSection: destIndexPath.section) - 1
            }
            guard let fromTask = dataSource.itemIdentifier(for: sourceIndexPath),
                  sourceIndexPath != destIndexPath else { return }
            
            var snap = dataSource.snapshot()
            var header = dataSource.sectionIdentifier(for: destIndexPath.section)!
            
            let sourceHeader = dataSource.sectionIdentifier(for: sourceIndexPath.section)!
            
            var changeHeader = false
            
            var sectionTasksCopy = section.sectionTasksDefaultSorted[destIndexPath.section].headerTasksDefaultSorted
            
            switch fromTask {
            case .header(_):
                print("cannot reorder headers here")
            case .task(let fromTodo):
                snap.deleteItems([.task(fromTodo)])
                
                if let toTask = dataSource.itemIdentifier(for: destIndexPath) {
                    switch toTask {
                    case .header(let fromHeader):
                        
                        // if there are no items in the header when trying to add a new one to it
                        if fromHeader.headerTasksDefaultSorted.isEmpty {                            
                            // no items are in the section, so just add it
                            snap.appendItems([.task(fromTodo)], toSection: fromHeader)
                            changeHeader = true
                            
                            fromTodo.header = fromHeader
                            
                            for item in sectionTasksCopy {
                                let sortIndex = sectionTasksCopy.firstIndex(of: item)!
                                item.userOrder = Double(sortIndex)
                            }
                            
                            try? AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer.viewContext.save()
                            dataSource.apply(snap, animatingDifferences: false)
                            
                            for header in section.sectionTasksDefaultSorted {
                                var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
                                let headerItem = TaskList.header(header)
                                dataSourceSnapshot.append([headerItem])
                                
                                for task in header.headerTasksDefaultSorted {
                                    dataSourceSnapshot.append([.task(task)], to: headerItem)
                                }
                                
                                dataSourceSnapshot.expand([headerItem])
                                
                                dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
                                
                            }
                            NotificationCenter.default.post(name: .SectionsUpdated, object: nil)
                            
                            return
                        } else {
                            header = dataSource.sectionIdentifier(for: destIndexPath.section - 1)!
                            
                            snap.appendItems([.task(fromTodo)], toSection: header)
                            changeHeader = true
                            dataSource.apply(snap, animatingDifferences: false)
                        }
                    case .task(let toTodo):
                        
                        if header == sourceHeader {
                            sectionTasksCopy.removeAll {$0.id == fromTodo.id}
                            
                            sectionTasksCopy.insert(fromTodo, at: destIndexPath.item - 1)
                        } else if header != sourceHeader && header.headerTasksDefaultSorted.count == (destIndexPath.item + 1) {
                            sectionTasksCopy.insert(fromTodo, at: destIndexPath.item - 1)
                        } else {
                            if let indexPath = coordinator.destinationIndexPath {
                                destIndexPath = indexPath
                            } else {
                                let row = collectionView.numberOfItems(inSection: 0)
                                destIndexPath = IndexPath(item: row - 1, section: 0)
                            }
                            sectionTasksCopy.removeAll {$0.id == fromTodo.id}
                            
                            var originalHeader = section.sectionTasksDefaultSorted[startingIndexPath.section].headerTasksDefaultSorted
                            let originalTask = originalHeader.remove(at: max(0, startingIndexPath.row - 1))
                            sectionTasksCopy.insert(originalTask, at: min(destIndexPath.item - 1, header.headerTasksDefaultSorted.count))
                        }
                        
                        let isAfter = destIndexPath.item > sourceIndexPath.item
                        if isAfter {
                            
                            snap.insertItems([.task(fromTodo)], afterItem: .task(toTodo))
                        } else {
                            snap.insertItems([.task(fromTodo)], beforeItem: .task(toTodo))
                        }
                    }
                } else {
                    if let lastTask = header.headerTasksDefaultSorted.last {
                        snap.insertItems([.task(fromTodo)], afterItem: .task(lastTask))
                    } else {
                        snap.appendItems([.task(fromTodo)], toSection: header)
                    }
                    
                }
            }
            
            if header != sourceHeader || changeHeader {
                if changeHeader {
                    for item in dataSource.snapshot().itemIdentifiers(inSection: header) {
                        let sortIndex = dataSource.snapshot().itemIdentifiers(inSection: header).firstIndex(of: item)!
                        
                        switch item {
                        case .task(let child):
                            child.header = header
                            child.userOrder = Double(sortIndex + 10)
                        case .header(_):
                            print("its really a header")
                            guard case let .task(childItem) = fromTask else { return }
                            childItem.header = header
                            childItem.userOrder = Double(sortIndex + 10)
                        }
                    }
                    
                    // reorder the items in the source section
                    let header = section.sectionTasksDefaultSorted[startingIndexPath.section]
                    let items = header.headerTasksDefaultSorted
                    
                    for item in section.sectionTasksDefaultSorted[startingIndexPath.section].headerTasks {
                        let sortIndex = items.firstIndex(of: item)!
                        item.userOrder = Double(sortIndex + 10)
                    }
                    
                } else {
                    sectionTasksCopy[destIndexPath.item - 1].header = header
                    // reorder the items in the destination section
                    for item in sectionTasksCopy {
                        let sortIndex = sectionTasksCopy.firstIndex(of: item)!
                        item.userOrder = Double(sortIndex + 10)
                    }
                    
                    // reorder the items in the source section
                    let header = section.sectionTasksDefaultSorted[startingIndexPath.section]
                    let items = header.headerTasksDefaultSorted
                    
                    for item in section.sectionTasksDefaultSorted[startingIndexPath.section].headerTasks {
                        let sortIndex = items.firstIndex(of: item)!
                        item.userOrder = Double(sortIndex + 10)
                    }
                }
            } else {
                for item in sectionTasksCopy {
                    let sortIndex = sectionTasksCopy.firstIndex(of: item)!
                    item.userOrder = Double(sortIndex + 10)
                }
            }
            
            dataSource.apply(snap, animatingDifferences: false)
            
            try? AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer.viewContext.save()
            
            for header in section.sectionTasksDefaultSorted {
                var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
                let headerItem = TaskList.header(header)
                dataSourceSnapshot.append([headerItem])
                
                for task in header.headerTasksDefaultSorted {
                    dataSourceSnapshot.append([.task(task)], to: headerItem)
                }
                
                dataSourceSnapshot.expand([headerItem])
                
                dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
                
            }
        }
        NotificationCenter.default.post(name: .SectionsUpdated, object: nil)
    }
    
    
    private func reorderTaskHeaders(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath {
            var destIndexPath = destinationIndexPath
            if destIndexPath.row >= collectionView.numberOfItems(inSection: destIndexPath.section) {
                destIndexPath.row = collectionView.numberOfItems(inSection: destIndexPath.section) - 1
            }
            
            guard let fromTodo = dataSource.sectionIdentifier(for: sourceIndexPath.section),
                  sourceIndexPath != destinationIndexPath else { return }
            
            var snap = dataSource.snapshot()
                        
            snap.deleteSections([fromTodo])
            for i in fromTodo.headerTasksDefaultSorted {
                snap.deleteItems([.task(i)])
            }
            
            
            var sectionTasksCopy = section.sectionTasksDefaultSorted
            
            if let toTodo = dataSource.sectionIdentifier(for: destinationIndexPath.section) {
                let isAfter = destinationIndexPath.section > sourceIndexPath.section
                
                sectionTasksCopy.removeAll {$0.id == fromTodo.id}
                sectionTasksCopy.insert(fromTodo, at: destinationIndexPath.section)
                
                if isAfter {
                    snap.insertSections([fromTodo], afterSection: toTodo)
                } else {
                    snap.insertSections([fromTodo], beforeSection: toTodo)
                }
                
                print("reordering headers and not tasks")
                
            } else {
                sectionTasksCopy.removeAll {$0.id == fromTodo.id}
                sectionTasksCopy.insert(fromTodo, at: destIndexPath.section)
                
                snap.appendSections([fromTodo])
            }
            
            dataSource.apply(snap)
            
            for item in sectionTasksCopy {
                let sortIndex = sectionTasksCopy.firstIndex(of: item)!
                item.userOrder = Double(sortIndex + 10)
            }
            
            
            try? AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer.viewContext.save()
            
            NotificationCenter.default.post(name: .SectionDragDropUpdated, object: nil)
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        // If you don't use diffable data source, you'll need to reconcile your local data store here.
        // In our case, we do so in the diffable datasource subclass.
        let destinationIndexPath: IndexPath
        
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(item: row, section: section)
        }
        
        for header in section.sectionTasksDefaultSorted {
            var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<TaskList>()
            let headerItem = TaskList.header(header)
            dataSourceSnapshot.append([headerItem])
            for task in header.headerTasksDefaultSorted {
                dataSourceSnapshot.append([.task(task)], to: headerItem)
            }
            dataSourceSnapshot.expand([.header(header)])
            dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
        }
        
        
        switch coordinator.proposal.operation {
        case .move:
            coordinator.session.loadObjects(ofClass: DataTypeDragItem.self) { items in
                if let sections = items as? [DataTypeDragItem] {                    
                    for (_, item) in sections.enumerated() {
                        DispatchQueue.main.async {
                            if item.type == DataType.todo.rawValue {
                                print("reordering the tasks")
                                
                                self.reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
                            } else if item.type == DataType.todoHeader.rawValue {
                                print("reordering the headers")
                                self.reorderTaskHeaders(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
                                
                            }
                        }
                    }
                }
            }
            
            break
        case .copy:
            // Not copying between collections so this block not needed.
            return
        default:
            return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

extension SectionDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.isEnabled = false
        
        if let textFieldHeader = textFieldHeader {
            textFieldHeader.title = textField.text
            try? storageProvider.persistentContainer.viewContext.save()
            
            
            if let indexPath = self.cellToChangeIndexPath {
                // make the text white when it is selected in the sidebar
                let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
                var content = cell.defaultContentConfiguration()
                content.text = textFieldHeader.title
                self.textField.removeFromSuperview()
                
                NotificationCenter.default.post(name: .DidUpdateTaskCell, object: nil)
                
            }
        }
        
        
        if let textFieldSection = textFieldTask {
            textFieldSection.title = textField.text
            try? self.storageProvider.persistentContainer.viewContext.save()
            //            NotificationCenter.default.post(name: .ProjectsUpdated, object: nil)
            if let textFieldSection = textFieldTask {
                if let indexPath = cellToChangeIndexPath {
                    // make the text white when it is selected in the sidebar
                    let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
                    var content = cell.defaultContentConfiguration()
                    content.text = textFieldSection.title
                    
                    var newSnapshot = dataSource.snapshot()
                    newSnapshot.reloadSections(section.sectionTasksDefaultSorted)
                    newSnapshot.reloadItems([.task(textFieldSection)])
                    dataSource.apply(newSnapshot)
                    
                    self.textField.removeFromSuperview()
                    
                    NotificationCenter.default.post(name: .DidUpdateTaskCell, object: nil)
                }
            }
        }
        
        textFieldTask = nil
        textFieldHeader = nil
        cellToChangeIndexPath = nil
                
        NotificationCenter.default.post(name: .SectionsUpdated, object: nil)
        
        return true
    }
}



