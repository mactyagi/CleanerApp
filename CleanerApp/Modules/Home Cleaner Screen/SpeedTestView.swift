//
//  SpeedTestView.swift
//  CleanerApp
//
//  Network Speed Test — Dual Ring Gauge design
//

import SwiftUI

// MARK: - Speed Test State
enum SpeedTestPhase: Equatable {
    case idle
    case testingDownload
    case downloadComplete
    case testingUpload
    case completed
}

// MARK: - Speed Test ViewModel
class SpeedTestViewModel: NSObject, ObservableObject, URLSessionDataDelegate {
    @Published var phase: SpeedTestPhase = .idle
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var ping: Int = 0
    @Published var currentSpeed: Double = 0
    @Published var liveDownloadSpeed: Double = 0
    @Published var liveUploadSpeed: Double = 0

    private var totalBytesReceived: Int64 = 0
    private var testStartTime: CFAbsoluteTime = 0
    private var speedSamples: [Double] = []
    private var updateTimer: Timer?
    private var downloadSession: URLSession?
    private var downloadTask: URLSessionDataTask?

    // Stability config
    private let minDuration: Double = 10.0
    private let maxDuration: Double = 10.0
    private let stableCount: Int = 6
    private let stableThreshold: Double = 0.10

    override init() { super.init() }

    // MARK: - Public
    func startTest() {
        phase = .testingDownload
        downloadSpeed = 0
        uploadSpeed = 0
        ping = 0
        currentSpeed = 0
        liveDownloadSpeed = 0
        liveUploadSpeed = 0

        measurePing { [weak self] in
            self?.startDownloadTest()
        }
    }

    // MARK: - Ping
    private func measurePing(completion: @escaping () -> Void) {
        let url = URL(string: "https://speed.cloudflare.com/__down?bytes=1")!
        let start = CFAbsoluteTimeGetCurrent()
        URLSession.shared.dataTask(with: url) { [weak self] _, _, _ in
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            DispatchQueue.main.async {
                self?.ping = max(1, Int(elapsed * 1000))
                completion()
            }
        }.resume()
    }

    // MARK: - Download Test (streaming with delegate)
    private func startDownloadTest() {
        totalBytesReceived = 0
        testStartTime = CFAbsoluteTimeGetCurrent()
        speedSamples = []

        // Create a fresh session with self as delegate
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForResource = 60
        downloadSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)

        let url = URL(string: "https://speed.cloudflare.com/__down?bytes=50000000")! // 50MB
        downloadTask = downloadSession?.dataTask(with: url)
        downloadTask?.resume()

        // Timer to compute speed from accumulated bytes
        startUpdateTimer()
    }

    // MARK: URLSessionDataDelegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        totalBytesReceived += Int64(data.count)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Download finished (naturally or cancelled) — finalize
        if phase == .testingDownload {
            finalizeDownload()
        }
    }

    // MARK: - Timer-based speed computation
    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.computeCurrentSpeed()
        }
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func computeCurrentSpeed() {
        let elapsed = CFAbsoluteTimeGetCurrent() - testStartTime
        guard elapsed > 0 else { return }

        if phase == .testingDownload {
            let mbps = (Double(totalBytesReceived) * 8) / (elapsed * 1_000_000)
            speedSamples.append(mbps)
            withAnimation(.linear(duration: 0.25)) {
                currentSpeed = mbps
                liveDownloadSpeed = mbps
            }

            if isStable(elapsed: elapsed) {
                finalizeDownload()
            }
        } else if phase == .testingUpload {
            // Upload speed computed from didSendBodyData — timer just checks stability
            if isStable(elapsed: elapsed) {
                finalizeUpload()
            }
        }
    }

    private func isStable(elapsed: Double) -> Bool {
        if elapsed >= maxDuration { return true }
        guard elapsed >= minDuration, speedSamples.count >= stableCount else { return false }

        let recent = Array(speedSamples.suffix(stableCount))
        let mean = recent.reduce(0, +) / Double(recent.count)
        guard mean > 0 else { return false }

        let variance = recent.reduce(0) { $0 + pow($1 - mean, 2) } / Double(recent.count)
        let cv = sqrt(variance) / mean
        return cv < stableThreshold
    }

    // MARK: - Finalize Download
    private func finalizeDownload() {
        guard phase == .testingDownload else { return }

        stopUpdateTimer()
        downloadTask?.cancel()
        downloadSession?.invalidateAndCancel()
        downloadSession = nil

        let finalSpeed = speedSamples.last ?? currentSpeed
        downloadSpeed = finalSpeed
        liveDownloadSpeed = finalSpeed
        currentSpeed = finalSpeed
        phase = .downloadComplete

        // 1 sec pause then start upload
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                self.currentSpeed = 0
                self.liveUploadSpeed = 0
            }
            self.phase = .testingUpload
            self.startUploadTest()
        }
    }

    // MARK: - Upload Test (completion-handler based with progress)
    private func startUploadTest() {
        testStartTime = CFAbsoluteTimeGetCurrent()
        speedSamples = []

        let url = URL(string: "https://speed.cloudflare.com/__up")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let payload = Data(count: 10_000_000) // 10MB

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForResource = 60
        let uploadSession = URLSession(configuration: sessionConfig)

        let task = uploadSession.uploadTask(with: request, from: payload) { [weak self] _, _, error in
            DispatchQueue.main.async {
                self?.finalizeUpload()
            }
        }

        // Observe upload progress via KVO
        let observer = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                guard let self = self, self.phase == .testingUpload else { return }
                let elapsed = CFAbsoluteTimeGetCurrent() - self.testStartTime
                guard elapsed > 0 else { return }

                let bytesSent = Double(payload.count) * progress.fractionCompleted
                let mbps = (bytesSent * 8) / (elapsed * 1_000_000)

                self.speedSamples.append(mbps)
                withAnimation(.linear(duration: 0.15)) {
                    self.currentSpeed = mbps
                    self.liveUploadSpeed = mbps
                }
            }
        }

        // Store observer to keep it alive
        objc_setAssociatedObject(task, "progressObserver", observer, .OBJC_ASSOCIATION_RETAIN)
        task.resume()

        startUpdateTimer()
    }

    // MARK: - Finalize Upload
    private func finalizeUpload() {
        guard phase == .testingUpload else { return }

        stopUpdateTimer()

        let finalSpeed = speedSamples.last ?? currentSpeed
        uploadSpeed = finalSpeed
        liveUploadSpeed = finalSpeed
        currentSpeed = finalSpeed
        phase = .completed
    }

    // MARK: - Computed
    var statusText: String {
        switch phase {
        case .idle: return "Tap to start"
        case .testingDownload: return "Testing Download..."
        case .downloadComplete: return "Download Complete"
        case .testingUpload: return "Testing Upload..."
        case .completed: return "Test Complete"
        }
    }

    var isTesting: Bool { phase == .testingDownload || phase == .testingUpload || phase == .downloadComplete }
}

