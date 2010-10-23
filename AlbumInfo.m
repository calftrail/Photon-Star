//
//  AlbumInfo.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/21/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "AlbumInfo.h"

#import "TLInvocationOperation.h"
#import "NSURL+TLExtensions.h"
#include "CGImage+TLExtensions.h"
#include <libkern/OSAtomic.h>


@interface AlbumInfo ()
- (void)performReload;
- (void)noteItemRated:(NSDictionary*)ratedItem;
+ (void)runScriptToApplyRating:(NSUInteger)starRating toItemWithID:(NSUInteger)itemID;
@end

NSString* const AlbumInfoDidReloadNotification = @"AlbumInfoDidReload";
NSString* const AlbumInfoDidReloadAlbumsKey = @"unratedAlbums";
NSString* const AlbumInfoDidReloadErrorKey = @"error";


@implementation AlbumInfo

- (id)init {
	self = [super init];
	if (self) {
		workQueue = [NSOperationQueue new];
		workQueue.maxConcurrentOperationCount = 1;
		ratedItems = [NSMutableSet new];
	}
	return self;
}

+ (id)sharedAlbumInfo {
	static id volatile sharedAlbumInfo = nil;
	if (!sharedAlbumInfo) {
		id tmp = [AlbumInfo new];
		BOOL swapped = objc_atomicCompareAndSwapGlobalBarrier(nil, tmp, &sharedAlbumInfo);
		if (!swapped) {
			[tmp release];
		}
	}
	return sharedAlbumInfo;
}

- (BOOL)didRateItems {
	return [ratedItems count] ? YES : NO;
}

- (void)reload {
	reloadTime = [NSDate date];
	TLInvocationOperation* op = [TLInvocationOperation new];
	[[op prepareWithTarget:self] performReload];
	[workQueue addOperation:op];
}

- (void)finish {
	[workQueue waitUntilAllOperationsAreFinished];
}

- (void)applyRating:(NSUInteger)starRating
			 toItem:(id)ratedItem
{
	NSAssert(starRating, @"Un-rating not supported.");
	NSInteger itemID = [[ratedItem objectForKey:@"tl_ItemKey"] integerValue];
	NSAssert(itemID, @"Item must have non-zero tl_ItemKey");
	TLInvocationOperation* op = [TLInvocationOperation new];
	[[op prepareWithTarget:[self class]] runScriptToApplyRating:starRating toItemWithID:itemID];
	[workQueue addOperation:op];
	
	TLInvocationOperation* op2 = [TLInvocationOperation new];
	[[op2 prepareWithTarget:self] noteItemRated:ratedItem];
	[workQueue addOperation:op2];
}

- (CGFloat)aspectRatioForItem:(id)item {
	return (CGFloat)[[item objectForKey:@"Aspect Ratio"] doubleValue];
}

- (CGImageRef)imageForItem:(id)item
					ofSize:(NSUInteger)imageSize
{
	NSString* path = imageSize > 360 ? [item objectForKey:@"ImagePath"] : [item objectForKey:@"ThumbPath"];
	NSURL* imageAliasURL = [NSURL fileURLWithPath:path isDirectory:NO];
	NSURL* imageURL = [NSURL tl_urlByResolvingAliasFile:imageAliasURL error:NULL];
	return tlCGImageMakeFromURL((CFURLRef)imageURL, imageSize);
}


#pragma mark Threadsafe class methods

+ (NSURL*)defaultAlbumInfoURL {
	CFArrayRef recentDatabases = CFPreferencesCopyValue(CFSTR("iPhotoRecentDatabases"), CFSTR("com.apple.iApps"),
														kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFMakeCollectable(recentDatabases);
	NSURL* albumDataURL = nil;
	if (recentDatabases && CFArrayGetCount(recentDatabases)) {
		albumDataURL = [NSURL URLWithString:
						(NSString*)CFArrayGetValueAtIndex(recentDatabases, 0)];
	}
	return albumDataURL;
}

+ (NSDictionary*)readAlbumInfo:(NSURL*)albumDataURL error:(NSError**)err {
	NSData* albumData = [NSData dataWithContentsOfURL:albumDataURL
											  options:(NSMappedRead | NSUncachedRead)
												error:err];
	if (!albumData) return nil;
	
	NSString* deserializeErrorString;
	NSDictionary* theAlbumInfo = [NSPropertyListSerialization propertyListFromData:albumData
																  mutabilityOption:NSPropertyListImmutable
																			format:NULL
																  errorDescription:&deserializeErrorString];
	if (!theAlbumInfo && err) {
		NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 deserializeErrorString, NSLocalizedDescriptionKey,
								 albumDataURL, NSURLErrorKey, nil];
		*err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:errInfo];
	}
	return theAlbumInfo;
}

