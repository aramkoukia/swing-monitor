import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isRunning = false


    var body: some View {
        VStack {
            Text(String(format: "Speed: %.2f m/s", cameraManager.speed))
                .font(.largeTitle)
                .padding()
            Text(String(format: "CurrX: %.2f", cameraManager.currX))
                .font(.largeTitle)
                .padding()
            Text(String(format: "CurrY: %.2f", cameraManager.currY))
                .font(.largeTitle)
                .padding()
            Text(String(format: "prevX: %.2f", cameraManager.prevX))
                .font(.largeTitle)
                .padding()
            Text(String(format: "prevY: %.2f", cameraManager.prevY))
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                isRunning.toggle()
                isRunning ? cameraManager.startSession() : cameraManager.stopSession()
            }) {
                Text(isRunning ? "Stop" : "Start")
            }
            .padding()
        }
        .onAppear {
            cameraManager.startSession()
        }
    }
}

