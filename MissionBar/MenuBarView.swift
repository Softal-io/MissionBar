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
                            Color.accentColor : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    }
                    .buttonStyle(.plain)
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
                }
                .buttonStyle(.plain)
                .disabled(systemMonitor.isLoading)
                
                // Quit button
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
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