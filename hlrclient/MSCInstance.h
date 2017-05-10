//
//  MSCInstance.h
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulibgsmmap/ulibgsmmap.h>
#import "GenericInstance.h"

@interface MSCInstance : GenericInstance
{
    NSString *smsForwardUrl;
    UMHTTPClient *webClient;
}

@property(readwrite,strong) NSString *smsForwardUrl;

- (void)handleIncomingSMS:(NSString *)json
                       oa:(UMGSMMAP_SM_RP_OA *)oa
                       da:(UMGSMMAP_SM_RP_DA *)da
                       ui:(UMGSMMAP_SignalInfo *)ui;

@end
