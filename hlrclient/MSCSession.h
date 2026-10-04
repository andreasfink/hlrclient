//
//  MSCSession.h
//  hlrclient
//
//  Created by Andreas Fink on 07.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulibss7config/ulibss7config.h>
#import <ulibss7config/WebMacros.h>
#import <ulibss7config/OutputFormat.h>

@interface MSCSession : SS7GenericSession
{
}

-(void) MAP_MT_ForwardSM:GSMMAP_INVOKE_INDICATION_PARAMETERS;
-(void) MAP_MO_ForwardSM:GSMMAP_INVOKE_INDICATION_PARAMETERS;
-(void) MAP_InsertSubscriberData:GSMMAP_INVOKE_INDICATION_PARAMETERS;

@end

