//
//  ViewController.m
//  DraggableNetworkDemo
//
//  Created by yichi.wang on 07/05/2018.
//  Copyright © 2018 blueeee. All rights reserved.
//

#import "ViewController.h"
#import "BEForceDirectedGenerator.h"

#define KBEForceDirectedContentWidth 2000
#define KBEForceDirectedContentHeight 2000

@interface ViewController ()<UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableArray *nodeViews;
@property (nonatomic, strong) CAShapeLayer *lineLayer;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIBezierPath *linePath;

@property (nonatomic, strong) NSMutableArray *cacheNodes;
@property (nonatomic, strong) NSMutableArray *cacheEdges;

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, strong) BEForceDirectedGenerator *forceDirectedGenerator;
@property (nonatomic) BOOL duringForceDirected;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    [self initData];
    [self forceDirected];
}

#pragma mark - copy
-(NSMutableArray *)copyWithArray:(NSArray *)array {
    NSMutableArray *results = [NSMutableArray array];
    for (id object in array) {
        if ([object conformsToProtocol:@protocol(NSCopying)]) {
            [results addObject:[object copy]];
        }
    }
    return results;
}

#pragma mark - UI
-(void)initUI {
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.contentSize = CGSizeMake(KBEForceDirectedContentWidth, KBEForceDirectedContentHeight);
    
    self.scrollView.contentOffset = CGPointMake((self.scrollView.contentSize.width - self.scrollView.frame.size.width)/2, (self.scrollView.contentSize.height - self.scrollView.frame.size.height)/2);
    self.scrollView.minimumZoomScale = 0.1;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height)];
    [self.scrollView addSubview:self.contentView];
    
}

#pragma mark - Data
-(void)initData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"data.json" ofType:@""];
    NSData *data = [NSData dataWithContentsOfFile:path];;
    NSDictionary *dataDic = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:NULL];
    NSArray *nodeArray = dataDic[@"node"];
    NSArray *edgeArray = dataDic[@"edge"];
    
    NSMutableArray *nodes = [NSMutableArray array];
    for (NSDictionary *nodeDic in nodeArray) {
        BEForceDirectedNode *node = [[BEForceDirectedNode alloc] init];
        node.identifier = nodeDic[@"name"];
        [nodes addObject:node];
    }
    
    NSMutableArray *edges = [NSMutableArray array];
    for (NSDictionary *edgeDic in edgeArray) {
        BEForceDirectedEdge *edge = [[BEForceDirectedEdge alloc] init];
        edge.source = nodes[([edgeDic[@"source"] integerValue] - 1)];
        edge.target = nodes[([edgeDic[@"target"] integerValue] - 1)];
        [edges addObject:edge];
    }
    //init forceDirectedGenerator
    self.forceDirectedGenerator = [[BEForceDirectedGenerator alloc] initWithConfiguration:[BEForceDirectedConfiguration defaultConfiguration]];
    self.forceDirectedGenerator.configuration.size = CGSizeMake(400, 400);
    self.forceDirectedGenerator.configuration.hasBoundary = NO;
    self.forceDirectedGenerator.configuration.times = 600;
    self.forceDirectedGenerator.configuration.iteDistance = 1;
    self.forceDirectedGenerator.nodes = nodes;
    self.forceDirectedGenerator.edges = edges;
}

-(void)forceDirected {
    self.cacheNodes = [NSMutableArray array];
    self.cacheEdges = [NSMutableArray array];
    
    [self.forceDirectedGenerator random];
    [self.cacheNodes addObject:[self copyWithArray:self.forceDirectedGenerator.nodes]];
    [self.cacheEdges addObject:[self copyWithArray:self.forceDirectedGenerator.edges]];
    [self startTiming];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < self.forceDirectedGenerator.configuration.times; i ++) {
            self.duringForceDirected = YES;
            [self.forceDirectedGenerator layout];
            [self.cacheNodes addObject:[self copyWithArray:self.forceDirectedGenerator.nodes]];
            [self.cacheEdges addObject:[self copyWithArray:self.forceDirectedGenerator.edges]];
            self.duringForceDirected = NO;
        }
    });
}

