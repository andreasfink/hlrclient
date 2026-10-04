//
//  MSCSession.m
//  hlrclient
//
//  Created by Andreas Fink on 07.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "MSCInstance.h"
#import "MSCSession.h"

@implementation MSCSession


#define VERIFY_MAP(a,b)\
if( a != b) \
{ \
NSLog(@"ERROR: got MAP=%@ but was expecting MAP=%@",a,b);\
return;\
}


#define VERIFY_DIALOG(a,b)\
if(a==NULL) \
{   \
a = b; \
}\
else \
{\
if(![a isEqualToString:b]) \
{ \
NSLog(@"ERROR: got DialogID=%@ but was expecting DialogID=%@",a,b);\
return;\
}\
}

#define VERIFY_UID(a,b)\
if(a==NULL) \
{   \
a = b; \
}\
else \
{\
if(![a isEqualToString:b]) \
{ \
NSLog(@"ERROR: got UserIdentifier=%@ but was expecting UserIdentifier=%@",a,b);\
return;\
}\
}

- (NSString *)getNewUserIdentifier
{
    return NULL;
}

#pragma mark -
#pragma mark handle incoming components


-(void) sessionMAP_Invoke_Ind:(UMASN1Object *)param
                       userId:(UMGSMMAP_UserIdentifier *)xuserIdentifier
                       dialog:(UMGSMMAP_DialogIdentifier *)xdialogId
                  transaction:(NSString *)xtcapTransactionId
                       opCode:(UMLayerGSMMAP_OpCode *)xopcode
                     invokeId:(int64_t)xinvokeId
                     linkedId:(int64_t)xlinkedId
                         last:(BOOL)xlast
                      options:(NSDictionary *)xoptions
{
    _hasReceivedInvokes++;

    NSLog(@"%@: MAP_Invoke_Ind  userIdentifier:%@ dialog: %@ opcode:%d",
          self.sessionName,
          xuserIdentifier,
          xdialogId,
          (int)xopcode.operation);
    
    self.dialogId = xdialogId;
    self.opcode = xopcode;
    self.tcapLocalTransactionId = xtcapTransactionId;
    
    @try
    {
        switch(xopcode.operation)
        {
            case UMGSMMAP_Opcode_mt_forwardSM:
                NSLog(@"MSCInstance: calling MAP_MT_ForwardSM");
                [self MAP_MT_ForwardSM:param
                                userId:_userIdentifier
                                dialog:xdialogId
                           transaction:xtcapTransactionId
                                opCode:xopcode
                              invokeId:xinvokeId
                              linkedId:xlinkedId
                                  last:xlast
                               options:xoptions];
                break;
            case UMGSMMAP_Opcode_mo_forwardSM:
                NSLog(@"MSCInstance: calling MAP_MO_ForwardSM");
                [self MAP_MO_ForwardSM:param
                                userId:_userIdentifier
                                dialog:xdialogId
                           transaction:xtcapTransactionId
                                opCode:xopcode
                              invokeId:xinvokeId
                              linkedId:xlinkedId
                                  last:xlast
                               options:xoptions];
                break;
            case UMGSMMAP_Opcode_informServiceCentre:
                NSLog(@"MSCInstance: calling MAP_informServiceCentre");
                [self MAP_informServiceCentre:param
                                      userId:_userIdentifier
                                      dialog:xdialogId
                                 transaction:xtcapTransactionId
                                      opCode:xopcode
                                    invokeId:xinvokeId
                                    linkedId:xlinkedId
                                        last:xlast
                                     options:xoptions];
                break;
            case UMGSMMAP_Opcode_alertServiceCentre:
                NSLog(@"MSCInstance: calling MAP_alertServiceCentre");
                [self MAP_alertServiceCentre:param
                                      userId:_userIdentifier
                                      dialog:xdialogId
                                 transaction:xtcapTransactionId
                                      opCode:xopcode
                                    invokeId:xinvokeId
                                    linkedId:xlinkedId
                                        last:xlast
                                     options:xoptions];
            case UMGSMMAP_Opcode_alertServiceCentreWithoutResult:
                NSLog(@"MSCInstance: calling MAP_alertServiceCentreWithoutResult");
                [self MAP_alertServiceCentre:param
                                      userId:_userIdentifier
                                      dialog:xdialogId
                                 transaction:xtcapTransactionId
                                      opCode:xopcode
                                    invokeId:xinvokeId
                                    linkedId:xlinkedId
                                        last:xlast
                                     options:xoptions];

                break;
            case UMGSMMAP_Opcode_insertSubscriberData:
                NSLog(@"VLRSession: calling MAP_InsertSubscriberData");
                [self MAP_InsertSubscriberData:param
                                       userId:_userIdentifier
                                       dialog:xdialogId
                                  transaction:xtcapTransactionId
                                       opCode:xopcode
                                     invokeId:xinvokeId
                                     linkedId:xlinkedId
                                         last:xlast
                                      options:xoptions];
                break;
            default:
                NSLog(@"MSCSession: operation not implemented %d",(int)xopcode.operation);
                [self abort];
        }
    }
    @catch(NSException *e)
    {
        NSLog(@"VLR_Instance: Sending U_Abort due to exception: %@",e);
        [_gInstance.gsmMap queueMAP_U_Abort_Req:xdialogId
                                       options:_options
                                        result:NULL
                                    diagnostic:NULL
                                      userInfo:NULL
                                         cause:UMTCAP_pAbortCause_badlyFormattedTransactionPortion];
    }
}


