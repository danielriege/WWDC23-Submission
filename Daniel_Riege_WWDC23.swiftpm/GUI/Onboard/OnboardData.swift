//
//  OnboardData.swift
//  WWDC23
//
//  Created by Daniel Riege on 05.04.23.
//

import Foundation
import SwiftUI

struct OnboardData: Hashable, Identifiable {
    let id: Int
    let primaryText: String
    let secondaryText: String
    let dismissButtonText: String? = nil
}
