//
//  ColorExtension.swift
//  NeuroRAD
//
//  Created for NeuroRAD Project
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

// Extensión de Color para compatibilidad entre macOS e iOS
extension Color {
    // Estas propiedades ya están definidas en otro lugar del proyecto,
    // por lo que las comento para evitar la redeclaración
    
    /*
    static var systemBackground: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
    
    static var systemGray5: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(.systemGray5)
        #endif
    }
    
    static var systemGray6: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor).opacity(0.8)
        #else
        return Color(.systemGray6)
        #endif
    }
    */
}
