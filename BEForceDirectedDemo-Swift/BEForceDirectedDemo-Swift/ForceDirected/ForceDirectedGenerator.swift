//
//  ForceDirectedGenerator.swift
//  ForceDirectedDemo-Swift
//
//  Created by yichi.wang on 16/05/2018.
//  Copyright © 2018 blueeee. All rights reserved.
//

import UIKit

// MARK: -
class ForceDirectedNode: Equatable {
    public var position: CGPoint
    public var identifier: String
    
    init(position: CGPoint, identifier: String) {
        self.position = position
        self.identifier = identifier
    }
    
    public static func == (lhs: ForceDirectedNode, rhs: ForceDirectedNode) -> Bool {
        return lhs.position.x == rhs.position.x && lhs.position.y == rhs.position.y && lhs.identifier.elementsEqual(rhs.identifier)
    }
}

// MARK: -
class ForceDirectedEdge: Equatable {
    public var source: ForceDirectedNode
    public var target: ForceDirectedNode
    
    public static func == (lhs: ForceDirectedEdge, rhs: ForceDirectedEdge) -> Bool {
        return lhs.source == rhs.source && lhs.target == rhs.target
    }
    
    init(source: ForceDirectedNode, target: ForceDirectedNode) {
        self.source = source
        self.target = target
    }
}

// MARK: -
struct ForceDirectedConfiguration {
    //节点分布范围
    public var size: CGSize
    //是否需要限制边界
    public var hasBoundary: Bool
    //迭代次数
    public var times: UInt
    //每次迭代在x和y轴上移动的最远距离
    public var iteDistance: CGFloat
    
    public static var defaultConfiguration: ForceDirectedConfiguration {
        return ForceDirectedConfiguration()
    }
    
    init() {
        self.init(size: CGSize(width: 1024, height: 1024), hasBoundary: true, times: 300, iteDistance: 3)
    }
    
    init(size: CGSize, hasBoundary: Bool, times: UInt, iteDistance: CGFloat) {
        if size.width <= 0 && size.height <= 0 {
            self.size = CGSize(width: 1024, height: 1024)
        }
        else {
            self.size = size
        }
        self.hasBoundary = hasBoundary
        self.times = times
        self.iteDistance = iteDistance
    }
}

// MARK: -
class ForceDirectedGenerator {
    public let nodes:[ForceDirectedNode]?
    public let edges:[ForceDirectedEdge]?
    public let configuration:ForceDirectedConfiguration
    
    private var constant: Float = 1000;
    
    init(nodes: [ForceDirectedNode]?, edges: [ForceDirectedEdge]?, configuration: ForceDirectedConfiguration?) {
        self.nodes = nodes;
        self.edges = edges;
        if let config = configuration {
            self.configuration = config
        }
        else {
            self.configuration = ForceDirectedConfiguration.init()
        }
    }
    
    public func forceDirected() {
        random()
        for _ in 0...self.configuration.times - 1 {
            layout()
        }
    }
    
    //随机分布
    public func random() {
        guard let nodes = self.nodes else { return }
        for node: ForceDirectedNode in nodes {
            node.position = CGPoint(x: CGFloat(arc4random() % UInt32(self.configuration.size.width)),y: CGFloat(arc4random() % UInt32(self.configuration.size.height)))
        }
        
    }
    
    //迭代
    public func layout() {
        guard let nodes = self.nodes, nodes.count != 0 else { return }
        self.constant = Float(sqrt(self.configuration.size.width * self.configuration.size.height / CGFloat(nodes.count)))
        
        var positions:[CGPoint] = [CGPoint]()
        repulsiveForce(positions: &positions)
        tractionForce(positions: &positions)
        mix(positions: positions)
    }
    
    //引力计算
    private func repulsiveForce(positions:inout [CGPoint]) {
        guard let nodes = self.nodes else { return }
        var distX: CGFloat, distY: CGFloat, dist:CGFloat
        // Coulomb's law
        let ejectFactor: CGFloat = 6;
        for v in 0...nodes.count - 1 {
            positions.append(CGPoint(x: 0.0, y: 0.0))
            for u in 0...nodes.count - 1 {
                if u != v {
                    distX = nodes[v].position.x - nodes[u].position.x
                    distY = nodes[v].position.y - nodes[u].position.y
                    dist = sqrt(distX * distX + distY * distY)
                    if dist > 0 && dist < 250 {
                        let xPosition = positions[v].x + CGFloat(distX / dist * self.constant.calculateValue() * self.constant.calculateValue() / dist * ejectFactor);
                        let yPosition = positions[v].y + CGFloat(distY / dist * self.constant.calculateValue() * self.constant.calculateValue() / dist * ejectFactor)
                        positions[v] = CGPoint(x: xPosition, y: yPosition)
                    }
                }
            }
        }
    }
    
    //斥力计算
    private func tractionForce(positions:inout [CGPoint]) {
        guard let edges = self.edges, let nodes = self.nodes else { return }
        var distX: CGFloat, distY: CGFloat, dist: CGFloat
        // Hooke's law
        let condenseFactor: CGFloat = 6;
        for e in 0...edges.count - 1 {
            let startNode = edges[e].source
            let endNode = edges[e].target
            
            guard let startIndex = nodes.index(of: startNode), let endIndex = nodes.index(of: endNode) else { return }
            
            distX = startNode.position.x - endNode.position.x
            distY = startNode.position.y - endNode.position.y
            dist = sqrt(distX * distX + distY * distY)
            
            let startX = positions[startIndex].x - distX * dist / self.constant.calculateValue() * condenseFactor
            let startY = positions[startIndex].y - distY * dist / self.constant.calculateValue() * condenseFactor
            positions[startIndex] = CGPoint(x: startX, y: startY)
            
            let endX = positions[endIndex].x + distX * dist / self.constant.calculateValue() * condenseFactor
            let endY = positions[endIndex].y + distY * dist / self.constant.calculateValue() * condenseFactor
            
            positions[endIndex] = CGPoint(x: endX, y: endY)
        }
    }
    
    //计算最终位置
    private func mix(positions: [CGPoint]) {
        guard var nodes = self.nodes else { return }
        
        let maxX = self.configuration.iteDistance
        let maxY = self.configuration.iteDistance
        
        for i in 0...nodes.count - 1 {
            let node = nodes[i]
            var dx = positions[i].x
            var dy = positions[i].y
            dx = abs(dx) > maxX && dx != 0 ? maxX * abs(dx)/dx : dx
            dy = abs(dy) > maxY && dy != 0 ? maxY * abs(dy)/dy : dy
            
            if self.configuration.hasBoundary {
                node.position = CGPoint(x: node.position.x + dx >= self.configuration.size.width || node.position.x < 0 ? node.position.x - dx : node.position.x + dx, y: node.position.y + dy >= self.configuration.size.height || node.position.y < 0 ? node.position.y - dy : node.position.y + dy)
            }
            else {
                node.position = CGPoint(x: node.position.x + dx, y: node.position.y + dy)
            }
        }
    }
}

extension Float {
    fileprivate func calculateValue() -> CGFloat {
        return CGFloat(self)
    }
}
