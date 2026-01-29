//
//  ContentView.swift
//  MP4-Compress
//
//  Created by spencer cap on 1/29/26.
//

/*
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
*/

//import SwiftUI
//import AppKit
//
//struct ContentView: View {
//    @EnvironmentObject var appDelegate: AppDelegate
//    @State private var statusText = "Drag MP4 files here"
//    @State private var progress: Double = 0.0
//
//    var body: some View {
//        VStack {
//            Text(statusText).padding()
//            ProgressView(value: progress).progressViewStyle(LinearProgressViewStyle()).padding()
//        }
//        .frame(width: 400, height: 100)
//        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
//            handleDrop(providers: providers)
//            return true
//        }
//        .onChange(of: appDelegate.filesToOpen) { oldValue, newValue in
//            for url in newValue where !oldValue.contains(url) {
//                compressFile(url: url)
//            }
//            if !newValue.isEmpty {
//                appDelegate.filesToOpen.removeAll()
//            }
//        }
//    }
//
//    func handleDrop(providers: [NSItemProvider]) {
//        print("handleDrop")
//        for provider in providers {
//            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
//                DispatchQueue.main.async {
//                    if let data = item as? Data,
//                       let url = URL(dataRepresentation: data, relativeTo: nil),
//                       url.pathExtension.lowercased() == "mp4" {
//                        print("handleDrop", url)
//                        compressFile(url: url)
//                    }
//                }
//            }
//        }
//    }
//
//    func compressFile(url: URL) {
//        let inputPath = url.path
//        let outputPath = url.deletingLastPathComponent().appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)-cc.mp4").path
//        
//        // Get duration using ffprobe
//        let ffprobe = Process()
//        ffprobe.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffprobe")
//        ffprobe.arguments = ["-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", inputPath]
//        let pipe = Pipe()
//        ffprobe.standardOutput = pipe
//        
//        do {
//            try ffprobe.run()
//        } catch {
//            DispatchQueue.main.async { statusText = "Error running ffprobe" }
//            return
//        }
//        ffprobe.waitUntilExit()
//        
//        guard let durationStr = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
//              let duration = Double(durationStr) else { return }
//        
//        // Run ffmpeg
//        let ffmpeg = Process()
//        ffmpeg.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
//        ffmpeg.arguments = ["-i", inputPath, "-c:v", "libx264", "-preset", "fast", "-crf", "23", "-c:a", "aac", "-b:a", "128k", "-movflags", "+faststart", outputPath]
//        let ffmpegPipe = Pipe()
//        ffmpeg.standardError = ffmpegPipe
//        
//        ffmpegPipe.fileHandleForReading.readabilityHandler = { handle in
//            if let line = String(data: handle.availableData, encoding: .utf8) {
//                for l in line.components(separatedBy: "\n") {
//                    if l.contains("time=") {
//                        if let timeStr = l.split(separator: " ").first(where: { $0.starts(with: "time=") })?.replacingOccurrences(of: "time=", with: "") {
//                            let parts = timeStr.split(separator: ":").map { Double($0) ?? 0 }
//                            if parts.count == 3 {
//                                let curSec = parts[0]*3600 + parts[1]*60 + parts[2]
//                                DispatchQueue.main.async {
//                                    progress = curSec / duration
//                                    statusText = "\(url.lastPathComponent): \(Int(progress*100))%"
//                                    NSApp.dockTile.badgeLabel = "\(Int(progress*100))%"
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        
//        do {
//            try ffmpeg.run()
//            ffmpeg.waitUntilExit()
//            DispatchQueue.main.async {
//                statusText = "Completed: \(url.lastPathComponent)"
//                progress = 1.0
//                NSApp.dockTile.badgeLabel = ""
//            }
//        } catch {
//            DispatchQueue.main.async { statusText = "Error compressing \(url.lastPathComponent)" }
//        }
//    }
//}
