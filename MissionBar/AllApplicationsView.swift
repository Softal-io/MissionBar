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
                            ApplicationRowView(application: app)
                                .environmentObject(systemMonitor)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct ApplicationRowView: View {
    let application: InstalledApplication
    @EnvironmentObject var systemMonitor: SystemMonitor
    @State private var showingUninstallConfirmation = false
    @State private var isHovered = false
    @State private var showInFinderHovered = false
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
                // Show in Finder button
                Button(action: {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: application.path.path)
                }) {
                    Image(systemName: "folder")
                        .font(.system(size: 14))
                        .foregroundColor(showInFinderHovered ? .blue : .secondary)
                        .frame(width: 24, height: 24)
                        .background(showInFinderHovered ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Show in Finder")
                .onHover { hovered in
                    showInFinderHovered = hovered
                }
                
                // Launch button (if not running)
                if !application.isRunning {
                    Button(action: {
                        NSWorkspace.shared.openApplication(at: application.path, configuration: NSWorkspace.OpenConfiguration())
                    }) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 14))
                            .foregroundColor(launchHovered ? .green : .secondary)
                            .frame(width: 24, height: 24)
                            .background(launchHovered ? Color.green.opacity(0.1) : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("Launch application")
                    .onHover { hovered in
                        launchHovered = hovered
                    }
                }
                
                // Uninstall button
                if application.canUninstall {
                    Button(action: {
                        showingUninstallConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(uninstallHovered ? .red : .secondary)
                            .frame(width: 24, height: 24)
                            .background(uninstallHovered ? Color.red.opacity(0.1) : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("Uninstall application")
                    .onHover { hovered in
                        uninstallHovered = hovered
                    }
                    .confirmationDialog(
                        "Uninstall Application",
                        isPresented: $showingUninstallConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Move to Trash", role: .destructive) {
                            systemMonitor.uninstallApplication(application)
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Are you sure you want to move \(application.name) to the Trash? This action cannot be undone.")
                    }
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