//
//  SecondViewController.swift
//  drawing-demo
//
//  Created by Ben Norris on 4/24/19.
//  Copyright © 2019 O.C. Tanner. All rights reserved.
//
//  Innovation project section for Cole Joplin
//

import UIKit
import AVFoundation
import Photos

class ThirdViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var drawingCanvas: DrawingImageView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var videoProgressView: UIProgressView!
   
    /// Permission to save to photo library
    var canSave: Bool = false
    
    // Value of progress segment based on audio duration
    var estimatedProgressStep: Float = 0
    
    /// Estimation of duration to processing time, highly subjective
    var estimatedProcessing: Double = 8
    var timer: Timer?
    
    // AVFoundation
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    // Image properties
    var images = [UIImage]()        // The usage on this has changed a bit, due to memory concerns
    var times = [TimeInterval]()    // Wanted to be used for exact drawing timing in video
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearFiles()
        configureAudio()
        progressLabel.text = nil
        drawingCanvas.delegate = self
        configureButtons()
        configurePhotoLibraryPermissions()
    }
    
    override func didReceiveMemoryWarning() {
        // If crap hits the fan on memory, stop the recording
        recordTapped(self)
        debugPrint("Ran out of memory, stopping recording.")
    }
    
    // MARK: - IBActions

    @IBAction func clearTapped(_ sender: Any) {
        drawingCanvas.clearCanvas(animated: true)
        showRecordingUI(false)
        clearFiles()
    }
    
    @IBAction func recordTapped(_ sender: Any) {
        if audioRecorder == nil {
            startAudioRecording()
        } else {
            showRecordingUI(true)
            finishAudioRecording(success: true)
        }
    }
    
}

extension ThirdViewController {
    
    /// Visal component setup
    func configureButtons() {
        let recordImage = imageOfRecord(imageSize: recordButton.frame.size)
        recordButton.setBackgroundImage(recordImage, for: .normal)
        recordButton.setBackgroundImage(recordImage, for: .disabled)
    }
    
    /// Make sure we obey the Photo Library gods
    func configurePhotoLibraryPermissions() {
        PHPhotoLibrary.requestAuthorization({
            (newStatus) in
            if newStatus ==  PHAuthorizationStatus.authorized {
                self.canSave = true
            }
        })
    }
    
