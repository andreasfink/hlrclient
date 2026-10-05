//
//  AppDelegate.m
//  gsm-api
//
//  Created by Andreas Fink on 14.12.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//
#import "../version.h"

#import "AppDelegate.h"
#import <ulibss7config/ulibss7config.h>
#import <uliblicense/uliblicense.h>

#import "MSCInstance.h"

#include <sys/types.h>
#include <unistd.h>
#include <sys/resource.h>

#define CONFIG_ERROR(s)     [NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__] reason:s userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]

@implementation AppDelegate

-(AppDelegate *)init
{
    NSDictionary *appOptions = @
    {
        @"msc": @(YES),
        @"hlr": @(NO),
        @"vlr": @(NO),
        @"eir": @(NO),
        @"gsmscf": @(NO),
        @"gmlc": @(NO),
        @"camel": @(NO),
        @"umtransport": @(NO),
        @"imsi-pool": @(NO),
    };
    self = [super initWithOptions:appOptions];
    if(self)
    {
        _coreFeature        = [[UMLicenseProductFeature alloc]initWithName:@"core"];
        _sctpFeature        = [[UMLicenseProductFeature alloc]initWithName:@"sctp"];
        _m2paFeature        = [[UMLicenseProductFeature alloc]initWithName:@"m2pa"];
        _mtp3Feature        = [[UMLicenseProductFeature alloc]initWithName:@"mtp3"];
        _m3uaFeature        = [[UMLicenseProductFeature alloc]initWithName:@"m3ua"];
        _sccpFeature        = [[UMLicenseProductFeature alloc]initWithName:@"sccp"];
        _tcapFeature        = [[UMLicenseProductFeature alloc]initWithName:@"tcap"];
        _gsmmapFeature      = [[UMLicenseProductFeature alloc]initWithName:@"gsmmap"];

        /* _umtransportService  is initialized in creatInstances */
        if([self increaseMaximumOpenFiles:16384]==NO)
        {
            if([self increaseMaximumOpenFiles:8192]==NO)
            {
                if([self increaseMaximumOpenFiles:4096]==NO)
                {
                    if([self increaseMaximumOpenFiles:2048]==NO)
                    {
                        if([self increaseMaximumOpenFiles:1024]==NO)
                        {
                            NSLog(@"Maximum open files is smaller than 1024. This wont work. Recommendation: increase by calling  'ulimit -n {value}'  where value >= 16384" );
                            exit(-1);
                        }
                    }
                }
            }
        }
    }
    return self;
}


- (NSString *)productName
{
    return @"hlrclient";
}

- (NSString *)productVersion
{
    return @(VERSION);
}

- (NSString *)productCopyright
{
    return @"© 2026 Andreas Fink";
}

- (NSString *)defaultConfigFile
{
    return @"/etc/hlrclient/hlrclient.conf";
}

- (NSString *)defaultLogDirectory
{
    return @"/var/log/hlrclient/";
}

- (int)defaultWebPort
{
    return 8086;
}
- (NSString *)defaultWebUser
{
    return @"admin";
}
- (NSString *)defaultWebPassword
{
    return @"admin";
}


- (NSArray *)commandLineSyntax
{
    return @[
             @{
                 @"name"  : @"version",
                 @"short" : @"-V",
                 @"long"  : @"--version",
                 @"help"  : @"shows the software version"
                 },
             @{
                 @"name"  : @"verbose",
                 @"short" : @"-v",
                 @"long"  : @"--verbose",
                 @"help"  : @"enables verbose mode"
                 },
             @{
                 @"name"  : @"help",
                 @"short" : @"-h",
                 @"long" : @"--help",
                 @"help"  : @"shows the help screen",
                 },
             @{
                 @"name"  : @"config",
                 @"short" : @"-c",
                 @"long"  : @"--read-config",
                 @"multi" : @(YES),
                 @"argument" : @"filename",
                 @"help"  : @"reads the indicated config (defaults to /etc/gsm-api/gsm-api.conf)",
                 },
             @{
                 @"name"  : @"print-config",
                 @"short" : @"",
                 @"long"  : @"--print-config",
                 @"help"  : @"prints the combined config to stdout",
                 },
             @{
                 @"name"  : @"pid-file",
                 @"short" : @"",
                 @"long"  : @"--pid-file",
                 @"argument" : @"filename",
                 @"help"  : @"writes the process-id to the indicated file",
                 },
             @{
                 @"name"  : @"quiet",
                 @"short" : @"-q",
                 @"long"  : @"--quiet",
                 @"help"  : @"silences output",
                 },
             @{
                 @"name"  : @"debug",
                 @"short" : @"-d",
                 @"long"  : @"--debug",
                 @"argument" : @"debug-option",
                 @"multi" : @(YES),
                 @"help"  : @"enables the named debug option(s)",
                 },
             ];
}



- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [self.logFeed infoText:@"Application will terminate"];

    // Insert code here to tear down your application
}


- (void)addAccessControlAllowOriginHeaders:(UMHTTPRequest *)req
{
    if(_runningConfig.generalConfig.hostname)
    {
        NSArray *keys = [_webserver_dict allKeys];
        for(NSString *key in keys)
        {
            UMHTTPServer *ws = _webserver_dict[key];
            if(ws.enableSSL)
            {
                if(ws.listenerSocket.localPort == 443)
                {
                    [req setResponseHeader:@"Access-Control-Allow-Origin" withValue:[NSString stringWithFormat:@"https://%@/",_runningConfig.generalConfig.hostname]];
                }
                else
                {
                    [req setResponseHeader:@"Access-Control-Allow-Origin" withValue:[NSString stringWithFormat:@"https://%@:%d/",_runningConfig.generalConfig.hostname,ws.listenerSocket.localPort]];
                }
            }
            else
            {
                if(ws.listenerSocket.localPort == 80)
                {
                    [req setResponseHeader:@"Access-Control-Allow-Origin" withValue:[NSString stringWithFormat:@"http://%@/",_runningConfig.generalConfig.hostname]];
                }
                else
                {
                    [req setResponseHeader:@"Access-Control-Allow-Origin" withValue:[NSString stringWithFormat:@"http://%@:%d/",_runningConfig.generalConfig.hostname,ws.listenerSocket.localPort]];
                }
            }
        }
    }
    else
    {
        [req setResponseHeader:@"Access-Control-Allow-Origin" withValue:@"*"];
    }
    [req setResponseHeader:@"Access-Control-Allow-Methods" withValue:@"GET, POST"];
}


- (void)  httpGetPost:(UMHTTPRequest *)req
{
    @autoreleasepool
    {
        NSString *path = req.url.relativePath;
        
        UMHTTPAuthenticationStatus status = [self httpRequireAdminAuthorisation:req realm:@"service"];
        if( status == UMHTTP_AUTHENTICATION_STATUS_PASSED)
        {
            if([path isEqualToString:@"/"])
            {
                NSString *s = [self webIndex];
                [req setResponseHtmlString:s];
            }

            if([path hasPrefix:@"/msc"])
            {
                [_mainMscInstance httpGetPost:req];
            }
            else if([path isEqualToString:@"/status"])
            {
                [self handleStatus:req];
            }
            else if(([path isEqualToString:@"/decode/mtp3"])
                    ||([path isEqualToString:@"/mtp3/decode"]))
            {
                [self handleDecodeMtp3:req];
            }
            else if([path isEqualToString:@"/mtp3/routing-table"])
            {
                [self handleMtp3RoutingTable:req];
            }
            else if([path isEqualToString:@"/mtp3/routing-update"])
            {
                [self handleMtp3RoutingUpdate:req];
            }
            else if(([path isEqualToString:@"/decode-sccp"])
                    ||([path isEqualToString:@"/sccp/decode"]))
            {
                [self handleDecodeSccp:req];
            }
            else if([path isEqualToString:@"/sccp/inject"])
            {
                [self handleInjectSccp:req];
            }
            else if([path isEqualToString:@"/sms/decode"])
            {
                [self handleDecodeSms:req];
            }
            else if(([path isEqualToString:@"/decode/tcap"])
                    ||  ([path isEqualToString:@"/tcap/decode"]))
            {
                [self handleDecodeTcap:req];
            }
            else if([path isEqualToString:@"/decode/tcap2"])
            {
                [self handleDecodeTcap2:req];
            }
            else if(([path isEqualToString:@"/decode/asn1"])
                    || ([path isEqualToString:@"/asn1/decode"]))
            {
                [self handleDecodeAsn1:req];
            }
            else if([path isEqualToString:@"/"])
            {
                NSString *s = [self webIndex];
                [req setResponseHtmlString:s];
            }
            else if([path isEqualToString:@"/debug"])
            {
                NSString *s = [self webIndexDebug];
                [req setResponseHtmlString:s];
            }
            else if([path isEqualToString:@"/debug/umobject-stat"])
            {
                [self umobjectStat:req];
            }
            else if([path isEqualToString:@"/debug/ummutex-stat"])
            {
                [self ummutexStat:req];
            }
            
            else if(([path isEqualToString:@"/decode/sms"])
                    ||  ([path isEqualToString:@"/sms/decode"]))
            {
                [self handleDecodeSms:req];
            }
            
            else if(([path isEqualToString:@"/sccp/decode"])
                    ||  ([path isEqualToString:@"/decode/sccp"]))
                
            {
                [self handleDecodeSccp:req];
            }
            
            else if([path isEqualToString:@"/decode"])
            {
                [self handleDecode:req];
            }
            else
            {
                return [super httpGetPost:req];
            }
        }
    }
}

