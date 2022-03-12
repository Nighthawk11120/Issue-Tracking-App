//
//  DataService.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 8/28/21.
//

import Foundation

extension Notification.Name {
    static var SectionsUpdated = Notification.Name("net.gobauer.issuetrackingApp.SectionUpdates")
    static var ProjectsUpdated = Notification.Name("net.gobauer.issuetrackingApp.ProjectUpdates")
    static var SectionDragDropUpdated = Notification.Name("net.gobauer.isuetrackingApp.SectionDragDropUpdated")
    static var DidStartEditing = Notification.Name("net.gobauer.issuetrackingApp.DidStartEditing")
    static var DidUpdateTaskCell = Notification.Name("net.gobauer.issuetrackingApp.DidUpdateTaskCell")
    static var SectionInProjectDragDropUpdated = Notification.Name("SectionInProjectDragDropUpdated")
    static var UpdateUpcomingTasksView = Notification.Name("net.gobauer.issuetrackingapp.UpdateUpcomingTasksView")
}
