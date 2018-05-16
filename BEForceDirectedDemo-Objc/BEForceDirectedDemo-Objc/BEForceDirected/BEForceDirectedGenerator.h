//
//  BEForceDirected.h
//  DraggableNetworkDemo
//
//  Created by yichi.wang on 09/05/2018.
//  Copyright © 2018 blueeee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BEForceDirectedNode : NSObject <NSCopying>
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic) CGPoint position;
@end

@interface BEForceDirectedEdge : NSObject <NSCopying>
@property (nonatomic, strong) BEForceDirectedNode *source;
@property (nonatomic, strong) BEForceDirectedNode *target;
@end


@interface BEForceDirectedConfiguration: NSObject
//节点分布范围 default: default: {width: 1024, height: 1024}
@property (nonatomic) CGSize size;
//是否需要限制边界 default: YES
@property (nonatomic) BOOL hasBoundary;
//迭代次数 default: 300
@property (nonatomic) NSUInteger times;
//每次迭代在x和y轴上移动的最远距离 (距离越短，迭代次数应该越多，反之亦然) default: 3
@property (nonatomic) CGFloat iteDistance;

@property (nonatomic, class, strong, readonly) BEForceDirectedConfiguration *defaultConfiguration;
@end

@interface BEForceDirectedGenerator : NSObject

@property (nonatomic, strong) BEForceDirectedConfiguration *configuration;
@property (nonatomic, strong) NSArray<BEForceDirectedNode *> *nodes;
@property (nonatomic, strong) NSArray<BEForceDirectedEdge *> *edges;

- (instancetype)initWithConfiguration:(BEForceDirectedConfiguration *)configuration;
//随机分布结点位置
-(void)random;
//使用force-directed迭代一次
-(void)layout;
//根据configuration,使用force-directed进行迭代
-(void)forceDirected;


@end




