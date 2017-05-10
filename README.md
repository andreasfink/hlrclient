# hlrclient
HLR Client example using the UniversalSS7 library

To use this example you need a M3UA connection to a signalling provider and a global title

Install the universalSS7 library either from source or from the debian messagemover repository (see www.universalss7.ch).
On MacOS X you can simply install the pkg files instead (sctp, ulib, ulibsctp, ulibm2pa, ulibmtp3, ulibgt, ulibsccp, ulibasn1, ulibtcap, ulibgsmmap, ulibpcap) .

then run

./configure
make

you now have a binary (under linux in the build directory, under macos its hlrclient-release or hlrclient-debug in the main directory.
Now create a config file (you can use hlrclient.conf-example as tempalte).
Place the config under /etc/hlrclient/hlrclient.conf or pass its location as the first parameter on the command line.

Now you can run the binary and it should start up a M3UA connection and start answering on the default HTTP port 8080.

the URL http://127.0.0.1:8080/status

should give you a quick & dirty overview of the status.
All instances should show up with "IS" (in service)

the URL http://127.0.0.1:8080/msc/sendRoutingInfoForSM
presents you with a form to submit a query. you can leave all fields in the default except msisdn.
enter the international number with a + in front.

when successful, you should get a json formatted answer like this:

{
  "query": {
    "msisdn": {
      "ton": 1,
      "npi": 1,
      "address": "123456789"
    },
    "sm-RP-PRI": true,
    "serviceCentreAddress": {
      "ton": 1,
      "npi": 1,
      "address": "987654321"
    }
  },
  "responses": [
    {
      "rx": {
        "ReturnResultLast": {
          "invokeId": 0,
          "RoutingInfoForSM_Res": {
            "imsi": "001019988776655",
            "locationInfoWithLMSI": {
              "networkNode-Number": {
                "ton": 1,
                "npi": 1,
                "address": "8888888888"
              }
            }
          }
        }
      }
    }
  ],
  "sccp-info": {
    "sccp-remote-address": {
      "ai": {
        "routing-indicator-bit": false,
        "sub-system-indicator": true,
        "national-reserved-bit": false,
        "global-title-indicator": 4,
        "point-code-indicator": false
      },
      "ssn": 6,
      "tt": 0,
      "nai": 4,
      "npi": 1,
      "address": "8888888800"
    },
    "sccp-local-address": {
      "ai": {
        "routing-indicator-bit": false,
        "sub-system-indicator": true,
        "national-reserved-bit": false,
        "global-title-indicator": 4,
        "point-code-indicator": false
      },
      "ssn": 8,
      "tt": 0,
      "nai": 4,
      "npi": 1,
      "address": "987654321"
    }
  },
  "user-identifier": "M00000002",
  "map-dialog-id": "D00000002",
  "tcap-transaction-id": "04091440",
  "tcap-end-indicator": true
}

