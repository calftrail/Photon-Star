//
//  Cinematroller.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 11/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Cinematroller.h"

#import <QuartzCore/QuartzCore.h>

#import "HostView.h"

@implementation Cinematroller

@synthesize hostView;
@synthesize parentController;
@synthesize layer;

- (id)init {
	NSAssert([NSThread isMainThread], @"Main thread only!");
	self = [super init];
	if (self) {
		layer = [CALayer layer];
		layer.layoutManager = self;
	}
	return self;
}

- (void)layerWillAppear {}
- (void)layerWillDisappear {}
- (void)layerDidAppear {}
- (void)layerDidDisappear {}

- (CALayer*)overlayLayer {
	return nil;
}

- (void)buttonUp {}
- (void)buttonDown {}
- (void)buttonLeft {}
- (void)buttonRight {}
- (void)buttonSelect {}
- (void)buttonMenu {}

@end
