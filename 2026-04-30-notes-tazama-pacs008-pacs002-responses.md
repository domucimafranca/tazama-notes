## Background

Having tested the default Tazama configuration with rule 901 and rule 902, we are extending our exploration of its behavior with various combinations of pacs.008 and pacs.002.  

The previous exploration was designed to force alerts with multiple transactions being sent from the same account -- this being the conditions that rule 901 and 902 are testing for.  We also forced pre-knowledge of the accounts on Tazama by loading the accounts and entities into the event database.

Now we want a little more variation to test it against "blind" transactions, e.g. transactions that the system is seeing for the first time, followed by subsequent transactions.  

Some of this info and processes will be repeats of the previous exercise; but that's intentional as a means to solidify our understanding of Tazama's behavior.

## Reviewing and revising what we learned
As mentioned, we're still working with the default demo configuration of Tazama.  Some of the things that we've learned so far:

- Tazama upserts info on accounts when they are first received in pacs.008 messages; so no need to pre-create them; which is to say that Tazama will accept pacs.008 messages (as long as they are properly formatted)
- In the current Tazama config, pacs.002 messages cannot stand alone; they must be preceded by a corresponding pacs.008 message, or they will throw an error (q: what links the two accounts?)

## Lessons from a failed attempt
We tried a configuration by which Tazama would use Rule 901 and Rule 902 to evaluate pacs.008 messages only.  The first step was to modify the network map, which we did by deleting the old network map (directly on the database, in the `configuration.network_map` table) and pushing a new network map:

```
curl -X POST "http://localhost:5100/v1/admin/configuration/network_map" \
     -H "Content-Type: application/json" \
     -d '{
  "active": true,
  "cfg": "1.0.0",
  "name": "Blind Intelligence POC Map",
  "tenantId": "DEFAULT",
  "messages": [
    {
      "id": "001@1.0.0",
      "cfg": "1.0.0",
      "txTp": "pacs.008.001.10",
      "typologies": [
        {
          "id": "typology-processor@1.0.0",
          "cfg": "999@1.0.0",
          "rules": [
            { "id": "901@1.0.0", "cfg": "1.0.0" },
            { "id": "902@1.0.0", "cfg": "1.0.0" }
          ],
          "tenantId": "DEFAULT"
        }
      ]
    },
    {
      "id": "004@1.0.0",
      "cfg": "1.0.0",
      "txTp": "pacs.002.001.12",
      "typologies": []
    }
  ]
}'
```

While Tazama successfully ingested the message, there was no discernible output downstream; and that was because rule 901 and rule 902 were rejecting pacs.008!  Lesson: rule 901 and rule 902 are specific to pacs.002.

Tracing the flow, the Tazama **Event Director** did process the message and sent them to rule 901 and 902, but that resulted in a `serviceOperation:undefined`.

```
,777,514,127,319 sid:[1] subject:[event-director]: 1060

{
  message: 'Successfully sent to 901@1.0.0',
  serviceOperation: undefined,
  id: undefined
}

{
  message: 'Successfully sent to 902@1.0.0',
  serviceOperation: undefined,
  id: undefined
}
```

This was because it was failing at Rule 901 and Rule 902.  Logs:

```
{
  message: 'Start - Handle execute request',
  serviceOperation: 'Rule-901 execute()',
  id: 'rule-901-rel-1-0-0'
}

{
  message: 'Failed to process execution request.\r\n' +
    "TypeError: Cannot read properties of undefined (reading 'GrpHdr')\n" +
    '    at handleTransaction (/home/app/node_modules/rule/lib/rule-901.js:7:48)\n' +
    '    at execute (/home/app/build/controllers/execute.js:102:53)\n' +
    '    at process.processTicksAndRejections (node:internal/process/task_queues:95:5)',
  serviceOperation: '901@1.0.0',
  id: 'rule-901-rel-1-0-0'
}

{
  message: 'End - Handle execute request',
  serviceOperation: '901@1.0.0',
  id: 'rule-901-rel-1-0-0'
}
{
  message: "Cannot read properties of undefined (reading 'GrpHdr')",
  serviceOperation: '901@1.0.0',
  id: undefined
```

Why? Because Rule 901 expects  `FIToFIPmtSts.GrpHdr` from pacs.002, but pacs.008 only provides `FIToFICstmrCdtTrf.GrpHdr.`

