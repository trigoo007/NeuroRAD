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
    static var systemBackground: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return Color(.windowBackgroundColor)
        #endif
    }
    
    static var systemGray5: Color {
        #if os(iOS)
        return Color(.systemGray5)
        #else
        return Color(.windowBackgroundColor).opacity(0.3)
        #endif
    }
    
    static var systemGray6: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color(.windowBackgroundColor).opacity(0.2)
        #endif
    }
}