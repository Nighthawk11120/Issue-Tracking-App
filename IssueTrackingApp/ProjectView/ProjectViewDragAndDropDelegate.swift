//
//  ProjectViewDragAndDropDelegate.swift
//  ProjectViewDragAndDropDelegate
//
//  Created by Scott Bauer on 8/6/21.
//

import UIKit
import SwiftUI

extension ProjectViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(item: row, section: section)
        }

        coordinator.session.loadObjects(ofClass: DataTypeDragItem.self) { items in
            if let sections = items as? [DataTypeDragItem] {
                var backupSection: HeaderSection? = nil
                
                for (_, item) in sections.enumerated() {
                    
                    DispatchQueue.main.async {
                        if item.type == DataType.group.rawValue {
                            self.reorderTaskHeaders(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
                            
                        } else if item.type == DataType.section.rawValue {
                            self.reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)

                        } else if item.type == DataType.todo.rawValue {
                            DispatchQueue.main.async {
                                do {
                                    let managedObjectID = self.viewModel.dataProvider.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: URL(string: item.id!)!)
                                    let task = try self.viewModel.dataProvider.persistentContainer.viewContext.existingObject(with: managedObjectID!) as? ToDo
                                    let indexPath = IndexPath(item: destinationIndexPath.item, section: destinationIndexPath.section)
                                    
                                    let sec = self.viewModel.dataSource.itemIdentifier(for: indexPath)
                                    
                                    switch sec {
                                    case .header(_):
                                        print("header")
                                    case .section(let section):
                                        backupSection = section
                                    case .none:
                                        print("none")
                                    }
                                    
                                    task?.header = backupSection?.sectionTasksDefaultSorted.first
                                                                        
                                    try? self.viewModel.dataProvider.persistentContainer.viewContext.save()
                                    
                                    if UIDevice.current.userInterfaceIdiom != .phone {
                                        if let backupSection = backupSection {
                                            let sheetViewController = SectionDetailViewController(section: backupSection, storageProvider: self.viewModel.dataProvider)
                                            sheetViewController?.title = "\(backupSection.title ?? "Section")"
                                            self.splitViewController?.setViewController(UINavigationController(rootViewController: sheetViewController!), for: .secondary)
                                            
                                            collectionView.selectItem(at: destinationIndexPath, animated: true, scrollPosition: [])
                                        }
                                    }
                                    
                                    if let backupSection = backupSection {
                                        self.showDropPopup(view: self.view, numberOfItems: sections.count, movedItemsTo: backupSection.sectionTitle)
                                    }
                                                                        
                                } catch {
                                    print("failed to drop the task into its new section destination")
                                }
                                
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath {
            var destIndexPath = destinationIndexPath
            if destIndexPath.item >= collectionView.numberOfItems(inSection: destIndexPath.section) {
                destIndexPath.item = collectionView.numberOfItems(inSection: destIndexPath.section) - 1
            }
            guard let fromTask = viewModel.dataSource.itemIdentifier(for: sourceIndexPath),
                             sourceIndexPath != destIndexPath else { return }

            var snap = viewModel.dataSource.snapshot()
            var header = viewModel.dataSource.sectionIdentifier(for: destIndexPath.section)!

            let sourceHeader = viewModel.dataSource.sectionIdentifier(for: sourceIndexPath.section)!
            print("header order = \(header.userOrder)")

            var changeHeader = false
            
            var sectionTasksCopy = viewModel.projects[destIndexPath.section].projectSectionsSorted

                       switch fromTask {
                       case .header(_):
                           print("cannot reorder headers 2")
                       case .section(let fromTodo):
                           snap.deleteItems([.section(fromTodo)])

                           if let toTask = viewModel.dataSource.itemIdentifier(for: destIndexPath) {
                               switch toTask {
                               case .header(let fromHeader):

                                   // if there are no items in the header when trying to add a new one to it
                                   if fromHeader.projectSectionsSorted.isEmpty {

                                           snap.appendItems([.section(fromTodo)], toSection: fromHeader)
                                       changeHeader = true

                                       fromTodo.project = fromHeader

                                       for item in sectionTasksCopy {
                                           let sortIndex = sectionTasksCopy.firstIndex(of: item)!
                                           item.userOrder = Int16(sortIndex)
                                       }

                                       try? AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer.viewContext.save()
                                       viewModel.dataSource.apply(snap, animatingDifferences: false)

                                       for header in viewModel.projects {
                                           var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<ExpandableListItem>()
                                           let headerItem = ExpandableListItem.header(header)
                                           dataSourceSnapshot.append([headerItem])

                                           for task in header.projectSectionsSorted {
                                               dataSourceSnapshot.append([.section(task)], to: headerItem)
                                           }

                                           dataSourceSnapshot.expand([headerItem])

                                           viewModel.dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
                                       }
                                       
                                       NotificationCenter.default.post(name: .SectionInProjectDragDropUpdated, object: nil)

                                       return
                                   } else {
                                       header = viewModel.dataSource.sectionIdentifier(for: destIndexPath.section - 1)!

                                       snap.appendItems([.section(fromTodo)], toSection: header)
                                       changeHeader = true
                                       viewModel.dataSource.apply(snap, animatingDifferences: false)
                                   }

                               case .section(let toTodo):
                                   
                                   if header == sourceHeader {
                                       sectionTasksCopy.removeAll {$0.id == fromTodo.id}

                                       sectionTasksCopy.insert(fromTodo, at: destIndexPath.item - 1)
                                   } else if header != sourceHeader && header.projectSectionsSorted.count == (destIndexPath.item + 1) {
                                       sectionTasksCopy.insert(fromTodo, at: destIndexPath.item - 1)
                                   } else {
                                       
                                       if let indexPath = coordinator.destinationIndexPath {
                                           destIndexPath = indexPath
                                       } else {
                                           let row = collectionView.numberOfItems(inSection: 0)
                                           destIndexPath = IndexPath(item: row - 1, section: 0)
                                       }

                                       var originalHeader = viewModel.projects[startingIndexPath.section].projectSectionsSorted
                                       let originalTask = originalHeader.remove(at: max(0, startingIndexPath.row - 1))
                                       sectionTasksCopy.insert(originalTask, at: min(destIndexPath.item - 1, header.projectSectionsSorted.count))
                                   }
                                   
                                   let isAfter = destIndexPath.item > sourceIndexPath.item
                                   if isAfter {
                                       snap.insertItems([.section(fromTodo)], afterItem: .section(toTodo))
                                   } else {
                                       snap.insertItems([.section(fromTodo)], beforeItem: .section(toTodo))
                                   }
                               }
                           } else {
                               if let lastTask = header.projectSectionsSorted.last {
                                   snap.insertItems([.section(fromTodo)], afterItem: .section(lastTask))
                               } else {
                                   snap.appendItems([.section(fromTodo)], toSection: header)
                               }
                               
                           }
                       }
            
            if header != sourceHeader || changeHeader {
                if changeHeader {

                    for item in viewModel.dataSource.snapshot().itemIdentifiers(inSection: header) {
                        let sortIndex = viewModel.dataSource.snapshot().itemIdentifiers(inSection: header).firstIndex(of: item)!

                        switch item {
                        case .section(let child):
                            child.project = header
                            child.userOrder = Int16(sortIndex + 10)
                        case .header(_):
                            guard case let .section(childItem) = fromTask else { return }
                            childItem.project = header
                            childItem.userOrder = Int16(sortIndex + 10)
                        }
                    }

                    // reorder the items in the source section
                    let header = viewModel.projects[startingIndexPath.section]
                let items = header.projectSectionsSorted

                    for item in viewModel.projects[startingIndexPath.section].projectSectionsSorted {
                    let sortIndex = items.firstIndex(of: item)!
                    item.userOrder = Int16(sortIndex + 10)
                }
                    
                } else {
                    sectionTasksCopy[destIndexPath.item - 1].project = header
                    // reorder the items in the destination section
                    for item in sectionTasksCopy {
                        let sortIndex = sectionTasksCopy.firstIndex(of: item)!
                        item.userOrder = Int16(sortIndex + 10)
                    }

                    // reorder the items in the source section
                    let header = viewModel.projects[startingIndexPath.section]
                    let items = header.projectSectionsSorted

                    for item in viewModel.projects[startingIndexPath.section].projectSectionsSorted {
                    let sortIndex = items.firstIndex(of: item)!
                    item.userOrder = Int16(sortIndex + 10)
                }
                }
            } else {
                for item in sectionTasksCopy {
                    let sortIndex = sectionTasksCopy.firstIndex(of: item)!
                    item.userOrder = Int16(sortIndex + 10)
                }
            }

            try? AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer.viewContext.save()

            for header in viewModel.projects {
                var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<ExpandableListItem>()
                let headerItem = ExpandableListItem.header(header)
                dataSourceSnapshot.append([headerItem])

                for task in header.projectSectionsSorted {
                    dataSourceSnapshot.append([.section(task)], to: headerItem)
                }

                dataSourceSnapshot.expand([headerItem])

                viewModel.dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: true)
            }
        }
        NotificationCenter.default.post(name: .SectionInProjectDragDropUpdated, object: nil)
    }
    
    private func reorderTaskHeaders(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath {
            var destIndexPath = destinationIndexPath
            if destIndexPath.row >= collectionView.numberOfItems(inSection: destIndexPath.section) {
                destIndexPath.row = collectionView.numberOfItems(inSection: destIndexPath.section) - 1
            }
            
            guard let fromGroup = viewModel.dataSource.sectionIdentifier(for: sourceIndexPath.section), sourceIndexPath != destinationIndexPath else { return }
            
            var snap = viewModel.dataSource.snapshot()
            let snapshot = NSDiffableDataSourceSectionSnapshot<ExpandableListItem>()
            
            snap.deleteSections([fromGroup])
            for i in fromGroup.projectSectionsSorted {
                snap.deleteItems([.section(i)])
            }
            viewModel.dataSource.apply(snapshot, to: fromGroup)
            
            var groupsCopy = viewModel.projects.sorted { $0.userOrder < $1.userOrder }
            
            if let toTodo = viewModel.dataSource.sectionIdentifier(for: destinationIndexPath.section) {
                let isAfter = destinationIndexPath.section > sourceIndexPath.section
                
                groupsCopy.removeAll {$0.id == fromGroup.id}
                groupsCopy.insert(fromGroup, at: destinationIndexPath.section)
                
                if isAfter {
                    snap.insertSections([fromGroup], afterSection: toTodo)
                } else {
                    snap.insertSections([fromGroup], beforeSection: toTodo)
                }
            } else {
                groupsCopy.removeAll {$0.id == fromGroup.id}
                groupsCopy.insert(fromGroup, at: destIndexPath.section)
                
                snap.appendSections([fromGroup])
            }
            
            for item in groupsCopy {
                let sortIndex = groupsCopy.firstIndex(of: item)!
                item.userOrder = Int16(sortIndex + 10)
            }
                   
            try? AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer.viewContext.save()
            
            NotificationCenter.default.post(name: .SectionInProjectDragDropUpdated, object: nil)
        }
    }
    
    // Only accept drop if row is a Project
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        

        for item in session.items {
            guard item.localObject as? String == "task" else {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
            return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
            
        }

        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    
        guard let item = viewModel.dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return [UIDragItem]()
        }
        
        collectionView.deselectItem(at: indexPath, animated: false)
        
        func getDragItem() -> [UIDragItem] {
            switch item {
            case .section(let section):
                let itemProvider = NSItemProvider(object: DataTypeDragItem(id: section.objectID.uriRepresentation().absoluteString, type: DataType.section.rawValue))
                
                let dragItem = UIDragItem(itemProvider: itemProvider)
                
                guard let cell = collectionView.cellForItem(at: indexPath) else { return [dragItem] }
                let cellInsetContents = cell.contentView.bounds.insetBy(dx: 2.0, dy: 2.0)
                
                startingIndexPath = indexPath

                // Drag preview
                dragItem.previewProvider = {
                    let dragPreviewPrams = UIDragPreviewParameters()
                    dragPreviewPrams.visiblePath = UIBezierPath(roundedRect: cellInsetContents, cornerRadius: 8.0)
                    dragPreviewPrams.backgroundColor = UIColor.systemGroupedBackground
                    
                    dragItem.localObject = "section"
                    
                    return UIDragPreview(view: cell.contentView, parameters: dragPreviewPrams)
                }
                
                return [dragItem]
            case .header(let header):
                let itemProvider = NSItemProvider(object: DataTypeDragItem(id: header.objectID.uriRepresentation().absoluteString, type: DataType.group.rawValue))
                
                if let sec = viewModel.dataSource.sectionIdentifier(for: indexPath.section) {
                    for header in viewModel.projects {
                        var dataSourceSnapshot = NSDiffableDataSourceSectionSnapshot<ExpandableListItem>()
                        let headerItem = ExpandableListItem.header(header)
                        dataSourceSnapshot.append([headerItem])
                        for task in header.projectSectionsSorted {
                            dataSourceSnapshot.append([.section(task)], to: headerItem)
                        }
                        dataSourceSnapshot.expand([.header(header)])
                        dataSourceSnapshot.collapse([.header(sec)])
                        viewModel.dataSource.apply(dataSourceSnapshot, to: header, animatingDifferences: false)
                    }
                }
                
                let dragItem = UIDragItem(itemProvider: itemProvider)
                dragItem.localObject = "header"
                return [dragItem]
            }
        }
        
        return getDragItem()
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        
        collectionView.deselectItem(at: indexPath, animated: false)
        
        guard let item = viewModel.dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return [UIDragItem]()
        }
        
        func getDragItem() -> [UIDragItem] {
            switch item {
            case .section(let section):
                let itemProvider = NSItemProvider(object: DataTypeDragItem(id: section.objectID.uriRepresentation().absoluteString, type: DataType.section.rawValue))
                let dragItem = UIDragItem(itemProvider: itemProvider)
                
                guard let cell = collectionView.cellForItem(at: indexPath) else { return [dragItem] }
                let cellInsetContents = cell.contentView.bounds.insetBy(dx: 2.0, dy: 2.0)
                
                // Drag preview
                dragItem.previewProvider = {
                    let dragPreviewPrams = UIDragPreviewParameters()
                    dragPreviewPrams.visiblePath = UIBezierPath(roundedRect: cellInsetContents, cornerRadius: 8.0)
                    dragItem.localObject = "section"

                    
                    return UIDragPreview(view: cell.contentView, parameters: dragPreviewPrams)
                }
                
                return [dragItem]
            case .header(_):
                return [UIDragItem]()
            }
        }
        
        return getDragItem()
    }
}