- (NSString *)webIndex
{
    NSMutableString *s = NULL;
    s = [[NSMutableString alloc]init];
    [SS7GenericInstance webHeader:s title:@"Main Menu"];

    [s appendString:@"<h2>Main Menu</h2>\n"];
    [s appendString:@"<UL>\n"];


    /* FIXME: missing subsystems to implement:

     ISUP (ansi)
     OMAP (ansi)
     MAP (ansi)
     EIR
     AUTH
     SMSC
     PCAP
     BSC_BSSAP_LE
     MSC_BSSAP_LE
     SMLC_BSSAP_LE
     BSS_O_AND_M
     RANAP
     RNSAP
     CAP
     SIWF
     SGSN
     GGSN
     INAP
     CNAM
     LNP
     800_NUMBER_TRANSLATION_
     800_NUMBER_TRANSLATION_TCAP

     */

    if(_mainMscInstance)
    {
        [s appendString:@"<LI><a href=\"/msc\">msc</a></LI>\n"];
    }
    else
    {
        [s appendString:@"<LI><i>msc</i></LI>\n"];
    }
    
    
    [s appendString:@"<LI><a href=\"/decode\">decode</a></LI>\n"];

    [s appendString:@"</UL>\n"];
    [s appendString:@"</body>\n"];
    [s appendString:@"</html>\n"];
    return s;
}

- (NSString *)webIndexDebug
{
    static NSMutableString *s = NULL;
    if(s)
    {
        return s;
    }
    s = [[NSMutableString alloc]init];

    [s appendString:@"<html>\n"];
    [s appendString:@"<header>\n"];
    [s appendString:@"    <link rel=\"stylesheet\" href=\"/css/style.css\" type=\"text/css\">\n"];
    [s appendFormat:@"    <title>Debug Menu</title>\n"];
    [s appendString:@"</header>\n"];
    [s appendString:@"<body>\n"];

    [s appendString:@"<h2>Debug Menu</h2>\n"];
    [s appendString:@"<UL>\n"];
    [s appendString:@"<LI><a href=\"/\">&lt-- main-menu</a></LI>\n"];
    [s appendString:@"<LI><a href=\"/debug/umobject-stat\">umobject-stat</a></LI>\n"];
    [s appendString:@"</UL>\n"];
    [s appendString:@"</body>\n"];
    [s appendString:@"</html>\n"];
    return s;
}


- (NSString *)handleApiCall:(UMHTTPRequest *)req
{
    return @"not-yet-implemented";
}


