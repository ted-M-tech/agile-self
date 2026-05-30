//
//  agile_selfApp.swift
//  agile-self Watch App
//
//  Created by Tetsuya Maeda on 2025/11/30.
//

import SwiftUI

@main
struct agile_self_Watch_AppApp: App {
    @State private var connectivity: WatchConnectivityManager

    init() {
        let manager = WatchConnectivityManager()
        manager.activate()
        _connectivity = State(initialValue: manager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(connectivity: connectivity)
        }
    }
}
