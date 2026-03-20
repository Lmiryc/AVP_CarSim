//
//  ContentView.swift
//  apv2
//
//  Created by Zhang Ada on 2026/2/20.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    var body: some View {
        VStack {
            Model3D(named: "Scene", bundle: realityKitContentBundle)
                .padding(.bottom, 50)

            Text("first 3d model！")
                            .font(.title)
                            .padding()
            Model3D(named: "carframe") { model in
                model
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(depth: 200)
            } placeholder:{
                ProgressView()
            }.frame(width: 400, height: 400)
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
