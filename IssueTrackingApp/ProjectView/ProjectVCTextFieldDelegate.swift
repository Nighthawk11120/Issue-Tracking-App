//
//  ProjectVCTextFieldDelegate.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 7/31/21.
//

import UIKit

extension ProjectViewController: UITextFieldDelegate {
        
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.isEnabled = false
        if let textFieldSection = viewModel.textFieldSection {
            textFieldSection.title = textField.text
            try? viewModel.dataProvider.persistentContainer.viewContext.save()
            NotificationCenter.default.post(name: .ProjectsUpdated, object: nil)
        }
        
        if let textFieldProject = viewModel.textFieldProject {
            textFieldProject.objectWillChange.send()
            textFieldProject.title = textField.text
            try? viewModel.dataProvider.persistentContainer.viewContext.save()
            NotificationCenter.default.post(name: .ProjectsUpdated, object: nil)
        }
        
        if UIDevice.current.userInterfaceIdiom != .phone {
            NotificationCenter.default.post(name: .SectionsUpdated, object: nil)

            if let textFieldSection = self.viewModel.textFieldSection {
                let sheetViewController = SectionDetailViewController(section: textFieldSection, storageProvider: self.viewModel.dataProvider)
                sheetViewController?.title = "\(textFieldSection.title ?? "Section")"
                self.splitViewController?.setViewController(UINavigationController(rootViewController: sheetViewController!), for: .secondary)
            }
        }
        
        if let textFieldSection = self.viewModel.textFieldSection {
            if let indexPath = self.viewModel.cellToChangeIndexPath {
                // make the text white when it is selected in the sidebar
                let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
                var content = cell.defaultContentConfiguration()
                content.text = textFieldSection.title
                
                self.viewModel.reloadItemsInSection(section: textFieldSection)
                self.projectEditTextField.removeFromSuperview()
                self.viewModel.updateCollectionViewList()
            }
        } else if let textFieldProject = self.viewModel.textFieldProject {
            if let indexPath = self.viewModel.cellToChangeIndexPath {
                // make the text white when it is selected in the sidebar
                let cell = self.collectionView.cellForItem(at: indexPath) as! UICollectionViewListCell
                var content = cell.defaultContentConfiguration()
                content.text = textFieldProject.title
                
                self.viewModel.reloadSections()
                self.projectEditTextField.removeFromSuperview()
            }
        }
        
        
        viewModel.textFieldSection = nil
        viewModel.textFieldProject = nil
        
        print("The notification was posted")
        NotificationCenter.default.post(name: .SectionsUpdated, object: nil)
        
        return true
    }
}


