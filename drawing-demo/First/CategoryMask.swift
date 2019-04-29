//
//  CategoryMask.swift
//  sketchy-racer
//
//  Created by Derik Flanary on 4/29/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation

enum CategoryMask: UInt32 {
    case car = 0b01 // 1
    case line = 0b10 // 2
    case badGuy = 0b11 // 3
}
