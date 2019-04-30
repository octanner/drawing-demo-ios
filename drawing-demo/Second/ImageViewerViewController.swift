//
//  ImageViewerViewController.swift
//  drawing-demo
//
//  Created by Parker Rushton on 4/29/19.
//  Copyright © 2019 Ben Norris. All rights reserved.
//

import UIKit

class ImageViewerViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
    
    @IBAction func donePressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pinched(_ sender: UIPinchGestureRecognizer) {
        sender.view?.transform = sender.view!.transform.scaledBy(x: sender.scale, y: sender.scale)
        sender.scale = 1.0
    }
    
}
