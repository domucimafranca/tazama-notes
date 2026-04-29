## Background

While the Tazama testing suite provides Postman collections to use against the Full-Stack-Docker-Tazama installation, I sought to recreate the process using bare API calls with only `curl` commands. This was a good way to test my understanding of the setup.

The starting point was option 2 of the full stack Docker installation.  This setup activated a network map with rules 901 and 902.  While it seems a little bare, it's sufficient to run tests based on amount and velocity.

## Tazama setup
The starting point is, of course, the GitHub repo https://github.com/tazama-lf/Full-Stack-Docker-Tazama.  This is fairly well-documented to run, so we repeat the details.  Just to add that it is possible to recreate the setup just specifying the Docker compose files to use.

```
docker compose -f docker-compose.base.infrastructure.yaml -f docker-compose.base.override.yaml -f docker-compose.hub.cfg.yaml -f docker-compose.hub.core.yaml -f docker-compose.hub.rules.yaml -f docker-compose.hub.relay.yaml -f docker-compose.hub.logs.base.yaml -f docker-compose.utils.nats-utils.yaml -f docker-compose.utils.pgadmin.yaml -f docker-compose.utils.hasura.yaml -p tazama up -d
```


### Additional notes on interacting with the database
Configurations and results can be found on the Postgres database.  Rather than using CLI to navigate through the database, we can use Hasura as user interface.  It is accessible via `https://tazama:6100`.  For the default installation, the password is `password`

Under the `data` tab, there are:
- `configuration` database, which contains
	- `network map` table
	- `rule` table
	- `typology` table
- `evaluation` database, which contains
	- `evaluation` table, the results of the evaluations
- `event_history` database
- `raw_history` database


## Getting the current configuration
There are two ways to get the network map configuration.  One is by looking at the configuration table of the database, accessible via Hasura (see above); the other is via a curl request to the Tazama server:

```
curl -X GET http://localhost:5100/v1/admin/configuration/network_map \
     -H "Content-Type: application/json"
```

The output is
```
{
  "data": [
    {
      "active": true,
      "cfg": "1.0.0",
      "messages": [
        {
          "id": "004@1.0.0",
          "cfg": "1.0.0",
          "txTp": "pacs.002.001.12",
          "typologies": [
            {
              "id": "typology-processor@1.0.0",
              "cfg": "999@1.0.0",
              "rules": [
                {
                  "id": "EFRuP@1.0.0",
                  "cfg": "none"
                },
                {
                  "id": "901@1.0.0",
                  "cfg": "1.0.0"
                },
                {
                  "id": "902@1.0.0",
                  "cfg": "1.0.0"
                }
              ],
              "tenantId": "DEFAULT"
            }
          ]
        }
      ],
      "name": "Public Network Map",
      "tenantId": "DEFAULT"
    }
  ],
  "meta": {
    "total": 1,
    "limit": 20,
    "offset": 0
  }
}
```

The typologies may likewise be extracted using curl.
```
curl -X GET http://localhost:5100/v1/admin/configuration/typology \
     -H "Content-Type: application/json"
```

As with the rules.
```
curl -s -X GET "http://localhost:5100/v1/admin/configuration/rule/901%401.0.0/1.0.0" \
     -H "Content-Type: application/json" | jq
```

```
curl -s -X GET "http://localhost:5100/v1/admin/configuration/rule/902%401.0.0/1.0.0" \
     -H "Content-Type: application/json" | jq
```

## Prepopulating the database

> Update (2026-04-29)
> This step may not be necessary after all.  After more testing, it looks like sending a pacs.008 message already performs an upsert into the account and entities tables, which would then satisfy the requirements for its corresponding pacs.002 message.  I will post a follow up note with more details on this.

Since we're following the Postman collection, the starting point is to prepopulate the database with accounts; else the transactions will fail on account of integrity checks.