## Sending 'blind' pacs.008 and pacs.002 messages
To the meat of this note: we want to send a series of 'blind' pacs.008 and pacs.002 messages to Tazama to see how it behaves under all normal conditions.

We'll modify our messages from the 2026-04-28 note.

trigger_blind_pacs008.json
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
        "InstrId": "instr-{{ID}}",
        "EndToEndId": "E2E-{{ID}}" 
      },
      "IntrBkSttlmAmt": { "Amt": { "Amt": 1500.00, "Ccy": "USD" } },
      "InstdAmt": { "Amt": { "Amt": 1500.00, "Ccy": "USD" } },
      "ChrgBr": "DEBT",
      "ChrgsInf": {
        "Amt": { "Amt": 0.00, "Ccy": "USD" },
        "Agt": { "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp001" } } }
      },
      "InitgPty": {
        "Nm": "{{SENDER}}",
        "Id": { 
          "PrvtId": { 
            "DtAndPlcOfBirth": { "BirthDt": "1980-01-01", "CityOfBirth": "Unknown", "CtryOfBirth": "ZZ" },
            "Othr": [{ "Id": "{{SENDER}}", "SchmeNm": { "Prtry": "TAZAMA_EID" } }] 
          } 
        },
        "CtctDtls": { "MobNb": "+27-000000000" }
      },
      "Dbtr": {
        "Nm": "{{SENDER}}",
        "Id": { 
          "PrvtId": { 
            "DtAndPlcOfBirth": { "BirthDt": "1980-01-01", "CityOfBirth": "Unknown", "CtryOfBirth": "ZZ" },
            "Othr": [{ "Id": "{{SENDER}}", "SchmeNm": { "Prtry": "TAZAMA_EID" } }] 
          } 
        },
        "CtctDtls": { "MobNb": "+27-000000000" }
      },
      "DbtrAcct": {
        "Id": { "Othr": [{ "Id": "{{SENDER}}", "SchmeNm": { "Prtry": "MSISDN" } }] },
        "Nm": "{{SENDER}}-ACCOUNT"
      },
      "DbtrAgt": { "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp001" } } },
      "CdtrAgt": { "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp002" } } },
      "Cdtr": {
        "Nm": "{{RECEIVER}}",
        "Id": { 
          "PrvtId": { 
            "DtAndPlcOfBirth": { "BirthDt": "1990-01-01", "CityOfBirth": "Unknown", "CtryOfBirth": "ZZ" },
            "Othr": [{ "Id": "{{RECEIVER}}", "SchmeNm": { "Prtry": "TAZAMA_EID" } }] 
          } 
        },
        "CtctDtls": { "MobNb": "+27-111111111" }
      },
      "CdtrAcct": {
        "Id": { "Othr": [{ "Id": "{{RECEIVER}}", "SchmeNm": { "Prtry": "MSISDN" } }] },
        "Nm": "{{RECEIVER}}-ACCOUNT"
      },
      "Purp": { "Cd": "MP2P" }
    },
    "RgltryRptg": { "Dtls": { "Tp": "BALANCE OF PAYMENTS", "Cd": "100" } },
    "RmtInf": { "Ustrd": "Blind Ingestion POC Test" },
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
    "dbtrId": "{{SENDER}}TAZAMA_EID",
    "cdtrId": "{{RECEIVER}}TAZAMA_EID",
    "dbtrAcctId": "{{SENDER}}MSISDNfsp001",
    "cdtrAcctId": "{{RECEIVER}}MSISDNfsp002",
    "creDtTm": "2026-04-28T14:15:00.000Z",
    "instdAmt": { "amt": 1500.00, "ccy": "USD" }
  },
  "tenantId": "DEFAULT"
}

