// The Capture Inbox's photo path: image bytes in, recognized text out.
// Apple Vision (VNRecognizeTextRequest) runs entirely on this device —
// the receipt/screenshot never leaves it. The Dart side feeds the text
// through the same deterministic parser as typed input, so this bridge
// stays a pure OCR function with no app knowledge.

import Flutter
import Foundation
import UIKit

#if canImport(Vision)
import Vision
#endif

enum VisionBridge {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "lifeassist/vision", binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { call, result in
            handle(call, result)
        }
    }

    private static func handle(
        _ call: FlutterMethodCall, _ result: @escaping FlutterResult
    ) {
        switch call.method {
        case "recognizeText":
            guard let data = call.arguments as? FlutterStandardTypedData else {
                result(FlutterError(
                    code: "bad-args", message: "expected image bytes",
                    details: nil))
                return
            }
            recognizeText(in: data.data, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func recognizeText(
        in data: Data, result: @escaping FlutterResult
    ) {
        #if canImport(Vision)
        guard let image = UIImage(data: data), let cgImage = image.cgImage
        else {
            result(FlutterError(
                code: "bad-image", message: "could not decode image",
                details: nil))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    DispatchQueue.main.async {
                        result(FlutterError(
                            code: "vision",
                            message: error.localizedDescription,
                            details: nil))
                    }
                    return
                }
                let observations =
                    (request.results as? [VNRecognizedTextObservation]) ?? []
                // Top candidate per line, in reading order — good enough
                // for receipts and stat screenshots.
                let lines = observations.compactMap {
                    $0.topCandidates(1).first?.string
                }
                DispatchQueue.main.async {
                    result(lines.joined(separator: "\n"))
                }
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "vision",
                        message: error.localizedDescription,
                        details: nil))
                }
            }
        }
        #else
        result(FlutterMethodNotImplemented)
        #endif
    }
}