The following command is executed via Hasura.
```
mutation SeedPOCData {
  # 1. Create the Entities (The 'People')
  insert_entity(objects: [
    {id: "SENDER-001TAZAMA_EID", tenantid: "DEFAULT", credttm: "2026-04-28T14:00:00Z"},
    {id: "RECEIVER-999TAZAMA_EID", tenantid: "DEFAULT", credttm: "2026-04-28T14:00:00Z"}
  ]) {
    affected_rows
  }

  # 2. Create the Accounts (The 'IBANs/Wallets')
  insert_account(objects: [
    {id: "SENDER-001MSISDNfsp001", tenantid: "DEFAULT"},
    {id: "RECEIVER-999MSISDNfsp002", tenantid: "DEFAULT"}
  ]) {
    affected_rows
  }

  # 3. Link them together
  insert_account_holder(objects: [
    {
      source: "SENDER-001TAZAMA_EID", 
      destination: "SENDER-001MSISDNfsp001", 
      tenantid: "DEFAULT", 
      credttm: "2026-04-28T14:00:00Z"
    },
    {
      source: "RECEIVER-999TAZAMA_EID", 
      destination: "RECEIVER-999MSISDNfsp002", 
      tenantid: "DEFAULT", 
      credttm: "2026-04-28T14:00:00Z"
    }
  ]) {
    affected_rows
  }
}
```

Basically, it creates entities and accounts and links them together.  

Unfortunately in the current configuration, Tazama will reject messages without the corresponding entities and accounts.  **TO-DO**: Figure out how auto-provisioning of accounts and entities works in Tazama.

## Sending pacs.008 and pacs.002 messages
In the default example, pacs.008 and pacs.002 must be sent in pairs (I first tried with just pacs.002 messages but it failed.)  

To recreate the Postman collection, we create a template pacs.008 JSON file

trigger_pacs008.json
```
{
  "TxTp": "pacs.008.001.10",
  "FIToFICstmrCdtTrf": {
    "GrpHdr": {
      "MsgId": "PAC8-{{ID}}",
      "CreDtTm": "2026-04-28T14:15:00.000Z",
      "NbOfTxs": 1,
      "SttlmInf": { "SttlmMtd": "CLRG" }
    },
    "CdtTrfTxInf": {
      "PmtId": { 
        "InstrId": "5ab4fc7355de4ef8a75b78b00a681ed2",
        "EndToEndId": "E2E-{{ID}}" 
      },
      "IntrBkSttlmAmt": { "Amt": { "Amt": 1500.00, "Ccy": "USD" } },
      "InstdAmt": { "Amt": { "Amt": 1500.00, "Ccy": "USD" } },
      "XchgRate": 1.0,
      "ChrgBr": "DEBT",
      "ChrgsInf": {
        "Amt": { "Amt": 0.00, "Ccy": "USD" },
        "Agt": { "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp001" } } }
      },
      "InitgPty": {
        "Nm": "SENDER-001",
        "Id": { 
          "PrvtId": { 
            "DtAndPlcOfBirth": { "BirthDt": "1968-02-01", "CityOfBirth": "Unknown", "CtryOfBirth": "ZZ" },
            "Othr": [{ "Id": "SENDER-001", "SchmeNm": { "Prtry": "TAZAMA_EID" } }] 
          } 
        },
        "CtctDtls": { "MobNb": "+27-730975224" }
      },
      "Dbtr": {
        "Nm": "SENDER-001",
        "Id": { 
          "PrvtId": { 
            "DtAndPlcOfBirth": { "BirthDt": "1968-02-01", "CityOfBirth": "Unknown", "CtryOfBirth": "ZZ" },
            "Othr": [{ "Id": "SENDER-001", "SchmeNm": { "Prtry": "TAZAMA_EID" } }] 
          } 
        },
        "CtctDtls": { "MobNb": "+27-730975224" }
      },
      "DbtrAcct": {
        "Id": { "Othr": [{ "Id": "SENDER-001", "SchmeNm": { "Prtry": "MSISDN" } }] },
        "Nm": "SENDER-001-ACCOUNT"
      },
      "DbtrAgt": { "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp001" } } },
      "CdtrAgt": { "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp002" } } },
      "Cdtr": {
        "Nm": "RECEIVER-999",
        "Id": { 
          "PrvtId": { 
            "DtAndPlcOfBirth": { "BirthDt": "1935-05-08", "CityOfBirth": "Unknown", "CtryOfBirth": "ZZ" },
            "Othr": [{ "Id": "RECEIVER-999", "SchmeNm": { "Prtry": "TAZAMA_EID" } }] 
          } 
        },
        "CtctDtls": { "MobNb": "+27-707650428" }
      },
      "CdtrAcct": {
        "Id": { "Othr": [{ "Id": "RECEIVER-999", "SchmeNm": { "Prtry": "MSISDN" } }] },
        "Nm": "RECEIVER-999-ACCOUNT"
      },
      "Purp": { "Cd": "MP2P" }
    },
    "RgltryRptg": {
      "Dtls": { "Tp": "BALANCE OF PAYMENTS", "Cd": "100" }
    },
    "RmtInf": { "Ustrd": "POC Test Payment" },
    "SplmtryData": {
      "Envlp": { 
        "Doc": { 
          "Xprtn": "2026-12-31T23:59:59.000Z",
          "InitgPty": { "Glctn": { "Lat": "-3.1609", "Long": "38.3588" } } 
        } 
      }
    }
  },
  "DataCache": {
    "dbtrId": "SENDER-001TAZAMA_EID",
    "cdtrId": "RECEIVER-999TAZAMA_EID",
    "dbtrAcctId": "SENDER-001MSISDNfsp001",
    "cdtrAcctId": "RECEIVER-999MSISDNfsp002",
    "creDtTm": "2026-04-28T14:15:00.000Z",
    "instdAmt": { "amt": 1500.00, "ccy": "USD" }
  },
  "tenantId": "DEFAULT"
}
```

