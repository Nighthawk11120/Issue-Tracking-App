//
//  ContentView.swift
//  ITStatusMenu
//
//  Created by Scott Bauer on 9/8/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) var managedObjectContext

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Project.userOrder, ascending: true)], animation: .default) var items: FetchedResults<Project>

    var body: some View {
        VStack {
            ForEach(items, id: \.self) { item in
                HStack {
                    Text(item.projectTitle).font(.footnote)
                    Spacer()
                }
                ForEach(item.projectSectionsSorted) { section in
                    HStack {
                        Text(section.sectionTitle)
                            .font(.title)
                            .foregroundColor(Color(section.projectColor))
                        Spacer()
                        Circle()
                            .frame(width: 20, height: 20)
                    }
                }
            }.padding(.bottom)
                            
        }.padding()
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

