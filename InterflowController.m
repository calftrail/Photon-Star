//
//  InterflowController.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/9/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "InterflowController.h"

#import "ItemDisplay.h"
#import "RateSet.h"
#import "HostView.h"
#import "AlbumInfo.h"

#import <QuartzCore/QuartzCore.h>
#import "NSColor+TLExtensions.h"


@interface InterflowController () <ItemDisplayDataSource>
@end

enum {
	RateStatusAboveDown = RateStatusDown - 1
};



@implementation InterflowController

@synthesize rateSet;
@synthesize ratePosition;
@synthesize state;
@synthesize stage;
@synthesize lastStage;

- (id)initWithItems:(NSArray*)unratedItems threeWay:(BOOL)isThreeWay {
	self = [super init];
	if (self) {
		threeWay = isThreeWay;
		rateSet = [RateSet rateSetWithItems:unratedItems];
		
		promoteDisplay = [ItemDisplay new];
		promoteDisplay.dataSource = self;
		[self.layer addSublayer:promoteDisplay.layer];
		
		rateDisplay1 = [ItemDisplay new];
		rateDisplay1.dataSource = self;
		[self.layer addSublayer:rateDisplay1.layer];
		
		if (threeWay) {
			rateDisplay2 = [ItemDisplay new];
			rateDisplay2.dataSource = self;
			[self.layer addSublayer:rateDisplay2.layer];
		}
		
		proceedText = [CATextLayer layer];
		proceedText.font = @"Futura";
		proceedText.foregroundColor = [[NSColor blackColor] tl_CGColor];
		proceedText.alignmentMode = kCAAlignmentCenter;
		[self.layer addSublayer:proceedText];
		
		[self.layer setNeedsLayout];
	}
	return self;
}

- (void)layerDidAppear {
	if (threeWay) for (NSUInteger itemIdx = 0; itemIdx < self.ratePosition; ++itemIdx) {
		if ([rateSet itemStatusAtIndex:itemIdx] == RateStatusNoChange) {
			[rateSet setItemStatus:RateStatusAboveDown atIndex:itemIdx];
		}
	}
	ratedItems1 = [rateSet itemsWithStatus:RateStatusDown];
	ratedItems2 = [rateSet itemsWithStatus:RateStatusAboveDown];
	
	if (!threeWay && self.stage > 1) {
		NSArray* unknownItems = [self.rateSet itemsWithStatus:RateStatusNoChange];
		ratedItems1 = [ratedItems1 arrayByAddingObjectsFromArray:unknownItems];
	}
	promotedItems = [rateSet itemsWithStatus:RateStatusUp];
	
	proceedText.string = (self.isLastStage) ? @"Done. Please confirm." : @"Please confirm.";
	
	if (![ratedItems1 count] && ![ratedItems2 count] && ![promotedItems count]) {
		[self performSelector:@selector(buttonRight) withObject:nil afterDelay:0];
		return;
	}
	
	[rateDisplay1 reloadData];
	[rateDisplay2 reloadData];
	[promoteDisplay reloadData];
	rateDisplay1.position = 0;
	rateDisplay2.position = 0;
	promoteDisplay.position = MAX([promotedItems count], 1) - 1;
	timer = [NSTimer scheduledTimerWithTimeInterval:1.0
											 target:self selector:@selector(updateDisplays:)
										   userInfo:nil repeats:YES];
}

- (void)layerWillDisappear {
	[timer invalidate], timer = nil;
	ratedItems1 = nil;
	ratedItems2 = nil;
	promotedItems = nil;
	[rateDisplay1 reloadData];
	[rateDisplay2 reloadData];
	[promoteDisplay reloadData];
}

- (void)updateDisplays:(NSTimer*)aTimer {
	(void)aTimer;
	
	if (rateDisplay1.position + 1 < [ratedItems1 count]) {
		rateDisplay1.position += 1;
	}
	else {
		rateDisplay1.position = 0;
	}
	
	if (rateDisplay2.position + 1 < [ratedItems2 count]) {
		rateDisplay2.position += 1;
	}
	else {
		rateDisplay2.position = 0;
	}
	
	if (promoteDisplay.position > 0) {
		promoteDisplay.position -= 1;
	}
	else {
		promoteDisplay.position = MAX([promotedItems count], 1) - 1;
	}
	
}


