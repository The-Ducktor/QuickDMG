//
//  ProgressBar.swift
//  QuickDMG
//
//  Created by Jackson Powell on 1/18/25.
//

import SwiftUI

struct ProgressBar: View {
    @Binding var value: Double
    var total: Double
    @Binding var message: String
    
    private var percentage: Int {
        Int((value / total) * 100)
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Image(nsImage: NSWorkspace.shared.icon(for: .archive))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(percentage)%")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: value, total: total)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProgressBar(
        value: .constant(0.45),
        total: 1.0,
        message: .constant("Copying App...")
    )
    .frame(width: 400)
    .padding()
}
