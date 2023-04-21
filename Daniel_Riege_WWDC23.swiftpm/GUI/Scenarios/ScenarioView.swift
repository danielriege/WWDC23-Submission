//
//  SwiftUIView.swift
//  
//
//  Created by Daniel Riege on 14.04.23.
//

import SwiftUI

enum ScenarioSelection: String, CaseIterable {
    case manualControl = "Manual Control"
    case lateralControl = "Lateral Control"
    case longitudinalControl = "Longitudinal Control"
    case overtakeManeuver = "Overtake Maneuver"
}

struct ScenarioView: View {
    @Binding var scenarioSelection: ScenarioSelection
    @Binding var simRunning: Bool
    
    var body: some View {
        HStack {
            Picker("", selection: $scenarioSelection) {
                ForEach(ScenarioSelection.allCases, id: \.self) { scenario in
                        Text(scenario.rawValue)
                            .tag(scenario)
                    }
            }
//            .onChange(of: scenarioSelection, perform: { newValue in
//                simRunning = false
//            })
            .frame(width: 200)
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15.0)
        .shadow(radius: 5.0)
        .offset(x: 30, y: 10)
    }
}
