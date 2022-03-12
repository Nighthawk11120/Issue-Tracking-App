//
//  Section-CoreDataHelpers.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 6/20/21.
//

import Foundation

extension HeaderSection {
    
    static let colors = [
        "Pink",
        "Purple",
        "Red",
        "Orange",
        "Gold",
        "Green",
        "Teal",
        "Light Blue",
        "Dark Blue",
        "Midnight",
        "Dark Gray",
        "Gray"
    ]
    
    var projectColor: String {
        color ?? "Light Blue"
    }
    
    enum SortOrder: String {
        case title, creationDate
    }
    
    var sectionCreationDate: Date {
        creationDate ?? Date()
    }
    
    var sectionRepeatingDaysToOccur: [Int] {
        daysToOccur ?? []
    }
    var sectionHeaders: [ToDoHeader] {
        taskHeaders?.allObjects as? [ToDoHeader] ?? []
    }
    
    var sectionTitle: String {
        title ?? "Section"
    }
    
    var sectionTasksDefaultSorted: [ToDoHeader] {
        return sectionHeaders.sorted { first, second in
            return first.userOrder < second.userOrder
        }
    }
}

extension HeaderSection {
    static let OpenDetailActivityType = "net.gobauer.SectionOpenDetailActivityType"
    static let OpenDetailIdKey = "sectionID"
    
    var openDetailUserActivity: NSUserActivity {
        let userActivity = NSUserActivity(activityType: HeaderSection.OpenDetailActivityType)
        userActivity.userInfo = [HeaderSection.OpenDetailIdKey: id]
        return userActivity
    }
}
