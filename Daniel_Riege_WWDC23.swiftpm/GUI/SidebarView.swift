//
//  SidebarView.swift
//  WWDC23
//
//  Created by Daniel Riege on 05.04.23.
//

import SwiftUI

struct SidebarView: View {
    @State private var sidebarOpen = false
    var body: some View {
        ZStack {
            Button {
                sidebarOpen.toggle()
            } label: {
                Image(systemName: "list.bullet")
                    .foregroundColor(.blue)
                    .font(.system(size: 30))
            }
            if sidebarOpen {
                List {
                    Button("Test1") {
                        
                    }
                }
                .listStyle(.sidebar)
                .frame(maxWidth: 500)
            }
        }
        .animation(.default, value: sidebarOpen)
        .padding()
        .background(Color.white)
        .cornerRadius(15.0)
        .shadow(radius: 5.0)
        .offset(x: 30, y: 10)
    }
}
