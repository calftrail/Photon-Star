//
//  CALayer+TLExtensions.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/11/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface CALayer (TLExtensions)
- (CGRect)tl_pixelAlignRect:(CGRect)proposedRect;
- (CALayer*)tl_rootLayer;
@end
