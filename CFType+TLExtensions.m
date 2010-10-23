/*
 *  CFType+TLExtensions.m
 *  Flowrate
 *
 *  Created by Nathan Vander Wilt on 1/8/10.
 *  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
 *
 */


#include "CFType+TLExtensions.h"

CFTypeRef tl_CFAutoreleaseHelper(CFTypeRef obj) {
	return [(id)obj autorelease];
}
