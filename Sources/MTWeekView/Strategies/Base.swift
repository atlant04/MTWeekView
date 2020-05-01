//
//  File.swift
//  
//
//  Created by MacBook on 4/30/20.
//

import UIKit

protocol CollisionStrategy {
    mutating func apply(frames: [CGRect]) -> [CGRect]
}

protocol BaseCollisionStrategy {
    associatedtype Node: BaseNode
    var nodes: [Node] { get set }
    mutating func addNode(frame: CGRect)
}

protocol BaseNode {
    var frames: [CGRect] { get set }
    mutating func adjust()
    mutating func add(_ frame: CGRect) -> Bool
}
