//
//  ScreenTimeReport.swift
//  ScreenTimeReport
//
//  Created by Tetsuya Maeda on 2025/12/01.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct ScreenTimeReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { activityReport in
            TotalActivityView(activityReport: activityReport)
        }
    }
}
