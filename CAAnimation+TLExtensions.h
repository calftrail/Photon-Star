//
//  CAAnimation+TLExtensions.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/12/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface CAAnimation (TLExtensions)

@property (setter=tl_setLayer:) CALayer* tl_layer;

- (void)tl_addToLayer:(CALayer*)theLayer;

@end
