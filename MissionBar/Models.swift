//
//  Models.swift
//  MissionBar
//
//  Created by Ram Patra on 29/07/2025.
//

import Foundation
import SwiftUI
import AppKit

struct RunningProcess: Identifiable, Hashable {
    let id = UUID()
    let pid: Int32
    let name: String
    let bundleIdentifier: String?
    let cpuUsage: Double
    let memoryUsage: UInt64 // in bytes
    let icon: NSImage?
    let isKillable: Bool
    
    var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryUsage), countStyle: .memory)
    }
    
    var formattedCPU: String {
        String(format: "%.1f%%", cpuUsage)
    }
}

struct InstalledApplication: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let version: String?
    let path: URL
    let icon: NSImage?
    let storageSize: UInt64 // in bytes
    let isRunning: Bool
    let canUninstall: Bool
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(storageSize), countStyle: .file)
    }
}

enum AppTab: String, CaseIterable {
    case running = "Running"
    case all = "Applications"
    
    var icon: String {
        switch self {
        case .running:
            return "play.circle"
        case .all:
            return "square.grid.2x2"
        }
    }
}

struct CustomConfirmationView: View {
    let title: String
    let message: String
    let destructiveButtonText: String
    let cancelButtonText: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Confirmation dialog
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack(spacing: 12) {
                    Button(cancelButtonText) {
                        onCancel()
                    }
                    .keyboardShortcut(.escape)
                    .controlSize(.large)
                    
                    Button(destructiveButtonText) {
                        onConfirm()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.red)
                    .keyboardShortcut(.return)
                }
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.5), radius: 25, x: 0, y: 15)
            .frame(maxWidth: 320)
            .padding(.horizontal, 20)
        }
    }
} 