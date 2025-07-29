//
//  Models.swift
//  MissionBar
//
//  Created by Ram Patra on 29/07/2025.
//

import Foundation
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