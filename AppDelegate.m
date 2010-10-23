//
//  AppDelegate.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 10/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "AlbumInfo.h"

#import "HostView.h"
#import "RootController.h"
#import "AlbumController.h"

#import "HIDRemote.h"


@interface AppDelegate ()
@property (readwrite, getter=isTerminating) BOOL terminating;
@end

static NSString* const LaunchFullScreen = @"LaunchFullScreen";


@implementation AppDelegate

@synthesize layerHost;
@synthesize terminating;

- (void)awakeFromNib {
	rootController = [RootController new];
	[self.layerHost pushController:rootController];
	if ([HIDRemote isCandelairInstallationRequiredForRemoteMode:kHIDRemoteModeExclusiveAuto]) {
		NSLog(@"Candelair needs to be installed!");
		rootController.status = RootRemoteError;
		return;
	}
	self.layerHost.remoteActive = YES;
}

- (void)applicationDidHide:(NSNotification*)notification {
	(void)notification;
	/* NOTE: this works around an issue (#806) where app can be hidden using Cmd-H
	 while in full screen. A better solution might be to disable the shortcut,
	 or figure out how to exit full screen properly when hidden. */
	if ([self.layerHost isInFullScreenMode]) {
		[NSApp performSelector:@selector(unhide:) withObject:self afterDelay:0];
		// NOTE: toggling results in first responder issue when unhidden by user.
		//[self toggleFullScreen];
	}
}

- (void)toggleFullScreen {
	if ([self.layerHost isInFullScreenMode]) {
		[NSCursor unhide];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:LaunchFullScreen];
		[self.layerHost exitFullScreenModeWithOptions:nil];
		// not exactly sure why this is necessary
		[[self.layerHost window] makeFirstResponder:layerHost];
	}
	else {
		[NSCursor hide];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:LaunchFullScreen];
		[self.layerHost enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
	}
	if ([[NSApp keyWindow] firstResponder] != layerHost) NSLog(@"Not first responder!");
}

- (void)preventFullScreen {
	if (![self.layerHost isInFullScreenMode]) return;
	
	[NSCursor unhide];
	[self.layerHost exitFullScreenModeWithOptions:nil];
	// not exactly sure why this is necessary
	[[self.layerHost window] makeFirstResponder:layerHost];
}

- (void)allowFullScreen {
	if ([self.layerHost isInFullScreenMode]) return;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:LaunchFullScreen]) {
		[self toggleFullScreen];
	}
}


- (void)finishQueueAndTerminate {
	[[AlbumInfo sharedAlbumInfo] finish];
	if ([[AlbumInfo sharedAlbumInfo] didRateItems]) {
		[NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:
		 [NSArray arrayWithObjects:@"-e", @"delay 0.05\ntell application \"iPhoto\" to activate", nil]];
	}
	[NSApp replyToApplicationShouldTerminate:YES];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender {
	(void)sender;
	self.terminating = YES;
	self.layerHost.remoteActive = NO;
	[self.layerHost popToController:rootController];
	rootController.status = RootQuitting;
	[self performSelectorInBackground:@selector(finishQueueAndTerminate) withObject:nil];
	return NSTerminateLater;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender {
	(void)sender;
	return YES;
}

- (IBAction)showHelp:(id)sender {
	(void)sender;
	NSURL* helpURL = [NSURL URLWithString:@"http://calftrail.com/support/photon_star_instructions.html"];
	[[NSWorkspace sharedWorkspace] openURL:helpURL];
}

@end
