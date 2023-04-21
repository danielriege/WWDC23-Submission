//
//  DashboardView.swift
//  WWDC23
//
//  Created by Daniel Riege on 04.04.23.
//

import Foundation
import SwiftUI

struct DashboardView: View {
    @Binding var runningSim: Bool
    @Binding var currentSpeed: Int
    @Binding var wheelAngle: Int

    var body: some View {
        HStack {
            Button {
                runningSim.toggle()
            } label: {
                if runningSim {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 30))
                } else {
                    Image(systemName: "play.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 30))
                }
            }
            .frame(width: 60)
            
            Divider()
                .frame(width: 30, height: 80)
            VStack {
                Text("\(currentSpeed)")
                    .font(.system(size: 64))
                    .fontWeight(.medium)
                Text("kph")
                    .foregroundColor(.secondary)
                    .font(.system(size: 20))
            }
            .frame(width: 100)
            Divider()
                .frame(width: 30, height: 80)
            ZStack {
                Image(systemName: "steeringwheel")
                    .foregroundColor(.secondary)
                    .font(.system(size: 50))
                    .rotationEffect(Angle(degrees: Double(wheelAngle)))
            }
            .frame(width: 60)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15.0)
        .shadow(radius: 5.0)
        .offset(y: 10)
    }
}
