//
//  FlowController.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 11/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FlowController.h"

#import <QuartzCore/QuartzCore.h>

#import "HostView.h"
#import "AlbumInfo.h"
#import "RateSet.h"
#import "ItemDisplay.h"
#import "StageController.h"

#import "NSColor+TLExtensions.h"
#import "TLSFX.h"


@interface FlowController () <ItemDisplayDataSource>
@end

@implementation FlowController

@synthesize autoHold;

- (id)initWithRateSet:(RateSet*)theRateSet {
	self = [super init];
	if (self) {
		rateSet = theRateSet;
		itemDisplay = [ItemDisplay new];
		itemDisplay.dataSource = self;
		itemDisplay.layer.backgroundColor = [[NSColor grayColor] tl_CGColor];
		itemDisplay.layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
		itemDisplay.layer.frame = self.layer.bounds;
		[self.layer addSublayer:itemDisplay.layer];
	}
	return self;
}


#pragma mark Item display data source

- (NSUInteger)position {
	return [itemDisplay position];
}

- (NSUInteger)numberOfItemsInDisplay:(ItemDisplay*)anItemDisplay {
	(void)anItemDisplay;
	return [rateSet count];
}

- (CGImageRef)itemDisplayNeedsImage:(ItemDisplay*)anItemDisplay
					 forItemAtIndex:(NSUInteger)itemIdx
						   withSize:(NSUInteger)imageSize
{
	(void)anItemDisplay;
	id item = [rateSet itemAtIndex:itemIdx];
	return [[AlbumInfo sharedAlbumInfo] imageForItem:item ofSize:imageSize];
}

- (CGFloat)itemDisplayNeedsAspectRatio:(ItemDisplay*)anItemDisplay
						forItemAtIndex:(NSUInteger)itemIdx
{
	(void)anItemDisplay;
	id item = [rateSet itemAtIndex:itemIdx];
	return [[AlbumInfo sharedAlbumInfo] aspectRatioForItem:item];
}

- (NSInteger)itemDisplayNeedsAlignment:(ItemDisplay*)anItemDisplay
						forItemAtIndex:(NSUInteger)itemIdx
{
	(void)anItemDisplay;
	return [rateSet itemStatusAtIndex:itemIdx];
}


#pragma mark Event handling

- (void)retreat {
	if (itemDisplay.position > 0) {
		itemDisplay.position -= 1;
	}
}

- (void)rateCurrentItem:(RateStatus)newStatus {
	NSString* soundName = nil;
	switch (newStatus) {
		case RateStatusDown:
			soundName = TLSFXNameDown;
			break;
		case RateStatusUp:
			soundName = TLSFXNameUp;
			break;
		case RateStatusNoChange:
			soundName = TLSFXNameNeutral;
			break;
	}
	if (soundName) {
		[self.hostView preventDefaultSound];
		[[TLSFX sharedSFX] playSound:soundName];
	}
	
	[rateSet setItemStatus:newStatus atIndex:(itemDisplay.position)];
	[itemDisplay.layer setNeedsLayout];
}

- (void)advance {
	if (itemDisplay.position + 1 < rateSet.count) {
		itemDisplay.position += 1;
	}
	else {
		// pop from stack when done
		[self.hostView popController];
	}
}

- (void)buttonLeft {
	[self retreat];
	if (true) {
		[self rateCurrentItem:RateStatusNoChange];
	}
}

- (void)buttonRight {
	if (self.autoHold && ![rateSet itemStatusAtIndex:(itemDisplay.position)]) {
		[self rateCurrentItem:RateStatusDown];
	}
	[self advance];
}

- (void)buttonDown {
	[self rateCurrentItem:RateStatusDown];
	[self advance];
}

- (void)buttonUp {
	[self rateCurrentItem:RateStatusUp];
	[self advance];
}

- (void)buttonMenu {
	[(StageController*)self.parentController showBreakMenu];
}

- (void)layerDidAppear {
	[self rateCurrentItem:RateStatusNoChange];
	[(StageController*)self.parentController checkBreakMenu];
}

@end
