//
//  UpcomingTasks.swift
//  UpcomingTasks
//
//  Created by Scott Bauer on 9/12/21.
//

import SwiftUI
import CoreData

import SwiftUI
import CoreData

class UpcomingTasksViewModel: ObservableObject {
    @Published var projects = [Project]()
    
    init(fetchedProjects: Published<[Project]>.Publisher, storageProvider: ProjectProvider) {
        fetchedProjects
            .print("assigned to the new array")
            .assign(to: &$projects)
    }
}

struct UpcomingTasksView: View {
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode

    @FetchRequest(
        entity: ToDo.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ToDo.dueDate, ascending: false),
        ], predicate: NSPredicate(format: "dueDateEnabled = true")
    ) var fetchedProjects: FetchedResults<ToDo>

    @ObservedObject var viewModel: UpcomingTasksViewModel
    
    @State var tasksDue = [ToDo]()
    @State var topTasksDue = ArraySlice<ToDo>()
    @State var tasksDueToday = [ToDo]()
    @State var tasksDueTomorrow = [ToDo]()
    @State var tasksDueThisWeek = [ToDo]()
    
    var body: some View {

        VStack {
            List {
                TasksView(items: fetchedProjects, title: "Upcoming")
            }
        }

        .onReceive(NotificationCenter.default.publisher(for: .UpdateUpcomingTasksView), perform: { output in
            tasksDue = []
            for project in viewModel.projects {
                for section in project.projectSections {
                    for taskHeader in section.sectionHeaders {
                        for task in taskHeader.headerTasks {
                            tasksDue.append(task)
                        }
                    }
                }
            }

            let calendar = Calendar.current

            topTasksDue = tasksDue.sorted { $0.dueDate! < $1.dueDate! }.prefix(15)
            
                tasksDueToday = topTasksDue.filter { calendar.isDateInToday($0.dueDate!)}.sorted { $0.dueDate! < $1.dueDate! }
                tasksDueTomorrow = topTasksDue.filter { calendar.isDateInTomorrow($0.dueDate!)}.sorted { $0.dueDate! < $1.dueDate! }
                tasksDueThisWeek = topTasksDue.filter { calendar.isDate($0.dueDate!, equalTo: Date(), toGranularity: .weekOfMonth) && !tasksDueToday.contains($0) && !tasksDueTomorrow.contains($0)}.sorted { $0.dueDate! < $1.dueDate! }
            
        })
        .onReceive(NotificationCenter.default.publisher(for: .DidUpdateTaskCell), perform: { output in
            tasksDue = []
            for project in viewModel.projects {
                for section in project.projectSections {
                    for taskHeader in section.sectionHeaders {
                        for task in taskHeader.headerTasks {
                            tasksDue.append(task)
                        }
                    }
                }
            }

                let calendar = Calendar.current

            topTasksDue = tasksDue.sorted { $0.dueDate! < $1.dueDate! }.prefix(15)
            
                tasksDueToday = topTasksDue.filter { calendar.isDateInToday($0.dueDate!)}.sorted { $0.dueDate! < $1.dueDate! }
                tasksDueTomorrow = topTasksDue.filter { calendar.isDateInTomorrow($0.dueDate!)}.sorted { $0.dueDate! < $1.dueDate! }
                tasksDueThisWeek = topTasksDue.filter { calendar.isDate($0.dueDate!, equalTo: Date(), toGranularity: .weekOfMonth) && !tasksDueToday.contains($0) && !tasksDueTomorrow.contains($0)}.sorted { $0.dueDate! < $1.dueDate! }
            
        })
        .onAppear {
            for project in viewModel.projects {
                for section in project.projectSections {
                    for taskHeader in section.sectionHeaders {
                        for task in taskHeader.headerTasks {
                            tasksDue.append(task)
                        }
                    }
                }
            }

            let calendar = Calendar.current

            topTasksDue = tasksDue.filter{ $0.dueDateEnabled == true }.sorted { $0.dueDate! < $1.dueDate! }.prefix(15)
            
                tasksDueToday = topTasksDue.filter { calendar.isDateInToday($0.dueDate!)}.sorted { $0.dueDate! < $1.dueDate! }
                tasksDueTomorrow = topTasksDue.filter { calendar.isDateInTomorrow($0.dueDate!)}.sorted { $0.dueDate! < $1.dueDate! }
                tasksDueThisWeek = topTasksDue.filter { calendar.isDate($0.dueDate!, equalTo: Date(), toGranularity: .weekOfMonth) && !tasksDueToday.contains($0) && !tasksDueTomorrow.contains($0)}.sorted { $0.dueDate! < $1.dueDate! }
        }
    }
}

struct TasksView: View {
    
    var items: FetchedResults<ToDo>
    var title: String
    var body: some View {
        Section(header: Text(title)) {
            ForEach(items, id: \.self) { item in
                Text(item.title ?? "Task")
                    .onTapGesture {
                        item.closed = true
                        try? AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer.viewContext.save()
                        NotificationCenter.default.post(name: .DidUpdateTaskCell, object: nil)
                    }
            }
        }
        .headerProminence(.increased)
    }
}
