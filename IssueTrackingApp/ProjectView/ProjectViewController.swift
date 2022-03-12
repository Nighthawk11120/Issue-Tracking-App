//
//  ProjectViewController.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 6/17/21.
//

import UIKit
import CoreData
import SwiftUI

typealias DataSource = NSDiffableDataSourceSnapshot<Project, ExpandableListItem>
typealias Snapshot = NSDiffableDataSourceSectionSnapshot<ExpandableListItem>

enum ExpandableListItem: Hashable {
    case header(Project)
    case section(HeaderSection)
}

class ProjectViewController: UIViewController {
    
    let VCActivityType = "VCKey"

    var projectEditTextField = UITextField()
    var collectionView: UICollectionView!
        
    var sectionDetailViewController: SectionDetailViewController?
    
    var viewModel: ProjectViewModel
    
    init(storageProvider: StorageProvider) {
        self.viewModel = ProjectViewModel()
        viewModel.setupFetchedResultsController()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var dragFromProject: Project? = nil
    
    var startingIndexPath = IndexPath(item: 0, section: 0)

    override func loadView() {
        super.loadView()
        
        configureCollectionView()
        configureToolbarItems()
        configureCollectionViewDragAndDrop()
        configureSearchBar()
        configureTextFieldDelegate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if targetEnvironment(macCatalyst)
        
        #else
        view.backgroundColor = .systemGroupedBackground
        #endif
        
        title = "Projects"
        
        if let splitViewController = splitViewController, let splitNavigationController = splitViewController.viewControllers.last as? UINavigationController, let topViewController = splitNavigationController.topViewController as? SectionDetailViewController {
            sectionDetailViewController = topViewController
        }
        
        //         Observe .didFindRelevantTransactions to update the UI if needed.
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).didFindRelevantTransactions(_:)),
            name: .didFindRelevantTransactions, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateProjectViewData), name: .ProjectsUpdated, object: nil)
        
        // show first section automatically when the app is on a mac or iPad
        if UIDevice.current.userInterfaceIdiom != .phone {
            if !viewModel.projects.isEmpty && (viewModel.projects.first?.projectSections.count)! > 0 {
                if let sectionToShow = AppDelegate.sectionToOpenInNewWindow {
                    let indexPath = self.viewModel.dataSource.indexPath(for: .section(sectionToShow))
                    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
                    
                    let sheetViewController = SectionDetailViewController(section: sectionToShow, storageProvider: self.viewModel.dataProvider)
                    sheetViewController?.title = "\(sectionToShow.title ?? "Section")"
                    
                    splitViewController?.setViewController(UINavigationController(rootViewController: sheetViewController!), for: .secondary)
                    
                    AppDelegate.sectionToOpenInNewWindow = nil
                    
                } else {
                    let section = viewModel.projects.first?.projectSectionsSorted.first
                    if let section = section {

                        collectionView.selectItem(at: IndexPath(item: 1, section: 0), animated: false, scrollPosition: [])
                        let sheetViewController = SectionDetailViewController(section: section, storageProvider: self.viewModel.dataProvider)
                        sheetViewController?.title = "\(section.title ?? "Section")"
                        
                        splitViewController?.setViewController(UINavigationController(rootViewController: sheetViewController!), for: .secondary)
                    }
                }
                
            } else {
                let hostingController = UIHostingController(rootView: EmptySectionDetailView())
                splitViewController?.setViewController(hostingController, for: .secondary)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(updateSectionsForAllWindows), name: .SectionInProjectDragDropUpdated, object: nil)
        
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
    
    @objc func updateSectionsForAllWindows() {
        var snap = viewModel.dataSource.snapshot()
        snap.deleteAllItems()
        viewModel.dataSource.apply(snap)
        
        viewModel.setupFetchedResultsController()
        viewModel.updateCollectionViewList()
    }
    
    @objc func updateProjectViewData() {
        viewModel.setupFetchedResultsController()
        viewModel.updateCollectionViewList()
        collectionView.reloadData()
    }
    
    func configureSearchBar() {
        viewModel.searchController.searchResultsUpdater = self
        viewModel.searchController.obscuresBackgroundDuringPresentation = false
        viewModel.searchController.searchBar.placeholder = "Search Projects"
        navigationItem.searchController = viewModel.searchController
        definesPresentationContext = true
    }
    
    func configureToolbarItems() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProject))
    }
    
    @objc func showUpcomingTasksView() {
        @StateObject var upcomingTasksViewModel = UpcomingTasksViewModel(fetchedProjects: self.viewModel.$projects, storageProvider: self.viewModel.dataProvider)

        let hostingController = UIHostingController(rootView: UpcomingTasksView(viewModel: upcomingTasksViewModel)            .environment(\.managedObjectContext, viewModel.dataProvider.persistentContainer.viewContext)
)
        hostingController.title = "Upcoming Tasks"
        
        
        if UIDevice.current.userInterfaceIdiom == .phone || windowMode() == "iPad slide over" {
            splitViewController?.showDetailViewController(UINavigationController(rootViewController: hostingController), sender: nil)
        } else {
            splitViewController?.setViewController(UINavigationController(rootViewController: hostingController), for: .secondary)
        }
        
    }
    
    @objc func showSettingsView() {
        let hostingController = UIHostingController(rootView: AppDelegate.sharedAppDelegate.catalystAppView)
        hostingController.title = "Settings"
        
        if UIDevice.current.userInterfaceIdiom == .phone || windowMode() == "iPad slide over" {
            splitViewController?.showDetailViewController(UINavigationController(rootViewController: hostingController), sender: nil)
        } else {
            splitViewController?.setViewController(UINavigationController(rootViewController: hostingController), for: .secondary)
        }
    }
    
    @objc func sortCollectionView() {
        let userDefaults = UserDefaults.standard
        let ac = UIAlertController(title: "Sort Project Sections", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Title", style: .default, handler: { _ in
            userDefaults.set(HeaderSection.SortOrder.title.rawValue, forKey: Constants.sortedSection)

            self.viewModel.updateCollectionViewList()
        }))
        ac.addAction(UIAlertAction(title: "Creation Date", style: .default, handler: { _ in
            userDefaults.set(HeaderSection.SortOrder.creationDate.rawValue, forKey: Constants.sortedSection)

            self.viewModel.updateCollectionViewList()
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = ac.popoverPresentationController {
            popover.barButtonItem = self.navigationItem.leftBarButtonItem
        }
        
        self.present(ac, animated: true)
    }
    
    @objc func addProject() {
        var userOrder: Int16 = 0
        if viewModel.projects.count > 0 {
            userOrder = viewModel.projects.last!.userOrder + 25
        } else {
            userOrder = 100
        }
        let project = Project(context: viewModel.dataProvider.persistentContainer.viewContext)
        project.title = "New Project"
        project.creationDate = Date()
        project.uuid = UUID()
        project.userOrder = userOrder
        
        let section = HeaderSection(context: viewModel.dataProvider.persistentContainer.viewContext)
        section.title = "New Section"
        section.creationDate = Date()
        section.project = project
        section.uuid = UUID()
        section.userOrder = 100
                
        let todoHeader = ToDoHeader(context: viewModel.dataProvider.persistentContainer.viewContext)
        todoHeader.title = "General"
        todoHeader.section = section
        todoHeader.creationDate = Date()
        todoHeader.id = UUID()
        todoHeader.userOrder = 100
        
        try? viewModel.dataProvider.persistentContainer.viewContext.save()
        
        var sectionSnapshot2 = NSDiffableDataSourceSectionSnapshot<ExpandableListItem>()
        
        viewModel.dataSourceSnapshot.appendSections([project])
        
                // Create a header ListItem & append as parent
                let headerListItem = ExpandableListItem.header(project)
                sectionSnapshot2.append([headerListItem])
        
                // Create an array of sectionListItem & append as child of headerListItem
                let sectionListItemArray = ExpandableListItem.section(section)
                sectionSnapshot2.append([sectionListItemArray], to: headerListItem)
        
                // Expand this section by default
                sectionSnapshot2.expand([headerListItem])
        
                // Apply section snapshot to the respective collection view section
        viewModel.dataSource.apply(sectionSnapshot2, to: project, animatingDifferences: true)
        
        
        if let indexPath = viewModel.dataSource.indexPath(for: .header(project)) {
            let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
            var content = cell.defaultContentConfiguration()
            content.text = ""
            
            cell.contentConfiguration = content
            self.projectEditTextField = UITextField(frame: cell.bounds)
            self.projectEditTextField.text = ""
            self.projectEditTextField.translatesAutoresizingMaskIntoConstraints = false
            self.projectEditTextField.isEnabled = true
            self.projectEditTextField.becomeFirstResponder()
            self.projectEditTextField.delegate = self
            self.projectEditTextField.placeholder = "Project Name"
            self.projectEditTextField.borderStyle = UITextField.BorderStyle.roundedRect
            self.projectEditTextField.returnKeyType = UIReturnKeyType.done
            self.projectEditTextField.clearButtonMode = UITextField.ViewMode.whileEditing
            self.projectEditTextField.backgroundColor = .white
            self.viewModel.textFieldProject = project
            cell.contentView.addSubview(self.projectEditTextField)
            self.viewModel.cellToChangeIndexPath = indexPath
            self.collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    @objc func onEditButtonTapped() {
        collectionView.isEditing.toggle()
    }
    
    func configureTextFieldDelegate() {
        projectEditTextField.delegate = self
    }
    
    func configureCollectionView() {
        // Set layout to collection view
        var layoutConfig = UICollectionLayoutListConfiguration(appearance: .sidebar)
        if UIDevice.current.userInterfaceIdiom == .phone {
        } else {
            layoutConfig = UICollectionLayoutListConfiguration(appearance: .sidebar)
        }
        
        layoutConfig.headerMode = .firstItemInSection
        
        layoutConfig.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self = self else { return nil }
            
            guard let item = self.viewModel.dataSource.itemIdentifier(for: indexPath) else {
                return nil
            }
            
            switch item {
            case .section(let section):
                let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, completion in
                    completion(true)
                    var snapShot = self.viewModel.dataSource.snapshot()
                    snapShot.deleteItems([item])
                    self.viewModel.dataSource.apply(snapShot)
                    
                    self.viewModel.dataProvider.persistentContainer.viewContext.delete(section)
                    try? self.viewModel.dataProvider.persistentContainer.viewContext.save()
                }
                return UISwipeActionsConfiguration(actions: [delete])
                
            case .header(let header):
                let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, completion in
                    completion(true)
                    
                    let ac = UIAlertController(title: "Are you sure you want to delete this project", message: "It will also delete all associated sections", preferredStyle: .alert)
                    
                    ac.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                        var snapShot = self.viewModel.dataSource.snapshot()
                        snapShot.deleteItems([item])
                        snapShot.deleteSections([header])
                        self.viewModel.dataSource.apply(snapShot)
                        
                        self.viewModel.dataProvider.persistentContainer.viewContext.delete(header)
                        try? self.viewModel.dataProvider.persistentContainer.viewContext.save()
                        NotificationCenter.default.post(name: .SectionInProjectDragDropUpdated, object: nil)
                    }))
                    
                    ac.addAction(UIAlertAction(title: "Cancel", style: .default))
                    
                    self.present(ac, animated: true)
                    
                }
                return UISwipeActionsConfiguration(actions: [delete])
            }
        }
        
        let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
        
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
        collectionView.delegate = self
        
        let projectHeaderCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Project> { [self] (cell, indexPath, headerItem) in
            
            var content = cell.defaultContentConfiguration()
            content.text = "\(headerItem.projectTitle) \(headerItem.userOrder)"
            cell.contentConfiguration = content
            
            // expand/collapse
            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options: headerDisclosureOption), .delete(displayed: .whenEditing, actionHandler: {
                var snapShot = self.viewModel.dataSource.snapshot()
                for sec in headerItem.projectSections {
                    
                    snapShot.deleteItems([.section(sec)])
                }
                snapShot.deleteSections([headerItem])
                self.viewModel.dataSource.apply(snapShot)
                
                self.viewModel.dataProvider.persistentContainer.viewContext.delete(headerItem)
                try? self.viewModel.dataProvider.persistentContainer.viewContext.save()
            }), .reorder(), .insert(displayed: .always, options: .init(isHidden: false, reservedLayoutWidth: .standard, tintColor: .white, backgroundColor:  .systemBlue), actionHandler: {
                
                var userOrder: Int16 = 0
                
                if headerItem.projectSectionsSorted.count > 0 {
                    userOrder = headerItem.projectSectionsSorted.last!.userOrder + 25
                } else {
                    userOrder = 100
                }
                
                let viewContext = self.viewModel.dataProvider.persistentContainer.viewContext
                let section = HeaderSection(context: viewContext)
                section.title = "Created Section"
                section.creationDate = Date()
                section.project = headerItem
                section.uuid = UUID()
                section.dateToOccur = Date()
                section.scheduleActive = true
                section.userOrder = userOrder
                
                let todoHeader = ToDoHeader(context: viewContext)
                todoHeader.title = "General"
                todoHeader.section = section
                todoHeader.creationDate = Date()
                todoHeader.id = UUID()
                todoHeader.userOrder = 100
                
                try? self.viewModel.dataProvider.persistentContainer.viewContext.save()
                var newSnapshot = self.viewModel.dataSource.snapshot()
                newSnapshot.appendItems([.section(section)], toSection: headerItem)
                self.viewModel.dataSource.apply(newSnapshot)

                AppDelegate.sharedAppDelegate.coreDataStack.saveContext()
                
                if let indexPath = viewModel.dataSource.indexPath(for: .section(section)) {
                    let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
                    var content = cell.defaultContentConfiguration()
                    content.text = ""
                    
                    cell.contentConfiguration = content
                    self.projectEditTextField = UITextField(frame: cell.bounds)
                    self.projectEditTextField.text = ""
                    self.projectEditTextField.translatesAutoresizingMaskIntoConstraints = false
                    self.projectEditTextField.isEnabled = true
                    self.projectEditTextField.becomeFirstResponder()
                    self.projectEditTextField.delegate = self
                    self.projectEditTextField.placeholder = "Section Name"
                    self.projectEditTextField.borderStyle = UITextField.BorderStyle.roundedRect
                    self.projectEditTextField.returnKeyType = UIReturnKeyType.done
                    self.projectEditTextField.clearButtonMode = UITextField.ViewMode.whileEditing
                    self.projectEditTextField.backgroundColor = .white
                    self.viewModel.textFieldSection = section
                    cell.contentView.addSubview(self.projectEditTextField)
                    self.viewModel.cellToChangeIndexPath = indexPath
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                }
            })]
            
            let contextInteraction = UIContextMenuInteraction(delegate: self)
            cell.addInteraction(contextInteraction)
        }
        
        let sectionCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, HeaderSection> { (cell, indexPath, section) in
            
            var content = cell.defaultContentConfiguration()
            content.text = "\( section.title!) \(section.uuid!.uuidString.first!) \(section.userOrder)"
            cell.contentConfiguration = content
            cell.indentationLevel = 2
            cell.accessories = [.delete(displayed: .whenEditing, actionHandler: {
                var snapshot = self.viewModel.dataSource.snapshot()
                snapshot.deleteItems([.section(section)])
                self.viewModel.dataSource.apply(snapshot)
                
                self.viewModel.dataProvider.persistentContainer.viewContext.delete(section)
                try? self.viewModel.dataProvider.persistentContainer.viewContext.save()
            })]
            let contextInteraction = UIContextMenuInteraction(delegate: self)
            cell.addInteraction(contextInteraction)
        }
        
        viewModel.dataSource = UICollectionViewDiffableDataSource<Project, ExpandableListItem>(collectionView: collectionView) {
            (collectionView, indexPath, listItem) -> UICollectionViewCell? in
            
            switch listItem {
            case .header(let projectHeader):
                // Dequeue header cell
                let cell = collectionView.dequeueConfiguredReusableCell(using: projectHeaderCellRegistration,
                                                                        for: indexPath,
                                                                        item: projectHeader)
                return cell
                
            case .section(let section):
                // Dequeue section cell
                let cell = collectionView.dequeueConfiguredReusableCell(using: sectionCellRegistration,
                                                                        for: indexPath,
                                                                        item: section)
                return cell
            }
        }
        
        viewModel.setupInitialData()
    }
    
    func configureCollectionViewDragAndDrop() {
        
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }
}

