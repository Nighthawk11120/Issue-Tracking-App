////
////  CalendarEventView.swift
////  IssueTrackingApp
////
////  Created by Scott Bauer on 9/15/21.
////
//
//import SwiftUI
//
//struct CalendarEventView: View {
//    let date: Date
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
//    var body: some View {
//        ScrollView {
//            Text(date, style: .date).bold()
//
//            ForEach(fetchedSections.filter {$0.dateToOccur?.day == date.day && $0.dateToOccur?.month == date.month && $0.dateToOccur?.year == date.year}, id: \.self) { section in
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(Color.green.opacity(0.8))
//                    .overlay(Text(section.sectionTitle).bold())
//                    .onTapGesture {
//                        let sheetViewController = SectionDetailViewController(section: section, storageProvider: storageProvider)
//                        sheetViewController?.title = "\(section.title ?? "Section")"
//
//                        if UIDevice.current.userInterfaceIdiom == .phone || windowMode() == "iPad slide over" {
//                            splitViewController.showDetailViewController(UINavigationController(rootViewController: sheetViewController!), sender: nil)
//                        } else {
//                            splitViewController.setViewController(UINavigationController(rootViewController: sheetViewController!), for: .secondary)
//                        }
//                    }
//                    .frame(height: 100)
//                    .padding(.horizontal)
//                    .padding(.vertical, 10)
//            }
//            Spacer()
//        }
//        .onAppear {
//
//        }
//
//    }
//}
//
////struct CalendarEventView_Previews: PreviewProvider {
////    static var previews: some View {
////        CalendarEventView()
////    }
////}
