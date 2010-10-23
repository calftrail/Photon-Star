//
//  CALayer+TLExtensions.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/11/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "CALayer+TLExtensions.h"


@implementation CALayer (TLExtensions)

- (CALayer*)tl_rootLayer {
	CALayer* parentLayer = self;
	while (parentLayer.superlayer) {
		parentLayer = parentLayer.superlayer;
	}
	return parentLayer;
}

- (CGRect)tl_pixelAlignRect:(CGRect)proposedRect {
	CALayer* rootLayer = self.tl_rootLayer;
	CGRect baseRect = [self convertRect:proposedRect toLayer:rootLayer];
	return [self convertRect:CGRectIntegral(baseRect) fromLayer:rootLayer];
}

@end
