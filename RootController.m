//
//  RootController.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/21/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "RootController.h"

#import "HostView.h"
#import "AppDelegate.h"
#import "AlbumInfo.h"
#import "AlbumController.h"
#import "StageController.h"

#import "MenuController.h"
#import "NSColor+TLExtensions.h"
#import "NSObject+TLKVO.h"
#import "CALayer+TLExtensions.h"
#import <QuartzCore/QuartzCore.h>


@implementation RootController

@synthesize status;

- (id)init {
	self = [super init];
	if (self) {
		self.layer.backgroundColor = [[NSColor whiteColor] tl_CGColor];
		statusLayer = [CATextLayer layer];
		statusLayer.foregroundColor = [[NSColor blackColor] tl_CGColor];
		statusLayer.font = @"Futura";
		statusLayer.alignmentMode = kCAAlignmentCenter;
		[self.layer addSublayer:statusLayer];
		[self.layer setNeedsLayout];
		TLKVORegisterSelf(self, @"status",
						  NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial);
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumInfoDidLoad:)
													 name:AlbumInfoDidReloadNotification object:nil];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object
						change:(NSDictionary*)change context:(void*)context
{
    if (context == &TLKVOContext) {
		if ([keyPath isEqualToString:@"status"]) {
			switch (self.status) {
				case RootRemoteError:
					statusLayer.string = @"Remote broken — Upgrade OS X";
					break;
				case RootLibraryError:
					statusLayer.string = @"No iPhoto library found!";
					break;
				case RootNoPhotos:
					statusLayer.string = @"No photos need rating.";
					break;
				case RootLoading:
					statusLayer.string = @"Photons: loading.";
					break;
				case RootQuitting:
					statusLayer.string = @"Finishing work: please stand by.";
					break;
				default:
					NSAssert(false, @"Bad status is bad");
			}
			[[NSApp delegate] preventFullScreen];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object
							   change:change context:context];
	}
}

- (void)layoutSublayersOfLayer:(CALayer*)theLayer {
	NSAssert(theLayer == self.layer, @"Layout own layer only");
	
	CGFloat hScale = CGRectGetWidth(theLayer.bounds) / 800;
	CGFloat vScale = CGRectGetHeight(theLayer.bounds) / 600;
	statusLayer.fontSize = 50 * MIN(vScale, hScale);
	statusLayer.bounds = CGRectMake(0, 0, 800 * hScale, 75 * vScale);
	statusLayer.position = CGPointMake(400 * hScale, 350 * vScale);
	statusLayer.frame = [theLayer tl_pixelAlignRect:statusLayer.frame];
}

- (void)layerDidAppear {
	if ([[NSApp delegate] isTerminating]) return;
	if (albumPicker) {
		NSDictionary* selectedAlbum = [albumPicker.albums objectAtIndex:albumPicker.position];
		NSArray* unratedItems = [selectedAlbum objectForKey:@"items"];
		NSInteger numStages = [[NSUserDefaults standardUserDefaults] integerForKey:@"NumberOfStages"];
		numStages = (numStages > 0) ? numStages : 4;
		numStages = MIN(numStages, 4);
		//printf("Number of stages: %li\n", (long)numStages);
		StageController* stagehand = [[StageController alloc] initWithItems:unratedItems
																	 stages:numStages];
		[self.hostView pushController:stagehand];
		albumPicker = nil;
		[[NSApp delegate] allowFullScreen];
	}
	else if (self.status == RootLoading) {
		[[NSApp delegate] preventFullScreen];
		[[AlbumInfo sharedAlbumInfo] reload];
	}
}

- (void)albumInfoDidLoad:(NSNotification*)aNotification {
	NSArray* unratedAlbums = [[aNotification userInfo] objectForKey:AlbumInfoDidReloadAlbumsKey];
	if (unratedAlbums) {
		NSAssert([unratedAlbums count], @"Albums expected!");
		albumPicker = [[AlbumController alloc] initWithAlbums:unratedAlbums];
		[self.hostView pushController:albumPicker];
	}
	else {
		NSError* err = [[aNotification userInfo] objectForKey:AlbumInfoDidReloadErrorKey];
		if ([[err domain] isEqualToString:@"com.calftrail.photostar"]) {
			self.status = RootNoPhotos;
		}
		else {
			NSLog(@"Error loading iPhoto data - %@", err);
			self.status = RootLibraryError;
		}
	}
}

- (void)buttonMenu {
	[NSApp terminate:self];
}

@end