```

trigger_blind_pacs002.json
```
{
  "TxTp": "pacs.002.001.12",
  "FIToFIPmtSts": {
    "GrpHdr": {
      "MsgId": "POC-MSG-{{ID}}",
      "CreDtTm": "2026-04-28T14:12:00.000Z"
    },
    "TxInfAndSts": {
      "OrgnlInstrId": "instr-{{ID}}",
      "OrgnlEndToEndId": "E2E-{{ID}}",
      "TxSts": "ACCC",
      "AccptncDtTm": "2026-04-28T14:12:05.000Z",
      "ChrgsInf": [
        {
          "Amt": { "Amt": 0.00, "Ccy": "USD" },
          "Agt": { "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp001" } } }
        }
      ],
      "InstgAgt": { "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp001" } } },
      "InstdAgt": { "FinInstnId": { "ClrSysMmbId": { "MmbId": "fsp002" } } }
    }
  },
  "DataCache": {
    "dbtrId": "{{SENDER}}TAZAMA_EID",
    "cdtrId": "{{RECEIVER}}TAZAMA_EID",
    "dbtrAcctId": "{{SENDER}}MSISDNfsp001",
    "cdtrAcctId": "{{RECEIVER}}MSISDNfsp002",
    "creDtTm": "2026-04-28T14:12:00.000Z",
    "instdAmt": { "amt": 1500.00, "ccy": "USD" },
    "intrBkSttlmAmt": { "amt": 1500.00, "ccy": "USD" },
    "xchgRate": 1.0
  },
  "tenantId": "DEFAULT"
}

```


send-blind.sh:
```
#!/bin/bash
HOST="tazama:5000"

for i in {1..3}
do
  # Generate unique IDs
  TX_ID=$(date +%s%N)
  SENDER="SNDR-$(head /dev/urandom | tr -dc 0-9 | head -c 6)"
  RECEIVER="RCVR-$(head /dev/urandom | tr -dc 0-9 | head -c 6)"

  echo "--- Loop $i: Sender $SENDER to Receiver $RECEIVER ---"
  echo "Transaction ID: E2E-$TX_ID"

  # Step 1: Prepare and send pacs.008
  # We use multiple -e flags in sed to replace all placeholders
  sed -e "s/{{ID}}/$TX_ID/g" \
      -e "s/{{SENDER}}/$SENDER/g" \
      -e "s/{{RECEIVER}}/$RECEIVER/g" trigger_blind_pacs008.json > current_pacs008.json

  RESPONSE_008=$(curl -s -X POST "http://$HOST/v1/evaluate/iso20022/pacs.008.001.10" \
       -H "Content-Type: application/json" -d @current_pacs008.json)
  
  echo "pacs.008 Response: $RESPONSE_008"

  # Step 2: Prepare and send pacs.002
  if [[ $RESPONSE_008 == *"Transaction is valid"* ]]; then
    echo "pacs.008 Accepted. Sending pacs.002..."
    
    sed -e "s/{{ID}}/$TX_ID/g" \
        -e "s/{{SENDER}}/$SENDER/g" \
        -e "s/{{RECEIVER}}/$RECEIVER/g" trigger_blind_pacs002.json > current_pacs002.json

    RESPONSE_002=$(curl -s -X POST "http://$HOST/v1/evaluate/iso20022/pacs.002.001.12" \
         -H "Content-Type: application/json" -d @current_pacs002.json)
    echo "pacs.002 Response: $RESPONSE_002"
  fi

  echo -e "\n--------------------------------------------\n"
  sleep 2
done

