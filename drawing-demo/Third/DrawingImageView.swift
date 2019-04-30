//
//  DrawingImageView.swift
//  drawing-demo
//
//  Created by Cole Joplin on 4/28/19.
//  Copyright © 2019 O. C. Tanner. All rights reserved.
//

import Foundation
import UIKit

protocol DrawingImageViewDelegate {
    func didHaveDrawingError()
}

/// Draws an image
class DrawingImageView: UIImageView {
    
    // MARK: - Properties
    
    var delegate: DrawingImageViewDelegate?
    
    // Drawing
    let pi = CGFloat(Double.pi)
    let forceSensitivity: CGFloat = 4.0
    var pencilTexture = UIColor(patternImage: UIImage(named: "PencilTexture")!)
    let defaultLineWidth : CGFloat = 10
    
    // Image properties
    var images = [UIImage]()
    
    override func awakeFromNib() {
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 2.0
    }
    
    // MARK: - Events
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        image?.draw(in: bounds)
        var touches = [UITouch]()
        
        if let coalescedTouches = event?.coalescedTouches(for: touch) {
            touches = coalescedTouches
        } else {
            touches.append(touch)
        }
        
        for touch in touches {
            drawStroke(context: context, touch: touch)
        }
        
        //TODO: Add predictive for better drawing performance
        
        image = UIGraphicsGetImageFromCurrentImageContext()
        
        if let drawnImage = image {
            images.append(drawnImage)
            writeImageFile(imageToWrite: drawnImage, number: images.count)
        }
        UIGraphicsEndImageContext()
    }
    
    // MARK: - Drawing Methods
    
    func drawStroke(context: CGContext?, touch: UITouch) {
        let previousLocation = touch.previousLocation(in: self)
        let location = touch.location(in: self)

        if let context = context {
            let lineWidth = lineWidthForDrawing(context: context, touch: touch)
            if touch.type == .stylus {
                pencilTexture.setStroke()
            }
            context.setLineWidth(lineWidth)
            context.setLineCap(.round)
            context.move(to: previousLocation)
            context.addLine(to: location)
            context.strokePath()
        }
    }
    
    func lineWidthForDrawing(context: CGContext?, touch: UITouch) -> CGFloat {
        //TODO: Add azimuth
//        var lineWidth = defaultLineWidth
//        if touch.force > 0 {
//            lineWidth = touch.force * forceSensitivity
//        }
//        return lineWidth
        return defaultLineWidth
    }
    
    func clearCanvas(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.5, animations: {
            }, completion: { finished in
                self.image = nil
            })
        } else {
            image = nil
        }
        images.removeAll()
    }
    
    // MARK: - File Methods
    
    func writeImageFile(imageToWrite: UIImage, number: Int) {
        DispatchQueue.global(qos: .background).async {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            if let filePath = paths.first?.appendingPathComponent("drawing\(number).png") {
                do {
                    try imageToWrite.pngData()?.write(to: filePath, options: .atomic)
                } catch {
                    self.delegate?.didHaveDrawingError()
                }
            }
        }
    }
    
}