#pragma mark - UIScrollViewDelegate
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.contentView;
}

#pragma mark - Draw Action
-(void)drawNodesWithNodes:(NSArray *)nodes {
    static int colors[5][3] = {{241,141,0},{244,150,201},{255,248,165},{128,205,227},{236,122,172}};
    CGFloat nodeLength = 20;
    CGFloat widthOffset = (KBEForceDirectedContentHeight - self.forceDirectedGenerator.configuration.size.width)/2;
    CGFloat heightOffset = (KBEForceDirectedContentHeight - self.forceDirectedGenerator.configuration.size.height)/2;
    if (self.nodeViews.count == 0) {
        self.nodeViews = [NSMutableArray array];
        for (BEForceDirectedNode *node in nodes) {
            CGPoint position = node.position;
            CALayer *layer = [CALayer layer];
            layer.bounds = CGRectMake(0, 0, nodeLength, nodeLength);
            layer.position = CGPointMake(position.x + widthOffset, position.y + heightOffset);
            
            int *color = colors[rand() % 5];
            layer.backgroundColor = [UIColor colorWithRed:color[0] / 255.0 green:color[1] / 255.0 blue:color[2] / 255.0 alpha:1].CGColor;
            layer.cornerRadius = nodeLength/2;
            [self.nodeViews addObject:layer];
            [self.contentView.layer addSublayer:layer];
        }
    } else {
        for (int i = 0; i < nodes.count ;i++) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            BEForceDirectedNode *node = nodes[i];
            CGPoint position = node.position;
            CALayer *layer = self.nodeViews[i];
            layer.position = CGPointMake(position.x + widthOffset, position.y + heightOffset);
            [CATransaction commit];
        }
    }
}

-(void)drawEdgesWithEdges:(NSArray *)edges {
    if (!self.lineLayer) {
        self.lineLayer = [[CAShapeLayer alloc] init];
        self.lineLayer.bounds = self.contentView.bounds;
        self.lineLayer.position = self.contentView.center;
        self.lineLayer.strokeColor = [UIColor grayColor].CGColor;
        
        self.lineLayer.lineWidth = 0.6;
        [self.contentView.layer addSublayer:self.lineLayer];
        self.linePath = [UIBezierPath bezierPath];
    }
    [self.linePath removeAllPoints];
    
    CGFloat widthOffset = (KBEForceDirectedContentWidth - self.forceDirectedGenerator.configuration.size.width)/2;
    CGFloat heightOffset = (KBEForceDirectedContentHeight - self.forceDirectedGenerator.configuration.size.height)/2;
    
    for (BEForceDirectedEdge *edge in edges) {
        [self.linePath moveToPoint:CGPointMake(edge.source.position.x + widthOffset, edge.source.position.y + heightOffset)];
        [self.linePath addLineToPoint:CGPointMake(edge.target.position.x +  widthOffset, edge.target.position.y + heightOffset)];
    }
    UIGraphicsBeginImageContext(self.lineLayer.bounds.size);
    [self.linePath stroke];
    UIGraphicsEndImageContext();
    
    self.lineLayer.path = self.linePath.CGPath;
}

-(void)forceDirectedDraw {
    if (self.cacheEdges.count == self.cacheNodes.count && self.cacheNodes.count != 0) {
        [self drawNodesWithNodes:self.cacheNodes[0]];
        [self drawEdgesWithEdges:self.cacheEdges[0]];
        [self.cacheNodes removeObjectAtIndex:0];
        [self.cacheEdges removeObjectAtIndex:0];
    } else if (self.cacheNodes.count == 0 && self.duringForceDirected == NO) {
        [self stopTiming];
    }
}

#pragma mark - Timing
- (void)startTiming {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(forceDirectedDraw)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopTiming {
    if (self.displayLink != nil) {
        self.displayLink.paused = YES;
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

@end
