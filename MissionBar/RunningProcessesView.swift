//
//  RunningProcessesView.swift
//  MissionBar
//
//  Created by Ram Patra on 29/07/2025.
//

import SwiftUI

struct RunningProcessesView: View {
    @EnvironmentObject var systemMonitor: SystemMonitor
    @State private var searchText = ""
    @State private var sortBy: ProcessSortOption = .name
    @State private var sortAscending = true
    @State private var showingKillConfirmation = false
    @State private var processToKill: RunningProcess?
    
    private var filteredProcesses: [RunningProcess] {
        let filtered = searchText.isEmpty ? 
            systemMonitor.runningProcesses : 
            systemMonitor.runningProcesses.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }
        
        return filtered.sorted { lhs, rhs in
            let comparison: Bool
            switch sortBy {
            case .name:
                comparison = lhs.name < rhs.name
            case .cpu:
                comparison = lhs.cpuUsage > rhs.cpuUsage
            case .memory:
                comparison = lhs.memoryUsage > rhs.memoryUsage
            }
            return sortAscending ? comparison : !comparison
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and sort controls
            HStack {
                SearchBoxView(searchText: $searchText, placeholder: "Search processes...")
                
                SortDropdownView(selectedOption: $sortBy, isAscending: $sortAscending)
                    .frame(width: 120)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Process list
            if systemMonitor.isLoading && systemMonitor.runningProcesses.isEmpty {
                VStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading processes...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredProcesses.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No processes found" : "No matching processes")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredProcesses) { process in
                            ProcessRowView(
                                process: process,
                                onForceKillRequest: { process in
                                    processToKill = process
                                    showingKillConfirmation = true
                                }
                            )
                            .environmentObject(systemMonitor)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .overlay(
            showingKillConfirmation && processToKill != nil ?
            CustomConfirmationView(
                title: "Force Kill Process",
                message: "Are you sure you want to force kill \(processToKill?.name ?? "this process")? This may cause data loss.",
                destructiveButtonText: "Force Kill",
                cancelButtonText: "Cancel",
                onConfirm: {
                    if let process = processToKill {
                        systemMonitor.forceKillProcess(process)
                    }
                    showingKillConfirmation = false
                    processToKill = nil
                },
                onCancel: {
                    showingKillConfirmation = false
                    processToKill = nil
                }
            ) : nil
        )
    }
}

struct ProcessRowView: View {
    let process: RunningProcess
    let onForceKillRequest: (RunningProcess) -> Void
    @EnvironmentObject var systemMonitor: SystemMonitor
    @State private var isHovered = false
    @State private var terminateHovered = false
    @State private var forceKillHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon
            if let icon = process.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app")
                    .frame(width: 24, height: 24)
                    .foregroundColor(.secondary)
            }
            
            // App info
            VStack(alignment: .leading, spacing: 2) {
                Text(process.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 16) {
                    Label(process.formattedCPU, systemImage: "cpu")
                    HStack(spacing: 4) {
                        Label(process.formattedMemory, systemImage: "memorychip")
                        if !process.isKillable {
                            Text("System")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(3)
                        }
                    }
                    if process.bundleIdentifier != nil {
                        Text("PID: \(process.pid)")
                            .foregroundColor(.secondary)
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 4) {
                // Terminate button
                Button(action: {
                    if process.isKillable {
                        systemMonitor.killProcess(process)
                    }
                }) {
                    Image(systemName: "stop.circle")
                        .font(.system(size: 14))
                        .foregroundColor(process.isKillable ? (terminateHovered ? .orange : .secondary) : .secondary.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .background((terminateHovered && process.isKillable) ? Color.orange.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(process.isKillable ? "Terminate process" : "Cannot terminate system process")
                .disabled(!process.isKillable)
                .onHover { hovered in
                    terminateHovered = hovered
                }
                
                // Force kill button
                Button(action: {
                    if process.isKillable {
                        onForceKillRequest(process)
                    }
                }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(process.isKillable ? (forceKillHovered ? .red : .secondary) : .secondary.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .background((forceKillHovered && process.isKillable) ? Color.red.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(process.isKillable ? "Force kill process" : "Cannot force kill system process")
                .disabled(!process.isKillable)
                .onHover { hovered in
                    forceKillHovered = hovered
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHovered ? Color.secondary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovered
            }
        }
    }
}

enum ProcessSortOption: String, CaseIterable {
    case name = "name"
    case cpu = "cpu"
    case memory = "memory"
    
    var displayName: String {
        switch self {
        case .name:
            return "Name"
        case .cpu:
            return "CPU"
        case .memory:
            return "Memory"
        }
    }
} 