//
//  AppDelegate.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 10/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HostView, RootController;

@interface AppDelegate : NSObject {
@private
	HostView* layerHost;
	RootController* rootController;
	BOOL terminating;
}

@property (nonatomic) IBOutlet HostView* layerHost;

@property (readonly, getter=isTerminating) BOOL terminating;

- (void)toggleFullScreen;
- (void)preventFullScreen;
- (void)allowFullScreen;

- (IBAction)showHelp:(id)sender;

@end