extension ProjectViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Get id of selected hero using index path
        guard let item = viewModel.dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        // --> Do section work here
        switch item {
        case .section(let section):
            viewModel.selectedSection = section
            let sheetViewController = SectionDetailViewController(section: section, storageProvider: self.viewModel.dataProvider)
            sheetViewController?.title = "\(section.title ?? "Section")"

            if UIDevice.current.userInterfaceIdiom == .phone || windowMode() == "iPad slide over" {
                splitViewController?.showDetailViewController(UINavigationController(rootViewController: sheetViewController!), sender: nil)
            } else {
                splitViewController?.setViewController(UINavigationController(rootViewController: sheetViewController!), for: .secondary)
            }
            
        case .header(_):
            print("tapped on a header")
        }
    }
}

class TaskData: ObservableObject {
    @Published var section: HeaderSection
    init(section: HeaderSection) {
        self.section = section
    }
}

extension ProjectViewController {
    @objc
    func didFindRelevantTransactions(_ notification: Notification) {
        viewModel.setupFetchedResultsController()
        NotificationCenter.default.post(name: .SectionsUpdated, object: nil)

        
        DispatchQueue.main.async {
            var newSnapshot = self.viewModel.dataSource.snapshot()
            newSnapshot.deleteAllItems()
            self.viewModel.dataSource.apply(newSnapshot)
            self.viewModel.updateCollectionViewList()

            self.collectionView.reloadData()
        }
    }
    
