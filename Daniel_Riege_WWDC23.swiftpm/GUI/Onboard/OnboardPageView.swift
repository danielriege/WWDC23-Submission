//
//  IntroView.swift
//  WWDC23
//
//  Created by Daniel Riege on 05.04.23.
//

import SwiftUI

struct OnboardPageView: View {
    var data: OnboardData
    
    var body: some View {
        HStack {
            ScrollView {
                VStack(alignment: .center) {
                    Text(data.primaryText)
                        .font(.system(.title))
                        .bold()
                        .foregroundColor(.primary)
                    Text(data.secondaryText)
                        .font(.body)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .padding()
                    Spacer()
                }
            }
        }
    }
}
