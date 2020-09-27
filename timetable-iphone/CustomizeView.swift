//
//  CustomizeController.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 26.09.20.
//  Copyright © 2020 Finn Weiler. All rights reserved.
//

import SwiftUI


@available(iOS 14.0, *)
struct CustomizeView: View {
    
    @State private var colorExam: Color = Color.green
    @State private var colorCancel: Color = Color.red
    @State private var colorLightBg: Color = Color.white
    @State private var colorDarkBg: Color = Color.black
    
    @State private var useBgInApp: Bool = true
    
    var body: some View {
        GeometryReader { metrics in
            VStack {
                Group {
                    Spacer()
                        .frame(height: 10)
                    Text("In diesem Menü kannst du verschiedene Farben für dein Widget einstellen und speichern. Nach kurzer Zeit sollte dein Widget sich aktualisieren.")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .multilineTextAlignment(.center)
                    Spacer()
                        .frame(height: 20)
                    ColorPicker("Farbe von Klausuren", selection: $colorExam, supportsOpacity: false)
                        .onChange(of: colorExam) { _ in saveColors() }
                    ColorPicker("Farbe von Entfall", selection: $colorCancel, supportsOpacity: false)
                        .onChange(of: colorCancel) { _ in saveColors() }
                    ColorPicker("Hintergrundfarbe Widget Hell", selection: $colorLightBg, supportsOpacity: false)
                        .onChange(of: colorLightBg) { _ in saveColors() }
                    ColorPicker("Hintergrundfarbe Widget Dunkel", selection: $colorDarkBg, supportsOpacity: false)
                        .onChange(of: colorDarkBg) { _ in saveColors() }
                    Spacer()
                        .frame(height: 30)
                    Toggle("Hintergrund auch in App anwenden", isOn: $useBgInApp)
                        .onChange(of: useBgInApp) { _ in saveColors() }
                        .toggleStyle(SwitchToggleStyle(tint: .primary))
                    Spacer()
                }
            }
            .padding(15)
        }.onAppear {
            guard let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") else {
                return
            }
            colorExam = Color(rgb: defaults.integer(forKey: "colorExam"))
            colorCancel = Color(rgb: defaults.integer(forKey: "colorCancel"))
            colorLightBg = Color(rgb: defaults.integer(forKey: "colorLightBg"))
            colorDarkBg = Color(rgb: defaults.integer(forKey: "colorDarkBg"))
            
            useBgInApp = defaults.bool(forKey: "useBgInApp")
        }
    }
    
    func saveColors() {
        guard let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") else {
            return
        }
        defaults.set(colorExam.rgb, forKey: "colorExam")
        defaults.set(colorCancel.rgb, forKey: "colorCancel")
        defaults.set(colorLightBg.rgb, forKey: "colorLightBg")
        defaults.set(colorDarkBg.rgb, forKey: "colorDarkBg")
        
        defaults.set(useBgInApp, forKey: "useBgInApp")
        defaults.synchronize()
    }
}

@available(iOS 14.0, *)
extension Color {
    
    private init(red: Int, green: Int, blue: Int) {
           assert(red >= 0 && red <= 255, "Invalid red component")
           assert(green >= 0 && green <= 255, "Invalid green component")
           assert(blue >= 0 && blue <= 255, "Invalid blue component")

           self.init(red: Double(red) / 255.0, green: Double(green) / 255.0, blue: Double(blue) / 255.0)
    }
    
    init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
    
    var rgb: Int {
        let rgb =
            (Int(self.components.red * 255.0) << 16) +
            (Int(self.components.green * 255.0) << 8) +
            (Int(self.components.blue * 255.0))
        return rgb
    }
    
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {

        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            // You can handle the failure here as you want
            return (0, 0, 0, 0)
        }

        return (r, g, b, o)
    }
}
