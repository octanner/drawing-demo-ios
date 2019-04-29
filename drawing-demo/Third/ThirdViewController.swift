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

class ThirdViewController: UIViewController {
    
    @IBOutlet weak var drawingCanvas: DrawingImageView!
    
    @IBOutlet weak var clearButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func clearTapped(_ sender: Any) {
        drawingCanvas.clearCanvas(true)
    }
    
}


