//
//  ItemDisplay.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/12/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol ItemDisplayDataSource;

@interface ItemDisplay : NSObject {
@private
	NSOperationQueue* workQueue;
	NSMapTable* itemLayers;
	NSTimer* advanceTimer;
	
	CALayer* layer;
	id dataSource;
	NSUInteger position;
	NSTimeInterval autoAdvanceInterval;
	
	CALayer* watermarkLayer;
	BOOL featherLeftEdge;
	BOOL featherRightEdge;
}

@property (readonly) CALayer* layer;
@property id<ItemDisplayDataSource> dataSource;
- (void)reloadData;

@property NSUInteger position;
@property NSTimeInterval autoAdvanceInterval;

@property BOOL featherLeftEdge;
@property BOOL featherRightEdge;

@end


@protocol ItemDisplayDataSource
- (NSUInteger)numberOfItemsInDisplay:(ItemDisplay*)anItemDisplay;
- (CGImageRef)itemDisplayNeedsImage:(ItemDisplay*)anItemDisplay
					 forItemAtIndex:(NSUInteger)itemIdx
						   withSize:(NSUInteger)imageSize;
- (CGFloat)itemDisplayNeedsAspectRatio:(ItemDisplay*)anItemDisplay
						forItemAtIndex:(NSUInteger)itemIdx;
@optional
- (NSInteger)itemDisplayNeedsAlignment:(ItemDisplay*)anItemDisplay
						forItemAtIndex:(NSUInteger)itemIdx;
@end
