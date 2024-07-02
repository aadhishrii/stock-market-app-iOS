//
//  LaunchScreenView.swift
//  HW4
//
//  Created by Ashwamegha Holkar on 4/11/24.
//

import SwiftUI

struct LaunchScreenView: View {
    @State var showMainScreen = false;
    var body: some View {
        ZStack{
            if showMainScreen{
                ContentView()
            }
            else{
                HStack{
                    Image("Launch_stock")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }.background(Color(red: 0.95, green: 0.95, blue: 0.95))
            }
        }.onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now()+4){
                self.showMainScreen = true;
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
