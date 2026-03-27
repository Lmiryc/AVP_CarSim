//
//  VXDisplayView.swift
//  apv2
//
//  Created by Zhang Ada on 2026/3/27.
//

import SwiftUI

struct VXDisplayView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 12) {
            Text("VX")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(String(format: "%.2f", appModel.currentVX))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            
            Text("km/h")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

#Preview {
    VXDisplayView()
        .environment(AppModel())
}