+ (NSString *)css
{
    static NSMutableString *s = NULL;

    if(s)
    {
        return s;
    }
    s = [[NSMutableString alloc]init];

    [s appendString:@"/*-- [START] css/mainarea.css --*/\n"];
    [s appendString:@"\n"];
    [s appendString:@"body\n"];
    [s appendString:@"{\n"];
    [s appendString:@"    border: none;\n"];
    [s appendString:@"    padding: 20px;\n"];
    [s appendString:@"    margin: 0px;\n"];
    [s appendString:@"    background-color:white;\n"];
    [s appendString:@"    color: black;\n"];
    [s appendString:@"    font-family: 'Metrophobic', \"Lucida Grande\", \"Lucida Sans Unicode\", arial, Helvetica, Verdana;\n"];
    [s appendString:@"    font-size: 11px;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"h1 {\n"];
    [s appendString:@"    font-size: 22px;\n"];
    [s appendString:@"    font-weight: normal;\n"];
    [s appendString:@"    padding-left: 0px;\n"];
    [s appendString:@"    margin-top: 15px;\n"];
    [s appendString:@"    margin-bottom: 20px;\n"];
    [s appendString:@"    color: #639c35;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"h2 {\n"];
    [s appendString:@"    font-size: 16px;\n"];
    [s appendString:@"    margin-bottom: 8px;\n"];
    [s appendString:@"    margin-top: 10px;\n"];
    [s appendString:@"    color: #639c35;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"\n"];
    [s appendString:@"h3 {\n"];
    [s appendString:@"    font-size: 13px;\n"];
    [s appendString:@"    margin-bottom: 8px;\n"];
    [s appendString:@"    margin-top: 10px;\n"];
    [s appendString:@"    \n"];
    [s appendString:@"    color: black;\n"];
    [s appendString:@"    font-weight: bold;\n"];
    [s appendString:@"    font-family: 'Metrophobic', \"Lucida Grande\", \"Lucida Sans Unicode\", arial, Helvetica, Verdana;\n"];
    [s appendString:@"    font-size: 13px;\n"];
    [s appendString:@"\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"a {\n"];
    [s appendString:@"    color: #000066;\n"];
    [s appendString:@"    text-decoration: underline;\n"];
    [s appendString:@"    font-weight: bold;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"a:hover {\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"\n"];
    [s appendString:@"hr {\n"];
    [s appendString:@"    height: 1px;\n"];
    [s appendString:@"    margin-bottom: 1em;\n"];
    [s appendString:@"    border-width: 0px;\n"];
    [s appendString:@"    border-bottom-width: 1px;\n"];
    [s appendString:@"    border-color: #000000;\n"];
    [s appendString:@"    border-style: solid;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"\n"];
    [s appendString:@".mandatory {\n"];
    [s appendString:@"    color: red;\n"];
    [s appendString:@"    font-weight: bold;\n"];
    [s appendString:@"    font-family: 'Metrophobic', \"Lucida Grande\", \"Lucida Sans Unicode\", arial, Helvetica, Verdana;\n"];
    [s appendString:@"    font-size: 11px;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@".optional {\n"];
    [s appendString:@"    color: green;\n"];
    [s appendString:@"    font-weight: lighter;\n"];
    [s appendString:@"    font-family: 'Metrophobic', \"Lucida Grande\", \"Lucida Sans Unicode\", arial, Helvetica, Verdana;\n"];
    [s appendString:@"    font-size: 11px;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@".subtitle {\n"];
    [s appendString:@"    color: black;\n"];
    [s appendString:@"    font-weight: bold;\n"];
    [s appendString:@"    font-family: 'Metrophobic', \"Lucida Grande\", \"Lucida Sans Unicode\", arial, Helvetica, Verdana;\n"];
    [s appendString:@"    font-size: 12px;\n"];
    [s appendString:@"}\n"];
    [s appendString:@".object_table     {  border: solid black; border-width: 1px; border-collapse: collapse; }\n"];
    [s appendString:@".object_title     {  border: solid black; border-width: 1px; background-color: #DDDDDD; }\n"];
    [s appendString:@".object_value     {  border: solid gray; border-width: 1px; }\n"];
    [s appendString:@".object_value_r   {  border: solid gray; border-width: 1px; text-align: right; }\n"];
    [s appendString:@"}\n"];
    return s;
}

- (UMHTTPAuthenticationStatus)httpAuthenticateRequest:(UMHTTPRequest *)req
                                                realm:(NSString **)realm
{
    return UMHTTP_AUTHENTICATION_STATUS_PASSED;
}



- (void)  handleInjectSccp:(UMHTTPRequest *)req
{
    NSString *pdu = req.params[@"hexpdu"];
    if(pdu==NULL)
    {
        NSMutableString *s = [[NSMutableString alloc]init];
        [SS7GenericInstance webHeader:s title:@"SCCP Inject"];
        [s appendFormat:@"<h3>SCCP Inject</h3>\r"];
        [s appendFormat:@"<form><pre>\r"];
        [s appendFormat:@"SCCP HEX PDU:<input type=text name=hexpdu size=80><br>\r"];
        [s appendFormat:@"<input type=submit>\r"];
        [s appendFormat:@"</pre></form>\r"];
        [s appendFormat:@"</body>\r"];
        [s appendFormat:@"</html>\r"];
        [req setResponseHtmlString:s];
    }
    else
    {
        NSArray *sccpLayerKeys = [_sccp_dict allKeys];
        if([sccpLayerKeys count]>=1)
        {
            NSString *key = sccpLayerKeys[0];
            UMLayerSCCP *sccp = _sccp_dict[key];

            UMSCCP_mtpTransfer *task;
            UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWitPc:1 variant:UMMTP3Variant_ITU];
            task = [[UMSCCP_mtpTransfer alloc]initForSccp:sccp
                                                     mtp3:NULL
                                                      opc:pc
                                                      dpc:pc
                                                       si:3
                                                       ni:0
                                                      sls:0
                                                     data:[pdu unhexedData]
                                                  options:@{ @"injected" : @YES }
                                                      map:NULL
                                      incomingLinksetName:@"inject"];
            [task main];
            NSString *json = [task.decodedJson jsonString];
            NSLog(@"Decoded %@",json);
            [req setResponsePlainText:json];
        }
        else
        {
            [req setResponseHtmlString:@"no sccp found"];
        }
    }
    return;
}







- (void)  handleMtp3RoutingTable:(UMHTTPRequest *)req
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc]init];
    NSArray *keys = [_mtp3_dict allKeys];
    for(id key in keys)
    {
        UMLayerMTP3 *mtp3 = _mtp3_dict[key];
        UMMTP3InstanceRoutingTable *rt = mtp3.routingTable;
        UMSynchronizedDictionary *rtd = [rt objectValue];
        d[mtp3.layerName] = rtd;
    }
    [req setResponsePlainText: [d jsonString]];
}

- (void)  handleMtp3RoutingUpdate:(UMHTTPRequest *)req
{

    NSString *mtp3_instance = req.params[@"mtp3"];
    NSString *linkset_name = req.params[@"linkset"];
    NSString *pc_string = req.params[@"pc"];
    NSString *update = req.params[@"update"];
    if((mtp3_instance.length==0) || (linkset_name.length == 0) || (pc_string.length == 0) || (update.length == 0))
    {
        NSMutableString *s = [[NSMutableString alloc]init];
        [SS7GenericInstance webHeader:s title:@"MTP3 Routing Update"];
        [s appendFormat:@"<h3>Advertize a pointcode to a linkset</h3>\r\n"];
        [s appendFormat:@"<form><pre>\r\n"];
        [s appendFormat:@"mtp3-instance:<input type=text name=mtp3>\r\n"];
        [s appendFormat:@"linkset:      <input type=text name=linkset>\r\n"];
        [s appendFormat:@"pointcode:    <input type=text name=pc>\r\n"];
        [s appendFormat:@"update:       <select name=update><option selected>available</option><option>unavailable</option><option>restricted</option></select>\r\n"];
        [s appendFormat:@"<input type=submit>\r\n"];
        [s appendFormat:@"</form>\r\n"];
        [s appendFormat:@"</body>\r\n"];
        [s appendFormat:@"</html>\r\n"];
        [req setResponseHtmlString:s];
    }
    else
    {
        UMLayerMTP3 *mtp3 = _mtp3_dict[mtp3_instance];
        if(mtp3 == NULL)
        {
            [req setResponsePlainText:@"mtp3 instance not found"];
            return;
        }

        UMMTP3LinkSet *linkset = [mtp3 getLinkSetByName:linkset_name];
        if(linkset == NULL)
        {
            [req setResponsePlainText:@"linkset not found"];
            return;
        }
        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithString:pc_string variant:mtp3.variant];
        if([update isEqualToString:@"available"])
        {
            [linkset advertizePointcodeAvailable:pc mask:pc.maxmask];
            [req setResponsePlainText:@"OK"];
        }
        else if([update isEqualToString:@"unavailable"])
        {
            [linkset advertizePointcodeUnavailable:pc mask:pc.maxmask];
            [req setResponsePlainText:@"OK"];
        }
        else if([update isEqualToString:@"restricted"])
        {
            [linkset advertizePointcodeRestricted:pc mask:pc.maxmask];
            [req setResponsePlainText:@"OK"];

        }
        else
        {
            [req setResponsePlainText:@"unknown-update-type"];
        }

    }
    return;
}




-(void)createInstances
{
    [super createInstances];
    NSArray *names;

    /*****************************************************************/
    /* MSC */
    /*****************************************************************/
    names = [_runningConfig getMSCNames];
    for(NSString *name in names)
    {
        UMSS7ConfigObject *co = [_runningConfig getMSC:name];
        NSDictionary *config = co.config.dictionaryCopy;
        if( [config configEnabledWithYesDefault])
        {
            [self addWithConfigMSC:config];
        }
    }

 
}

#pragma mark -
#pragma mark MSC
- (MSCInstance *)getMSC:(NSString *)name
{
    return _msc_dict[name];
}

- (void)addWithConfigMSC:(NSDictionary *)config
{
    NSString *name = config[@"name"];
    if(name)
    {
        UMSS7ConfigMSC *co = [[UMSS7ConfigMSC alloc]initWithConfig:config];
        [_runningConfig addMSC:co];

        config = co.config.dictionaryCopy;
        int concurrentTasks = [[self concurrentTasksForConfig:co] intValue];
        UMTaskQueueMulti *_mscTaskQueue = [[UMTaskQueueMulti alloc]initWithNumberOfThreads:concurrentTasks
                                                                                      name:@"msc"
                                                                             enableLogging:NO
                                                                            numberOfQueues:UMLAYER_QUEUE_COUNT];

        MSCInstance *msc = [[MSCInstance alloc]initWithTaskQueueMulti:_mscTaskQueue];
        msc.logFeed = [[UMLogFeed alloc]initWithHandler:_logHandler section:@"msc"];
        msc.logFeed.name = name;
        msc.webClient = _webClient;
        msc.authDelegate = self;
        [msc setConfig:config applicationContext:self];
        _msc_dict[name] = msc;

        UMLayerGSMMAP *map  = [self getGSMMAP:co.attachTo];
        if(map==NULL)
        {
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"MSC %@ can not attach to GSM-MAP %@",name,co.attachTo]];
        }
        else
        {
            msc.gsmMap = map;
            map.user = msc;
        }
        if(!_mainMscInstance)
        {
            _mainMscInstance = msc;
        }
    }
}

- (void)deleteMSC:(NSString *)name
{
    //MSCInstance *instance =  _msc_dict[name];
    [_msc_dict removeObjectForKey:name];
    //    [instance stopDetachAndDestroy];

}

- (void)renameMSC:(NSString *)oldName to:(NSString *)newName
{
    MSCInstance *layer =  _msc_dict[oldName];
    [_msc_dict removeObjectForKey:oldName];
    layer.layerName = newName;
    _msc_dict[newName] = layer;
}

@end
