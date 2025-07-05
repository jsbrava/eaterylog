//
//  AboutView.swift
//  EateryLog
//
//  Created by jim on 7/5/25.
//


import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.accentColor)
                .padding(.top, 40)
            
            Text("EateryLog")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("""
                Track your favorite restaurants and memorable meals.
                Discover new favorites nearby.

                Created by Jim.
                Version 1.0
                """)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("About")
    }
}