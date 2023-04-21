//
//  CameraControlView.swift
//  WWDC23
//
//  Created by Daniel Riege on 04.04.23.
//

import SwiftUI

struct CameraControlView: View {
    @Binding var onboardCamera: Bool
    @Binding var perceptionView: Bool
    
    var body: some View {
        HStack {
            Picker("", selection: $perceptionView) {
                Text("Environment").tag(false)
                Text("Perception").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 250)
            Divider()
                .frame(width: 30, height: 40)
            Button {
                onboardCamera = !onboardCamera
            } label: {
                if !onboardCamera {
                    Image(systemName: "car.circle")
                        .foregroundColor(.blue)
                        .font(.system(size: 40))
                } else {
                    Image(systemName: "car.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 40))
                }
            }

        }
        .padding()
        .background(Color.white)
        .cornerRadius(15.0)
        .shadow(radius: 5.0)
        .offset(x: -30, y: 10)
    }
}
