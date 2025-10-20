//
//  Onboarding.swift
//  AccessManagementSystem
//
//  Created by youngkyun park on 10/20/25.
//

import SwiftUI

struct Onboarding: View {
    var body: some View {
        
        VStack(spacing: 16) {
            Image(.unionBiometricsLogo)
                .resizable()
                .scaledToFit()
                .frame(height: 66)
            
            Text("지원자 박영균")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.system(size: 16))
                .padding(.top, 24)
        }
        
    }
}

#Preview {
    Onboarding()
}
