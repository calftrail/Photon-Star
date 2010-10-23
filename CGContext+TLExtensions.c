/*
 *  CGContext+TLExtensions.c
 *  Flowrate
 *
 *  Created by Nathan Vander Wilt on 12/7/09.
 *  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "CGContext+TLExtensions.h"

CGContextRef tlCGBitmapContextCreateForImage(size_t width, size_t height) {
	CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGContextRef ctx = CGBitmapContextCreate(NULL, width, height,
											 8, 4*width,
											 cs,  kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
	CFRelease(cs);
	return ctx;
}