#pragma mark -
#pragma mark helper methods
- (UMSynchronizedSortedDictionary *)decodeSmsObject:(NSData *)pdu
                                            context:(id)context
{
    return NULL;
}

- (void)sccpTraceSentPdu:(NSData *)data
                 options:(NSDictionary *)options
{
    
}

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"MSCSession [%p]:\n",self];
    [s appendFormat:@"{\n"];
    [s appendFormat:@"\tsessionName: %@\n",_sessionName];
    [s appendFormat:@"\tuserIdentifier: %@\n",_userIdentifier];
    [s appendFormat:@"\tdialogId: %@\n",_dialogId];
    [s appendFormat:@"\ttcapLocalTransactionId: %@\n",_tcapLocalTransactionId];
    [s appendFormat:@"\ttcapRemoteTransactionId: %@\n",_tcapRemoteTransactionId];
    [s appendFormat:@"\tgInstance: '%@'\n",_gInstance.layerName];
    [s appendFormat:@"\topcode %d\n",(int)[self operation]];
    [s appendFormat:@"\topcode2 %d\n",(int)[self operation2]];
    [s appendFormat:@"\topcode3 %d\n",(int)[self operation3]];
    [s appendFormat:@"\tlocalAddress %@\n",_localAddress.description];
    [s appendFormat:@"\tremoteAddress %@\n",_remoteAddress.description];
    [s appendFormat:@"\thttp request %p\n",_req];
    [s appendFormat:@"\tundefinedSession %@\n",_undefinedSession ? @"YES" : @"NO"];
    [s appendFormat:@"}\n"];
    return s;
}

-(void) MAP_MT_ForwardSM:GSMMAP_INVOKE_INDICATION_PARAMETERS
{
    [self abortUnknown];
}

-(void) MAP_MO_ForwardSM:GSMMAP_INVOKE_INDICATION_PARAMETERS
{
    [self abortUnknown];
}

-(void) MAP_alertServiceCentre:GSMMAP_INVOKE_INDICATION_PARAMETERS
{
    [self abortUnknown];
}

-(void) MAP_informServiceCentre:GSMMAP_INVOKE_INDICATION_PARAMETERS
{
    [self abortUnknown];
}

-(void) MAP_InsertSubscriberData:GSMMAP_INVOKE_INDICATION_PARAMETERS
{
    [self abortUnknown];
}


@end
