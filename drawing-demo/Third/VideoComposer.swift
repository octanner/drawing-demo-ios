//
//  VideoComposer.swift
//  drawing-demo
//
//  Created by Cole Joplin on 4/30/19.
//  Copyright © 2019 O. C. Tanner. All rights reserved.
//

import UIKit
import AVFoundation

public class VideoComposer: NSObject {
    
    var videoFileName = "drawingDemo"
    var videoBackgroundColor = UIColor.black
    var videoWriter: AVAssetWriter?
    let minSingleVideoDuration: Double = 3.0
    
    override init() {
        super.init()
    }
    
    func createVideo(with images: [UIImage], times: [TimeInterval], audio: URL, completion: @escaping (_ progress: Float, _ success: Bool, _ error: Error?) -> Void) {
        let dispatchQueue = DispatchQueue(label: "createVideo", qos: .background)
        guard images.count > 0 else {
            completion(0, false, nil)
            return
        }
        dispatchQueue.async {
            let videoSize = images.first!.size
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path
            let videoURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("test.m4v")
            do {
                try self.videoWriter = AVAssetWriter(outputURL: videoURL, fileType: .mp4)
            } catch {
                self.videoWriter = nil
                completion(0, false, nil)
            }
            
            if let videoWriter = self.videoWriter {
                // create the basic video settings
                let videoSettings: [String : AnyObject] = [
                    AVVideoCodecKey  : AVVideoCodecType.h264 as AnyObject,
                    AVVideoWidthKey  : videoSize.width as AnyObject,
                    AVVideoHeightKey : videoSize.height as AnyObject,
                ]
                
                /// create a video writter input
                let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
                
                /// create setting for the pixel buffer
                let sourceBufferAttributes: [String : AnyObject] = [
                    (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB) as AnyObject,
                    (kCVPixelBufferWidthKey as String): Float(videoSize.width) as AnyObject,
                    (kCVPixelBufferHeightKey as String):  Float(videoSize.height) as AnyObject,
                    (kCVPixelBufferCGImageCompatibilityKey as String): NSNumber(value: true),
                    (kCVPixelBufferCGBitmapContextCompatibilityKey as String): NSNumber(value: true)
                ]
                
                /// create pixel buffer for the input writter and the pixel buffer settings
                let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourceBufferAttributes)
                
                /// check if an input can be added to the asset
                assert(videoWriter.canAdd(videoWriterInput))
                
                /// add the input writter to the video asset
                videoWriter.add(videoWriterInput)
                
                /// check if a write session can be executed
                if videoWriter.startWriting() {
                    
                    /// if it is possible set the start time of the session (current at the begining)
                    videoWriter.startSession(atSourceTime: CMTime.zero)
                    
                    /// check that the pixel buffer pool has been created
                    assert(pixelBufferAdaptor.pixelBufferPool != nil)
                    
                    /// create/access separate queue for the generation process
                    let media_queue = DispatchQueue(label: "mediaInputQueue", attributes: [])
                    
                    /// start video generation on a separate queue
                    videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                        
                        if let frameDuration = self.durationOfAudio(audio) {
                            let numImages = images.count
                            var frameCount = 0
                            
                            var nextStartTimeForFrame: CMTime! = CMTime(seconds: 0, preferredTimescale: 1)
                            var imageForVideo: UIImage!
                            while (videoWriterInput.isReadyForMoreMediaData && frameCount < numImages - 1) {
                                imageForVideo = images[frameCount]
                                let timespan = CMTime(seconds: times[frameCount + 1], preferredTimescale: 1000000)
                                nextStartTimeForFrame = frameCount == 0 ? CMTime(seconds: 0, preferredTimescale: 1) : timespan
                                if !self.appendPixelBufferForImage(imageForVideo, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: nextStartTimeForFrame) {
                                }
                                frameCount += 1
                            }
                            videoWriterInput.markAsFinished()
                            videoWriter.endSession(atSourceTime: frameDuration)
                            videoWriter.finishWriting { () -> Void in
                                self.videoWriter = nil
                                completion(0, true, nil)
                            }
                        }
                    })
                }
            }
