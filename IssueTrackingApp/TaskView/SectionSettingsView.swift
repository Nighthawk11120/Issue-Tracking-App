//
//  SectionSettingsView.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 9/27/21.
//

import SwiftUI

enum Weekdays: Int {
    case Sunday = 1
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
}

struct SectionSettingsView: View {
    var storageProvider: ProjectProvider
    var section: HeaderSection
    @State var selectedWeekdays = [Weekdays]()
    
    @State var weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    @State var weekdaySelections = [String]()
    @State var isScheduleActive = false
    @State var isRecurring = false
    @State var dateToOccur = Date()
    @State var color: String = "Light Blue"
    
    let colorColumns = [
        GridItem(.adaptive(minimum: 44))
    ]
        
    var body: some View {
        VStack {
            Toggle("Is Schedule Active", isOn: $isScheduleActive)
            
            Toggle("Is Recurring", isOn: $isRecurring)
            
            if isRecurring {
                DatePicker("Date to occur", selection: $dateToOccur, displayedComponents: .hourAndMinute)
                
                List {
                    ForEach(weekdays, id: \.self) { item in
                        MultipleSelectionRow(title: item, isSelected: self.weekdaySelections.contains(item)) {
                            if self.weekdaySelections.contains(item) {
                                self.weekdaySelections.removeAll(where: { $0 == item })
                            }
                            else {
                                self.weekdaySelections.append(item)
                            }
                        }
                    }
                }
            } else {
                DatePicker("Date to occur", selection: $dateToOccur, displayedComponents: .date)
            }
            
            Section(header: Text("Custom project color")) {
                LazyVGrid(columns: colorColumns) {
                    ForEach(HeaderSection.colors, id: \.self, content: colorButton)
                }
                .padding(.vertical)
            }
            
            Spacer()
            
        }.onDisappear {
            section.dateToOccur = dateToOccur
            section.recurring = isRecurring
            section.scheduleActive = isScheduleActive
            section.daysToOccur = weekdaySelections.map(getWeekdayValue(_:))
            try? storageProvider.fetchedResultsController.managedObjectContext.save()
        }
        .task {
            dateToOccur = section.dateToOccur ?? Date()
            isRecurring = section.recurring
            isScheduleActive = section.scheduleActive
            weekdaySelections = section.sectionRepeatingDaysToOccur.map(getWeekdayString(_:))
            color = section.projectColor
        }
    }
    
    func update() {
        section.dateToOccur = dateToOccur
        section.recurring = isRecurring
        section.scheduleActive = isScheduleActive
        section.daysToOccur = weekdaySelections.map(getWeekdayValue(_:))
        section.color = color
        try? storageProvider.fetchedResultsController.managedObjectContext.save()
    }
    
    func colorButton(for item: String) -> some View {
        ZStack {
            Color(item)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(6)

            if item == color {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
        }
        .onTapGesture {
            color = item
            update()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(
            item == color
                ? [.isButton, .isSelected]
                : .isButton
        )
        .accessibilityLabel(LocalizedStringKey(item))
    }
    
    func getWeekdayString(_ weekdayValue: Int) -> String {
        switch weekdayValue {
        case 1:
            return "Sunday"
        case 2:
            return "Monday"
        case 3:
            return "Tuesday"
        case 4:
            return "Wednesday"
        case 5:
            return "Thursday"
        case 6:
            return "Friday"
        case 7:
            return "Saturday"
        default:
            return "Sunday"
        }
    }
    
    func getWeekdayValue(_ weekday: String) -> Int {
        switch weekday {
        case "Sunday":
            return 1
        case "Monday":
            return 2
        case "Tuesday":
            return 3
        case "Wednesday":
            return 4
        case "Thursday":
            return 5
        case "Friday":
            return 6
        case "Saturday":
            return 7
        default:
            return 0
        }
    }
}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.title)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
