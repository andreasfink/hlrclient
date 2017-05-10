//
//  MSCTransaction_SendRoutingInfoForSM.m
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "MSCTransaction_SendRoutingInfoForSM.h"
#import "MSCInstance.h"

@implementation MSCTransaction_SendRoutingInfoForSM

-(MSCTransaction_SendRoutingInfoForSM *)initWithHttpReq:(UMHTTPRequest *)hreq
                                               instance:(MSCInstance *)inst
{
    self = [super initWithHttpReq:hreq
                        operation:UMGSMMAP_Opcode_sendRoutingInfoForSM
                         instance:inst];
    if(self)
    {
        transactionName = @"SendRoutingInfoForSM";
    }
    return self;
}

- (void)main
{
    @try
    {
        NSDictionary *p = req.params;

        SET_MANDATORY_PARAMETER(p,msisdn,@"msisdn");
        SET_OPTIONAL_PARAMETER(p,smsc,@"smsc");

        [self handleSccpAddressesDefaultCallingSsn:@"msc"
                                  defaultCalledSsn:@"hlr"
                              defaultCallingNumber:gInstance.instanceAddress
                               defaultCalledNumber:msisdn
                           defaultCalledNumberPlan:SCCP_NPI_ISDN_E164];

        [self setDefaultApplicationContext:UMGSMMAP_ApplicationContextString(UMGSMMAP_ApplicationContext_locationInfoRetrievalContext,3)];


        UMGSMMAP_RoutingInfoForSM_Arg *param = [[UMGSMMAP_RoutingInfoForSM_Arg alloc]init];
        param.sm_RP_PRI = [[UMASN1Boolean alloc]initAsYes];
        MSCInstance *mscInstance = (MSCInstance *)gInstance;
        param.msisdn = [[UMGSMMAP_ISDN_AddressString alloc]initWithString:msisdn];

        if(smsc.length > 0)
        {
            param.serviceCentreAddress = [[UMGSMMAP_ISDN_AddressString alloc]initWithString:smsc];
        }
        else
        {
            param.serviceCentreAddress = [[UMGSMMAP_ISDN_AddressString alloc]initWithString:mscInstance.instanceAddress];
        }
        [self setUserInfo_MAP_Open];
        self.query = param;
        [self submit];
    }
    @catch(NSException *e)
    {
        [self webException:e];
    }
}

+ (NSString *)webForm
{
    static NSMutableString *s = NULL;
    if(s)
    {
        return s;
    }
    s = [[NSMutableString alloc]init];

    [GenericTransaction webFormStart:s title:@"SendRoutingInfoForSM"];
    [GenericTransaction webMapTitle:s];

    [s appendString:@"    <td class=mandatory>msisdn</td>\n"];
    [s appendString:@"    <td class=mandatory><input name=\"msisdn\" type=text placeholder=\"+12345678\"> E.164 Number</td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>smsc</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"smsc\" type=text placeholder=\"+12345678\" value=\"default\"> E.164 Number</td>\n"];
    [s appendString:@"</tr>\n"];

    [GenericTransaction webDialogTitle:s];
    [GenericTransaction webDialogOptions:s];
    [GenericTransaction webTcapTitle:s];
    [GenericTransaction webTcapOptions:s
                            appContext:@"04000001001402"
                        appContextName:@"(shortMsgGatewayContext-v2)"];
    [GenericTransaction webSccpTitle:s];
    [GenericTransaction webSccpOptions:s
                        callingComment:@"msc"
                         calledComment:@"msisdn"
                            callingSSN:@"msc"
                             calledSSN:@"hlr"];
    [GenericTransaction webMtp3Title:s];
    [GenericTransaction webMtp3Options:s];
    [GenericTransaction webFormEnd:s];
    return s;
}

-(void) MAP_ReturnResult_Resp:(UMASN1Object *)param
                       userId:(NSString *)xuserIdentifier
                       dialog:(NSString *)xdialogId
                  transaction:(NSString *)xtcapTransactionId
                       opCode:(UMLayerGSMMAP_OpCode *)xopcode
                     invokeId:(int64_t)xinvokeId
                     linkedId:(int64_t)xlinkedId
                         last:(BOOL)xlast
                      options:(NSDictionary *)xoptions
{
    UMGSMMAP_RoutingInfoForSM_Res *param1 = [[UMGSMMAP_RoutingInfoForSM_Res alloc]initWithASN1Object:param context:NULL];
    [super MAP_ReturnResult_Resp:param1
                          userId:xuserIdentifier
                          dialog:xdialogId
                     transaction:xtcapTransactionId
                          opCode:xopcode
                        invokeId:xinvokeId
                        linkedId:xlinkedId
                            last:xlast
                         options:xoptions];
}


@end
