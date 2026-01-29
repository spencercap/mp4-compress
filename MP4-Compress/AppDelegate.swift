//
//  AppDelegate.swift
//  MP4-Compress
//
//  Created by spencer cap on 1/29/26.
//

import Foundation
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var processingQueue: [URL] = []
    private var isProcessing = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // No window to show - just dock icon
    }
    
    // Handle files dropped on dock icon
    func application(_ application: NSApplication, open urls: [URL]) {
        let mp4URLs = urls.filter { 
            let ext = $0.pathExtension.lowercased()
            return ext == "mp4" || ext == "m4v"
        }
        
        guard !mp4URLs.isEmpty else { return }
        
        processingQueue.append(contentsOf: mp4URLs)
        processNextFile()
    }
    
    private func processNextFile() {
        guard !isProcessing, let url = processingQueue.first else {
            if processingQueue.isEmpty {
                // All done
                DispatchQueue.main.async {
                    NSApp.dockTile.badgeLabel = nil
                }
            }
            return
        }
        
        isProcessing = true
        processingQueue.removeFirst()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.compressFile(url: url)
        }
    }
    
    private func compressFile(url: URL) {
        let inputPath = url.path
        let outputPath = url.deletingLastPathComponent()
            .appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)-cc.mp4").path
        
        // Get duration using ffprobe
        let ffprobe = Process()
        ffprobe.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffprobe")
        ffprobe.arguments = ["-v", "error", "-show_entries", "format=duration", 
                            "-of", "default=noprint_wrappers=1:nokey=1", inputPath]
        let probePipe = Pipe()
        ffprobe.standardOutput = probePipe
        ffprobe.standardError = FileHandle.nullDevice
        
        do {
            try ffprobe.run()
            ffprobe.waitUntilExit()
        } catch {
            finishProcessing()
            return
        }
        
        guard let durationStr = String(data: probePipe.fileHandleForReading.readDataToEndOfFile(), 
                                        encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let duration = Double(durationStr), duration > 0 else {
            finishProcessing()
            return
        }
        
        // Run ffmpeg
        let ffmpeg = Process()
        ffmpeg.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        ffmpeg.arguments = ["-y", "-i", inputPath, 
                           "-c:v", "libx264", "-preset", "fast", "-crf", "23",
                           "-c:a", "aac", "-b:a", "128k", 
                           "-movflags", "+faststart", outputPath]
        
        let ffmpegPipe = Pipe()
        ffmpeg.standardError = ffmpegPipe
        ffmpeg.standardOutput = FileHandle.nullDevice
        
        ffmpegPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
            
            // Parse time= from ffmpeg output
            if let timeRange = line.range(of: "time="),
               let endRange = line.range(of: " ", range: timeRange.upperBound..<line.endIndex) {
                let timeStr = String(line[timeRange.upperBound..<endRange.lowerBound])
                let parts = timeStr.split(separator: ":").compactMap { Double($0) }
                if parts.count == 3 {
                    let currentSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2]
                    let progress = min(Int((currentSeconds / duration) * 100), 99)
                    DispatchQueue.main.async {
                        NSApp.dockTile.badgeLabel = "\(progress)%"
                    }
                }
            }
        }
        
        do {
            try ffmpeg.run()
            ffmpeg.waitUntilExit()
            
            DispatchQueue.main.async {
                NSApp.dockTile.badgeLabel = "✓"
            }
            
            // Brief pause to show checkmark
            Thread.sleep(forTimeInterval: 1.0)
            
        } catch {
            DispatchQueue.main.async {
                NSApp.dockTile.badgeLabel = "✗"
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        ffmpegPipe.fileHandleForReading.readabilityHandler = nil
        finishProcessing()
    }
    
    private func finishProcessing() {
        isProcessing = false
        DispatchQueue.main.async {
            self.processNextFile()
        }
    }
    
    // Keep app running even with no windows
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
