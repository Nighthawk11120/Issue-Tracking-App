////
////  ProjectsProvider.swift
////  IssueTrackingApp
////
////  Created by Scott Bauer on 6/25/21.
////
//
//import UIKit
//import CoreData
//
//class ProjectsProvider: NSObject {
//    fileprivate let fetchedResultsController: NSFetchedResultsController<Project>
//    
//    @Published var snapshot: NSDiffableDataSourceSnapshot<Project, ExpandableListItem>?
//    @Published var sectionSnapshot: NSDiffableDataSourceSectionSnapshot<ExpandableListItem>?
//    
//    init(storageProvider: StorageProvider) {
//        let request: NSFetchRequest<Project> = Project.fetchRequest()
//        request.sortDescriptors = [NSSortDescriptor(keyPath: \Project.creationDate, ascending: false)]
//        
//        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: storageProvider.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
//        
//        super.init()
//        
//        fetchedResultsController.delegate = self
//        try! fetchedResultsController.performFetch()
//        
//        func sections(for project: Project) -> [HeaderSection] {
//            project.projectSections.sorted(by: \HeaderSection.sectionCreationDate)
//        }
//        
//        let projects = fetchedResultsController.fetchedObjects
//        print("projects count = \(projects!.count)")
//        
//        var snapshot = NSDiffableDataSourceSnapshot<Project, ExpandableListItem>()
//        for headerItem in projects! {
//            
//            snapshot.appendSections([headerItem])
//            
//            // Create an array of sectionListItem & append as child of headerListItem
//            for section in sections(for: headerItem) {
//                snapshot.appendItems([ExpandableListItem.section(section)], toSection: headerItem)
//            }
//            
//            // MARK: -> Apply section snapshot to the respective collection view section
////            dataSource.apply(sectionSnapshot, to: headerItem, animatingDifferences: false)
////            self.sectionSnapshot = sectionSnapshot
//            self.snapshot = snapshot
//        }
//    }
//    
//    func object(at indexPath: IndexPath) -> Project {
//        return fetchedResultsController.object(at: indexPath)
//    }
//    
//    //    func section(at indexPath: IndexPath, project: Project) -> Section {
//    //        return project.projectSections.first { section in
//    //            section.objectID == project.sections.ob
//    //        }
//    //    }
//}
//
//extension ProjectsProvider: NSFetchedResultsControllerDelegate {
//    
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        // recompute the snapshot
////        var newSnapshot = snapshot! as NSDiffableDataSourceSnapshot<Project, ExpandableListItem>
//        
//    }
//    
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        // find out what objects have been inserted, updated, or deleted
//        // tell the new snapshot to reload items
//        
////        switch type {
////        case .insert:
////            if let indexPath = newIndexPath {
////                if let section = anObject as? Section {
////                    var newSnapshot = DataSource()
////                    newSnapshot.appendItems([.section(section)], toSection: section.project)
////                    snapshot = newSnapshot
////                }
////                if let project = anObject as? Project {
////                    var newSnapshot = DataSource()
////                    newSnapshot.appendSections([project])
////                    snapshot = newSnapshot
////                }
////            }
////        case .delete:
////            if let section = anObject as? Section {
////                var newSnapshot = DataSource()
////                newSnapshot.deleteItems([.section(section)])
////                snapshot = newSnapshot
////            }
////            if let project = anObject as? Project {
////                var newSnapshot = DataSource()
////                newSnapshot.deleteSections([project])
////                snapshot = newSnapshot
////            }
////        case .move:
////            if let section = anObject as? Section {
////                var newSnapshot = DataSource()
////                newSnapshot.reloadItems([.section(section)])
////                snapshot = newSnapshot
////            }
////            if let project = anObject as? Project {
////                var newSnapshot = DataSource()
////                newSnapshot.reloadSections([project])
////                snapshot = newSnapshot
////            }
////        case .update:
////            if let section = anObject as? Section {
////                var newSnapshot = DataSource()
////                newSnapshot.reloadItems([.section(section)])
////                snapshot = newSnapshot
////            }
////            if let project = anObject as? Project {
////                var newSnapshot = DataSource()
////                newSnapshot.reloadSections([project])
////                snapshot = newSnapshot
////            }
////        }
//    }
//    
////    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
////        var newSnapshot = snapshot as NSDiffableDataSourceSnapshot<Project, ExpandableListItem>
////
////        var isSection = false
////        let reloadIdentifiers = newSnapshot.itemIdentifiers.filter { listItem in
////            switch listItem {
////            case .header(let project):
////                guard let oldIndex = self.snapshot?.indexOfSection(project),
////                      let newIndex = newSnapshot.indexOfSection(project),
////                      oldIndex == newIndex else {
////                  return false
////                }
////
////                // check if we need to update this object
////                guard (try? controller.managedObjectContext.existingObject(with: project.objectID))?.isUpdated == true else {
////                  return false
////                }
////                isSection = true
////            case .section(let section):
////                guard let oldIndex = self.snapshot?.indexOfItem(.section(section)),
////                      let newIndex = newSnapshot.indexOfItem(.section(section)),
////                      oldIndex == newIndex else {
////                  return false
////                }
////
////                // check if we need to update this object
////                guard (try? controller.managedObjectContext.existingObject(with: section.objectID))?.isUpdated == true else {
////                  return false
////                }
////            }
////            return true
////        }
////
////        if isSection {
////            for listItem in reloadIdentifiers {
////                switch listItem {
////                case .header(let header):
////                    newSnapshot.reloadSections([header])
////                case .section(_):
////                    print("")
////                }
////            }
////            isSection = false
////        } else {
////            newSnapshot.reloadItems(reloadIdentifiers)
////
////        }
////
////        self.snapshot = newSnapshot
////    }
//}
//
//
//
//
//
//
//
////extension ProjectViewController {
////    func makeDataSource() -> UICollectionViewDiffableDataSource<Project, ExpandableListItem> {
//////      let cellRegistration =
//////        UICollectionView.CellRegistration<UICollectionViewListCell, ExpandableListItem> { [weak self] cell, indexPath, projectId in
//////          guard let project = self?.projectsProvider.object(at: indexPath) else {
//////            return
//////          }
//////
//////          var config = cell.defaultContentConfiguration()
//////          config.text = project.title
//////          cell.contentConfiguration = config
//////      }
////
////
////        let projectHeaderCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Project> { [weak self] (cell, indexPath, headerItem) in
////
//////            guard let project = self?.projectsProvider.object(at: indexPath) else {
//////                return
//////            }
////
////            // Set headerItem's data to cell
////            var content = cell.defaultContentConfiguration()
////            content.text = headerItem.title
////            cell.contentConfiguration = content
////
////            // Add outline disclosure accessory
////            // With this accessory, the header cell's children will expand / collapse when the header cell is tapped.
////            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
////            cell.accessories = [.outlineDisclosure(options: headerDisclosureOption), .delete(), .reorder(), .insert(displayed: .always, options: .init(isHidden: false, reservedLayoutWidth: .standard, tintColor: .white, backgroundColor: .green), actionHandler: {
////
////                let managedObjectContext = self?.storageProvider.persistentContainer.viewContext
////                let section = Section(context: managedObjectContext!)
////                section.title = "Created Section"
////                section.creationDate = Date()
////                section.project = headerItem
////                try? managedObjectContext?.save()
////
////                headerItem.title = "Updated Project"
////                var newSnapshot = self?.dataSource.snapshot()
////                newSnapshot!.reconfigureItems([ExpandableListItem.header(headerItem)])
////                self?.dataSource.apply(newSnapshot!)
////
////            })]
////        }
////
////        let sectionCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Section> { [weak self] (cell, indexPath, section) in
////
//////            guard let sectionItem = self?.projectsProvider.object(at: indexPath) else {
//////                return
//////            }
////
////            // Set sections's data to cell
////            var content = cell.defaultContentConfiguration()
////            content.text = section.title
////            cell.contentConfiguration = content
////            cell.indentationLevel = 2
////            cell.accessories = [.delete(), .reorder()]
////
////        }
////
////      return UICollectionViewDiffableDataSource<Project, ExpandableListItem>(
////        collectionView: collectionView, cellProvider: { collectionView, indexPath, listItem in
////
////          switch listItem {
////          case .header(let projectHeader):
////              // Dequeue header cell
////              let cell = collectionView.dequeueConfiguredReusableCell(using: projectHeaderCellRegistration,
////                                                                      for: indexPath,
////                                                                      item: projectHeader)
////              return cell
////
////          case .section(let section):
////              // Dequeue section cell
////              let cell = collectionView.dequeueConfiguredReusableCell(using: sectionCellRegistration,
////                                                                      for: indexPath,
////                                                                      item: section)
////
////              return cell
////          }
////
////        })
////    }
////}
