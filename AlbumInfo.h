//
//  AlbumInfo.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/21/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AlbumInfo : NSObject {
@private
	NSOperationQueue* workQueue;
	NSMutableSet* ratedItems;
	NSDate* reloadTime;
}

+ (id)sharedAlbumInfo;

@property (readonly) BOOL didRateItems;

// non-blocking
- (void)reload;
- (void)applyRating:(NSUInteger)starRating
			 toItem:(id)ratedItem;

// blocking
- (void)finish;
- (CGFloat)aspectRatioForItem:(id)item;
- (CGImageRef)imageForItem:(id)item
					ofSize:(NSUInteger)imageSize;
@end

extern NSString* const AlbumInfoDidReloadNotification;
extern NSString* const AlbumInfoDidReloadAlbumsKey;
extern NSString* const AlbumInfoDidReloadErrorKey;
