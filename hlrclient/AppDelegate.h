//
//  AppDelegate.h
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulibss7config/ulibss7config.h>

@class MSCInstance;

@interface AppDelegate : SS7AppDelegate
{
    NSDictionary                *_staticWebPages;
    MSCInstance                 *_mainMscInstance;
}


@property(readwrite,strong) MSCInstance                 *mainMscInstance;

- (UMHTTPAuthenticationStatus)httpAuthenticateRequest:(UMHTTPRequest *)req
                                                realm:(NSString **)realm;


- (void)  handleMtp3RoutingTable:(UMHTTPRequest *)req;

@end
