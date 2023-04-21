//
//  SwiftUIView.swift
//
//
//  Created by Daniel Riege on 16.04.23.
//

import SwiftUI
import Charts

struct OvertakeControlView: View {
    @Binding var driveOnLane: PathplanningOnLane
    @Binding var maxSpeed: Float
    @Binding var maxDistance: Float
    @Binding var distances: RingBuffer<Float>
    @Binding var minDistanceForOvertake: Float

    var body: some View {
        HStack {
            Chart {
                RuleMark(y: .value("PID Goal Distance", maxDistance * 10))
                    .foregroundStyle(.red)
                RuleMark(y: .value("Min Distance for Overtake", minDistanceForOvertake * 10))
                    .foregroundStyle(.green)
                
                ForEach(Array(distances.enumerated()), id: \.offset) { index, value in
                    LineMark(x: .value("Index", index),
                             y: .value("Distance", value * 10))
                }
            }
            .chartYAxisLabel("Distance to Obstacle")
            .chartXAxis(content: {})
            .chartLegend(.visible)
            .chartForegroundStyleScale([
                    "Distance": Color.blue,
                    "Min Distance for Overtake": Color.green,
                    "PID Goal Distance": Color.red
                ])
            .padding(20)
            .padding(.bottom, 20)
            Divider()
                .frame(height: 150)
                .frame(width: 50)
            VStack {
                HStack {
                    Text("Overtake Maneuver")
                        .font(.system(.headline))
                    InfoButtonView(title: "Overtake Maneuver", text: "In this scenario the path planning of the autonomous car can be altered. Using a picker, the path planning will generate a local path either on the right or left side of the road. In automatic mode, an overtake maneuver will be enganged when the car reaches a specific distance to an obstacle. The type of the road marking, like a solid line, is not taken into account but the car will not overtake in tight turns or when a vehicle on the left lane is blocking the overtake. This maneuver is only a change to the left lane and a change back as soon as there is no distance to an obstacle anymore.")
                }
                Spacer()
                HStack {
                    Text("Drive on Lane")
                    Picker("", selection: $driveOnLane) {
                        ForEach(PathplanningOnLane.allCases, id: \.self) { lane in
                            Text(lane.rawValue)
                                .tag(lane)
                        }
                    }
                    .pickerStyle(.segmented)
                    InfoButtonView(title: "Drive on Lane", text: "This picker changes the path planning algorithm to choose a path either on the right or left side of the road. In automatic, the side of the road will be choosen automatically given a distance to an obstacle.")
                }
                HStack {
                    Text("Overtake Distance")
                    Slider(value: $minDistanceForOvertake, in: 0...3.0)
                    Text(String(format: "%.1f m", minDistanceForOvertake * 10))
                        .frame(width: 70)
                    InfoButtonView(title: "Overtake Distance", text: "Only used in automatic mode, this parameter sets the distance at which a lane change will be engaged. This should always be higher than the pid goal distance, otherwise the car will always follow the car ahead.")
                }
                HStack {
                    Text("Max Speed")
                    Slider(value: $maxSpeed, in: 0...1)
                    Text(String(format: "%.0f kph", maxSpeed * 36 * RobocarModel.maxSpeed))
                        .frame(width: 70)
                }
                Spacer()
            }

        }
        .padding()
        .frame(height: 320)
        .background(Color.white)
        .cornerRadius(15.0)
        .shadow(radius: 5.0)
        .offset(y: 15)
    }
}