// MARK: - Speed Test View
struct SpeedTestView: View {
    @StateObject private var viewModel = SpeedTestViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status
                Text(viewModel.statusText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.teal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)

                // Dual Rings
                HStack(spacing: 28) {
                    ringGauge(
                        speed: viewModel.liveDownloadSpeed,
                        maxValue: 100,
                        label: "Download",
                        color: .blue,
                        isActive: viewModel.phase == .testingDownload
                    )

                    ringGauge(
                        speed: viewModel.liveUploadSpeed,
                        maxValue: 100,
                        label: "Upload",
                        color: .green,
                        isActive: viewModel.phase == .testingUpload
                    )
                }
                .padding(.vertical, 8)

                // Results Card
                if viewModel.downloadSpeed > 0 {
                    infoCard {
                        resultRow(icon: "arrow.down.circle.fill", label: "Download",
                                  value: String(format: "%.1f Mbps", viewModel.downloadSpeed), color: .blue)
                        if viewModel.phase == .completed {
                            Divider().padding(.leading, 46)
                            resultRow(icon: "arrow.up.circle.fill", label: "Upload",
                                      value: String(format: "%.1f Mbps", viewModel.uploadSpeed), color: .green)
                        }
                        Divider().padding(.leading, 46)
                        resultRow(icon: "timer", label: "Ping",
                                  value: "\(viewModel.ping) ms", color: .orange)
                    }
                    .padding(.horizontal)
                }

                // Start Button
                Button {
                    viewModel.startTest()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isTesting {
                            ProgressView().tint(.white).scaleEffect(0.9)
                        } else {
                            Image(systemName: viewModel.phase == .completed ? "arrow.clockwise" : "play.fill")
                        }
                        Text(viewModel.isTesting ? "Testing..." : (viewModel.phase == .completed ? "Test Again" : "Start Test"))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.teal)
                            .shadow(color: .teal.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isTesting)
                .opacity(viewModel.isTesting ? 0.7 : 1)
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
        }
        .background(Color("lightBlueDarkGreyColor"))
        .navigationTitle("Speed Test")
        .onAppear { if viewModel.phase == .idle { viewModel.startTest() } }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Ring Gauge
    private func ringGauge(speed: Double, maxValue: Double, label: String, color: Color, isActive: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 14)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: min(speed / maxValue, 1.0))
                    .stroke(
                        AngularGradient(colors: [color.opacity(0.6), color], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: speed)

                Circle()
                    .stroke(color.opacity(isActive ? 0.2 : 0), lineWidth: 1.5)
                    .frame(width: 160, height: 160)
                    .scaleEffect(isActive ? 1.05 : 1.0)
                    .opacity(isActive ? 0.5 : 0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isActive)

                VStack(spacing: 2) {
                    Text(String(format: "%.1f", speed))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .frame(width: 100)
                    Text("Mbps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isActive ? color : .secondary)
        }
    }

    // MARK: - Reusable
    private func infoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding()
            .background(Color("offWhiteAndGrayColor"))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func resultRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            }
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold())
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SpeedTestView()
    }
}
