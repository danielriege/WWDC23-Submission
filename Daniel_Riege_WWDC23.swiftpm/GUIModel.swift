//
//  WorldSceneModel.swift
//  WWDC23
//
//  Created by Daniel Riege on 03.04.23.
//

import Foundation
import SwiftUI
import SceneKit

/**
 This class functions as the view model for the entire GUI.
 
 All values that can be changed via the GUI are landing here, where they are polled by the simulation pipeline.
 */
class GUIModel: ObservableObject {
    // General
    @Published var controlThrottle: Float = 0.0
    @Published var controlSteering: Float = 0.0
    @Published var currentSpeed: Int = 0
    @Published var onboardCamera: Bool = false
    @Published var perceptionView: Bool = false
    @Published var dashboardWheelAngle: Int = 0
    @Published var simRunning: Bool = false
    // car parameters
    @Published var maxAcceleration: Float = 1
    @Published var maxDeacceleration: Float = 3
    @Published var maxSteeringChange: Float = 90
    @Published var speeds: RingBuffer<Float> = RingBuffer(count: 60, withValue: 0)
    @Published var steeringAngles: RingBuffer<Float> = RingBuffer(count: 60, withValue: 0)
    // Scneario
    @Published var currentScenario: ScenarioSelection = .manualControl
    // stanley control
    @Published var stanleyGain: Float = 1.0
    @Published var crossTrackErrors: RingBuffer<Float> = RingBuffer(count: 60, withValue: 0)
    @Published var headingErrors: RingBuffer<Float> = RingBuffer(count: 60, withValue: 0)
    @Published var intersectionHeuristic: PathplanningIntersectionHeuristic = .middle
    // pid speed
    @Published var P: Float = 1.0
    @Published var I: Float = 0.0
    @Published var D: Float = 0.0
    @Published var maxDistance: Float = 0.3
    @Published var distances: RingBuffer<Float> = RingBuffer(count: 60, withValue: .nan)
    // overtake
    @Published var driveOnLane: PathplanningOnLane = .right
    @Published var minDistanceForOvertake: Float = 0.6
    
    
    private var lastSpeed: Int = 0
    private var lastSteeringAngle: Int = 0
    
    func setSpeed(speed: Float) {
        let value = Int(speed)
        if lastSpeed != value {
            lastSpeed = value
            DispatchQueue.main.async {
                self.currentSpeed = value
            }
        }
    }
    
    func setDashboardWheelAngle(steeringAngle: Float) {
        let value = Int(steeringAngle * 18)
        if lastSteeringAngle != value {
            lastSteeringAngle = value
            DispatchQueue.main.async {
                self.dashboardWheelAngle = value
            }
        }
    }
    
    func addCrossTrackErrorValue(value: Float) {
        DispatchQueue.main.async {
            self.crossTrackErrors.write(value)
        }
    }
    
    func addHeadingErrorValue(value: Float) {
        DispatchQueue.main.async {
            self.headingErrors.write(value)
        }
    }
    
    func addDistanceValue(value: Float) {
        DispatchQueue.main.async {
            self.distances.write(value)
        }
        
    }
    
    func addSpeedValue(value: Float) {
        DispatchQueue.main.async {
            self.speeds.write(value)
        }
        
    }
    
    func addSteeringValue(value: Float) {
        DispatchQueue.main.async {
            self.steeringAngles.write(value)
        }
        
    }
}
