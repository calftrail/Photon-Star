//
//  RootController.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/21/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Cinematroller.h"


typedef enum {
	RootRemoteError = -3,
	RootLibraryError = -2,
	RootNoPhotos = -1,
	RootLoading = 0,
	RootQuitting = 1
} RootStatus;


@class CATextLayer, AlbumController;

@interface RootController : Cinematroller {
@private
	RootStatus status;
	CATextLayer* statusLayer;
	AlbumController* albumPicker;
}

@property RootStatus status;

@end
