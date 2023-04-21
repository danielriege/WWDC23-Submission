//
//  File.swift
//  
//
//  Created by Daniel Riege on 15.04.23.
//

import SwiftUI
import Charts

struct LongitudinalControlView: View {
    @Binding var maxSpeed: Float
    @Binding var P: Float
    @Binding var I: Float
    @Binding var D: Float
    @Binding var maxDistance: Float
    @Binding var distances: RingBuffer<Float>
    
    var body: some View {
        HStack {
            Chart {
                RuleMark(y: .value("Goal Distance", maxDistance * 10))
                    .foregroundStyle(.red)
                
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
                    "Goal Distance": Color.red
                ])
            .padding(20)
            .padding(.bottom, 20)
            Divider()
                .frame(height: 150)
                .frame(width: 50)
            VStack {
                HStack {
                    Text("PID Controller Parameters")
                        .font(.system(.headline))
                    InfoButtonView(title: "PID Controller", text: "A PID (Proportional-Integral-Derivative) controller is a feedback control algorithm that adjusts an input based on the difference between a desired setpoint and a measured process variable, using proportional, integral, and derivative terms to optimize the response. \n In this scenario a PID controller will be used to control the speed of the car depending on the distance to an obstacle. If there is no obstacle in reach, the max speed parameter will be used as the speed of the car. Using the chart the parameters can be tuned on the fly to an optimal controller.")
                }
                HStack {
                    Text("P Gain")
                    Slider(value: $P, in: 0.0...1.0)
                    Text(String(format: "%.2f", P))
                        .frame(width: 70)
                    InfoButtonView(title: "Proportional Gain", text: "The proportional gain determines the strength of the controller's response to the difference between the setpoint (goal distance) and the measured process variable (speed of car). This difference is also called error.")
                }
                HStack {
                    Text("I Gain")
                    Slider(value: $I, in: 0.0...0.1)
                    Text(String(format: "%.3f", I))
                        .frame(width: 70)
                    InfoButtonView(title: "Integral Gain", text: "The integral gain determines the strength of the controller's response to past errors, proportional to the integral of the error over time, and helps to eliminate a steady-state error. This steady-state error can be viewed in the chart and with no integral term, there will be an offset between desired goal distance and actual distance to an obstacle.")
                }
                HStack {
                    Text("D Gain")
                    Slider(value: $D, in: 0.0...0.1)
                    Text(String(format: "%.3f", D))
                        .frame(width: 70)
                    InfoButtonView(title: "Derivative Gain", text: "The derivative gain determines the strength of the controller's response to changes in the error over time, proportional to the rate of change of the error, and helps to improve the controller's stability and response time. This can be used to dampen the curve in the chart.")
                }
                HStack {
                    Text("Goal Distance")
                    Slider(value: $maxDistance, in: 0.2...1.0)
                    Text(String(format: "%.1f m", maxDistance * 10))
                        .frame(width: 70)
                    InfoButtonView(title: "Goal Distance", text: "This parameter sets the desired clearance between the ego car and an obstacle.")
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