- (void)applyRating:(NSUInteger)rating toItems:(NSArray*)theRatedItems {
	//printf("Rating %i items with %i star(s).\n", (int)[theRatedItems count], (int)rating);
	for (id ratedItem in theRatedItems) {
		[[AlbumInfo sharedAlbumInfo] applyRating:rating toItem:ratedItem];
	}
}

- (void)layoutSublayersOfLayer:(CALayer*)theLayer {
	NSAssert(theLayer == self.layer, @"Only layout own layer");
	
	CGRect targetBounds = theLayer.bounds;
	CGFloat height = targetBounds.size.height / ((threeWay) ? 4 : 3);
	
	for (CALayer* sublayer in theLayer.sublayers) {
		NSUInteger tmpPos = -1;
		if (sublayer == proceedText) {
			tmpPos = (threeWay) ? 2 : 1;
		}
		else if (sublayer == promoteDisplay.layer) {
			tmpPos = (threeWay) ? 3 : 2;
		}
		else if (sublayer == rateDisplay2.layer) {
			// only present when threeWay
			tmpPos = 1;
		}
		else if (sublayer == rateDisplay1.layer) {
			// always at bottom
			tmpPos = 0;
		}
		sublayer.frame = CGRectMake(targetBounds.origin.x,
									targetBounds.origin.y + tmpPos * height,
									targetBounds.size.width, height);
	}
}


#pragma mark Display data source

- (NSArray*)itemsForDisplay:(ItemDisplay*)anItemDisplay {
	NSArray* items = nil;
	if (anItemDisplay == promoteDisplay) {
		items = promotedItems;
	}
	else if (anItemDisplay == rateDisplay1) {
		items = ratedItems1;
	}
	else if (anItemDisplay == rateDisplay2) {
		items = ratedItems2;
	}
	else NSAssert(false, @"Unknown item display");
	return items;
}

- (NSUInteger)numberOfItemsInDisplay:(ItemDisplay*)anItemDisplay {
	return [[self itemsForDisplay:anItemDisplay] count];
}


- (CGImageRef)itemDisplayNeedsImage:(ItemDisplay*)anItemDisplay
					 forItemAtIndex:(NSUInteger)itemIdx
						   withSize:(NSUInteger)imageSize
{
	id item = [[self itemsForDisplay:anItemDisplay] objectAtIndex:itemIdx];
	return [[AlbumInfo sharedAlbumInfo] imageForItem:item ofSize:imageSize];
}

- (CGFloat)itemDisplayNeedsAspectRatio:(ItemDisplay*)anItemDisplay
						forItemAtIndex:(NSUInteger)itemIdx
{
	id item = [[self itemsForDisplay:anItemDisplay] objectAtIndex:itemIdx];
	return [[AlbumInfo sharedAlbumInfo] aspectRatioForItem:item];
}


#pragma mark Event handling

- (void)buttonLeft {
	self.state = InterflowReturnedState;
	self.lastStage = NO;
	[self.hostView popController];
}

- (void)buttonRight {
	NSAssert(ratedItems1 && ratedItems2 && promotedItems, @"Items not correctly set");
	if (threeWay) {
		NSAssert(self.stage > 1, @"Stage (or three-way) incorrectly set");
		if (self.stage < 4) [self applyRating:(self.stage-1) toItems:ratedItems1];
		[self applyRating:self.stage toItems:ratedItems2];
		if (!self.isLastStage) [self applyRating:(self.stage+1) toItems:promotedItems];
	}
	else {
		[self applyRating:self.stage toItems:ratedItems1];
	}
	
	if (self.isLastStage) {
		[self applyRating:(self.stage+1) toItems:promotedItems];
		promotedItems = nil;
	}
	
	if ([promotedItems count]) {
		rateSet = [RateSet rateSetWithItems:promotedItems];
		self.state = InterflowAdvancedState;
	}
	else {
		rateSet = nil;
		self.state = InterflowDoneState;
	}
	
	[self.hostView popController];
}

- (void)buttonMenu {
	[self buttonLeft];
}

- (void)buttonSelect {
	[self buttonRight];
}

@end
