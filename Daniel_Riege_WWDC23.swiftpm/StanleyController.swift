//
//  StanleyController.swift
//  WWDC23
//
//  Created by Daniel Riege on 14.04.23.
//

import Foundation
import simd

class StanleyController {
    
    static func getSteeringAngle(previousWaypoint: RoadGraphNode, nextWaypoint: RoadGraphNode, currentSpeed: Float, currentTransform: simd_float4x4, k: Float) -> (steeringAngle: Float, crossTrackError: Float, headingError: Float) {
        let xc = currentTransform[3,0]
        let yc = currentTransform[3,2]
        let x1 = previousWaypoint.x
        let y1 = previousWaypoint.z
        let x2 = nextWaypoint.x
        let y2 = nextWaypoint.z
        
        // calculate cross track error
        // https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line#Line_defined_by_two_points
        let ce_num = (x2-x1) * (y1-yc) - (x1-xc) * (y2-y1)
        let ce_de = sqrt(pow(x2-x1, 2) + pow(y2-y1, 2))
        let ce = ce_num / ce_de
        
        // heading error
        let psi = atan2(currentTransform[0,2] * (x2-x1) - currentTransform[0,0] * (y2-y1), currentTransform[0,0] * (x2-x1) + currentTransform[0,2] * (y2-y1)) * -1
        
        // cross track steering
        let theta_xc = atan2(k * ce, currentSpeed)
        
        // total steering
        let steering = (psi + theta_xc) * 180 / .pi
        
        return (steering, ce, psi)
    }
}
