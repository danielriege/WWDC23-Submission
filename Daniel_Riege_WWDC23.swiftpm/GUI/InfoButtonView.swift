//
//  InfoView.swift
//  WWDC23
//
//  Created by Daniel Riege on 15.04.23.
//

import SwiftUI

struct InfoButtonView: View {
    let title: String
    let text: String
    @State var infoPresented: Bool = false
    
    var body: some View {
        Button {
            infoPresented.toggle()
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
                .font(.system(size: 20))
        }
        .popover(isPresented: $infoPresented, content: {
            InfoView(title: title, text: text)
                .preferredColorScheme(.light)
        })

    }
}

struct InfoView: View {
    @State var title: String
    @State var text: String
    
    var body: some View {
        ScrollView {
            VStack {
                Text(title)
                    .padding(10)
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text(text)
                    .frame(minWidth: 300, maxWidth: 600, minHeight: 100, maxHeight: 500)
                    .fixedSize(horizontal: false, vertical: false)
                    .lineLimit(nil)
                Spacer()
            }
        }
        .padding()

    }
}



struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoButtonView(title: "Stanley Gain", text: "Lorem ipsum.....")
            .previewDevice(PreviewDevice(rawValue: "iPad Air"))
    }
}