    private func resetAndReload(select section: HeaderSection?) {
        viewModel.dataProvider.persistentContainer.viewContext.reset()
        viewModel.setupFetchedResultsController()
        DispatchQueue.main.async {
            var newSnapshot = self.viewModel.dataSource.snapshot()
            newSnapshot.deleteAllItems()
            self.viewModel.dataSource.apply(newSnapshot)
            self.viewModel.updateCollectionViewList()
            
            self.collectionView.reloadData()
        }
    }
}

extension ProjectViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        viewModel.currentSearchText = text
        
        if self.viewModel.shouldReloadSearchResults {
            
            viewModel.setupFetchedResultsController()
            print("searching")
            DispatchQueue.main.async {
                var newSnapshot = self.viewModel.dataSource.snapshot()
                newSnapshot.deleteAllItems()
                self.viewModel.dataSource.apply(newSnapshot)
                self.viewModel.projects = self.viewModel.filteredSections(for: searchController.searchBar.text)
                
                if searchController.searchBar.text != "" {
                    self.collectionView.dragInteractionEnabled = false

                    for headerItem in self.viewModel.projects {
                        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ExpandableListItem>()
                        
                        let headerListItem = ExpandableListItem.header(headerItem)
                        sectionSnapshot.append([headerListItem])

                        for section in self.viewModel.sections(for: headerItem).sorted(by: \HeaderSection.userOrder) where section.title!.lowercased().contains(searchController.searchBar.text?.lowercased() ?? "") {
                                sectionSnapshot.append([ExpandableListItem.section(section)], to: headerListItem)
                            }
                        
                        sectionSnapshot.expand([headerListItem])
                        
                        self.viewModel.dataSource.apply(sectionSnapshot, to: headerItem, animatingDifferences: true)
                    }
                    self.collectionView.reloadData()
                } else {
                    self.collectionView.dragInteractionEnabled = true
                    self.viewModel.updateCollectionViewList()
                }
            }
        }
    }
}

func windowMode() -> String {
  let screenRect = UIScreen.main.bounds
  let appRect = UIApplication.shared.windows[0].bounds

  if (UIDevice.current.userInterfaceIdiom == .phone) {
    return "iPhone fullscreen"
  } else if (screenRect == appRect) {
    return "iPad fullscreen"
  } else if (appRect.size.height < screenRect.size.height) {
    return "iPad slide over"
  } else {
    return "iPad split view"
  }
}