    /// A red circle
    func drawRecord(frame: CGRect = CGRect(x: 0, y: 0, width: 23, height: 23)) {
        //// Color Declarations
        let color = UIColor(red: 0.841, green: 0.001, blue: 0.001, alpha: 1.000)
        
        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height))
        color.setFill()
        ovalPath.fill()
    }
    
    /// Returns a UIImage of a red circle
    func imageOfRecord(imageSize: CGSize = CGSize(width: 23, height: 23)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        drawRecord(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        
        let imageOfRecord = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return imageOfRecord
    }
    
    
    /// Control UI elements shown during recording
    ///
    /// - Parameter isShown: set to `true` means we see progress and text, `false` shows the record button
    func showRecordingUI(_ isShown: Bool) {
        DispatchQueue.main.async {
            self.progressLabel.text = isShown ? "Processing files..." : nil
            self.recordButton.isHidden = isShown
            self.recordButton.isEnabled = !isShown
            self.videoProgressView.isHidden = !isShown
            self.videoProgressView.progress = 0
            if !isShown {
                self.timer?.invalidate()
            }
        }
    }
    
    /// Updates the progress bar from a timer
    @objc func updateProgress() {
        DispatchQueue.main.async {
            self.videoProgressView.progress += self.estimatedProgressStep
        }
    }
    
    /// Removes all files from the documents directory
    func clearFiles() {
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            do {
                try fileManager.removeItem(at: myDocuments)
            } catch {
                return
            }
        }
    }
    
    // MARK: - Audio Methods
    
    /// Returns the preferred audio file url
    func audioFileURL() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("audio.m4a")
        return path as URL
    }
    
    /// AVFoundationaudio setup, with permissions
    func configureAudio() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { (success) in
                if success {
                    self.recordButton.isEnabled = true
                } else {
                    self.recordButton.isEnabled = false
                    self.showAudioSessionError(message: "We do not have permission to access the microphone. PLease enable it in Settings.")
                }
            }
        } catch {
            self.recordButton.isEnabled = false
            self.showAudioSessionError(message: "Something went wrong setting up the microphone.")
        }
    }
    
    /// Audio error alert
    func showAudioSessionError(message: String) {
        self.recordButton.isEnabled = false
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// Fires up an audio recorder
    func startAudioRecording() {
        let audioFilename = audioFileURL()
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            recordButton.setTitle("Stop", for: .normal)
        } catch {
            finishAudioRecording(success: false)
        }
    }
    
    /// Reacts to success or failure of audio recording
    func finishAudioRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        recordButton.setTitle("Record", for: .normal)
        
        // If things go bad, try to start over.
        if !success {
            let alertController = UIAlertController(title: "Error", message: "Something went wrong with the recording. Please try again.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Okay", style: .default) { (action:UIAlertAction) in
                self.drawingCanvas.clearCanvas(animated: true)
                self.clearFiles()
            }
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Video Methods
    
    /// Combines the audio recording with the saved drawing images.
    func createVideo() {
        
        // This is where I started, but I wasn't able to finish in time, so I used some open source. Blah!
        //        let video = VideoComposer()
        //        video.createVideo(with: images, times: times, audio: audioFileURL()) { (progress, success, error) in
        //            print("done")
        //        }
        //    }
        
        images.removeAll()  // reset array, which has changed its use and timing a few times
        showRecordingUI(true)
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent("drawing\(times.count).jpg") {
            while UIImage(contentsOfFile: filePath.path) == nil {
                // This is dangerous! Wait for the last image file to be done writing.
//                debugPrint("Not ready yet! drawing\(times.count).jpg")
            }
        }

        DispatchQueue.main.async {
            self.progressLabel.text = "Creating new video with your drawing and voice. Please be patient. This can take a few minutes."
        }
        
        // Because of memory issues of keeping all those images around, I'm saving images to file, so we don't crash.
        for i in 1...times.count {
            if let filePath = paths.first?.appendingPathComponent("drawing\(i).jpg"), let image = UIImage(contentsOfFile: filePath.path) {
                images.append(image)
            } else {
                debugPrint("Could not load drawing\(i).png")
            }
        }
//        debugPrint("We have \(images.count) images out of \(times.count) possible")
        
        // I wanted to use my own, but it was taking too long. Not happy about its linear drawing timing
        VideoGenerator.current.fileName = "drawing"
        VideoGenerator.current.shouldOptimiseImageForVideo = true
        VideoGenerator.current.videoBackgroundColor = .white
        VideoGenerator.current.videoImageWidthForMultipleVideoGeneration = 400  // bigger video means more memory
        
        // Grab our audio file, and get estimated progress numbers forit
        let audioURL = audioFileURL()
        let audioAsset = AVURLAsset.init(url: audioURL, options: nil)
        let duration = audioAsset.duration.seconds
        self.estimatedProgressStep = Float(duration) / 600
        timer = Timer.scheduledTimer(timeInterval: duration/estimatedProcessing, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        
        VideoGenerator.current.generate(withImages: images, andAudios: [audioURL], andType: .singleAudioMultipleImage, { (progress) in
//            debugPrint("progress: \(progress)")
            // This progress is really kinda useless! It's so fast it means nothing except we are almost done.
            DispatchQueue.main.async {
                self.progressLabel.text = "Finalizing video..."
            }
            
        }, success: { (sURL) in
//            debugPrint("done")
            self.images.removeAll()
            DispatchQueue.main.async {
                self.showRecordingUI(false)
                // Copies our local video into the photo library if we gave our app permission
                if let videoFilePath = paths.first?.appendingPathComponent("drawing.m4v") {
                    if self.canSave {
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoFilePath)
                        }) { saved, error in
                            if saved {
                                // What the heck, give some in your face success
                                let alertController = UIAlertController(title: "Your video was successfully saved to your photo library.", message: nil, preferredStyle: .alert)
                                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alertController.addAction(defaultAction)
                                self.present(alertController, animated: true, completion: nil)
                            }
                        }
                    } else {
                        // This user does not deserve a video, let's be honest.
                        let alertController = UIAlertController(title: "Cannot Save Video", message: "You need to give permission to your photo library in Settings.", preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(defaultAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }) { (error) in
//            debugPrint("error!")
            self.images.removeAll()
            self.showRecordingUI(false)
            let alertController = UIAlertController(title: "Error", message: "Something went wrong when creating the video. Please try again.", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension ThirdViewController: AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishAudioRecording(success: false)
        } else {
            createVideo()
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Error while recording audio \(error!.localizedDescription)")
    }
}

extension ThirdViewController: DrawingImageViewDelegate {
    
    func didHaveDrawingError() {
        DispatchQueue.main.async {
            self.finishAudioRecording(success: false)
        }
    }

    func didUpdateImages(with images: [UIImage], times: [TimeInterval]) {
        self.images = images
        self.times = times
    }

}


