////
////  CalendarView.swift
////  CalendarView
////
////  Created by Scott Bauer on 9/12/21.
////
//
//import SwiftUI
//import UniformTypeIdentifiers
//#if os(iOS)
//import MobileCoreServices
//#endif
//import CoreData
//
//
//enum DropStatus {
//    case inActive
//    case note
//    case folderBefore
//    case folderAfter
//    case subfolder
//    
//    var folderRelated: Bool {
//        switch self {
//        case .folderAfter, .folderBefore, .subfolder:
//            return true
//        default:
//            return false
//        }
//    }
//    
//    var dropAfter: Bool  {
//        switch self {
//        case .folderAfter, .subfolder:
//            return true
//        default:
//            return false
//        }
//    }
//    
//}
//
//struct CalendarScheduleView: View {
//    var storageProvider: PostProvider
//    var splitViewController: UISplitViewController
//
//    var body: some View {
//
//        RootView(storageProvider: storageProvider, splitViewController: splitViewController)
//    }
//}
//
////struct CalendarScheduleView_Previews: PreviewProvider {
////    static var previews: some View {
////        CalendarScheduleView()
////.previewInterfaceOrientation(.landscapeLeft)
////    }
////}
//
//
//
//fileprivate extension DateFormatter {
//    static var month: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMMM"
//        return formatter
//    }
//
//    static var monthAndYear: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMMM yyyy"
//        return formatter
//    }
//}
//
//
//
//fileprivate extension Calendar {
//    func generateDates(
//        inside interval: DateInterval,
//        matching components: DateComponents
//    ) -> [Date] {
//        var dates: [Date] = []
//        dates.append(interval.start)
//
////        dates.append(Date().startOfMonth())
//
//        enumerateDates(
//            startingAfter: interval.start,
//            matching: components,
//            matchingPolicy: .nextTime
//        ) { date, _, stop in
//            if let date = date {
//                if date < interval.end {
//                    dates.append(date)
//                } else {
//                    stop = true
//                }
//            }
//        }
//
//        return dates
//    }
//}
//
//struct WeekView<DateView>: View where DateView: View {
//    @Environment(\.calendar) var calendar
//
//    let week: Date
//    @Binding var currentDay: Date
//    let content: (Date) -> DateView
//
//    init(week: Date, currentDay: Binding<Date>, @ViewBuilder content: @escaping (Date) -> DateView) {
//        self.week = week
//        self.content = content
//        self._currentDay = currentDay
//    }
//
//    private var days: [Date] {
//        guard
//            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: week)
//            else { return [] }
//        return calendar.generateDates(
//            inside: weekInterval,
//            matching: DateComponents(hour: 0, minute: 0, second: 0)
//        )
//    }
//
//    var body: some View {
//            HStack {
//                ForEach(days, id: \.self) { date in
//                    HStack {
//                        if self.calendar.isDate(self.week, equalTo: date, toGranularity: .month) {
//                            self.content(date)
//                        } else {
//                            self.content(date).hidden()
//                        }
//                    }
//                }
//            }
//    }
//}
//
//struct MonthView<DateView>: View where DateView: View {
//    @Environment(\.calendar) var calendar
//
//    @State private var month: Date
//
////    let month: Date
//    let showHeader: Bool
//    let content: (Date) -> DateView
//    @Binding var currentWeek: Int
//    @Binding var currentDay: Date
//    init(
//        month: Date,
//        showHeader: Bool = true,
//        currentWeek: Binding<Int>,
//        currentDay: Binding<Date>,
//        @ViewBuilder content: @escaping (Date) -> DateView
//    ) {
//        self._month = State(initialValue: month)
//        self.content = content
//        self.showHeader = showHeader
//        self._currentWeek = currentWeek
//        self._currentDay = currentDay
//    }
//
//    private var weeks: [Date] {
//        guard
//            let monthInterval = calendar.dateInterval(of: .month, for: month)
//            else { return [] }
//        return calendar.generateDates(
//            inside: monthInterval,
//            matching: DateComponents(hour: 0, minute: 0, second: 0, weekday: calendar.firstWeekday)
//        )
//    }
//    
//    func changeDateBy(_ months: Int) {
//            if let date = Calendar.current.date(byAdding: .month, value: months, to: month) {
//                self.month = date
//            }
//        }
//    
//    private var header: some View {
//            let component = calendar.component(.month, from: month)
//            let formatter = component == 1 ? DateFormatter.monthAndYear : .month
//            return HStack{
//                Text(formatter.string(from: month))
//                    .font(.title)
//                    .padding(.horizontal)
//                Spacer()
//                HStack{
//                    Group{
//                        Button(action: {
//                            self.changeDateBy(-1)
//                        }) {
//                        Image(systemName: "chevron.left.square") //
//                            .resizable()
//                        }
//                        Button(action: {
//                            self.month = Date()
//                        }) {
//                        Image(systemName: "dot.square")
//                            .resizable()
//                        }
//                        Button(action: {
//                            self.changeDateBy(1)
//                        }) {
//                        Image(systemName: "chevron.right.square") //"chevron.right.square"
//                            .resizable()
//                        }
//                    }
//                    .foregroundColor(Color.blue)
//                    .frame(width: 25, height: 25)
//                    
//                }
//                .padding(.trailing, 20)
//            }
//        }
//
//    var body: some View {
//        VStack {
//            if showHeader {
//                header
//            }
//            if UIDevice.current.userInterfaceIdiom != .phone {
//            HStack{
//                ForEach(0..<7, id: \.self) {index in
//                    Spacer()
//                    Text("30")
//                        .hidden()
//                        .padding(8)
//                        .clipShape(Circle())
//                        .padding(.horizontal, 4)
//                        .overlay(
//                            Text(getWeekDaysSorted()[index].uppercased())
//                                .bold()
//                                .font(.headline)
//                        )
//                    Spacer()
//                }
//            }
//            }
//
//            ForEach(weeks, id: \.self) { week in
//                    WeekView(week: week, currentDay: $currentDay, content: self.content)
//            }
//        }
//    }
//    func getWeekDaysSorted() -> [String]{
//        let weekDays = Calendar.current.shortWeekdaySymbols
//        let sortedWeekDays = Array(weekDays[Calendar.current.firstWeekday - 1 ..< Calendar.current.shortWeekdaySymbols.count] + weekDays[0 ..< Calendar.current.firstWeekday - 1])
//        return sortedWeekDays
//    }
//}
//
//struct CalendarView<DateView>: View where DateView: View {
//    @Environment(\.calendar) var calendar
//
//    let interval: DateInterval
//    let content: (Date) -> DateView
//    @Binding var currentMonth: Int
//    @Binding var currentWeek: Int
//    @Binding var currentDay: Date
//
//    init(interval: DateInterval, currentMonth: Binding<Int>, currentWeek: Binding<Int>, currentDay: Binding<Date>, @ViewBuilder content: @escaping (Date) -> DateView) {
//        self.interval = interval
//        self.content = content
//        self._currentWeek = currentWeek
//        self._currentMonth = currentMonth
//        self._currentDay = currentDay
//    }
//
//    private var months: [Date] {
//        calendar.generateDates(
//            inside: interval,
//            matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0)
//        )
//    }
//
//
//    var body: some View {
//        ScrollView(.vertical, showsIndicators: false) {
//            VStack {
//                
//                ForEach(months, id: \.self) { month in
//                        MonthView(month: month, currentWeek: $currentWeek, currentDay: $currentDay, content: self.content)
//                }
//                
//            }
//        }
//    }
//}
//
//struct RootView: View {
//    @Environment(\.calendar) var calendar
//    
//    @Environment(\.managedObjectContext) var managedObjectContext
//    @Environment(\.presentationMode) var presentationMode
//
//    var storageProvider: PostProvider
//    var splitViewController: UISplitViewController
//    
//    @FetchRequest(
//        entity: HeaderSection.entity(),
//        sortDescriptors: [
//            NSSortDescriptor(keyPath: \HeaderSection.dateToOccur, ascending: false),
//        ], predicate: NSPredicate(format: "scheduleActive = true")
//    ) var fetchedSections: FetchedResults<HeaderSection>
//    
//
//    @State var dropStatus = DropStatus.note
////    @State private var models: [CalendarViewModel] = []
////
////    @State private var dragging: ScheduleItem?
////
////    @State var items = [ScheduleItem]()
//    
//    @State var desiredDate = Date()
//    private var monthly: DateInterval {
//        var monthComponent = DateComponents()
//        monthComponent.month = 2
//        let endDate = self.calendar.date(byAdding: monthComponent, to: self.desiredDate) ?? Date()
//        return DateInterval(start: Date(), end: endDate)
//      }
//
//
//
//    private var year: DateInterval {
//        calendar.dateInterval(of: .month, for: Date())!
//    }
//    let currentCalendar = Calendar.current
//    
//    @State var currentMonth = Date().month
//    @State var currentWeek = Date().week
//    @State var currentDay: Date = Date()
//
//    var body: some View {
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            VStack {
//                CalendarView(interval: year, currentMonth: $currentMonth, currentWeek: $currentWeek, currentDay: $currentDay) { date in
//                    
//                        Text("30")
//                            .hidden()
//                            .padding(8)
//                            .background(fetchedSections.contains{$0.dateToOccur?.day == date.day && $0.dateToOccur?.month == date.month && $0.dateToOccur?.year == date.year} ? Color.orange : Color.blue) // Make your logic
//                            .clipShape(Rectangle())
//                            .cornerRadius(4)
//                            .padding(4)
//                            .overlay(
//                                Text(String(self.calendar.component(.day, from: date)))
//                                    .foregroundColor(Color.black)
//                                    .underline(2 == 2) //Make your own logic
//                            )
//                            .onTapGesture {
//                                let hostingController = UIHostingController(rootView: CalendarEventView(date: date, storageProvider: storageProvider, splitViewController: splitViewController).environment(\.managedObjectContext, managedObjectContext))
//                                splitViewController.setViewController(hostingController, for: .secondary)
//                            }
//                }
//                Spacer()
//            }
//        } else {
//            
//            CalendarView(interval: year, currentMonth: $currentMonth, currentWeek: $currentWeek, currentDay: $currentDay) { date in
//                VStack {
//                    HStack {
//                        Spacer()
//                        Text("30")
//                            .hidden()
//                            .padding(8)
//                            .background(currentCalendar.isDate(Date(), equalTo: date, toGranularity: .day) ? Color.blue : Color.clear)
//                            .clipShape(Circle())
//                            .padding(.vertical, 4)
//                            .overlay(
//                                Text(String(self.calendar.component(.day, from: date)))
//                            )
//                    }
//                    
//                    ForEach(fetchedSections) { section in
//                        
//                        if section.recurring {
//                            if section.sectionRepeatingDaysToOccur.contains { $0 == date.weekday } {
//                                RoundedRectangle(cornerRadius: 8)
//                                    .fill(Color(section.projectColor).opacity(0.25))
//                                    .overlay(Text(section.sectionTitle).bold().foregroundColor(Color(section.projectColor)))
////                                    .onDrag({NSItemProvider(object: NSString(string: section.objectID.uriRepresentation().absoluteString))})
//                                    .onTapGesture {
//                                        let sheetViewController = SectionDetailViewController(section: section, storageProvider: storageProvider)
//                                        sheetViewController?.title = "\(section.title ?? "Section")"
//                                        
//                                        if UIDevice.current.userInterfaceIdiom == .phone || windowMode() == "iPad slide over" {
//                                            splitViewController.showDetailViewController(UINavigationController(rootViewController: sheetViewController!), sender: nil)
//                                        } else {
//                                            splitViewController.setViewController(UINavigationController(rootViewController: sheetViewController!), for: .secondary)
//                                        }
//                                    }
//                            }
//                        } else {
//                            if currentCalendar.isDate(section.dateToOccur!, equalTo: date, toGranularity: .day) {
//                                RoundedRectangle(cornerRadius: 8)
//                                    .fill(Color(section.projectColor).opacity(0.25))
//                                    .overlay(Text(section.sectionTitle).bold().foregroundColor(Color(section.projectColor)))
//                                    .onDrag({NSItemProvider(object: NSString(string: section.objectID.uriRepresentation().absoluteString))})
//                                    .onTapGesture {
//                                        let sheetViewController = SectionDetailViewController(section: section, storageProvider: storageProvider)
//                                        sheetViewController?.title = "\(section.title ?? "Section")"
//                                        
//                                        if UIDevice.current.userInterfaceIdiom == .phone || windowMode() == "iPad slide over" {
//                                            splitViewController.showDetailViewController(UINavigationController(rootViewController: sheetViewController!), sender: nil)
//                                        } else {
//                                            splitViewController.setViewController(UINavigationController(rootViewController: sheetViewController!), for: .secondary)
//                                        }
//                                    }
//                            }
//                        }
//                       
//                    }
//                    
//                    Spacer()
//                    
//                }
//                .frame(minWidth: 0, maxWidth: .infinity, minHeight: UIDevice.current.userInterfaceIdiom == .phone ? 600 : 200, alignment: .center)
//                .background(UIDevice.current.userInterfaceIdiom == .phone ? Color.gray : Color.white)
//                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 20 : 0)
//                .onDrop(of: [kUTTypeData as String], delegate: HeaderSectionDropDelegate(managedObjectContext: managedObjectContext, date: date))
//                
//            }
//        }
//    }
//}
//
//struct HeaderSectionDropDelegate: DropDelegate {
////    @Environment(\.managedObjectContext) var managedObjectContext
//    let managedObjectContext: NSManagedObjectContext
//    let date: Date
////    @Binding var dropStatus: DropStatus
//    
//    func dropEntered(info: DropInfo) {
//        //check folder or note
//
//    }
//    
//    func validateDrop(info: DropInfo) -> Bool {
//        info.hasItemsConforming(to: [kUTTypeURL as String])
//    }
//    
//    func dropExited(info: DropInfo) {
////        finishDrop()
//    }
//    
//    func finishDrop() {
////        dropStatus = .inActive
////        NotificationCenter.default.post(name: .finishDrop, object: nil)
//    }
//    
//    func performDrop(info: DropInfo) -> Bool {
//        let providers = info.itemProviders(for: [kUTTypeData as String])
//        
//        
//        guard let itemProvider = info.itemProviders(for: [(kUTTypeData as String)]).first else { return false }
//        DispatchQueue.main.async {
//            print("got here2")
//        }
//        
//#if os(iOS)
//        itemProvider.loadObject(ofClass: String.self) { item, error in
//            guard let data = item as? String else { return }
//            let managedObjectID = managedObjectContext.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: URL(string: data)!)
//            DispatchQueue.main.async {
//                do {
//                    print("change section date")
//                    let section = try managedObjectContext.existingObject(with: managedObjectID!) as? HeaderSection
//                    let calendar = Calendar.current
//                    var dateComponents = calendar.dateComponents([.month, .year, .day, .second, .hour, .minute], from: (section?.dateToOccur)!)
//                    
//                    let newDay = calendar.dateComponents([.day, .month, .year], from: date)
//                    dateComponents.day = newDay.day
//                    dateComponents.month = newDay.month
//                    dateComponents.year = newDay.year
//                    section?.dateToOccur = calendar.date(from: dateComponents)
//                    try? managedObjectContext.save()
//
//                } catch {
//                    print("failed to convert ManagedObjectID to Section object")
//                }
//                
//            }
//        }
//#else
//        itemProvider.loadItem(forTypeIdentifier: (kUTTypeURL as String), options: nil) { item, error in
//            guard let data = item as? Data else { return }
//            DispatchQueue.main.async {
//                print("got here3")
//            }
//            let value = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL
//            let managedObjectID = managedObjectContext.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: value)
//            
//            DispatchQueue.main.async {
//                do {
//                    print("change section date")
//                    let section = try managedObjectContext.existingObject(with: managedObjectID!) as? HeaderSection
//                    let calendar = Calendar.current
//                    var dateComponents = calendar.dateComponents([.month, .year, .day, .second, .hour, .minute], from: (section?.dateToOccur)!)
//                    
//                    let newDay = calendar.dateComponents([.day, .month, .year], from: date)
//                    dateComponents.day = newDay.day
//                    dateComponents.month = newDay.month
//                    dateComponents.year = newDay.year
//                    section?.dateToOccur = calendar.date(from: dateComponents)
//                    try? managedObjectContext.save()
//                } catch {
//                    print("failed to convert ManagedObjectID to Section object")
//                }
//                
//            }
//        }
//        
////        let found = destinationFolder.handleMovedDrop(with: providers, dropStatus: dropStatus)
////
////       finishDrop()
////        return found
//#endif
//        return true
//    }
//}
//
//
//struct CalendarView_Previews: PreviewProvider {
//    static var previews: some View {
//        CalendarView(interval: .init(), currentMonth: .constant(4), currentWeek: .constant(2), currentDay: .constant(Date())) { _ in
//            Text("30")
//                .padding(8)
//                .background(Color.blue)
//                .cornerRadius(8)
//        }
//    }
//}
