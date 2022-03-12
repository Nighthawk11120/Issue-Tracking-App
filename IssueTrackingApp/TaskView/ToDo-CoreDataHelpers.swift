//
//  ToDo-CoreDataHelpers.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 7/19/21.
//

import Foundation

extension ToDo {
    var todoName: String {
        get { title ?? "" }
        set { title = newValue }
    }

    var todoBodyText: String {
        get { bodyText ?? "" }
        set { bodyText = newValue }
    }
    
    var todoCreationDate: Date {
        creationDate ?? Date()
    }
    
    var todoID: UUID {
        id ?? UUID()
    }
    
    var todoFormattedText: NSAttributedString {
        get {
            if let data = formattedText {
                return data.toAttributedString()
            } else {
                return NSAttributedString(string: "")
            }
        }
        set {
            bodyText = newValue.string
            formattedText = newValue.toData()
        }
    }
    
    var todoChildren: [ToDo] {
        children_?.allObjects as? [ToDo] ?? []
    }
}

extension ToDoHeader {
    
    var headerTitle: String {
        title ?? "Untitled Header"
    }
        var headerTasks: [ToDo] {
            tasks?.allObjects as? [ToDo] ?? []
        }
    
    var headerTasksDefaultSorted: [ToDo] {
        return headerTasks.sorted { first, second in
            return first.userOrder < second.userOrder
        }
    }
}


