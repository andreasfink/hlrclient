//
//  MSCTransaction.h
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//


#import <ulib/ulib.h>
#import <ulibasn1/ulibasn1.h>
#import <ulibgt/ulibgt.h>
#import <ulibgsmmap/ulibgsmmap.h>
#import <ulibpcap/ulibpcap.h>
#import <ulibgsmmap/ulibgsmmap.h>

#import "WebMacros.h"
#import "GenericTransaction.h"

@interface MSCTransaction : GenericTransaction
{
}

-(void) MAP_MT_ForwardSM:GSMMAP_INVOKE_INDICATION_PARAMETERS;
-(void) MAP_MO_ForwardSM:GSMMAP_INVOKE_INDICATION_PARAMETERS;
@end