+ (void)runScriptToApplyRating:(NSUInteger)starRating
				  toItemWithID:(NSUInteger)itemID
{
	NSString* scriptPath = [[NSBundle mainBundle] pathForResource:@"RateItem" ofType:@"scpt"];
	NSAssert(scriptPath, @"Helper script not found");
	NSArray* args = [NSArray arrayWithObjects: scriptPath,
					 [NSString stringWithFormat:@"%lu", (size_t)itemID],
					 [NSString stringWithFormat:@"%lu", (size_t)starRating], nil];
	[[NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:args] waitUntilExit];
	//printf("Item %lu assigned %lu star.\n", (size_t)itemID, (size_t)starRating);
}


#pragma mark Work queue methods

- (NSArray*)findUnratedAlbums:(NSDictionary*)theAlbumInfo {
	NSMutableArray* unratedAlbumInfo = [NSMutableArray new];
	NSDictionary* imageList = [theAlbumInfo objectForKey:@"Master Image List"];
	for (NSDictionary* album in [theAlbumInfo objectForKey:@"List of Albums"]) {
		// find unratedItems in album
		NSMutableArray* unratedItems = [NSMutableArray new];
		for (NSString* itemKey in [album objectForKey:@"KeyList"]) {
			NSDictionary* item = [imageList objectForKey:itemKey];
			if ([[item objectForKey:@"MediaType"] isEqualToString:@"Image"] &&
				![[item objectForKey:@"Rating"] intValue] &&
				![ratedItems member:[item objectForKey:@"GUID"]])
			{
				NSMutableDictionary* annotatedItem = [item mutableCopy];
				[annotatedItem setObject:itemKey forKey:@"tl_ItemKey"];
				[unratedItems addObject:annotatedItem];
			}
		}
		// add album to list if necessary
		if ([unratedItems count]) {
			NSDictionary* unratedAlbum = [NSDictionary dictionaryWithObjectsAndKeys:
										  [album objectForKey:@"AlbumName"], @"name",
										  unratedItems, @"items", nil];
			[unratedAlbumInfo addObject:unratedAlbum];
		}
	}
	return unratedAlbumInfo;
}

- (NSArray*)reload:(NSError**)err {
	NSURL* albumDataURL = [[self class] defaultAlbumInfoURL];
	if (!albumDataURL) {
		if (err) {
			NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"Could not find current iPhoto library", NSLocalizedDescriptionKey,
									 @"No iPhoto data was found. Please make sure that an iPhoto library "
									 @"has been properly configured", NSLocalizedFailureReasonErrorKey, nil];
			*err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:errInfo];
		}
		return nil;
	}
	
	NSDictionary* theAlbumInfo = [[self class] readAlbumInfo:albumDataURL error:err];
	if (!theAlbumInfo) return nil;
	
	return [self findUnratedAlbums:theAlbumInfo];
}

- (void)performReload {
	NSError* reloadError;
	NSArray* unratedAlbums = [self reload:&reloadError];
	if (![unratedAlbums count]) {
		NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"No unrated photos found", NSLocalizedDescriptionKey,
								 @"There are no unrated photos in your current iPhoto library at this time. "
								 @"Please try again after importing some new photos.",
								 NSLocalizedFailureReasonErrorKey, nil];
		reloadError = [NSError errorWithDomain:@"com.calftrail.photostar" code:1 userInfo:errInfo];
		unratedAlbums = nil;
	}
	
	NSDictionary* reloadInfo = nil;
	if (unratedAlbums) {
		reloadInfo = [NSDictionary dictionaryWithObject:unratedAlbums
												 forKey:AlbumInfoDidReloadAlbumsKey];
	}
	else {
		reloadInfo = [NSDictionary dictionaryWithObject:reloadError
												 forKey:AlbumInfoDidReloadErrorKey];
	}
	const NSTimeInterval minimumDelay = 1.0;
	NSTimeInterval reloadDuration = [[NSDate date] timeIntervalSinceDate:reloadTime];
	if (reloadDuration < minimumDelay) {
		NSTimeInterval remainingTime = minimumDelay - reloadDuration;
		//printf("fake load - %f\n", remainingTime);
		usleep((float)(remainingTime * 1000000));
	}
	NSNotification* reloadNotification = [NSNotification notificationWithName:AlbumInfoDidReloadNotification
															   object:self
															 userInfo:reloadInfo];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
														   withObject:reloadNotification
														waitUntilDone:YES];
}

- (void)noteItemRated:(NSDictionary*)ratedItem {
	NSString* itemGUID = [ratedItem objectForKey:@"GUID"];
	[ratedItems addObject:itemGUID];
}

@end
