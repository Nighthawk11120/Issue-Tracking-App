//
//  SectionDetailViewContextMenuDelegate.swift
//  SectionDetailViewContextMenuDelegate
//
//  Created by Scott Bauer on 9/12/21.
//

import UIKit

extension SectionDetailViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let locationInCollectionView = interaction.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: locationInCollectionView) else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { actions in
            if let selectedItem = self.dataSource.itemIdentifier(for: indexPath) {
                switch selectedItem {
                case .header(let header):
                    print("context menu is for a header")

                    let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis"), identifier: nil) { action in
                        
                        let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
                        var content = cell.defaultContentConfiguration()
                        content.text = ""
                        
                        cell.contentConfiguration = content
                        self.textField = UITextField(frame: cell.bounds)
                        self.textField.text = header.title
                        self.textField.translatesAutoresizingMaskIntoConstraints = false
                        self.textField.isEnabled = true
                        self.textField.becomeFirstResponder()
                        self.textField.delegate = self
                        self.textField.placeholder = "Section Name"
                        self.textField.borderStyle = UITextField.BorderStyle.roundedRect
                        self.textField.returnKeyType = UIReturnKeyType.done
                        self.textField.clearButtonMode = UITextField.ViewMode.whileEditing
                        self.textField.backgroundColor = .white
                        self.textFieldHeader = header
                        cell.contentView.addSubview(self.textField)
                        self.cellToChangeIndexPath = indexPath
                        self.collectionView.deselectItem(at: indexPath, animated: true)
                        
                        header.objectWillChange.send()
                    }
                    
                    let deleteAction = UIAction(title: "Delete Task Header", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
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
                    
                    
                    return UIMenu(title: "", children: [renameAction, deleteAction])
                    
                case .task(let section):
                    let renameAction =
                    UIAction(title: NSLocalizedString("Change Name", comment: ""),
                                 image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis")) { action in

                        let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
                        var content = cell.defaultContentConfiguration()
                        content.text = ""
                        
                        cell.contentConfiguration = content
                        self.textField = UITextField(frame: cell.bounds)
                        self.textField.text = section.title
                        self.textField.translatesAutoresizingMaskIntoConstraints = false
                        self.textField.isEnabled = true
                        self.textField.becomeFirstResponder()
                        self.textField.delegate = self
                        self.textField.placeholder = "Section Name"
                        self.textField.borderStyle = UITextField.BorderStyle.roundedRect
                        self.textField.returnKeyType = UIReturnKeyType.done
                        self.textField.clearButtonMode = UITextField.ViewMode.whileEditing
                        self.textField.backgroundColor = .white
                        self.textFieldTask = section
                        cell.contentView.addSubview(self.textField)
                        self.cellToChangeIndexPath = indexPath
                        self.collectionView.deselectItem(at: indexPath, animated: true)
                        
                        section.objectWillChange.send()
                        }
                    
                    let deleteAction =
                        UIAction(title: NSLocalizedString("Delete Section", comment: ""),
                                 image: UIImage(systemName: "trash"),
                                 attributes: .destructive) { action in
                            var snapShot = self.dataSource.snapshot()
                            
                            snapShot.deleteItems([.task(section)])
                            self.dataSource.apply(snapShot)
                            
                            self.storageProvider.persistentContainer.viewContext.delete(section)
                            try? self.storageProvider.persistentContainer.viewContext.save()
                            NotificationCenter.default.post(name: .DidUpdateTaskCell, object: nil)

                        }
                    return UIMenu(title: "", children: [renameAction, deleteAction])
                }
            } else {
                return UIMenu()
            }
            
        }
    }
}
