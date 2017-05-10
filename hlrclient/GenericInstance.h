//
//  GenericInstance.h
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibgt/ulibgt.h>
#import <ulibsccp/ulibsccp.h>
#import <ulibtcap/ulibtcap.h>
#import <ulibgsmmap/ulibgsmmap.h>

@class GenericTransaction;

@interface GenericInstance : UMLayer<UMLayerGSMMAP_UserProtocol,
                                    UMHTTPServerHttpGetPostDelegate,
                                    UMHTTPRequest_TimeoutProtocol>
{
    NSString *instanceAddress;
    UMSynchronizedDictionary *transactions;
    UMLayerGSMMAP *gsmMap;
    NSTimeInterval timeoutInSeconds;
    NSString *httpUser;
    NSString *httpPass;
}

@property(readwrite,strong) UMLayerGSMMAP *gsmMap;
@property(readwrite,strong) NSString *instanceAddress;
@property(readwrite,strong) NSString *httpUser;
@property(readwrite,strong) NSString *httpPass;

- (GenericInstance *)initWithNumber:(NSString *)iAddress;
- (NSString *)status;
- (void) setConfig:(NSDictionary *)cfg applicationContext:(id)appContext;


- (NSString *)getNewUserIdentifier;
- (GenericTransaction *)transactionById:(NSString *)userId;
- (void)addTransaction:(GenericTransaction *)t userId:(NSString *)uidstr;
- (void) markTransactionForTermination:(GenericTransaction *)t;
+ (NSString *)webIndexForm;
+ (void)webHeader:(NSMutableString *)s title:(NSString *)t;
- (UMHTTPAuthenticationStatus)httpAuthenticateRequest:(UMHTTPRequest *)req
                                                realm:(NSString **)realm;
- (BOOL)authenticateUser:(NSString *)user pass:(NSString *)pass;
@end