And then its pair pacs.002 file:

trigger_pacs002.json
```
{
  "TxTp": "pacs.002.001.12",
  "FIToFIPmtSts": {
    "GrpHdr": {
      "MsgId": "POC-MSG-{{ID}}",
      "CreDtTm": "2026-04-28T14:12:00.000Z"
    },
    "TxInfAndSts": {
      "OrgnlInstrId": "5ab4fc7355de4ef8a75b78b00a681ed2",
      "OrgnlEndToEndId": "E2E-{{ID}}",
      "TxSts": "ACCC",
      "AccptncDtTm": "2026-04-28T14:12:05.000Z",
      "ChrgsInf": [
        {
          "Amt": { "Amt": 0.00, "Ccy": "USD" },
          "Agt": { "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp001" } } }
        }
      ],
      "InstgAgt": {
        "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp001" } }
      },
      "InstdAgt": {
        "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp002" } }
      }
    }
  },
  "DataCache": {
    "dbtrId": "SENDER-001TAZAMA_EID",
    "cdtrId": "RECEIVER-999TAZAMA_EID",
    "dbtrAcctId": "SENDER-001MSISDNfsp001",
    "cdtrAcctId": "RECEIVER-999MSISDNfsp002",
    "creDtTm": "2026-04-28T14:12:00.000Z",
    "instdAmt": { "amt": 1500.00, "ccy": "USD" },
    "intrBkSttlmAmt": { "amt": 1500.00, "ccy": "USD" },
    "xchgRate": 1.0
  },
  "tenantId": "DEFAULT"
}
```

Why do we need to pair pacs.002 with a corresponding pacs.008?

The Transaction Monitoring Suite (TMS) uses the .008 to "anchor" the transaction in the database.  Without the .008, the .002 (a status report) has no "Source" or "Destination" metadata to feed the rules, because those details are historically stored in the initial payment request.

In short: You cannot have a status report (pacs.002) for a transaction that the system hasn't recorded yet (pacs.008)

Finally, the driver script that actually sends the messages

send.sh
```
#!/bin/bash
HOST="tazama:5000"

for i in {1..3}
do
  TX_ID=$(date +%s%N)
  echo "--- Loop $i: Processing EndToEndId E2E-$TX_ID ---"

  # Step 1: Send pacs.008
  sed "s/{{ID}}/$TX_ID/g" trigger_pacs008.json > current_pacs008.json
  RESPONSE_008=$(curl -s -X POST "http://$HOST/v1/evaluate/iso20022/pacs.008.001.10" \
       -H "Content-Type: application/json" -d @current_pacs008.json)
  
  echo "pacs.008 Response: $RESPONSE_008"

  # Only proceed to Step 2 if Step 1 was accepted
  if [[ $RESPONSE_008 == *"Transaction is valid"* ]]; then
    echo "pacs.008 Accepted. Sending pacs.002..."
    sleep 1
    
    sed "s/{{ID}}/$TX_ID/g" trigger_pacs002.json > current_pacs002.json
    RESPONSE_002=$(curl -s -X POST "http://$HOST/v1/evaluate/iso20022/pacs.002.001.12" \
         -H "Content-Type: application/json" -d @current_pacs002.json)
    echo "pacs.002 Response: $RESPONSE_002"
  else
    echo "pacs.008 FAILED. Skipping pacs.002."
  fi

  echo -e "\n--------------------------------------------\n"
  sleep 2
done

rm current_pacs008.json current_pacs002.json
```

