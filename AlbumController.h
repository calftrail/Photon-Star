//
//  AlbumController.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 12/16/09.
//  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Cinematroller.h"

@class ItemDisplay, MenuController;

@interface AlbumController : Cinematroller {
@private
	NSArray* albums;
	NSUInteger position;
	CALayer* albumLayer;
	ItemDisplay* albumDisplay;
	MenuController* breakMenu;
}

- (id)initWithAlbums:(NSArray*)theAlbums;

@property (readonly) NSArray* albums;
@property NSUInteger position;

// exposed only for -[RootController appRegistered:]
@property (readonly) MenuController* breakMenu;

@end
