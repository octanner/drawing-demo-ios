//
//  CoreDataManager.swift
//  drawing-demo
//
//  Created by Parker Rushton on 4/29/19.
//  Copyright © 2019 Ben Norris. All rights reserved.
//

import Foundation
import CoreData

struct CoreDataManager {
    
    static let shared = CoreDataManager()
    
    private let context = CoreDataStack.shared.persistentContainer.viewContext
    
    @discardableResult func addDrawing(title: String? = nil, data: Data) -> Drawing? {
        let drawing = NSEntityDescription.insertNewObject(forEntityName: Drawing.entityName, into: context) as! Drawing
        drawing.title = title
        drawing.createdAt = Date()
        drawing.imageData = data
        drawing.save()
        return drawing
    }
    
    func allDrawings() -> [Drawing] {
        let request = NSFetchRequest<Drawing>(entityName: String(describing: Drawing.self))
        do {
            return try context.fetch(request)
        } catch {
            dump(error)
        }
        return []
    }
    
}
