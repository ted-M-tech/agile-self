//
//  TotalActivityReport.swift
//  ScreenTimeReport
//
//  Created by Tetsuya Maeda on 2025/12/01.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

extension DeviceActivityReport.Context {
    /// Context for displaying total daily screen time
    static let totalActivity = Self("Total Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityReport) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        var totalDuration: TimeInterval = 0

        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalDuration += segment.totalActivityDuration
            }
        }

        return ActivityReport(totalDuration: totalDuration)
    }
}

struct ActivityReport {
    let totalDuration: TimeInterval

    var formattedTime: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "--"
        }
    }
}