extension UIViewController {
    func showDropPopup(view: UIView, numberOfItems: Int, movedItemsTo: String) {
        let window = UIApplication.shared.windows.first(where: \.isKeyWindow)
        if UIDevice.current.userInterfaceIdiom == .phone {
            
            let popupView = UIView(frame: CGRect(x: 0, y: -80, width: (window?.frame.size.width ?? 100), height: 75.0))
            popupView.backgroundColor = view.traitCollection.userInterfaceStyle == .dark ? UIColor.gray : UIColor.white
            popupView.layer.cornerRadius = 20
            popupView.frame = popupView.frame.insetBy(dx: 12, dy: 12)
            let label = UILabel(frame: popupView.bounds)
            label.bounds = label.bounds.insetBy(dx: 10, dy: 10)
            label.textColor = .label
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.9
            label.text = "You moved \(numberOfItems) items to \(movedItemsTo)"
            popupView.addSubview(label)
            
            UIView.transition(with: popupView, duration: 1.5, options: .curveEaseInOut, animations: {
                window?.addSubview(popupView)
                popupView.center.y += 130
            }, completion: { _ in
                UIView.animate(withDuration: 1, delay: 0.5, options: .curveEaseInOut) {
                    popupView.center.y -= 130
                } completion: { finished in
                    print("completed animation")
                    // remember to remove the popup when you're done!
                    popupView.removeFromSuperview()
                }
            })
        } else {
            let popupView = UIView(frame: CGRect(x: 0, y: -80, width: 325, height: 75.0))
            popupView.backgroundColor = view.traitCollection.userInterfaceStyle == .dark ? UIColor.gray : UIColor.white
            popupView.layer.cornerRadius = 20
            popupView.frame = popupView.frame.insetBy(dx: 12, dy: 12)
            let label = UILabel(frame: popupView.bounds)
            label.bounds = label.bounds.insetBy(dx: 10, dy: 10)
            label.textColor = .label
            label.text = "You moved \(numberOfItems) items to \(movedItemsTo)"
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.85
            popupView.addSubview(label)
            
            UIView.transition(with: popupView, duration: 1.5, options: .curveEaseInOut, animations: {
                window?.addSubview(popupView)
                popupView.center.y += 130
            }, completion: { _ in
                UIView.animate(withDuration: 1, delay: 0.5, options: .curveEaseInOut) {
                    popupView.center.y -= 130
                } completion: { finished in
                    print("completed animation")
                    // remember to remove the popup when you're done!
                    popupView.removeFromSuperview()
                }
            })
        }
    }
}
