//
//  GenericTransaction.h
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

@class GenericInstance;

@interface GenericTransaction : UMLayerTask<UMLayerGSMMAP_UserProtocol,UMSCCP_TraceProtocol>
{
    NSString *userIdentifier;

    UMASN1Object *query;
    UMLayerGSMMAP_OpCode *opcode;

    GenericInstance *gInstance;
    SccpAddress *localAddress;
    SccpAddress *remoteAddress;

    UMHTTPRequest *req;
    NSDate *startTime;
    NSMutableDictionary *options;
    UMTCAP_asn1_objectIdentifier *applicationContext;
    UMTCAP_asn1_objectIdentifier *incomingApplicationContext;
    UMASN1BitString *dialogProtocolVersion;
    NSMutableArray *sccp_sent;
    NSMutableArray *sccp_received;
    BOOL sccpDebugEnabled;
    BOOL sccpTracefileEnabled;
    UMPCAPFile *pcap;
    NSTimeInterval timeoutValue;
    NSDate          *timeoutTime;
    UMTCAP_asn1_dialoguePortion *incomingDialogPortion;
    UMTCAP_asn1_userInformation *userInfo;
    UMTCAP_asn1_userInformation *incomingUserInfo;
    NSString *dialogId;
    BOOL    doEnd;
    UMTCAP_Variant  tcapVariant;
    NSString *transactionId;
    NSString *remoteTransactionId;
    NSDictionary *incomingOptions;
    UMSynchronizedArray *_components;
    OutputFormat outputFormat;
    int         nowait;
    BOOL        undefinedTransaction;
    NSString    *transactionName;
    int         firstInvokeId;
    NSString *_opc;
    NSString *_dpc;

}

@property(readwrite,strong) GenericInstance *gInstance;
@property(readwrite,strong,atomic)     UMSynchronizedArray *components;
@property(readwrite,strong) NSString *userIdentifier;
@property(readwrite,strong) UMASN1Object *query;
@property(readwrite,assign) int64_t operation;
@property(readwrite,strong) UMASN1Object *query2;
@property(readwrite,assign) int64_t operation2;
@property(readwrite,strong) SccpAddress *localAddress;
@property(readwrite,strong) SccpAddress *remoteAddress;
@property(readwrite,strong) UMHTTPRequest *req;
@property(readwrite,strong) NSDate *startTime;

@property(readwrite,strong) NSDictionary *options;
@property(readwrite,strong) UMTCAP_asn1_objectIdentifier *applicationContext;
@property(readwrite,strong) UMTCAP_asn1_objectIdentifier *applicationContext2;
@property(readwrite,strong) UMTCAP_asn1_objectIdentifier *incomingApplicationContext;
@property(readwrite,strong) NSMutableArray *sccp_sent;
@property(readwrite,strong) NSMutableArray *sccp_received;
@property(readwrite,assign) BOOL sccpDebugEnabled;
@property(readwrite,assign) BOOL sccpTracefileEnabled;
@property(readwrite,assign) NSTimeInterval timeoutValue;
@property(readwrite,strong) NSDate *timeoutTime;
@property(readwrite,strong) UMTCAP_asn1_userInformation *userInfo;
@property(readwrite,strong) UMTCAP_asn1_userInformation *incomingUserInfo;
@property(readwrite,strong) NSString *dialogId;
@property(readwrite,strong) UMLayerGSMMAP_OpCode *opcode;
@property(readwrite,strong) UMLayerGSMMAP_OpCode *opcode2;
@property(readwrite,assign) UMTCAP_Variant tcapVariant;
@property(readwrite,strong) NSDictionary *incomingOptions;
@property(readwrite,strong) NSString *transactionId;
@property(readwrite,strong) NSString *remoteTransactionId;
@property(readwrite,assign) OutputFormat outputFormat;
@property(readwrite,assign) BOOL doEnd;
@property(readwrite,strong) UMPCAPFile *pcap;
@property(readwrite,assign) int nowait;
@property(readwrite,assign) BOOL undefinedTransaction;
@property(readwrite,strong) NSString    *transactionName;
@property(readwrite,strong) UMTCAP_asn1_dialoguePortion *incomingDialogPortion;
@property(readwrite,strong) UMASN1BitString *dialogProtocolVersion;
@property(readwrite,strong,atomic) NSString *opc;
@property(readwrite,strong,atomic) NSString *dpc;

- (NSString *)getNewUserIdentifier;

- (GenericTransaction *)initWithHttpReq:(UMHTTPRequest *)xreq
                              operation:(int64_t)op
                               instance:(GenericInstance *)inst;

- (void) handleSccpAddressesDefaultCallingSsn:(NSString *)defaultCallingSsn
                             defaultCalledSsn:(NSString *)defaultCalledSsn
                         defaultCallingNumber:(NSString *)defaultCalling
                          defaultCalledNumber:(NSString *)defaultCalled
                      defaultCalledNumberPlan:(int)numberplan;

- (void) setDefaultApplicationContext:(NSString *)def;
- (void) setUserInfo_MAP_Open;
- (void) setTimeouts;
- (void) setOptions;
- (void)submit;
- (void)submitApplicationContextTest;
- (void)webException:(NSException *)e;
- (GenericTransaction *)initWithTransaction:(GenericTransaction *)ot;
- (void)markForTermination;

- (void) MAP_Invoke_Ind_Log:(UMASN1Object *)xparam
                     userId:(NSString *)xuserIdentifier
                     dialog:(NSString *)xdialogId
                transaction:(NSString *)xtcapTransactionId
                     opCode:(UMLayerGSMMAP_OpCode *)xopcode
                   invokeId:(int64_t)xinvokeId
                   linkedId:(int64_t)xlinkedId
                       last:(BOOL)xlast
                    options:(NSDictionary *)xoptions;

- (void) MAP_ReturnResult_Log:(UMASN1Object *)xparam
                       dialog:(NSString *)dialogId
                     invokeId:(int64_t)xinvokeId
                     linkedId:(int64_t)xlinkedId
                       opCode:(UMLayerGSMMAP_OpCode *)xopcode
                         last:(int64_t)xlast
                      options:(NSDictionary *)xoptions;

- (void)logWebtransaction;

+ (void)webFormStart:(NSMutableString *)s title:(NSString *)t;
+ (void)webFormEnd:(NSMutableString *)s;

+ (void)webMapTitle:(NSMutableString *)s;
+ (void)webDialogTitle:(NSMutableString *)s;
+ (void)webDialogOptions:(NSMutableString *)s;

+ (void)webTcapTitle:(NSMutableString *)s;
+ (void)webTcapOptions:(NSMutableString *)s
            appContext:(NSString *)ac
        appContextName:(NSString *)acn;

+ (void)webSccpTitle:(NSMutableString *)s;
+ (void)webSccpOptions:(NSMutableString *)s
        callingComment:(NSString *)callingComment
         calledComment:(NSString *)calledComment
            callingSSN:(NSString *)callingSSN
             calledSSN:(NSString *)calledSSN;
+ (void)webMtp3Title:(NSMutableString *)s;
+ (void)webMtp3Options:(NSMutableString *)s;

@end

