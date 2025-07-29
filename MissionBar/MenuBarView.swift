//
//  MenuBarView.swift
//  MissionBar
//
//  Created by Ram Patra on 29/07/2025.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var systemMonitor: SystemMonitor
    @State private var selectedTab: AppTab = .running
    @State private var hoveredTab: AppTab?
    @State private var hoveredRefresh = false
    @State private var hoveredQuit = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12))
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab ? 
                            Color.accentColor : 
                            (hoveredTab == tab ? Color.secondary.opacity(0.1) : Color.clear),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredTab = isHovered ? tab : nil
                        }
                    }
                    .help(tab.rawValue)
                }
                
                Spacer()
                
                // Refresh button
                Button(action: {
                    Task {
                        await systemMonitor.refreshData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(hoveredRefresh ? Color.secondary.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .disabled(systemMonitor.isLoading)
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hoveredRefresh = isHovered
                    }
                }
                .help("Refresh data")
                
                // Quit button
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(hoveredQuit ? Color.secondary.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hoveredQuit = isHovered
                    }
                }
                .help("Quit MissionBar")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            Group {
                switch selectedTab {
                case .running:
                    RunningProcessesView()
                case .all:
                    AllApplicationsView()
                }
            }
            .environmentObject(systemMonitor)
        }
        .frame(width: 480, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
} 