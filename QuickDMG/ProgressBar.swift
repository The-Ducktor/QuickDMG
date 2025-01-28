//
//  ProgressBar.swift
//  QuickDMG
//
//  Created by Jackson Powell on 1/18/25.
//

import SwiftUI

func getDMGIcon() -> NSImage {
    // Return the icon name for the DMG
    let icon = NSWorkspace.shared.icon(for: .archive)
    
    return icon
}
   
func formatProgress(value: Double, total: Double) -> String {
    // Return the formatted progress as "value / total"
    return "\(Int(round(value*3))) / \(Int(round(total*3)))"
}


struct ProgressBar: View {
    @Binding var value: Double   // Bind the value to ensure updates reflect
    var total: Double
    var height: CGFloat = 6
    @Binding var message: String // Bind message to reflect changes
    var body: some View {
        // icon then progress bar with message
        HStack {
            Image(nsImage: getDMGIcon())
                .resizable()
                .aspectRatio(contentMode: .fit) // Maintain aspect ratio
                .frame(width: 35.0, height: 35.0) // Specify both width and height
                .foregroundColor(.accentColor)
            VStack(spacing: 5) {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ProgressView(value: value, total: total)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.accentColor))
                    .frame(height: height)
                    .background(Color.secondary.opacity(0.3))
                    .cornerRadius(10)
                Text(formatProgress(value: value , total: total))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                
            }
            .padding(.horizontal)
        }
    }
}
