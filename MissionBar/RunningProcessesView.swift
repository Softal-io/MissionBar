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
    
    private var filteredProcesses: [RunningProcess] {
        let filtered = searchText.isEmpty ? 
            systemMonitor.runningProcesses : 
            systemMonitor.runningProcesses.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }
        
        return filtered.sorted { lhs, rhs in
            switch sortBy {
            case .name:
                return lhs.name < rhs.name
            case .cpu:
                return lhs.cpuUsage > rhs.cpuUsage
            case .memory:
                return lhs.memoryUsage > rhs.memoryUsage
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and sort controls
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    
                    TextField("Search processes...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
                Menu {
                    ForEach(ProcessSortOption.allCases, id: \.self) { option in
                        Button(option.displayName) {
                            sortBy = option
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortBy.displayName)
                            .font(.system(size: 12))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 80)
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
                            ProcessRowView(process: process)
                                .environmentObject(systemMonitor)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct ProcessRowView: View {
    let process: RunningProcess
    @EnvironmentObject var systemMonitor: SystemMonitor
    @State private var showingKillConfirmation = false
    
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
                    Label(process.formattedMemory, systemImage: "memorychip")
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
            HStack(spacing: 6) {
                if process.isKillable {
                    // Terminate button
                    Button(action: {
                        systemMonitor.killProcess(process)
                    }) {
                        Image(systemName: "stop.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .help("Terminate process")
                    
                    // Force kill button
                    Button(action: {
                        showingKillConfirmation = true
                    }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Force kill process")
                    .confirmationDialog(
                        "Force Kill Process",
                        isPresented: $showingKillConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Force Kill", role: .destructive) {
                            systemMonitor.forceKillProcess(process)
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Are you sure you want to force kill \(process.name)? This may cause data loss.")
                    }
                } else {
                    Text("System")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered in
            // Add subtle hover effect
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