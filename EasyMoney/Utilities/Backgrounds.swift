//
//  Backgrounds.swift
//  EasyMoney
//
//  Created by Tim Terrance on 8/6/26.
//

import Foundation
import SwiftUI
 
struct Backgrounds {
    // gradient generator: https://angrytools.com/gradient/
 
    static var gradient1 = LinearGradient(
        gradient: Gradient(colors: [
            Color("BG_Grad1_top"),
            Color("BG_Grad1_bottom")
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
 
 
    static var gradient2 = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#40576D"),
            Color(hex: "#7890A7"),
            Color(hex: "#B8C7D6"),
            Color(hex: "#E8EEF3"),
        ]),
        startPoint: .bottom,  // "to top" in CSS becomes .bottom to .top in SwiftUI
        endPoint: .top
    )
 
    static var gradient3 = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#716B83"),
            Color(hex: "#2F7E9A"),
            Color(hex: "#3B8D99"),
        ]),
        startPoint: .bottom,  // "to top" in CSS becomes .bottom to .top in SwiftUI
        endPoint: .top
    )

    static var balanceGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#0F6B4F"),
            Color(hex: "#16865A"),
            Color(hex: "#2E9B73"),
        ]),
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
 
}
