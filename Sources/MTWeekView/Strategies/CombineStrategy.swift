//
//  CombineStrategy.swift.swift
//  
//
//  Created by MacBook on 4/30/20.
//

import Foundation

struct CombineStretegy: CollisionStrategy, BaseCollisionStrategy {
    var nodes: [CombineNode] = []
    typealias Node = CombineNode


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
        nodes.append(Node(frame: frame))
    }
}

struct CombineNode: BaseNode {
    var frames: [CGRect] = [CGRect]()

    init(frame: CGRect) {
        frames.append(frame)
    }

    mutating func adjust() {
        let width = frames.first!.width / CGFloat(frames.count)
        for i in 0 ..< frames.count {
            frames[i].size.width = width
            frames[i].origin.x += width * CGFloat(i)
        }
    }

    mutating func add(_ frame: CGRect) -> Bool {
        for f in frames {
            if f.intersects(frame) {
                frames.append(frame)
                return true
            }
        }
        return false
    }
}
