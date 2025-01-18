//
//  ProgressBar.swift
//  QuickDMG
//
//  Created by Jackson Powell on 1/18/25.
//

import SwiftUI

// Custom ProgressBar view to show progress.
struct ProgressBar: View {
    @Binding var value: Double   // Bind the value to ensure updates reflect
    var total: Double
    var height: CGFloat = 6
    @Binding var message: String // Bind message to reflect changes

    var body: some View {
        VStack(spacing: 5) {
            ProgressView(value: value, total: total)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.accentColor))
                .frame(height: height)
                .background(Color.secondary.opacity(0.3))
                .cornerRadius(10)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}
