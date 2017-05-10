//
//  AppDelegate.h
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulibgsmmap/ulibgsmmap.h>

@class MSCInstance;


#ifdef __APPLE__
/*
   For unit tests to work in Xcode we need NSApplicationDelegate.
   We dont want to include gnustep-gui under Linux just for that.
   gnustep-base is enough.
*/
#import <cocoa/cocoa.h>
#endif

@interface AppDelegate : NSObject  <UMHTTPServerHttpGetPostDelegate,
                                    UMHTTPServerAuthenticateRequestDelegate,
                                    UMLayerUserProtocol,
#ifdef __APPLE__
                                    NSApplicationDelegate,
#endif
                                    UMLayerUserProtocol,
                                    UMLayerSctpApplicationContextProtocol,
                                    UMLayerM2PAApplicationContextProtocol,
                                    UMLayerMTP3ApplicationContextProtocol,
                                    UMLayerSCCPApplicationContextProtocol,
                                    UMLayerTCAPApplicationContextProtocol,
                                    UMLayerGSMMAPApplicationContextProtocol>
{
    UMLogHandler        *logHandler;
    UMLogFeed           *stdLogFeed;
    UMTaskQueueMulti    *taskQueue;

    UMSynchronizedDictionary *sctp_dict;
    UMSynchronizedDictionary *m2pa_dict;
    UMSynchronizedDictionary *mtp3_dict;
    UMSynchronizedDictionary *mtp3_link_dict;
    UMSynchronizedDictionary *mtp3_linkset_dict;
    UMSynchronizedDictionary *m3ua_as_dict;
    UMSynchronizedDictionary *m3ua_asp_dict;

    UMSynchronizedDictionary *sccp_dict;
    UMSynchronizedDictionary *sccp_next_hop_dict;
    UMSynchronizedDictionary *tcap_dict;
    UMSynchronizedDictionary *gsmmap_dict;

    UMSynchronizedDictionary *webserver_dict;
    UMSynchronizedDictionary *msc_dict;

    MSCInstance *mainMscInstance;
    UMTCAP_TransactionIdPool *tidPool;
    UMConfig *config;
}

- (void)readConfigFile:(NSString *)filename;
- (UMLogFeed *)logFeed;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)applicationWillTerminate:(NSNotification *)aNotification;

- (void)applicationGoToHot;
- (void)applicationGoToStandby;
- (NSDictionary *)cnamResponseForMsisdn:(NSString *)msisdn;
- (UMHTTPAuthenticationStatus)httpAuthenticateRequest:(UMHTTPRequest *)req
                                                realm:(NSString **)realm;

- (UMLayerSctp *)getSCTP:(NSString *)name;
- (UMLayerM2PA *)getM2PA:(NSString *)name;
- (UMLayerMTP3 *)getMTP3:(NSString *)name;
- (UMLayerSCCP *)getSCCP:(NSString *)name;
- (UMLayerTCAP *)getTCAP:(NSString *)name;
- (UMLayerGSMMAP *)getGSMMAP:(NSString *)name;
- (UMMTP3Link *)getMTP3_Link:(NSString *)name;
- (UMMTP3LinkSet *)getMTP3_LinkSet:(NSString *)name;
- (UMM3UAApplicationServerProcess *)getM3UA_ASP:(NSString *)name;
- (UMM3UAApplicationServer *)getM3UA_AS:(NSString *)name;
- (MSCInstance *)getMSC:(NSString *)name;
- (SccpNextHop *)getSCCP_NextHop:(NSString *)name;

@end
