//
//  ProjectContextMenuInteractionDelegate.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 7/31/21.
//

import UIKit
import CloudKit

extension ProjectViewController: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let locationInTableView =
        interaction.location(in: collectionView)
        guard let indexPath = collectionView
                .indexPathForItem(at: locationInTableView)
        else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
            suggestedActions in
            self.viewModel.shouldReloadSearchResults = false
            self.viewModel.searchController.dismiss(animated: true, completion: nil)
            self.viewModel.shouldReloadSearchResults = true
            
            print("cancel the search")
            
            if let listSection = self.viewModel.dataSource.itemIdentifier(for: indexPath) {
                switch listSection {
                    
                case .header(let project):
                    let renameAction =
                    UIAction(title: NSLocalizedString("Change Name", comment: ""),
                             image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis")) { action in
                        
                        let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
                        var content = cell.defaultContentConfiguration()
                        content.text = ""
                        
                        cell.contentConfiguration = content
                        self.projectEditTextField = UITextField(frame: cell.bounds)
                        self.projectEditTextField.text = project.title
                        self.projectEditTextField.translatesAutoresizingMaskIntoConstraints = false
                        self.projectEditTextField.isEnabled = true
                        self.projectEditTextField.becomeFirstResponder()
                        self.projectEditTextField.delegate = self
                        self.projectEditTextField.placeholder = "Section Name"
                        self.projectEditTextField.borderStyle = UITextField.BorderStyle.roundedRect
                        self.projectEditTextField.returnKeyType = UIReturnKeyType.done
                        self.projectEditTextField.clearButtonMode = UITextField.ViewMode.whileEditing
                        self.projectEditTextField.backgroundColor = .white
                        self.viewModel.textFieldProject = project
                        cell.contentView.addSubview(self.projectEditTextField)
                        self.viewModel.cellToChangeIndexPath = indexPath
                        self.collectionView.deselectItem(at: indexPath, animated: true)
                        
                        project.objectWillChange.send()
                    }
                    
                    let deleteAction =
                    UIAction(title: NSLocalizedString("Delete Project", comment: ""),
                             image: UIImage(systemName: "trash"),
                             attributes: .destructive) { action in
                        
                        let ac = UIAlertController(title: "Are you sure you want to delete this project", message: "It will also delete all associated sections", preferredStyle: .alert)
                        
                        ac.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                            var snapshot = self.viewModel.dataSource.snapshot()
                            snapshot.deleteSections([project])
                            for section in project.projectSections {
                                snapshot.deleteItems([.section(section)])
                            }
                            self.viewModel.dataSource.apply(snapshot)
                            
                            self.viewModel.dataProvider.persistentContainer.viewContext.delete(project)
                            try? self.viewModel.dataProvider.persistentContainer.viewContext.save()
                            NotificationCenter.default.post(name: .SectionInProjectDragDropUpdated, object: nil)
                            
                        }))
                        
                        ac.addAction(UIAlertAction(title: "Cancel", style: .default))
                        
                        self.present(ac, animated: true)
                    }
                    
                    return UIMenu(title: "", children: [deleteAction, renameAction])
                case .section(let section):
                    
                    let renameAction =
                    UIAction(title: NSLocalizedString("Change Name", comment: ""),
                             image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis")) { action in
                        
                        let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
                        var content = cell.defaultContentConfiguration()
                        content.text = ""
                        
                        cell.contentConfiguration = content
                        self.projectEditTextField = UITextField(frame: cell.bounds)
                        self.projectEditTextField.text = section.title
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
                        
                        section.objectWillChange.send()
                    }
                    
                    let openInNewWindowAction = UIAction(title: "Open in New Window", image: UIImage(systemName: "uiwindow.split.2x1"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { action in
                        
                        var openDetailUserActivity: NSUserActivity {
                            let userActivity = NSUserActivity(activityType: HeaderSection.OpenDetailActivityType)
                            userActivity.userInfo = [HeaderSection.OpenDetailIdKey: section.id]
                            return userActivity
                        }
                        
                        AppDelegate.sectionToOpenInNewWindow = section
                        let activity = NSUserActivity(activityType: self.VCActivityType)
                        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
                    }
                    
                    let addTaskAction =
                    UIAction(title: NSLocalizedString("Add Task", comment: ""),
                             image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis")) { action in
                        
                        let task = ToDoHeader(context: self.viewModel.dataProvider.persistentContainer.viewContext)
                        task.title = "New Task 2"
                        task.section = section
                        task.id = UUID()
                        try? self.viewModel.dataProvider.persistentContainer.viewContext.save()
                    }
                    
                    let deleteAction =
                    UIAction(title: NSLocalizedString("Delete Section", comment: ""),
                             image: UIImage(systemName: "trash"),
                             attributes: .destructive) { action in
                        var snapShot = self.viewModel.dataSource.snapshot()
                        
                        snapShot.deleteItems([.section(section)])
                        self.viewModel.dataSource.apply(snapShot)
                        
                        self.viewModel.dataProvider.persistentContainer.viewContext.delete(section)
                        try? self.viewModel.dataProvider.persistentContainer.viewContext.save()
                        NotificationCenter.default.post(name: .SectionsUpdated, object: nil)
                    }
                    return UIMenu(title: "", children: [renameAction, deleteAction, addTaskAction, openInNewWindowAction])
                }
                
            } else {
                let deleteAction =
                UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                         image: UIImage(systemName: "trash"),
                         attributes: .destructive) { action in
                }
                
                return UIMenu(title: "", children: [deleteAction])
            }
        })
    }
}

