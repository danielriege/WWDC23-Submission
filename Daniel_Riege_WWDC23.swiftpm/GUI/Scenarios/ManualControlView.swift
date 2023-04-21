//
//  ControlView.swift
//  WWDC23
//
//  Created by Daniel Riege on 04.04.23.
//

import SwiftUI
import Charts

struct ManualControlView: View {
    @Binding var maxSpeed: Float
    @Binding var steering: Float
    @Binding var maxAcceleration: Float
    @Binding var maxDeacceleration: Float
    @Binding var maxSteeringChange: Float
    @Binding var speeds: RingBuffer<Float>
    @Binding var steeringAngles: RingBuffer<Float>
    
    var body: some View {
        HStack {
            ScrollView {
                Chart {
                    RuleMark(y: .value("Set Steering Angle", steering * RobocarModel.maxSteeringAngle))
                        .foregroundStyle(.red)
                    
                    ForEach(Array(steeringAngles.enumerated()), id: \.offset) { index, value in
                        LineMark(x: .value("Index", index),
                                 y: .value("Steering Angle", value))
                    }
                }
                .chartYAxisLabel("Steering Angle [deg]")
                .chartXAxis(content: {})
                .chartLegend(.visible)
                .chartForegroundStyleScale([
                        "Steering Angle": Color.blue,
                        "Set Steering Angle": Color.red
                    ])
                .padding(20)
                .padding(.bottom, 20)
                
                Chart {
                    RuleMark(y: .value("Set Speed", maxSpeed * 36 * RobocarModel.maxSpeed))
                        .foregroundStyle(.red)
                    
                    ForEach(Array(speeds.enumerated()), id: \.offset) { index, value in
                        LineMark(x: .value("Index", index),
                                 y: .value("Speed", value))
                    }
                }
                .chartYAxisLabel("Speed [km/h]")
                .chartXAxis(content: {})
                .chartLegend(.visible)
                .chartForegroundStyleScale([
                    "Speed": Color.blue,
                    "Set Speed": Color.red
                ])
                .padding(20)
                .padding(.bottom, 20)
            }
            Divider()
                .frame(height: 150)
                .frame(width: 50)
            VStack {
                HStack {
                    Text("Car Parameters")
                        .font(.system(.headline))
                }
                HStack {
                    Text("Acceleration")
                    Slider(value: $maxAcceleration, in: 0.0...2.0)
                    Text(String(format: "%.2f m/s^2", maxAcceleration))
                        .frame(width: 100)
                    InfoButtonView(title: "Max Acceleration", text: "This parameter limits the acceleration the car can perform. With a bigger value the target speed will be achieved faster.")
                }
                HStack {
                    Text("Braking")
                    Slider(value: $maxDeacceleration, in: 0.0...4.0)
                    Text(String(format: "%.2f m/s^2", maxDeacceleration))
                        .frame(width: 100)
                    InfoButtonView(title: "Max Deacceleration", text: "As the acceleration parameter, this limits the deacceleration (breaking) of the car. With a bigger value the target speed when breaking will be achieved faster.")
                }
                HStack {
                    Text("Steering Change")
                    Slider(value: $maxSteeringChange, in: 0.0...180)
                    Text(String(format: "%.0f deg/s", maxSteeringChange))
                        .frame(width: 100)
                    InfoButtonView(title: "Steering Change", text: "This parameter defines how fast  the steering of the car can change. With a bigger value the target steering angle can be achieved faster. In a real car this depends on the servo motor controlling the steering wheel.")
                }
                HStack {
                    Text("Manual Control")
                        .font(.system(.headline))
                }
                HStack {
                    Text("Steering Angle")
                    Slider(value: $steering, in: -1.0...1.0) { editing in
                        if !editing {
                            steering = 0
                        }
                    }
                    Text(String(format: "%.0f deg", steering * RobocarModel.maxSteeringAngle))
                        .frame(width: 70)
                }
                HStack {
                    Text("Speed")
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