//            completion(0, false, nil)
        }
    }
    
    func durationOfAudio(_ url: URL) -> CMTime? {
        let audioAsset = AVURLAsset.init(url: url, options: nil)
//        var duration: CMTime?
        return audioAsset.duration
//        audioAsset.loadValuesAsynchronously(forKeys: ["duration"]) {
//            var error: NSError? = nil
//            let status = audioAsset.statusOfValue(forKey: "duration", error: &error)
//            if status == .loaded { return audioAsset.duration }
//            switch status {
//            case .loaded:
//                duration = audioAsset.duration
//                break
//            case .failed: break
//            case .cancelled: break
//            default: print("nothing")
//            }
//        }
//        return duration
    }
    
    /**
     Private method to append pixels to a pixel buffer
     
     - parameter url:                The image which pixels will be appended to the pixel buffer
     - parameter pixelBufferAdaptor: The pixel buffer to which new pixels will be added
     - parameter presentationTime:   The duration of each frame of the video
     
     - returns: True or false depending on the action execution
     */
    private func appendPixelBufferForImage(_ image: UIImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        
        /// at the beginning of the append the status is false
        var appendSucceeded = false
        
        /**
         *  The proccess of appending new pixels is put inside a autoreleasepool
         */
        autoreleasepool {
            
            // check posibilitty of creating a pixel buffer pool
            if let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                
                let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: MemoryLayout<CVPixelBuffer?>.size)
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                    kCFAllocatorDefault,
                    pixelBufferPool,
                    pixelBufferPointer
                )
                
                /// check if the memory of the pixel buffer pointer can be accessed and the creation status is 0
                if let pixelBuffer = pixelBufferPointer.pointee, status == 0 {
                    
                    // if the condition is satisfied append the image pixels to the pixel buffer pool
                    fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
                    
                    // generate new append status
                    appendSucceeded = pixelBufferAdaptor.append(
                        pixelBuffer,
                        withPresentationTime: presentationTime
                    )
                    
                    /**
                     *  Destroy the pixel buffer contains
                     */
                    pixelBufferPointer.deinitialize(count: 1)
                } else {
                    NSLog("error: Failed to allocate pixel buffer from pool")
                }
                
                /**
                 Destroy the pixel buffer pointer from the memory
                 */
                pixelBufferPointer.deallocate()
            }
        }
        
        return appendSucceeded
    }
    
    /**
     Private method to append image pixels to a pixel buffer
     
     - parameter image:       The image which pixels will be appented
     - parameter pixelBuffer: The pixel buffer (as memory) to which the image pixels will be appended
     */
    private func fillPixelBufferFromImage(_ image: UIImage, pixelBuffer: CVPixelBuffer) {
        // lock the buffer memoty so no one can access it during manipulation
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        // get the pixel data from the address in the memory
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        // create a color scheme
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        /// set the context size
        let contextSize = image.size
        
        // generate a context where the image will be drawn
        if let context = CGContext(data: pixelData, width: Int(contextSize.width), height: Int(contextSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) {
            
            var imageHeight = image.size.height
            var imageWidth = image.size.width
            
            if Int(imageHeight) > context.height {
                imageHeight = 16 * (CGFloat(context.height) / 16).rounded(.awayFromZero)
            } else if Int(imageWidth) > context.width {
                imageWidth = 16 * (CGFloat(context.width) / 16).rounded(.awayFromZero)
            }
            
//            let center = type == .single ? CGPoint.zero : CGPoint(x: (minSize.width - imageWidth) / 2, y: (minSize.height - imageHeight) / 2)
            let center = CGPoint.zero
            
            context.clear(CGRect(x: 0.0, y: 0.0, width: imageWidth, height: imageHeight))
            
            // set the context's background color
            context.setFillColor(self.videoBackgroundColor.cgColor)
            context.fill(CGRect(x: 0.0, y: 0.0, width: CGFloat(context.width), height: CGFloat(context.height)))
            
            context.concatenate(.identity)
            
            // draw the image in the context
            
            if let cgImage = image.cgImage {
                context.draw(cgImage, in: CGRect(x: center.x, y: center.y, width: imageWidth, height: imageHeight))
            }
            
            // unlock the buffer memory
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        }
    }
}
