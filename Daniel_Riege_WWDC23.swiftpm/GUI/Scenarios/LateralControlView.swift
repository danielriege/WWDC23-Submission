//
//  SwiftUIView.swift
//  
//
//  Created by Daniel Riege on 14.04.23.
//

import SwiftUI
import Charts

struct LateralControlView: View {
    @Binding var crossTrackErrors: RingBuffer<Float>
    @Binding var headingErrors: RingBuffer<Float>
    @Binding var stanleyGain: Float
    @Binding var speed: Float
    @Binding var intersectionHeuristic: PathplanningIntersectionHeuristic
    
    var body: some View {
        HStack {
            ScrollView {
                Chart {
                    ForEach(Array(crossTrackErrors.enumerated()), id: \.offset) { index, value in
                        LineMark(x: .value("Index", index),
                                 y: .value("Value", value))
                    }
                }
                .chartYAxisLabel("Cross Track Error")
                .chartXAxis(content: {})
                .padding(20)
                Chart {
                    ForEach(Array(headingErrors.enumerated()), id: \.offset) { index, value in
                        LineMark(x: .value("Index", index),
                                 y: .value("Value", value))
                    }
                }
                .chartYAxisLabel("Heading Error")
                .chartXAxis(content: {})
                .padding(20)
            }
            Divider()
                .frame(height: 150)
                .frame(width: 50)
            VStack {
                HStack {
                    Text("Stanley Controller Parameters")
                        .font(.system(.headline))
                    InfoButtonView(title: "Stanley Controller", text: "The Stanley Controller, proposed in a Stanford research paper, is one of different options to control the steering wheel of the car given a path. The generated path, which will be used as reference, can be seen in the perception view when running the simulation. \n The two main components of the stanley controller are the cross track error and the heading error, which should be minimal for an optimal path following.")
                }
                HStack {
                    Text("Stanley Gain")
                    Slider(value: $stanleyGain, in: 0.0...2.0)
                    Text(String(format: "%.2f", stanleyGain))
                        .frame(width: 70)
                    InfoButtonView(title: "Stanley Gain", text: "This parameter multiplies onto the cross track error, resulting in a punishment factor. With a bigger value the car will try to minimize the cross track error even more. The influence of this can be well experienced in a lane change (overtake maneuver) or by moving the car in manual control to an offset of the lane.")
                }
                HStack {
                    Text("Intersection Heuristic")
                    Picker("", selection: $intersectionHeuristic) {
                        ForEach(PathplanningIntersectionHeuristic.allCases, id: \.self) { heuristic in
                            Text(heuristic.rawValue)
                                .tag(heuristic)
                        }
                    }
                    .pickerStyle(.segmented)
                    InfoButtonView(title: "Intersection Heuristic", text: "This decides which path will be taken when multiple paths can be taken. At intersections the different paths will lead into different intersection exits.")
                }
                HStack {
                    Text("Max Speed")
                    Slider(value: $speed, in: 0...1)
                    Text(String(format: "%.0f kph", speed * 36 * RobocarModel.maxSpeed))
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


//struct LateralControlView_Previews: PreviewProvider {
//    static var previews: some View {
//        LateralControlView(speed: Binding<Float>(projectedValue: <#Binding<Float>#>))
//    }
//}
