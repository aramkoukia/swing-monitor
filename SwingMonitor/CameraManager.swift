import AVFoundation
import SwiftUI
import Combine
import Vision

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var previousObservation: CGPoint?
    private let frameRate: Double = 30.0  // Assuming a frame rate of 30 fps
    
    @Published var speed: Double = 0.0
    @Published var currX: Double = 0.0
    @Published var currY: Double = 0.0
    @Published var prevX: Double = 0.0
    @Published var prevY: Double = 0.0
    
    
    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }

    func startSession() {
        captureSession.startRunning()
    }

    func stopSession() {
        captureSession.stopRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let currentObservation = detectObjectPosition(from: pixelBuffer)
        
        // Calculate speed based on previous observation
        if let previous = previousObservation {
            let dx = currentObservation.x - previous.x
            let dy = currentObservation.y - previous.y
            let distance = sqrt(dx * dx + dy * dy) // Calculate distance in pixels
            
            // Assuming distance is in pixels and frameRate is in frames per second
            let calculatedSpeed = (distance / UIScreen.main.bounds.width) * frameRate
            
            // Update speed on the main thread
            DispatchQueue.main.async {
                self.speed = calculatedSpeed
                self.currX = currentObservation.x
                self.currY = currentObservation.y
                self.prevX = previous.x
                self.prevY = previous.y

            }
        }
        
        // Update the previous observation for the next frame
        previousObservation = currentObservation
    }

    private func detectObjectPosition(from pixelBuffer: CVPixelBuffer) -> CGPoint {
        // Create a request to detect objects
        let request = VNCoreMLRequest(model: yourModel) { request, error in
            if let results = request.results as? [VNRecognizedObjectObservation] {
                // Process detected objects
                for observation in results {
                    // Get the bounding box of the detected object
                    let boundingBox = observation.boundingBox
                    
                    // Convert the bounding box to the coordinate system of the camera view
                    let size = CGSize(width: boundingBox.width * UIScreen.main.bounds.width,
                                      height: boundingBox.height * UIScreen.main.bounds.height)
                    let origin = CGPoint(x: boundingBox.origin.x * UIScreen.main.bounds.width,
                                         y: (1 - boundingBox.origin.y - boundingBox.height) * UIScreen.main.bounds.height)

                    // Calculate the center point of the bounding box
                    return CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
                }
            }
        }
        
        // Create the Vision request handler
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform object detection: \(error)")
        }

        // Return a default value if no object was detected
        return CGPoint(x: 0.5, y: 0.5) // Default to center if nothing detected
    }

}