Running `send.sh` a few times will produce entries in the database.  Look under `event_history` and `raw_history`, as well as the outcomes in `evaluation.`

## Reading the results

### Reading from the database
The database is thus far the best source of data to review the transactions passing through the system.  To start with, the `raw_history` database has tables for each of the different pacs messages.  For our case, we can view the `pacs008` and `pacs002` tables and see the messages we sent.

The `evaluation` database shows the evaluation results and tells us why it was triggered.  Here is an example result:

```
{
    "report": {
        "status": "ALRT",
        "metaData": {
            "prcgTmDP": 24143075,
            "prcgTmED": 687189
        },
        "timestamp": "2026-04-28T06:38:43.763Z",
        "tadpResult": {
            "id": "004@1.0.0",
            "cfg": "1.0.0",
            "prcgTm": 4277132,
            "typologyResult": [
                {
                    "id": "typology-processor@1.0.0",
                    "cfg": "999@1.0.0",
                    "prcgTm": 3620234,
                    "result": 400,
                    "review": true,
                    "tenantId": "DEFAULT",
                    "workflow": {
                        "flowProcessor": "EFRuP@1.0.0",
                        "alertThreshold": 300,
                        "interdictionThreshold": 500
                    },
                    "ruleResults": [
                        {
                            "id": "902@1.0.0",
                            "cfg": "1.0.0",
                            "wght": 200,
                            "prcgTm": 3641804,
                            "tenantId": "DEFAULT",
                            "subRuleRef": ".02",
                            "indpdntVarbl": 2
                        },
                        {
                            "id": "EFRuP@1.0.0",
                            "cfg": "none",
                            "wght": 0,
                            "prcgTm": 7676511,
                            "tenantId": "DEFAULT",
                            "subRuleRef": "none",
                            "indpdntVarbl": 0
                        },
                        {
                            "id": "901@1.0.0",
                            "cfg": "1.0.0",
                            "wght": 200,
                            "prcgTm": 7786264,
                            "tenantId": "DEFAULT",
                            "subRuleRef": ".02",
                            "indpdntVarbl": 2
                        }
                    ]
                }
            ]
        },
        "evaluationID": "019dd2cf-c033-73b6-b108-33206cd7ece7"
    },
    "dataCache": {
        "cdtrId": "RECEIVER-999TAZAMA_EID",
        "dbtrId": "SENDER-001TAZAMA_EID",
        "creDtTm": "2026-04-28T14:15:00.000Z",
        "instdAmt": {
            "amt": 1500,
            "ccy": "USD"
        },
        "xchgRate": 1,
        "cdtrAcctId": "RECEIVER-999MSISDNfsp002",
        "dbtrAcctId": "SENDER-001MSISDNfsp001",
        "intrBkSttlmAmt": {
            "amt": 1500,
            "ccy": "USD"
        }
    },
    "networkMap": {
        "cfg": "1.0.0",
        "active": true,
        "messages": [
            {
                "id": "004@1.0.0",
                "cfg": "1.0.0",
                "txTp": "pacs.002.001.12",
                "typologies": [
                    {
                        "id": "typology-processor@1.0.0",
                        "cfg": "999@1.0.0",
                        "rules": [
                            {
                                "id": "EFRuP@1.0.0",
                                "cfg": "none"
                            },
                            {
                                "id": "901@1.0.0",
                                "cfg": "1.0.0"
                            },
                            {
                                "id": "902@1.0.0",
                                "cfg": "1.0.0"
                            }
                        ],
                        "tenantId": "DEFAULT"
                    }
                ]
            }
        ],
        "tenantId": "DEFAULT"
    },
    "transaction": {
        "TxTp": "pacs.002.001.12",
        "TenantId": "DEFAULT",
        "FIToFIPmtSts": {
            "GrpHdr": {
                "MsgId": "POC-MSG-1777358322401364739",
                "CreDtTm": "2026-04-28T14:12:00.000Z"
            },
            "TxInfAndSts": {
                "TxSts": "ACCC",
                "ChrgsInf": [
                    {
                        "Agt": {
                            "FinInstnId": {
                                "ClrSysMmbId": {
                                    "MmbId": "fsp001"
                                }
                            }
                        },
                        "Amt": {
                            "Amt": 0,
                            "Ccy": "USD"
                        }
                    }
                ],
                "InstdAgt": {
                    "FinInstnId": {
                        "ClrSysMmbId": {
                            "MmbId": "fsp002"
                        }
                    }
                },
                "InstgAgt": {
                    "FinInstnId": {
                        "ClrSysMmbId": {
                            "MmbId": "fsp001"
                        }
                    }
                },
                "AccptncDtTm": "2026-04-28T14:12:05.000Z",
                "OrgnlInstrId": "5ab4fc7355de4ef8a75b78b00a681ed2",
                "OrgnlEndToEndId": "E2E-1777358322401364739"
            }
        }
    },
    "transactionID": "POC-MSG-1777358322401364739"
}
```

