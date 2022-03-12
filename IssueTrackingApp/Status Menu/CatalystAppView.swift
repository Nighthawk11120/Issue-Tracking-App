//
//  CatalystAppView.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 11/8/21.
//

import SwiftUI

struct CatalystAppView: View {
    
    #if targetEnvironment(macCatalyst)
    @StateObject var statusMenuHelper = StatusMenuHelper()
    #endif
    
    var body: some View {
        VStack {
            #if targetEnvironment(macCatalyst)
            Toggle("Enable Status Menu", isOn: $statusMenuHelper.isEnabled)
            #endif
            
        }
    }
}
