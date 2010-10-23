//
//  AlbumController.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 12/16/09.
//  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
//

#import "AlbumController.h"

#import <QuartzCore/QuartzCore.h>

#import "HostView.h"
#import "StageController.h"
#import "MenuController.h"
#import "AlbumInfo.h"
#import "AppDelegate.h"
#import "ItemDisplay.h"

#import "NSObject+TLKVO.h"
#import "NSColor+TLExtensions.h"
#import "CALayer+TLExtensions.h"
#import "TLSFX.h"


@interface AlbumController () <ItemDisplayDataSource>
@end


@implementation AlbumController

@synthesize albums;
@synthesize position;
@synthesize breakMenu;

- (id)initWithAlbums:(NSArray*)theAlbums {
	self = [super init];
	if (self) {
		albums = [theAlbums copy];
		
		self.layer.backgroundColor = [[NSColor whiteColor] tl_CGColor];
		
		albumLayer = [CALayer layer];
		albumLayer.layoutManager = self;
		for (NSDictionary* album in albums) {
			CATextLayer* itemLabel = [CATextLayer layer];
			itemLabel.string = [album objectForKey:@"name"];
			itemLabel.truncationMode = kCATruncationNone;
			itemLabel.font = @"Futura";
			itemLabel.foregroundColor = [[NSColor blackColor] tl_CGColor];
			if ([album objectForKey:@"isPurchaseAlbum"]) {
				itemLabel.foregroundColor = [[NSColor redColor] tl_CGColor];
			}
			[albumLayer addSublayer:itemLabel];
		}
		
		CATextLayer* star = [CATextLayer layer];
		star.alignmentMode = kCAAlignmentCenter;
		star.foregroundColor = [[NSColor blackColor] tl_CGColor];
		star.string = @"★";
		[albumLayer addSublayer:star];
		[albumLayer setNeedsLayout];
		[self.layer addSublayer:albumLayer];
		
		albumDisplay = [ItemDisplay new];
		albumDisplay.autoAdvanceInterval = 1.0;
		albumDisplay.dataSource = self;
		//albumDisplay.featherLeftEdge = YES;
		albumDisplay.featherRightEdge = YES;
		albumDisplay.layer.masksToBounds = YES;
		[self.layer addSublayer:(albumDisplay.layer)];
		
		[self.layer setNeedsLayout];
		
		TLKVORegisterSelf(self, @"position", NSKeyValueObservingOptionNew);
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
    if (context == &TLKVOContext) {
		if ([keyPath isEqualToString:@"position"]) {
			[albumLayer setNeedsLayout];
			[albumDisplay reloadData];
			
			NSDictionary* album = [albums objectAtIndex:(self.position)];
			if ([album objectForKey:@"isPurchaseAlbum"]) {
				//[[TLSFX sharedSFX] playSound:@"hooray!"];
			}
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)layoutSublayersOfLayer:(CALayer*)theLayer {
	NSAssert(theLayer.tl_rootLayer == self.hostView.layer, @"Layer must be hosted before layout");
	NSAssert(!CGRectIsEmpty(theLayer.bounds), @"Layer bounds must be set before layout");
	if (theLayer == self.layer) {
		CGRect targetBounds = theLayer.bounds;
		albumLayer.frame = targetBounds;
		albumDisplay.layer.frame = CGRectMake(CGRectGetMinX(targetBounds),
											  CGRectGetMinY(targetBounds),
											  CGRectGetWidth(targetBounds) / 2,
											  CGRectGetHeight(targetBounds) / 2);
	}
	else if (theLayer == albumLayer) {
		CGFloat xScale = CGRectGetWidth(theLayer.bounds) / 800;
		CGFloat yScale = CGRectGetHeight(theLayer.bounds) / 600;
		
		CGFloat height = 50;
		CGFloat centerY = CGRectGetMaxY(theLayer.bounds) - 75 * yScale - height;
		CGFloat guideX = 450 * xScale;
		CGFloat width = CGRectGetWidth(theLayer.bounds);
		
		NSUInteger layerIdx = 0;
		for (CALayer* sublayer in theLayer.sublayers) {
			NSInteger offsetPosition = layerIdx - self.position;
			CGFloat y = centerY - offsetPosition * height;
			sublayer.frame = [theLayer tl_pixelAlignRect:CGRectMake(guideX, y, width, height)];
			++layerIdx;
		}
		CALayer* star = [theLayer.sublayers lastObject];
		CGFloat halfHeight = height / 2;
		star.bounds = CGRectMake(0, 0, halfHeight * 1.5f, halfHeight * 1.5f);
		star.position = CGPointMake(guideX - height, centerY + halfHeight);
		star.transform = CATransform3DMakeRotation(18 * (CGFloat)M_PI/180, 0, 0, -1);
	}
}


#pragma mark Item display data source

- (NSUInteger)numberOfItemsInDisplay:(ItemDisplay*)anItemDisplay {
	(void)anItemDisplay;
	if (!self.layer.superlayer) return 0;
	NSDictionary* album = [albums objectAtIndex:(self.position)];
	return [[album objectForKey:@"items"] count];
}

- (CGImageRef)itemDisplayNeedsImage:(ItemDisplay*)anItemDisplay
					 forItemAtIndex:(NSUInteger)itemIdx
						   withSize:(NSUInteger)imageSize
{
	(void)anItemDisplay;
	NSDictionary* album = [albums objectAtIndex:(self.position)];
	id item = [[album objectForKey:@"items"] objectAtIndex:itemIdx];
	return [[AlbumInfo sharedAlbumInfo] imageForItem:item ofSize:imageSize];
}

- (CGFloat)itemDisplayNeedsAspectRatio:(ItemDisplay*)anItemDisplay
						forItemAtIndex:(NSUInteger)itemIdx
{
	(void)anItemDisplay;
	NSDictionary* album = [albums objectAtIndex:(self.position)];
	id item = [[album objectForKey:@"items"] objectAtIndex:itemIdx];
	return [[AlbumInfo sharedAlbumInfo] aspectRatioForItem:item];
}


#pragma mark Event handling

- (void)buttonDown {
	if (self.position + 1 < albums.count) {
		self.position += 1;
	}
}

- (void)buttonUp {
	if (self.position > 0) {
		self.position -= 1;
	}
}

- (void)buttonSelect {
	[self.hostView popController];
}

enum {
	BreakToggleFullscreen = 0,
	BreakQuit = 1,
	BreakNoChoice = MenuControllerNoChoice
};

+ (NSArray*)breakChoices {
	return [NSArray arrayWithObjects:@"Toggle fullscreen", @"Quit", nil];
}

- (void)buttonMenu {
	NSArray* menuChoices = [[self class] breakChoices];
	breakMenu = [[MenuController alloc] initWithChoices:menuChoices];
	[self.hostView pushController:breakMenu];
}

- (void)layerDidAppear {
	if (breakMenu) {
		NSUInteger theChoice = breakMenu.chosenIndex;
		switch (theChoice) {
			case BreakNoChoice:
				// ignore
				break;
			case BreakToggleFullscreen:
				[[NSApp delegate] toggleFullScreen];
				break;
			case BreakQuit:
				[NSApp performSelector:@selector(terminate:) withObject:self afterDelay:0];
				break;
			default:
				NSAssert1(false, @"Bad break menu choice %i", theChoice);
				break;
		}
		breakMenu = nil;
	}
	[albumDisplay reloadData];
}

- (void)layerWillDisappear {
	[albumDisplay reloadData];
}

@end
