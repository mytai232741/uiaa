import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var logs: [String] = []
    @State private var alertMessage: String?
    @State private var leftAppAt: Date?

    private var alertShown: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                if logs.isEmpty {
                    Text("Chưa có sự kiện nào.\nHãy thử chụp màn hình hoặc thoát app rồi mở lại.")
                        .foregroundColor(.secondary)
                }
                ForEach(logs, id: \.self) { Text($0) }
            }
            .navigationTitle("ScreenGuard")
        }
        // Phát hiện chụp màn hình (iOS báo SAU khi đã chụp)
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            report("📸 Bạn vừa chụp màn hình!")
        }
        // Phát hiện quay màn hình / mirroring
        .onReceive(NotificationCenter.default.publisher(
            for: UIScreen.capturedDidChangeNotification)) { _ in
            if UIScreen.main.isCaptured {
                report("🎥 Màn hình đang được quay hoặc chiếu ra ngoài!")
            }
        }
        // Phát hiện thoát khỏi app (vào nền) và quay lại
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                leftAppAt = Date()
            case .active:
                if let t = leftAppAt {
                    let secs = Int(Date().timeIntervalSince(t))
                    leftAppAt = nil
                    report("🚪 Bạn đã thoát khỏi ứng dụng khoảng \(secs) giây.")
                }
            default:
                break
            }
        }
        .alert("Cảnh báo", isPresented: alertShown) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func report(_ message: String) {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        logs.insert("[\(f.string(from: Date()))] \(message)", at: 0)
        alertMessage = message
    }
}
