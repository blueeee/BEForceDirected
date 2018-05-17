//
//  BEForceDirected.m
//  DraggableNetworkDemo
//
//  Created by yichi.wang on 09/05/2018.
//  Copyright © 2018 blueeee. All rights reserved.
//

#import "BEForceDirectedGenerator.h"
@implementation BEForceDirectedNode
- (id)copyWithZone:(nullable NSZone *)zone {
    BEForceDirectedNode *node = [[BEForceDirectedNode alloc] init];
    node.position = CGPointMake(self.position.x, self.position.y);
    node.identifier = self.identifier;
    return node;
}

@end

@implementation BEForceDirectedEdge
- (id)copyWithZone:(nullable NSZone *)zone {
    BEForceDirectedEdge *edge = [[BEForceDirectedEdge alloc] init];
    edge.source = self.source;
    edge.target = self.target;
    return self;
}
@end

@implementation BEForceDirectedConfiguration

- (instancetype)init {
    self = [super init];
    if (self) {
        self.size = CGSizeMake(1024, 1024);
        self.times = 300;
        self.hasBoundary = YES;
        self.iteDistance = 3.0;
    }
    return self;
}
+ (BEForceDirectedConfiguration *)defaultConfiguration {
    return [[BEForceDirectedConfiguration alloc] init];
}
@end

@implementation BEForceDirectedGenerator

- (instancetype)initWithConfiguration:(BEForceDirectedConfiguration *)configuration {
    self = [super init];
    if (self) {
        self.configuration = configuration;
    }
    return self;
}

- (void)forceDirected{
    [self random];
    for (int i = 0; i < self.configuration.times; i++) {
        [self layout];
    }
}

-(void)random {
    if (self.nodes.count == 0) return;
    for (BEForceDirectedNode *node in self.nodes) {
        CGFloat width = self.configuration.size.width;
        CGFloat height = self.configuration.size.height;
        if (width == 0 || height == 0) {
            width = 1024;
            height = 1024;
        }
        node.position = CGPointMake(rand() % (int)width, rand() % (int)height);
    }
}

- (void)layout{
    if (self.nodes.count == 0) return;
    double k;
    if (self.configuration.size.width == 0 || self.configuration.size.height == 0) {
        k = sqrt(1024 * 1024 / ((double)self.nodes.count));
    } else {
        k = sqrt(self.configuration.size.width * self.configuration.size.height / ((double)self.nodes.count));
    }
    
    CGFloat xs[self.nodes.count], ys[self.nodes.count];
    memset(xs, 0, sizeof(xs));
    memset(ys, 0, sizeof(ys));
    
    [self repulsiveForceWithXs:xs ys:ys k:k];
    [self tractionForceWithXs:xs ys:ys k:k];
    
    //mix
    CGFloat maxtx = self.configuration.iteDistance, maxty = self.configuration.iteDistance;
    for (int v = 0; v < self.nodes.count; v++) {
        BEForceDirectedNode *node = self.nodes[v];
        CGFloat dx = xs[v];
        CGFloat dy = ys[v];
        
        if (dx < -maxtx) dx = -maxtx;
        if (dx > maxtx) dx = maxtx;
        if (dy < -maxty) dy = -maxty;
        if (dy > maxty) dy = maxty;
        
        if (!self.configuration.hasBoundary) {
            node.position = CGPointMake(node.position.x + dx, node.position.y + dy);
            
        } else {
            CGFloat x = (node.position.x + dx) >= self.configuration.size.width || (node.position.x + dx) <= 0 ? node.position.x - dx : node.position.x + dx;
            CGFloat y = (node.position.y + dy) >= self.configuration.size.height || (node.position.y + dy) <= 0 ? node.position.y - dy : node.position.y + dy;
            node.position = CGPointMake(x, y);
        }
    }
}

-(void)repulsiveForceWithXs:(CGFloat *)xs ys:(CGFloat *)ys k:(double)k{
    double distX, distY, dist;
    // Coulomb's law
    int ejectFactor = 6;
    for (int v = 0; v < self.nodes.count; v++) {
        xs[v] = 0.0;
        ys[v] = 0.0;
        for (int u = 0; u < self.nodes.count; u++) {
            if (u != v) {
                distX = ((BEForceDirectedNode *)self.nodes[v]).position.x - ((BEForceDirectedNode *)self.nodes[u]).position.x;
                distY = ((BEForceDirectedNode *)self.nodes[v]).position.y - ((BEForceDirectedNode *)self.nodes[u]).position.y;
                dist = sqrt(distX * distX + distY * distY);
                if (dist > 0 && dist < 250) {
                    xs[v] = xs[v] + distX / dist * k * k / dist * ejectFactor;
                    ys[v] = ys[v] + distY / dist * k * k / dist * ejectFactor;
                }
            }
        }
    }
}

-(void)tractionForceWithXs:(CGFloat *)xs ys:(CGFloat *)ys k:(double)k {
    double distX, distY, dist;
    
    //Hooke's law
    int condenseFactor = 3;
    BEForceDirectedNode *startNode, *endNode;
    for (int e = 0; e < self.edges.count; e++) {
        startNode = ((BEForceDirectedEdge *)self.edges[e]).source;
        endNode = ((BEForceDirectedEdge *)self.edges[e]).target;
        
        NSUInteger startIndex = [self.nodes indexOfObject:startNode];
        NSUInteger endIndex = [self.nodes indexOfObject:endNode];
        
        distX = startNode.position.x - endNode.position.x;
        distY = startNode.position.y - endNode.position.y;
        dist = sqrt(distX * distX + distY * distY);
        xs[startIndex] = xs[startIndex] - distX * dist / k * condenseFactor;
        ys[startIndex] = ys[startIndex] - distY * dist / k * condenseFactor;
        
        xs[endIndex] = xs[endIndex] + distX * dist / k * condenseFactor;
        ys[endIndex] = ys[endIndex] + distY * dist / k * condenseFactor;
    }
}


-(BEForceDirectedConfiguration *)configuration {
    if (!_configuration) {
        _configuration = BEForceDirectedConfiguration.defaultConfiguration;
    }
    return _configuration;
}
@end
