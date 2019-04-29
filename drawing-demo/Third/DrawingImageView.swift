//
//  DrawingImageView.swift
//  drawing-demo
//
//  Created by Cole Joplin on 4/28/19.
//  Copyright © 2019 Ben Norris. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class DrawingImageView: UIImageView {
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    let pi = CGFloat(Double.pi)
    let forceSensitivity: CGFloat = 4.0
    
//    var pencilTexture = UIColor.black
    var pencilTexture = UIColor(patternImage: UIImage(named: "PencilTexture")!)

    let defaultLineWidth : CGFloat = 60
    
    var images = [UIImage]()
    
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
        
        image = UIGraphicsGetImageFromCurrentImageContext()
        
        if image != nil {
            images.append(image!)
            // Create path.
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            if let filePath = paths.first?.appendingPathComponent("MyImageName.png") {
                do {
                    try image!.pngData()?.write(to: filePath, options: .atomic)
                } catch {
                    // Handle the error
                }
            }
        }
        UIGraphicsEndImageContext()
    }
    
    func drawStroke(context: CGContext?, touch: UITouch) {
        let previousLocation = touch.previousLocation(in: self)
        let location = touch.location(in: self)
        
        var lineWidth : CGFloat = 1.0
        
        if touch.type == .stylus {
            lineWidth = lineWidthForDrawing(context: context, touch: touch)
//            UIColor.darkGray.setStroke()
            pencilTexture.setStroke()
        }
        
        context!.setLineWidth(lineWidth)
        context!.setLineCap(.round)
        
        context?.move(to: previousLocation)
        context?.addLine(to: location)
        
        context!.strokePath()
    }
    
    func lineWidthForDrawing(context: CGContext?, touch: UITouch) -> CGFloat {
        var lineWidth = defaultLineWidth
        
        if touch.force > 0 {
            lineWidth = touch.force * forceSensitivity
        }
        
        return lineWidth
    }
    
    func clearCanvas(_ animated: Bool) {
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
}
