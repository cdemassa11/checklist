import AVFoundation
import SwiftUI

@main
struct MomentPrototypeApp: App {
    init() {
        // Let the prototype's click and chime sounds play even with the ring/silent switch on.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 10 / 255, green: 16 / 255, blue: 18 / 255).ignoresSafeArea()
                PrototypeView()
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct PrototypeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PrototypeViewController {
        PrototypeViewController()
    }

    func updateUIViewController(_ controller: PrototypeViewController, context: Context) {}
}
