//
//  AllApplicationsView.swift
//  MissionBar
//
//  Created by Ram Patra on 29/07/2025.
//

import SwiftUI

struct AllApplicationsView: View {
    @EnvironmentObject var systemMonitor: SystemMonitor
    @State private var searchText = ""
    @State private var sortBy: AppSortOption = .name
    @State private var showOnlyUserApps = false
    @State private var showingUninstallConfirmation = false
    @State private var applicationToUninstall: InstalledApplication?
    
    private var filteredApplications: [InstalledApplication] {
        var filtered = systemMonitor.installedApplications
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }
        }
        
        // Filter by user apps only
        if showOnlyUserApps {
            filtered = filtered.filter { $0.canUninstall }
        }
        
        // Sort
        return filtered.sorted { lhs, rhs in
            switch sortBy {
            case .name:
                return lhs.name < rhs.name
            case .size:
                return lhs.storageSize > rhs.storageSize
            case .status:
                if lhs.isRunning != rhs.isRunning {
                    return lhs.isRunning && !rhs.isRunning
                }
                return lhs.name < rhs.name
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filter controls
            VStack(spacing: 8) {
                HStack {
                    SearchBoxView(searchText: $searchText, placeholder: "Search applications...")
                    
                    Menu {
                        ForEach(AppSortOption.allCases, id: \.self) { option in
                            Button(action: {
                                sortBy = option
                            }) {
                                HStack {
                                    Text(option.displayName)
                                    Spacer()
                                    if sortBy == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(sortBy.displayName)
                                .font(.system(size: 12))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                        )
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 100)
                }
                
                HStack {
                    Toggle("User Apps Only", isOn: $showOnlyUserApps)
                        .font(.system(size: 12))
                        .toggleStyle(.checkbox)
                    
                    Spacer()
                    
                    Text("\(filteredApplications.count) apps")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Application list
            if systemMonitor.isLoading && systemMonitor.installedApplications.isEmpty {
                VStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading applications...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredApplications.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No applications found" : "No matching applications")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredApplications) { app in
                            ApplicationRowView(
                                application: app,
                                onUninstallRequest: { application in
                                    applicationToUninstall = application
                                    showingUninstallConfirmation = true
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
            showingUninstallConfirmation && applicationToUninstall != nil ? 
            CustomConfirmationView(
                title: "Uninstall Application",
                message: "Are you sure you want to move \(applicationToUninstall?.name ?? "this application") to the Trash? This action cannot be undone.",
                destructiveButtonText: "Move to Trash",
                cancelButtonText: "Cancel",
                onConfirm: {
                    if let app = applicationToUninstall {
                        systemMonitor.uninstallApplication(app)
                    }
                    showingUninstallConfirmation = false
                    applicationToUninstall = nil
                },
                onCancel: {
                    showingUninstallConfirmation = false
                    applicationToUninstall = nil
                }
            ) : nil
        )
    }
}

struct ApplicationRowView: View {
    let application: InstalledApplication
    let onUninstallRequest: (InstalledApplication) -> Void
    @EnvironmentObject var systemMonitor: SystemMonitor
    @State private var isHovered = false
    @State private var launchHovered = false
    @State private var uninstallHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon
            if let icon = application.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app")
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
            }
            
            // App info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(application.name)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    
                    if application.isRunning {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                    }
                }
                
                HStack(spacing: 16) {
                    if let version = application.version {
                        Text("v\(version)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Label(application.formattedSize, systemImage: "internaldrive")
                            .foregroundColor(.secondary)
                        if !application.canUninstall {
                            Text("System")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(3)
                        }
                    }
                }
                .font(.system(size: 11))
                
                Text(application.bundleIdentifier)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 4) {
                // Launch/Stop button
                Button(action: {
                    if application.isRunning {
                        systemMonitor.quitApplication(application)
                    } else {
                        NSWorkspace.shared.openApplication(at: application.path, configuration: NSWorkspace.OpenConfiguration())
                    }
                }) {
                    Image(systemName: application.isRunning ? "stop.circle" : "play.circle")
                        .font(.system(size: 14))
                        .foregroundColor(application.isRunning ? (launchHovered ? .orange : .secondary) : (launchHovered ? .green : .secondary))
                        .frame(width: 24, height: 24)
                        .background(launchHovered ? (application.isRunning ? Color.orange.opacity(0.1) : Color.green.opacity(0.1)) : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(application.isRunning ? "Quit application" : "Launch application")
                .onHover { hovered in
                    launchHovered = hovered
                }
                
                // Uninstall button
                Button(action: {
                    if application.canUninstall {
                        onUninstallRequest(application)
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(application.canUninstall ? (uninstallHovered ? .red : .secondary) : .secondary.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .background((uninstallHovered && application.canUninstall) ? Color.red.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(application.canUninstall ? "Uninstall application" : "Cannot uninstall system application")
                .disabled(!application.canUninstall)
                .onHover { hovered in
                    uninstallHovered = hovered
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isHovered ? Color.secondary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovered
            }
        }
    }
}

enum AppSortOption: String, CaseIterable {
    case name = "name"
    case size = "size"
    case status = "status"
    
    var displayName: String {
        switch self {
        case .name:
            return "Name"
        case .size:
            return "Size"
        case .status:
            return "Status"
        }
    }
} 