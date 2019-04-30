//
//  UIView+ImageRender.swift
//  drawing-demo
//
//  Created by Parker Rushton on 4/30/19.
//  Copyright © 2019 Ben Norris. All rights reserved.
//

import UIKit

extension UIView {
    
    var asImage: UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
}
