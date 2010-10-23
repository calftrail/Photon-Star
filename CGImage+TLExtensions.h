/*
 *  CGImage+TLExtensions.h
 *  Flowrate
 *
 *  Created by Nathan Vander Wilt on 1/8/10.
 *  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
 *
 */

#ifndef __CGIMAGE_TLEXTENSIONS__
#define __CGIMAGE_TLEXTENSIONS__

#include <ApplicationServices/ApplicationServices.h>

CGImageRef tlCGImageCreateWithURL(CFURLRef imageURL);
CGImageRef tlCGImageGet(CFStringRef imgName);

CGImageRef tlCGImageMakeFromURL(CFURLRef imageURL, size_t maxImageSize);

#endif /* __CGIMAGE_TLEXTENSIONS__ */