### Reading from NATS
Messages coming from NATS are ephemeral, unless Jetstream were installed.  So as far as reviewing messages is concerned, we unfortunately won't find it here.

In a demo or even in live production, though, we would be reading from NATS as a pub/sub channel.  We could do that by connecting a NATS client to the NATS broker. 

One of my goals was to interact with the results using NATS exclusively.  I thought I would be able to use nats-utils for this purpose but it turns out the container doesn't start correctly because of several missing environment variables, e.g. TMS_ENDPOINT.  With too many things to fix, I dropped this approach altogether.

Instead, I ran NATS utilities via a Docker container

`docker run --network host --rm -it natsio/nats-box nats sub -s nats://localhost:14222 "investigation-service`

This spins up a container with NATS CLI; in the example above, it listens on `investigation-service` for results.

The subjects available in this setup are:

| Subject | Source | Content |
|-----|-----|-----|
| `investigation-service` | TADP (Decision Engine) | Final ALRT/NALT reports for review |
| `relay-service-nats-tadp` | Typology Processor | Internal data for the adjudication service |
| `relay-service-nats-ef` | Event-Flow | Metadata for tracking the message lifecycle |

## What I learned
The demonstration from the `Full-Stack-Docker-Tazama` repo, specifically option 2, is a simple but constrained environment.  Working only with Rule 901 and 902 may seem very limiting but these are good starting filters for detecting fraud.

What I wish the documentation had provided up front and more clearly was a discussion of the configuration, specifically the network map, the rules, and the typologies, and how they related to the actual JSON configuration files; and to start with, how and where to get them.

Guessing at the intent of the Tazama team by the way the demo and the Postman collections are structured and presented, it appears that the goal was to show the rules being triggered; which it does a good job of.  But it also leaves out some of the rationales of the setup, for instance:

- why the database needs to be prepopulated instead of autoprovisioning (cases can be made for both approaches); manual seeding ensures referential integrity during the first run
- how pacs.008 and pacs.002 are interlinked within Tazama itself: since the network map specified we would be focused on pacs.002, it can be puzzling why pacs.008 would still be needed

NATS is a new component to me, and I quickly equated it to Kafka.  It seems however that this is not exactly so.  NATS is used as a real-time bus but its default configuration does not have storage (like Kafka) unless used with Jetstream. So we still go back to Postgres/Hasura for the audit trail.

Lastly, the `DataCache` portion in both pacs.008 and pacs.002 JSON messages is an important one as it provides a fast way for Tazama to read the relevant portions of the message, without having to traverse through the complex tree of the full ISO20022 message.  *This is a design choice acting as a standardized interface for messages (Gemini).* The data here is leaner and simpler to understand.

Rule 901 and 902 do not actually "read" the ISO 20022 tree; they read the DataCache. This allows the same rule to work for a pacs.008, a pacs.002, or even a non-ISO message, provided the DataCache is present. (Gemini)


### Using Gemini AI to dissect the POC
Disclaimer: I used Gemini 3 (Thinking) to help me walk through the code and build the scripts.  Gemini was surprisingly able and up-to-date on Tazama.  The trigger templates for pacs.008 and pacs.002, as well as the sending script, were generated by Gemini.  Not as a one-shot, mind you, but through several iterations involving review of the error messages and cribbing from the Postman collections.  Gemini acted as a "Schema Translator," helping bridge the gap between the Postman collection's JavaScript logic and the raw shell/JSON requirements of the API.

### Further reading
**Note on Service Identification:**
Rule containers identify themselves to the system via internal environment variables (e.g., RULE_NAME or SERVICE_ID). For a rule to process transactions, this internal ID must match the id field in the Network Map (e.g., 901@1.0.0). NATS then uses this ID to route data to the correct "channel" for that specific rule. (Gemini)
