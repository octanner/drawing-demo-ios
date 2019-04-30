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

class ThirdViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var drawingCanvas: DrawingImageView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    
    // AVFoundation
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var isRecortding = false
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearFiles()
        configureAudio()
    }
    
    // MARK: - IBActions

    @IBAction func clearTapped(_ sender: Any) {
        drawingCanvas.clearCanvas(animated: true)
        clearFiles()
    }
    
    @IBAction func recordTapped(_ sender: Any) {
        if audioRecorder == nil {
            startAudioRecording()
        } else {
            finishAudioRecording(success: true)
        }
    }
    
}

extension ThirdViewController {
    
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
    
    func audioFileURL() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("audio.m4a")
        return path as URL
    }
    
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
    
    func showAudioSessionError(message: String) {
        self.recordButton.isEnabled = false
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
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
}

extension ThirdViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishAudioRecording(success: false)
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
}


