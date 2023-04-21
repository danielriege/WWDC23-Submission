//
//  OnboardView.swift
//  WWDC23
//
//  Created by Daniel Riege on 05.04.23.
//

import SwiftUI

struct OnboardView: View {
    @Binding var showOnboard: Bool
    
    @State var currentTab = 0
    var onboardData: [OnboardData]
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.size.width
    }
    
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.size.height
    }

    var body: some View {
        VStack {
            HStack{
                Spacer()
                Button("Dismiss") {
                    showOnboard = false
                }
                .padding()
                .offset(x:-20,y:10)
            }
            
            TabView(selection: $currentTab,
                    content:  {
                ForEach(onboardData) { viewData in
                    OnboardPageView(data: viewData)
                        .tag(viewData.id)
                }
            })
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
//        .frame(minWidth: screenWidth*0.4, maxWidth: screenWidth*0.6, minHeight: screenHeight*0.2, maxHeight: screenHeight*0.4)
        .background(Color.white)
//        .cornerRadius(30)
//        .shadow(radius: 10.0)
    }
}