rm current_pacs008.json current_pacs002.json
```

Running send-blind.sh will now send off pairs of pacs.008 and pacs.002 messages, each one for a new sender.

### Results
A pacs.008 / pacs.002 pair for a new account will produce an evaluation with a NALT result:

```
{
    "report": {
        "status": "NALT",
        "metaData": {
            "prcgTmDP": 10674273,
            "prcgTmED": 649012
        },
        "timestamp": "2026-04-30T02:22:26.134Z",
        "tadpResult": {
            "id": "004@1.0.0",
            "cfg": "1.0.0",
            "prcgTm": 3681993,
            "typologyResult": [
                {
                    "id": "typology-processor@1.0.0",
                    "cfg": "999@1.0.0",
                    "prcgTm": 4049344,
                    "result": 200,
                    "review": false,
                    "tenantId": "DEFAULT",
                    "workflow": {
                        "flowProcessor": "EFRuP@1.0.0",
                        "alertThreshold": 300,
                        "interdictionThreshold": 500
                    },
                    "ruleResults": [
                        {
                            "id": "EFRuP@1.0.0",
                            "cfg": "none",
                            "wght": 0,
                            "prcgTm": 3932435,
                            "tenantId": "DEFAULT",
                            "subRuleRef": "none",
                            "indpdntVarbl": 0
                        },
                        {
                            "id": "902@1.0.0",
                            "cfg": "1.0.0",
                            "wght": 100,
                            "prcgTm": 2579975,
                            "tenantId": "DEFAULT",
                            "subRuleRef": ".01",
                            "indpdntVarbl": 1
                        },
                        {
                            "id": "901@1.0.0",
                            "cfg": "1.0.0",
                            "wght": 100,
                            "prcgTm": 9369474,
                            "tenantId": "DEFAULT",
                            "subRuleRef": ".01",
                            "indpdntVarbl": 1
                        }
                    ]
                }
            ]
        },
        "evaluationID": "019ddc31-d356-76a9-8bb2-b0edd1f900c5"
    },
    "dataCache": {
        "cdtrId": "RCVR-564412TAZAMA_EID",
        "dbtrId": "SNDR-122894TAZAMA_EID",
        "creDtTm": "2026-04-28T14:15:00.000Z",
        "instdAmt": {
            "amt": 1500,
            "ccy": "USD"
        },
        "cdtrAcctId": "RCVR-564412MSISDNfsp002",
        "dbtrAcctId": "SNDR-122894MSISDNfsp001",
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
                        ]
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
                "MsgId": "POC-MSG-1777515745883480203",
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
                "OrgnlInstrId": "instr-1777515745883480203",
                "OrgnlEndToEndId": "E2E-1777515745883480203"
            }
        }
    },
    "transactionID": "POC-MSG-1777515745883480203"
}
```

Rule 901, as seen from the logs, produces the following result

```
1,777,515,746,093 sid:[1] subject:[sub-rule-901@1.0.0]: 563
{
  message: 'Start - Handle execute request',
  serviceOperation: 'Rule-901 execute()',
  id: 'rule-901-rel-1-0-0'
}
{
  message: 'End - Handle execute request',
  serviceOperation: '901@1.0.0',
  id: 'rule-901-rel-1-0-0'
}
{
  message: 'The debtor has performed one transaction to date',
  serviceOperation: '901@1.0.0',
  id: undefined
}
```

Rule 902 produces something similar

```
{
  message: 'Start - Handle execute request',
  serviceOperation: 'Rule-902 execute()',
  id: 'rule-902-rel-1-0-0'
}
{
  message: 'End - Handle execute request',
  serviceOperation: '902@1.0.0',
  id: 'rule-902-rel-1-0-0'
}
{
  message: 'The creditor has received one transaction to date',
  serviceOperation: '902@1.0.0',
  id: undefined
}
```

## Gemini's assessment
The above note was written by me. I ran it through Gemini, which produced the following result:

### 1. Identity & Ingestion Breakthroughs
Automatic Provisioning: You confirmed that Tazama upserts account information upon receiving the first pacs.008 message, removing the operational burden of pre-seeding accounts and entities for basic ingestion.

The "Anchor" Requirement: Your tests proved that a pacs.002 (Payment Status) cannot stand alone; it requires a preceding pacs.008 to serve as a transaction anchor in the database.

Permissive Gateway: You demonstrated that the Tazama Management System (TMS) validates ISO 20022 schemas structurally but does not block transactions based on the absence of a pre-existing participant profile.

### 2. Lessons from the pacs.008 Trigger Failure
Message-Type Dependency: The attempt to trigger Rule 901 and 902 directly from a pacs.008 failed because the rules are hard-coded to expect the pacs.002 wrapper.

Structural Mismatch: Specifically, the rules crashed with a TypeError while attempting to read GrpHdr from the FIToFIPmtSts block (standard in .002), which does not exist in the .008 structure (FIToFICstmrCdtTrf).

Routing Success: Despite the rule failure, you confirmed the Event Director is functional and correctly routes messages based on updated Network Map configurations.

### 3. Validation of the "Blind Pair" Workflow
Successful Evaluation: By sending a randomized pacs.008 followed by a pacs.002, you successfully triggered a full evaluation for "stranger" participants.

NALT (No Alert) Results: The system produced a neutral 200 result for these new IDs, indicating they passed the fraud check as low-risk, first-time transactions.

Rule Adaptability:

Rule 901 (Location): Successfully processed the transaction and noted it as the debtor's first transaction.

Rule 902 (Velocity): Successfully recorded and counted the first transaction for the new creditor.
