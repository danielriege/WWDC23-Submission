//
//  PID.swift
//  WWDC23
//
//  Created by Daniel Riege on 15.04.23.
//

import Foundation

class PIDController {
    var integral: Float = 0.0
    var preError: Float = 0.0
    
    func calculate(target: Float, previous: Float, P: Float, I: Float, D: Float, dt: TimeInterval) -> Float {
        let error = target - previous
        // propotional term
        let pout = P * error
        // integral term
        integral += error * Float(dt)
        let iout = I * integral
        // derivative term
        let derivative = (error - preError) / Float(dt)
        let dout = D * derivative
        
        let output = pout + iout + dout
        
        preError = error
        return output
    }
}
