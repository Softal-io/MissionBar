//
//  AboutView.swift
//  MissionBar
//
//  Created by Ram Patra on 29/07/2025.
//

import SwiftUI

// Static data outside the view to prevent recreation
private let otherApps = [
    SoftalApp(
        name: "Presentify",
        icon: "PresentifyIcon",
        appStoreURL: "https://apps.apple.com/app/apple-store/id1507246666?pt=121362679&ct=missionbar&mt=8",
        websiteURL: "https://presentifyapp.com"
    ),
    SoftalApp(
        name: "FaceScreen",
        icon: "FaceScreenIcon",
        appStoreURL: "https://apps.apple.com/app/apple-store/id6702028512?pt=121362679&ct=missionbar&mt=8",
        websiteURL: "https://facescreenapp.com"
    ),
    SoftalApp(
        name: "ToDoBar",
        icon: "ToDoBarIcon",
        appStoreURL: "https://apps.apple.com/app/apple-store/id6470928617?pt=121362679&ct=missionbar&mt=8",
        websiteURL: "https://todobarapp.com"
    ),
    SoftalApp(
        name: "SimpleFill",
        icon: "SimpleFillIcon",
        appStoreURL: "https://apps.apple.com/app/apple-store/id6743927264?pt=121362679&ct=missionbar&mt=8",
        websiteURL: "https://simplefillapp.com"
    )
]

struct AboutView: View {
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Information Section
                VStack(spacing: 16) {
                    // App Icon and Name
                    VStack(spacing: 8) {
                        Image(systemName: "app")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        
                        Text("MissionBar")
                            .font(.system(size: 24, weight: .semibold))
                    }
                    
                    // Version and Build Info
                    VStack(spacing: 4) {
                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                            Text("Version \(version)")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                            Text("Build \(build)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Copyright
                    Text("© 2025 softal.io")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding(.vertical, 16)
                
                Divider()
                
                // Other Apps Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Other Apps from Softal")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                    }
                    
                    LazyVStack(spacing: 8) {
                        ForEach(otherApps) { app in
                            AppRowView(app: app)
                        }
                    }
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct AppRowView: View {
    let app: SoftalApp
    @State private var hoveredButton: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            Image(app.icon)
                .resizable()
                .frame(width: 40, height: 40)
            
            // App Name
            Text(app.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 1) {
                // App Store Link
                if let appStoreURL = app.appStoreURL {
                    Button(action: {
                        if let url = URL(string: appStoreURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(hoveredButton == "appstore" ? Color.secondary.opacity(0.15) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredButton = isHovered ? "appstore" : nil
                        }
                    }
                    .help("View on App Store")
                }
                
                // Website Link
                if let websiteURL = app.websiteURL {
                    Button(action: {
                        if let url = URL(string: websiteURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(hoveredButton == "website" ? Color.secondary.opacity(0.15) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredButton = isHovered ? "website" : nil
                        }
                    }
                    .help("Visit Website")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    AboutView()
        .frame(width: 480, height: 600)
} 
