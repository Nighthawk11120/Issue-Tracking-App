//
//  Project-CoreDataHelpers.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 6/20/21.
//

import Foundation
import CoreData

extension Project {
    
    var projectSections: [HeaderSection] {
        sections?.allObjects as? [HeaderSection] ?? []
    }
    
    var projectSectionsSorted: [HeaderSection] {
        projectSections.sorted { $0.userOrder < $1.userOrder}
    }
    
    var projectTitle: String {
        title ?? "project"
    }
    
    var projectChildren: [Project] {
        children_?.allObjects as? [Project] ?? []
    }
}
