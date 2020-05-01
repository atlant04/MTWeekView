//
//  Colisions.swift
//  
//
//  Created by MacBook on 4/30/20.
//

import UIKit

struct OffsetStrategy: CollisionStrategy, BaseCollisionStrategy {
    var offset: CGFloat

    init(offset: CGFloat) {
        self.offset = offset
    }
    
    var nodes: [OffsetNode] = []
    typealias Node = OffsetNode

    mutating func apply(frames: [CGRect]) -> [CGRect] {
        for frame in frames {
            addNode(frame: frame)
        }

        for i in 0 ..< nodes.count {
            nodes[i].adjust()
        }

        let newFrames = nodes.flatMap { $0.frames }
        nodes = []
        return newFrames
    }

    mutating func addNode(frame: CGRect) {
        for i in 0 ..< nodes.count {
            if nodes[i].add(frame) {
                return
            }
        }

        //no intersections found, append new node
        nodes.append(Node(frame: frame, offset: offset))
    }
}

struct OffsetNode: BaseNode {
    var frames: [CGRect] = [CGRect]()
    var offset: CGFloat

    init(frame: CGRect, offset: CGFloat) {
        self.offset = offset
        self.frames.append(frame)
    }

    mutating func adjust() {
        for i in 0 ..< frames.count {
            frames[i].origin.x += offset * CGFloat(i)
            frames[i].size.width -= offset * CGFloat(i)
        }
    }

    mutating func add(_ frame: CGRect) -> Bool {
        for f in frames {
            if f.intersects(frame) {
                frames.append(frame)
                frames.sort { $0.minY < $1.minY }
                return true
            }
        }
        return false
    }
}

