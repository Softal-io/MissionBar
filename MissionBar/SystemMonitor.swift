//
//  SystemMonitor.swift
//  MissionBar
//
//  Created by Ram Patra on 29/07/2025.
//

import Foundation
import AppKit
import Combine

@MainActor
class SystemMonitor: ObservableObject {
    @Published var runningProcesses: [RunningProcess] = []
    @Published var installedApplications: [InstalledApplication] = []
    @Published var isLoading = false
    
    nonisolated(unsafe) private var timer: Timer?
    private let processQueue = DispatchQueue(label: "com.missionbar.process", qos: .utility)
    nonisolated(unsafe) private var previousCPUInfo: [Int32: (time: UInt64, timestamp: Date)] = [:]
    nonisolated(unsafe) private lazy var cpuCount: Double = {
        var count: natural_t = 0
        var countSize = MemoryLayout<natural_t>.size
        let result = sysctlbyname("hw.ncpu", &count, &countSize, nil, 0)
        return result == 0 ? Double(count) : 1.0
    }()
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    nonisolated func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshData()
            }
        }
        
        // Initial load
        Task { [weak self] in
            await self?.refreshData()
        }
    }
    
    nonisolated func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func refreshData() async {
        isLoading = true
        
        async let processes = fetchRunningProcesses()
        async let applications = fetchInstalledApplications()
        
        let (fetchedProcesses, fetchedApps) = await (processes, applications)
        
        await MainActor.run {
            self.runningProcesses = fetchedProcesses
            self.installedApplications = fetchedApps
            self.isLoading = false
        }
    }
    
    private func fetchRunningProcesses() async -> [RunningProcess] {
        return await withCheckedContinuation { continuation in
            processQueue.async {
                var processes: [RunningProcess] = []
                
                // Get running applications
                let runningApps = NSWorkspace.shared.runningApplications
                
                for app in runningApps {
                    guard let name = app.localizedName,
                          app.activationPolicy != .prohibited else { continue }
                    
                    let cpuUsage = self.getCPUUsage(for: app.processIdentifier)
                    let memoryUsage = self.getMemoryUsage(for: app.processIdentifier)
                    
                    let process = RunningProcess(
                        pid: app.processIdentifier,
                        name: name,
                        bundleIdentifier: app.bundleIdentifier,
                        cpuUsage: cpuUsage,
                        memoryUsage: memoryUsage,
                        icon: app.icon,
                        isKillable: app.bundleIdentifier != Bundle.main.bundleIdentifier
                    )
                    
                    processes.append(process)
                }
                
                // Clean up CPU tracking for processes that no longer exist
                let currentPIDs = Set(processes.map { $0.pid })
                self.previousCPUInfo = self.previousCPUInfo.filter { currentPIDs.contains($0.key) }
                
                continuation.resume(returning: processes.sorted { $0.name < $1.name })
            }
        }
    }
    
    private func fetchInstalledApplications() async -> [InstalledApplication] {
        let runningBundleIds = Set(runningProcesses.compactMap { $0.bundleIdentifier })
        
        return await withCheckedContinuation { continuation in
            processQueue.async { [runningBundleIds] in
                var applications: [InstalledApplication] = []
                
                // Search common application directories
                let applicationDirs = [
                    URL(fileURLWithPath: "/Applications"),
                    URL(fileURLWithPath: "/System/Applications"),
                    FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
                ]
                
                for dir in applicationDirs {
                    guard let enumerator = FileManager.default.enumerator(
                        at: dir,
                        includingPropertiesForKeys: [.isApplicationKey, .fileSizeKey],
                        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
                    ) else { continue }
                    
                    for case let url as URL in enumerator {
                        if url.pathExtension == "app" {
                            if let app = self.createInstalledApplication(from: url, runningBundleIds: runningBundleIds) {
                                applications.append(app)
                            }
                        }
                    }
                }
                
                continuation.resume(returning: applications.sorted { $0.name < $1.name })
            }
        }
    }
    
    nonisolated private func createInstalledApplication(from url: URL, runningBundleIds: Set<String>) -> InstalledApplication? {
        guard let bundle = Bundle(url: url),
              let bundleId = bundle.bundleIdentifier,
              let name = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
                        bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                        bundle.infoDictionary?["CFBundleName"] as? String else {
            return nil
        }
        
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        let storageSize = getDirectorySize(url: url)
        let isRunning = runningBundleIds.contains(bundleId)
        let canUninstall = !url.path.hasPrefix("/System/") && !url.path.hasPrefix("/usr/")
        
        return InstalledApplication(
            name: name,
            bundleIdentifier: bundleId,
            version: version,
            path: url,
            icon: icon,
            storageSize: storageSize,
            isRunning: isRunning,
            canUninstall: canUninstall
        )
    }
    
    nonisolated private func getCPUUsage(for pid: Int32) -> Double {
        var info = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.size
        
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(size)) == size else {
            return 0.0
        }
        
        let currentTime = info.pti_total_user + info.pti_total_system
        let currentTimestamp = Date()
        
        // Use cached CPU count
        let numCPUs = cpuCount
        
        // For first measurement, return 0
        guard let previousInfo = previousCPUInfo[pid] else {
            previousCPUInfo[pid] = (time: currentTime, timestamp: currentTimestamp)
            return 0.0
        }
        
        let deltaTime = currentTimestamp.timeIntervalSince(previousInfo.timestamp)
        let deltaCPUTime = currentTime > previousInfo.time ? currentTime - previousInfo.time : 0
        
        // Update stored values
        previousCPUInfo[pid] = (time: currentTime, timestamp: currentTimestamp)
        
        // Avoid division by zero
        guard deltaTime > 0 else { return 0.0 }
        
        // Calculate CPU percentage
        // deltaCPUTime is in nanoseconds, deltaTime is in seconds
        let cpuPercent = (Double(deltaCPUTime) / 1_000_000_000.0) / deltaTime * 100.0 / numCPUs
        
        return max(0.0, min(100.0, cpuPercent))
    }
    
    nonisolated private func getMemoryUsage(for pid: Int32) -> UInt64 {
        // Get comprehensive task and memory information
        var taskAllInfo = proc_taskallinfo()
        let allInfoSize = MemoryLayout<proc_taskallinfo>.size
        
        if proc_pidinfo(pid, PROC_PIDTASKALLINFO, 0, &taskAllInfo, Int32(allInfoSize)) == allInfoSize {
            let taskInfo = taskAllInfo.ptinfo
            
            // Activity Monitor's "Memory" includes:
            // - Physical memory (resident)  
            // - Some allocated virtual memory
            // - Compressed memory
            // This is a closer approximation to Activity Monitor's calculation
            let residentSize = taskInfo.pti_resident_size
            let virtualSize = taskInfo.pti_virtual_size
            
            // Use a heuristic that's closer to Activity Monitor:
            // Resident memory + a portion of virtual memory that likely represents
            // allocated but not necessarily resident pages
            if virtualSize > residentSize {
                let allocatedVirtual = virtualSize - residentSize
                // Add a fraction of the allocated virtual memory (empirically determined)
                let additionalMemory = min(allocatedVirtual / 8, residentSize / 4)
                return residentSize + additionalMemory
            }
            
            return residentSize
        }
        
        // Fallback to basic proc_taskinfo
        var taskInfo = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.size
        
        if proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, Int32(size)) == size {
            return taskInfo.pti_resident_size
        }
        
        return 0
    }
    
    nonisolated private func getDirectorySize(url: URL) -> UInt64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]
        ) else { return 0 }
        
        var totalSize: UInt64 = 0
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                if !resourceValues.isDirectory! {
                    totalSize += UInt64(resourceValues.fileSize ?? 0)
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    func killProcess(_ process: RunningProcess) {
        guard process.isKillable else { return }
        
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-TERM", String(process.pid)]
        
        do {
            try task.run()
        } catch {
            print("Failed to kill process: \(error)")
        }
    }
    
    func forceKillProcess(_ process: RunningProcess) {
        guard process.isKillable else { return }
        
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-KILL", String(process.pid)]
        
        do {
            try task.run()
        } catch {
            print("Failed to force kill process: \(error)")
        }
    }
    
    func uninstallApplication(_ app: InstalledApplication) {
        guard app.canUninstall else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try FileManager.default.trashItem(at: app.path, resultingItemURL: nil)
                DispatchQueue.main.async {
                    self.installedApplications.removeAll { $0.id == app.id }
                }
            } catch {
                print("Failed to uninstall application: \(error)")
            }
        }
    }
} 