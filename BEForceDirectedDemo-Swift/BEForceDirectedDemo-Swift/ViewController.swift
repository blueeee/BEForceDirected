//
//  ViewController.swift
//  BEForceDirectedDemo-Swift
//
//  Created by yichi.wang on 16/05/2018.
//  Copyright © 2018 blueeee. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {
    
    private static let contentWidth: CGFloat = 2000
    private static let contentHeight: CGFloat = 2000
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var forceDirectedGenerator: ForceDirectedGenerator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        DispatchQueue.global().async {
            self.initData()
            self.forceDirected()
            DispatchQueue.main.async {
                self.drawNodesAndEdges()
            }
        }
    }
    
    private func initUI() {
        scrollView = UIScrollView(frame:self.view.bounds)
        scrollView.contentSize = CGSize(width: ViewController.contentWidth, height: ViewController.contentHeight)
        scrollView.contentOffset = CGPoint(x: (scrollView.contentSize.width - scrollView.bounds.size.width)/2, y: (scrollView.contentSize.height - scrollView.bounds.size.height)/2)
        scrollView.minimumZoomScale = 0.1
        scrollView.delegate = self
        self.view.addSubview(scrollView)
        
        contentView = UIView(frame: CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height))
        self.scrollView.addSubview(contentView)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }
    
    private func initData() {
        guard let path = Bundle.main.path(forResource: "data", ofType: "json") else { return }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
        guard let dataAny = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else { return }
        guard let dataDictionary = dataAny as? [String : Any] else { return }
        guard let nodesAny = dataDictionary["node"], let edgesAny = dataDictionary["edge"] else { return }

        if let nodes = nodesAny as? [[String : String]], let edges = edgesAny as? [[String : Int]] {
            var transferNodes: [ForceDirectedNode]? = []
            var transferEdges: [ForceDirectedEdge]? = []
            nodes.forEach {
                guard let name = $0["name"] else { return }
                transferNodes!.append(ForceDirectedNode(position: CGPoint(x: 0, y: 0), identifier: name));
            }
            
            edges.forEach {
                guard let source = $0["source"], let target = $0["target"] else { return }
                transferEdges!.append(ForceDirectedEdge(source: transferNodes![source - 1] , target: transferNodes![target - 1]));
            }
            
            forceDirectedGenerator =  ForceDirectedGenerator (nodes: transferNodes, edges: transferEdges, configuration: ForceDirectedConfiguration(size: CGSize(width: 400, height: 400), hasBoundary: false, times: 400, iteDistance: 4))
        }
    }
    
    private func forceDirected() {
        if let forceDirectedGenerator = self.forceDirectedGenerator {
            forceDirectedGenerator.forceDirected()
        }
        
    }
    
    private func drawNodesAndEdges() {
        guard let forceDirectedGenerator = self.forceDirectedGenerator else { return }
        let nodeLength = 8;
        let widthOffset = (ViewController.contentWidth - forceDirectedGenerator.configuration.size.width)/2
        let heightOffset = (ViewController.contentHeight - forceDirectedGenerator.configuration.size.height)/2
        
        if let nodes = forceDirectedGenerator.nodes {
            nodes.forEach {
                let position = $0.position
                let layer = NodeLayer()
                layer.bounds = CGRect(x: 0, y: 0, width: nodeLength, height: nodeLength)
                layer.position = CGPoint(x: position.x + widthOffset, y: position.y + heightOffset)
                layer.randomBackgroundColor()
                layer.cornerRadius = CGFloat(nodeLength / 2)
                contentView.layer.addSublayer(layer)
                layer.springAnimation()
            }
        }
        
        if let edges = forceDirectedGenerator.edges {
            let lineLayer = CAShapeLayer()
            lineLayer.bounds = contentView.bounds
            lineLayer.position = self.contentView.center
            lineLayer.strokeColor = UIColor.gray.cgColor
            lineLayer.lineWidth = 0.6
            
            let linePath = UIBezierPath()
            edges.forEach {
                linePath.move(to: CGPoint(x: $0.source.position.x + widthOffset, y: $0.source.position.y + heightOffset))
                linePath.addLine(to: CGPoint(x: $0.target.position.x + widthOffset, y: $0.target.position.y + heightOffset))
            }
            
            UIGraphicsBeginImageContext(lineLayer.bounds.size)
            linePath.stroke()
            UIGraphicsEndImageContext()
            lineLayer.path = linePath.cgPath
            contentView.layer.addSublayer(lineLayer)
        }
    }
}

