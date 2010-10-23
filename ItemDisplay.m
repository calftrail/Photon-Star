//
//  ItemDisplay.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/12/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "ItemDisplay.h"

#import <QuartzCore/QuartzCore.h>

#import "NSObject+TLKVO.h"
#import "NSColor+TLExtensions.h"

static NSString* const LayerItemIndexKey = @"com_calftrail_ItemIndex";
static NSString* const LayerLoadOperationKey = @"com_calftrail_LoadOperation";
static NSString* const LayerLoadSizeKey = @"com_calftrail_LoadSize";


@interface ItemDisplay ()
- (void)loadLayerInBackground:(CALayer*)photoLayer;
- (void)updateLayers;
@end

@implementation ItemDisplay

@synthesize layer;
@synthesize dataSource;
@synthesize position;
@synthesize autoAdvanceInterval;
@synthesize featherLeftEdge;
@synthesize featherRightEdge;

- (id)init {
	self = [super init];
	if (self) {
		NSAssert([NSGarbageCollector defaultCollector], @"Currently GC-only");
		workQueue = [NSOperationQueue new];
		layer = [CALayer layer];
		layer.layoutManager = self;
		// prevent removed layers from fading out
		layer.actions = [NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNull null], @"sublayers", nil];
		
		itemLayers = [NSMapTable mapTableWithStrongToStrongObjects];
		TLKVORegisterSelf(self, @"dataSource", NSKeyValueObservingOptionNew);
		TLKVORegisterSelf(self, @"position", NSKeyValueObservingOptionNew);
		TLKVORegisterSelf(self, @"autoAdvanceInterval", NSKeyValueObservingOptionNew);
		TLKVORegisterSelf(self, @"featherLeftEdge", NSKeyValueObservingOptionNew);
		TLKVORegisterSelf(self, @"featherRightEdge", NSKeyValueObservingOptionNew);
		TLKVORegisterSelf(self, @"layer.bounds", NSKeyValueObservingOptionNew);
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	if (context == &TLKVOContext) {
		if ([keyPath isEqualToString:@"dataSource"]) {
			[self reloadData];
		}
		else if ([keyPath isEqualToString:@"position"] ||
				 [keyPath isEqualToString:@"layer.bounds"])
		{
			[self updateLayers];
		}
		else if ([keyPath isEqualToString:@"autoAdvanceInterval"]) {
			[advanceTimer invalidate], advanceTimer = nil;
			if (self.autoAdvanceInterval > 0.0 && [self.dataSource numberOfItemsInDisplay:self]) {
				advanceTimer = [NSTimer scheduledTimerWithTimeInterval:self.autoAdvanceInterval
																target:self selector:@selector(advance:)
															  userInfo:nil repeats:YES];
			}
		}
		else if ([keyPath isEqualToString:@"featherLeftEdge"] ||
				 [keyPath isEqualToString:@"featherRightEdge"])
		{
			if (self.featherLeftEdge || self.featherRightEdge) {
				CALayer* mask = [CALayer layer];
				mask.delegate = self;
				mask.needsDisplayOnBoundsChange = YES;
				mask.frame = self.layer.bounds;
				self.layer.mask = mask;
			}
			else {
				self.layer.mask = nil;
			}
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)reloadData {
	for (id itemKey in itemLayers) {
		CALayer* itemLayer = [itemLayers objectForKey:itemKey];
		[itemLayer removeFromSuperlayer];
	}
	[itemLayers removeAllObjects];
	self.position = 0;
	self.autoAdvanceInterval = self.autoAdvanceInterval;
}

- (void)advance:(NSTimer*)aTimer {
	(void)aTimer;
	NSUInteger numItems = [self.dataSource numberOfItemsInDisplay:self];
	if (self.position + 1 < numItems) {
		self.position += 1;
	}
	else {
		self.position = 0;
	}
}

- (void)updateLayers {
	NSUInteger numItems = [self.dataSource numberOfItemsInDisplay:self];
	if (!numItems) return;
	NSAssert(self.position < numItems, @"Bad position");
	
	CGRect target = self.layer.bounds;
	if (CGRectIsEmpty(target)) return;
	
	CGFloat aspectRatio = CGRectGetWidth(target) / CGRectGetHeight(target);
	const CGFloat minImageAspectRatio = 0.6f;
	NSUInteger maxNumImagesVisible = (NSUInteger)ceil(aspectRatio / minImageAspectRatio);
	NSUInteger positionPadding = (maxNumImagesVisible + 1) / 2;
	
	NSMutableSet* activeLayers = [NSMutableSet set];
	NSUInteger startIdx = MAX(positionPadding, self.position) - positionPadding;
	NSUInteger stopIdx = MIN(numItems, (self.position + 1) + positionPadding);
	for (NSUInteger positionIdx = startIdx; positionIdx < stopIdx; ++positionIdx) {
		id itemKey = [NSNumber numberWithUnsignedInteger:positionIdx];
		CALayer* itemLayer = [itemLayers objectForKey:itemKey];
		if (!itemLayer) {
			itemLayer = [CALayer layer];
			//photoLayer.shadowColor = [[NSColor grayColor] tl_CGColor];
			itemLayer.shadowOpacity = 0.75f;
			itemLayer.contentsGravity = kCAGravityResizeAspect;
			//photoLayer.backgroundColor = [[NSColor blueColor] tl_CGColor];
			[itemLayer setValue:itemKey forKey:LayerItemIndexKey];
			[itemLayers setObject:itemLayer forKey:itemKey];
			NSAssert(self.layer, @"Layer expected.");
			[self.layer addSublayer:itemLayer];
		}
		NSAssert(itemLayer.superlayer == self.layer, @"Photo layer not in parent layer");
		[activeLayers addObject:itemLayer];
	}
	
	NSArray* sublayers = [self.layer.sublayers copy];
	for (CALayer* sublayer in sublayers) {
		if ([activeLayers containsObject:sublayer]) continue;
		[[sublayer valueForKey:LayerLoadOperationKey] cancel];
		[sublayer removeFromSuperlayer];
		[itemLayers removeObjectForKey:[sublayer valueForKey:LayerItemIndexKey]];
	}
	[self.layer setNeedsLayout];
}

- (void)layoutSublayersOfLayer:(CALayer*)theLayer {
	if (theLayer != self.layer) return;		// ignore request to lay out mask sublayers.
	if (CGRectIsEmpty(theLayer.bounds)) return;
	for (CALayer* sublayer in theLayer.sublayers) {
		NSAssert([sublayer valueForKey:LayerItemIndexKey], @"Expected ID value not found");
	}
	
	id sd = [[NSSortDescriptor alloc] initWithKey:LayerItemIndexKey ascending:YES];
	NSArray* sortedSublayers = [theLayer.sublayers
								sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd]];
	
	CGFloat talliedWidth = 0.0f;
	CGFloat middleWidthOffset = 0.0f;
	for (CALayer* sublayer in sortedSublayers) {
		NSUInteger itemIdx = [[sublayer valueForKey:LayerItemIndexKey] unsignedIntegerValue];
		// aspectRatio = width / height
		CGFloat aspectRatio = [self.dataSource itemDisplayNeedsAspectRatio:self
															forItemAtIndex:itemIdx];
		NSAssert(aspectRatio > 0, @"Bad aspect ratio");
		CGFloat width = MIN(aspectRatio, 1.0f);
		if (itemIdx == self.position) {
			middleWidthOffset = talliedWidth + (width / 2);
			break;
		}
		talliedWidth += width;
	}
	
	const CGFloat imagePadding = 10;
	CGRect targetBounds = theLayer.bounds;
	CGFloat targetHeight = targetBounds.size.height;
	CGFloat statusAdjustment = targetHeight / 4;
	CGFloat xOffset = CGRectGetMidX(targetBounds) - middleWidthOffset * targetHeight;
	CGFloat yOffset = theLayer.bounds.origin.y;
	
	NSUInteger sublayerIdx = 0;
	for (CALayer* sublayer in sortedSublayers) {
		NSUInteger itemIdx = [[sublayer valueForKey:LayerItemIndexKey] unsignedIntegerValue];
		NSInteger alignment = 0;
		if ([(id)self.dataSource respondsToSelector:
			 @selector(itemDisplayNeedsAlignment:forItemAtIndex:)])
		{
			alignment = [self.dataSource itemDisplayNeedsAlignment:self forItemAtIndex:itemIdx];
		}
		CGFloat aspectRatio = [self.dataSource itemDisplayNeedsAspectRatio:self forItemAtIndex:itemIdx];
		CGFloat imageWidth = targetHeight * MIN(aspectRatio, 1);
		CGFloat imageHeight = imageWidth / aspectRatio;
		CGRect imageBox = CGRectMake(xOffset, yOffset, imageWidth, targetHeight);
		imageBox = CGRectOffset(imageBox, 0, alignment * statusAdjustment);
		imageBox = CGRectInset(imageBox, 0, (targetHeight - imageHeight) / 2);
		sublayer.frame = CGRectInset(imageBox, imagePadding, imagePadding / aspectRatio);
		[self loadLayerInBackground:sublayer];
		xOffset += imageWidth;
		++sublayerIdx;
	}
	theLayer.mask.frame = theLayer.bounds;
}

- (void)drawLayer:(CALayer*)theLayer inContext:(CGContextRef)ctx {
	NSAssert(theLayer == self.layer.mask, @"Draws mask only");
	
	CGContextSetGrayFillColor(ctx, 0, 0);
	CGContextFillRect(ctx, CGContextGetClipBoundingBox(ctx));
	
	const CGFloat featherSize = 10;
	CGRect featherRect = [theLayer bounds];
	
	NSArray* colors = [NSArray arrayWithObjects:		// NOTE: doesn't work well with gray colors
					   (id)[[NSColor colorWithDeviceRed:0 green:0 blue:1 alpha:1] tl_CGColor],
					   (id)[[NSColor colorWithDeviceRed:0 green:0 blue:1 alpha:0.75f] tl_CGColor],
					   (id)[[NSColor colorWithDeviceRed:0 green:0 blue:1 alpha:0] tl_CGColor], nil];
	CGGradientRef gradient = CGGradientCreateWithColors(NULL, (CFArrayRef)colors, NULL);
	
	CGRect midRect = featherRect;
	if (self.featherLeftEdge) {
		CGPoint midEnd = CGPointMake(CGRectGetMinX(featherRect), CGRectGetMidY(featherRect));
		CGPoint start = CGPointMake(midEnd.x + featherSize, midEnd.y);
		CGContextDrawLinearGradient(ctx, gradient, start, midEnd, 0);
		midRect = CGRectInset(midRect, featherSize / 2, 0);
		midRect = CGRectOffset(midRect, featherSize / 2, 0);
	}
	if (self.featherRightEdge) {
		CGPoint end = CGPointMake(CGRectGetMaxX(featherRect), CGRectGetMidY(featherRect));
		CGPoint midStart = CGPointMake(end.x - featherSize, end.y);	
		CGContextDrawLinearGradient(ctx, gradient, midStart, end, 0);
		midRect = CGRectInset(midRect, featherSize / 2, 0);
		midRect = CGRectOffset(midRect, -featherSize / 2, 0);
	}
	
	CGContextSetGrayFillColor(ctx, 0, 1);
	CGContextFillRect(ctx, midRect);
}

- (void)loadLayerInBackground:(CALayer*)itemLayer {
	NSAssert(!CGRectIsEmpty(itemLayer.bounds), @"Layer bounds must be set to load photo");
	NSUInteger neededSize = MAX(itemLayer.bounds.size.width, itemLayer.bounds.size.height);
	NSUInteger loadedSize = [[itemLayer valueForKey:LayerLoadSizeKey] unsignedIntegerValue];
	if (neededSize <= loadedSize) {
		return;
	}
	// NOTE: could pad neededSize to reduce live-resize flashing
	itemLayer.contents = NULL;
	itemLayer.borderWidth = 1;
	itemLayer.borderColor = [[NSColor colorWithDeviceWhite:0 alpha:0.25f] tl_CGColor];
	itemLayer.backgroundColor = [[NSColor colorWithDeviceWhite:1 alpha:0.5f] tl_CGColor];
	[[itemLayer valueForKey:LayerLoadOperationKey] cancel];
	
	NSOperation* op = [[NSInvocationOperation alloc] initWithTarget:self
														   selector:@selector(loadPhotoForLayer:)
															 object:itemLayer];
	NSUInteger positionIdx = [[itemLayer valueForKey:LayerItemIndexKey] unsignedIntegerValue];
	if (positionIdx == self.position) {
		op.queuePriority = NSOperationQueuePriorityHigh;
	}
	[itemLayer setValue:op forKey:LayerLoadOperationKey];
	[itemLayer setValue:[NSNumber numberWithUnsignedInteger:neededSize] forKey:LayerLoadSizeKey];
	[workQueue addOperation:op];
}

- (void)loadPhotoForLayer:(CALayer*)itemLayer {
	(void)[NSThread self];
	//NSAssert(![NSThread isMainThread], @"Should be called in background!");
	NSUInteger imageSize = [[itemLayer valueForKey:LayerLoadSizeKey] unsignedIntegerValue];
	NSAssert(imageSize, @"Image size must be set for layer");
	
	NSUInteger itemIdx = [[itemLayer valueForKey:LayerItemIndexKey] unsignedIntegerValue];
	CGImageRef image = [self.dataSource itemDisplayNeedsImage:self
											   forItemAtIndex:itemIdx
													 withSize:imageSize];
	NSAssert(image, @"No image, sad trombone.");
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithInt:1] forKey:kCATransactionAnimationDuration];
	itemLayer.borderWidth = 0;
	itemLayer.backgroundColor = nil;
	itemLayer.contents = (id)image;
	[CATransaction commit];
	[CATransaction flush];	// queue has no run loop, must flush manually
	[itemLayer setValue:nil forKey:LayerLoadOperationKey];
	
	/* NOTE: if no events come in to the app, memory usage will grow without bound. rdar://7536762
	 See also related http://lists.apple.com/archives/cocoa-dev/2008/Oct/msg01812.html */
	static int gNum = 0;
	if (!(++gNum % 5)) [[NSGarbageCollector defaultCollector] collectExhaustively];
}

@end
