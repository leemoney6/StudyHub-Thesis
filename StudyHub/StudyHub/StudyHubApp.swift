//
//  StudyHubApp.swift
//  StudyHub
//
//  Created by Salah Ben Sarar on 2025. 10. 01..
//

import SwiftUI

@main
struct StudyHubApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
