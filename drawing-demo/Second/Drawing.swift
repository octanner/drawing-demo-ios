//
//  Drawing.swift
//  drawing-demo
//
//  Created by Parker Rushton on 4/29/19.
//  Copyright © 2019 Ben Norris. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Drawing)
class Drawing: NSManagedObject, EntityDefining {
    
    static fileprivate var fullDateAndTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
    
    @NSManaged var createdAt: Date
    @NSManaged var imageData: Data
    @NSManaged var title: String?
    
    var image: UIImage? {
        return UIImage(data: imageData)
    }
    
    var createdAtString: String {
        return Drawing.fullDateAndTimeFormatter.string(from: createdAt)
    }
    
}
