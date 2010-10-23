//
//  CAAnimation+TLExtensions.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/12/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "CAAnimation+TLExtensions.h"


@implementation CAAnimation (TLExtensions)

static NSString* const LayerKey = @"com_calftrail_animation_layer";

- (CALayer*)tl_layer {
	return [self valueForKey:LayerKey];
}

- (void)tl_setLayer:(CALayer*)theLayer {
	[self setValue:theLayer forKey:LayerKey];
}

- (void)tl_addToLayer:(CALayer*)theLayer {
	self.tl_layer = theLayer;
	[theLayer addAnimation:self forKey:nil];
	NSAssert(![theLayer animationForKey:nil], @"No animation should be returned for nil key");
}

@end
