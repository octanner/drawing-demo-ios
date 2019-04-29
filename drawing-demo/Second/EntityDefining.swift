//
//  EntityDefining.swift
//  drawing-demo
//
//  Created by Parker Rushton on 4/29/19.
//  Copyright © 2019 Ben Norris. All rights reserved.
//

import Foundation

protocol EntityDefining { }

extension EntityDefining {
    static var entityName: String {
        return String(describing: Self.self)
    }
    
    func save() {
        CoreDataStack.shared.saveContext()
    }
    
}
