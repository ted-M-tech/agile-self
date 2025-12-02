//
//  TotalActivityView.swift
//  ScreenTimeReport
//
//  Created by Tetsuya Maeda on 2025/12/01.
//

import SwiftUI

/// View displayed by the DeviceActivityReport extension
/// This view renders inside the main app via DeviceActivityReport SwiftUI component
struct TotalActivityView: View {
    let activityReport: ActivityReport

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.title3)
                .foregroundStyle(.cyan)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(activityReport.formattedTime)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Screen Time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VStack {
        TotalActivityView(activityReport: ActivityReport(totalDuration: 9240))
        TotalActivityView(activityReport: ActivityReport(totalDuration: 2700))
        TotalActivityView(activityReport: ActivityReport(totalDuration: 0))
    }
    .padding()
}
