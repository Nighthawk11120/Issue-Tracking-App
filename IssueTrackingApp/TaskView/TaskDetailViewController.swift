//
//  TaskDetailViewController.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 7/19/21.
//

import UIKit
import SwiftUI
import Combine


struct SectionDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var todo: ToDo
    var reloadTask: CurrentValueSubject<ToDo?, Never>?
    var appDelegate = AppDelegate.sharedAppDelegate
    @State var canEdit = false
    var storageProvider: ProjectProvider
    
    @State var dateSelection = Date()
    @State var name = ""
    @State var isDueDateEnabled = false
    
    var body: some View {
        
#if os(iOS)
        VStack {
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.automatic)
                
                Spacer()
            }.padding()
            
            TextField("Task Title", text: $todo.todoName.onChange {
                
                todo.objectWillChange.send()
                save()
                reloadTask?.value = todo
                reloadTask?.value = nil
                
            })
                .font(.system(size: 20, weight: .bold, design: .default))
            Divider()
            
            HStack {
                Toggle(isOn: $isDueDateEnabled) {
                    Text("Due Date")
                }
                .onChange(of: isDueDateEnabled) { newValue in
                    todo.dueDateEnabled = newValue
                    print("the value was changed to \(newValue)")
                }
                
                if todo.dueDateEnabled {
                    DatePicker("Date", selection: $dateSelection)
                        .onChange(of: dateSelection) { newValue in
                            todo.dueDate = newValue
                        }
                }
            }
            
            TextViewWrapper(section: todo)
            
        }
        .onAppear {
            dateSelection = todo.dueDate ?? Date()
            name = todo.todoName
            isDueDateEnabled = todo.dueDateEnabled
        }
        .background(Color.white)
        .onDisappear {
            save()
            NotificationCenter.default.post(name: .UpdateUpcomingTasksView, object: nil)
            NotificationCenter.default.post(name: .SectionDragDropUpdated, object: nil)
            
        }
        .padding(.horizontal, 20)
        
#else
        VStack {
            
            TextField("Task Title", text: $section.sectionName.onChange(save))
            TextViewWrapper(section: todo)
        }
        .onDisappear {
            todo.objectWillChange.send()
            save()
            NotificationCenter.default.post(name: .UpdateUpcomingTasksView, object: nil)
        }
        .onAppear {
            dateSelection = todo.dueDate ?? Date()
            name = todo.todoName
            isDueDateEnabled = todo.dueDateEnabled
        }
#endif
    }
    
    func save() {
        try? storageProvider.persistentContainer.viewContext.save()
    }
}

struct EmptyTaskDetailView: View {
    var body: some View {
        Text("Welcome Back! - Implement home screen here")
            .font(.title)
            .bold()
    }
}

struct EmptySectionDetailView: View {
    var body: some View {
        Text("Select a section")
            .font(.title)
            .bold()
    }
}
