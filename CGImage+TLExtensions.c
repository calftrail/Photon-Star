/*
 *  CGImage+TLExtensions.c
 *  Flowrate
 *
 *  Created by Nathan Vander Wilt on 1/8/10.
 *  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
 *
 */

#include "CGImage+TLExtensions.h"

#include "CFType+TLExtensions.h"

CGImageRef tlCGImageCreateWithURL(CFURLRef imageURL) {
	CGImageSourceRef isrc = CGImageSourceCreateWithURL(imageURL, NULL);
	CGImageRef img = NULL;
	if (isrc) {
		if (CGImageSourceGetCount(isrc)) {
			img = CGImageSourceCreateImageAtIndex(isrc, 0, NULL);
		}
		CFRelease(isrc);
	}
	return img;
}

CGImageRef tlCGImageGet(CFStringRef imgName) {
	CFArrayRef pieces = CFStringCreateArrayBySeparatingStrings(kCFAllocatorDefault,
															   imgName, CFSTR("."));
	CFIndex numPieces = CFArrayGetCount(pieces);
	CFStringRef extension = NULL;
	if (numPieces > 1) {
		extension = CFArrayGetValueAtIndex(pieces, numPieces-1);
		CFMutableArrayRef namePieces = CFArrayCreateMutableCopy(kCFAllocatorDefault, 0, pieces);
		CFArrayRemoveValueAtIndex(namePieces, numPieces-1);
		imgName = CFStringCreateByCombiningStrings(kCFAllocatorDefault, namePieces, CFSTR("."));
		CFRelease(namePieces);
	}
	else {
		CFRetain(imgName);
	}
	CFRelease(pieces);
	
	CFURLRef imageURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), imgName, extension, NULL);
	CGImageRef img = tlCGImageCreateWithURL(imageURL);
	CFRelease(imageURL);
	CFRelease(imgName);
	return img ? (CGImageRef)tlCFAutoreleaseC(img) : NULL;
}

CGImageRef tlCGImageMakeFromURL(CFURLRef imageURL, size_t maxImageSize) {
	CGImageRef img = NULL;
	CGImageSourceRef imgSrc = CGImageSourceCreateWithURL(imageURL, NULL);
	if (imgSrc) {
		if (CGImageSourceGetCount(imgSrc)) {
			if (!maxImageSize) {
				CFDictionaryRef imgProps = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, NULL);
				if (imgProps) {
					CFNumberRef w = CFDictionaryGetValue(imgProps, kCGImagePropertyPixelWidth);
					CFNumberRef h = CFDictionaryGetValue(imgProps, kCGImagePropertyPixelHeight);
					if (w && h) {
						CFComparisonResult cmp = CFNumberCompare(w, h, NULL);
						switch (cmp) {
							case kCFCompareLessThan:
							case kCFCompareEqualTo:
								CFNumberGetValue(h, kCFNumberLongType, &maxImageSize);
								break;
							case kCFCompareGreaterThan:
								CFNumberGetValue(w, kCFNumberLongType, &maxImageSize);
								break;
						}
					}
					CFRelease(imgProps);
				}
			}
			
			if (maxImageSize) {
				CFStringRef optionKeys[] = {
					kCGImageSourceCreateThumbnailFromImageAlways,
					kCGImageSourceCreateThumbnailWithTransform,
					kCGImageSourceThumbnailMaxPixelSize
				};
				CFNumberRef maxSizeNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongType, &maxImageSize);
				CFTypeRef optionValues[] = {
					kCFBooleanTrue,
					kCFBooleanTrue,
					maxSizeNum
				};
				CFDictionaryRef thumbnailOptions = CFDictionaryCreate(kCFAllocatorDefault,
																	  (const void**)optionKeys, (const void**)optionValues, 3,
																	  &kCFCopyStringDictionaryKeyCallBacks,
																	  &kCFTypeDictionaryValueCallBacks);
				CFRelease(maxSizeNum);
				img = CGImageSourceCreateThumbnailAtIndex(imgSrc, 0, thumbnailOptions);
				CFRelease(thumbnailOptions);
			}
		}
		CFRelease(imgSrc);
	}
	return img ? (CGImageRef)tlCFAutoreleaseC(img) : NULL;
}
