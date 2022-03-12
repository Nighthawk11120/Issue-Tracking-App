//
//  ProjectViewModel.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 7/27/21.
//

import UIKit
import Combine
import CoreData

class ProjectViewModel: NSObject, ObservableObject {
    @Published var projects = [Project]()
    
    var currentSearchText = ""
    var shouldReloadSearchResults = true
    @Published var searchController = UISearchController(searchResultsController: nil)

    var textFieldSection: HeaderSection? = nil
    var textFieldProject: Project? = nil
    
    var cellToChangeIndexPath: IndexPath?
    
    var selectedSection: HeaderSection? = nil
    
    var sortOrder: HeaderSection.SortOrder = HeaderSection.SortOrder.creationDate

    var dataSource: UICollectionViewDiffableDataSource<Project, ExpandableListItem>!
    var dataSourceSnapshot = NSDiffableDataSourceSnapshot<Project, ExpandableListItem>()

    lazy var dataProvider: ProjectProvider = {
        let container = AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer
        let provider = ProjectProvider(with: container,
                                    fetchedResultsControllerDelegate: self)
        return provider
    }()

    func setupInitialData() {
        dataSourceSnapshot.appendSections(projects)
        dataSource.apply(dataSourceSnapshot)
        
        for headerItem in projects {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ExpandableListItem>()
            
            let headerListItem = ExpandableListItem.header(headerItem)
        
            sectionSnapshot.append([headerListItem])
            
            for section in sections(for: headerItem) {
                sectionSnapshot.append([ExpandableListItem.section(section)], to: headerListItem)
            }
            
            sectionSnapshot.expand([headerListItem])
            
            dataSource.apply(sectionSnapshot, to: headerItem, animatingDifferences: false)
        }
    }
    
    func filteredSections(for queryOrNil: String?) -> [Project] {
        guard
          let query = queryOrNil,
          !query.isEmpty
          else {
            return projects
        }
        
        return projects.filter { project in
            var matches = project.title?.lowercased().contains(query.lowercased())
            for section in project.projectSections {
                if section.sectionTitle.lowercased().contains(query.lowercased()) {
                    matches = true
                    break
                }
            }
            return matches!
        }
    }
    
    func sections(for project: Project) -> [HeaderSection] {
        project.projectSectionsSorted
    }
    
    func reloadItemsInSection(section: HeaderSection) {
        var newSnapshot = dataSource.snapshot()
        newSnapshot.reloadSections(projects)
        newSnapshot.reloadItems([.section(section)])
        dataSource.apply(newSnapshot)
    }
    
    func reloadSections() {
        var newSnapshot = dataSource.snapshot()
        newSnapshot.reloadSections(projects)
        dataSource.apply(newSnapshot)
    }
    
    
    /// Setup the `NSFetchedResultsController`, which manages the data shown in our table view
    func setupFetchedResultsController() {
           let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
           
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Project.userOrder, ascending: true)]
           
           dataProvider.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                       managedObjectContext: dataProvider.persistentContainer.viewContext,
                                                       sectionNameKeyPath: nil, cacheName: nil)
           dataProvider.fetchedResultsController.delegate = self
           
                    
           do {
               try dataProvider.fetchedResultsController.performFetch()

               projects = dataProvider.fetchedResultsController.fetchedObjects ?? []
           } catch {
               print("Fetch failed")
           }
       }
    
    func addProject() {
        var userOrder: Int16 = 0
        if projects.count > 0 {
            userOrder = projects.last!.userOrder + 25
        } else {
            userOrder = 100
        }
        let project = Project(context: dataProvider.persistentContainer.viewContext)
        project.title = "New Project"
        project.creationDate = Date()
        project.uuid = UUID()
        project.userOrder = userOrder
        
        let section = HeaderSection(context: dataProvider.persistentContainer.viewContext)
        section.title = "New Section"
        section.creationDate = Date()
        section.project = project
        section.uuid = UUID()
        section.userOrder = 100
                
        let todoHeader = ToDoHeader(context: dataProvider.persistentContainer.viewContext)
        todoHeader.title = "General"
        todoHeader.section = section
        todoHeader.creationDate = Date()
        todoHeader.id = UUID()
        todoHeader.userOrder = 100
        
        try? dataProvider.persistentContainer.viewContext.save()
        
        var sectionSnapshot2 = NSDiffableDataSourceSectionSnapshot<ExpandableListItem>()
        
                dataSourceSnapshot.appendSections([project])
        
                // Create a header ListItem & append as parent
                let headerListItem = ExpandableListItem.header(project)
                sectionSnapshot2.append([headerListItem])
        
                // Create an array of sectionListItem & append as child of headerListItem
                let sectionListItemArray = ExpandableListItem.section(section)
                sectionSnapshot2.append([sectionListItemArray], to: headerListItem)
        
                // Expand this section by default
                sectionSnapshot2.expand([headerListItem])
        
                // Apply section snapshot to the respective collection view section
                dataSource.apply(sectionSnapshot2, to: project, animatingDifferences: true)
    }
    
    func updateCollectionViewList() {
        let userDefaults = UserDefaults.standard
        let sortOrder = userDefaults.string(forKey: Constants.sortedSection)
        
        // reload the entire collection view list so when a drag/drop operation occurs the app does not crash
        // Loop through each header item so that we can create a section snapshot for each respective header item.
        for headerItem in projects {
            // Create a section
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ExpandableListItem>()
            
            // Create a header ListItem & append as parent
            let headerListItem = ExpandableListItem.header(headerItem)
            sectionSnapshot.append([headerListItem])
            
            if sortOrder == HeaderSection.SortOrder.title.rawValue {
                for section in sections(for: headerItem).sorted(by: \HeaderSection.userOrder) {
                    sectionSnapshot.append([ExpandableListItem.section(section)], to: headerListItem)
                }
            } else {
                for section in sections(for: headerItem).sorted(by: \HeaderSection.userOrder) {
                    sectionSnapshot.append([ExpandableListItem.section(section)], to: headerListItem)
                }
            }
            
            // Expand this section by default
            sectionSnapshot.expand([headerListItem])
            
            // Apply section snapshot to the respective collection view section
            dataSource.apply(sectionSnapshot, to: headerItem, animatingDifferences: true)
        }
    }
}

extension ProjectViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupFetchedResultsController()
        updateCollectionViewList()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith diff: CollectionDifference<NSManagedObjectID>) {
        setupFetchedResultsController()
        updateCollectionViewList()
    }
}
