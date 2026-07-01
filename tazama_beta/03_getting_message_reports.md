# Getting Message Reports

You can get the report of the results of a PACS message using the `getreportbymsgid` API endpoint of the admin service.  This is documented in [the admin service README](https://github.com/tazama-lf/admin-service/blob/main/README.md).

## Example

### Results of a test message

Using the `no_alert_send.sh` script, this is an example result:

```
--- Loop 3: Sender SNDR-397841 to Receiver RCVR-141913 ---
Transaction ID: E2E-1782780666101649846
pacs.008 Response: {"message":"Transaction is valid","data":{"FIToFICstmrCdtTrf":{"GrpHdr":{"MsgId":"PAC8-1782780666101649846","CreDtTm":"2026-04-28T14:15:00.000Z","NbOfTxs":1,"SttlmInf":{"SttlmMtd":"CLRG"}},"CdtTrfTxInf":{"PmtId":{"InstrId":"instr-1782780666101649846","EndToEndId":"E2E-1782780666101649846"},"IntrBkSttlmAmt":{"Amt":{"Amt":1500,"Ccy":"USD"}},"InstdAmt":{"Amt":{"Amt":1500,"Ccy":"USD"}},"ChrgBr":"DEBT","ChrgsInf":{"Amt":{"Amt":0,"Ccy":"USD"},"Agt":{"FinInstnId":{"ClrSysMmbId":{"MmbId":"fsp001"}}}},"InitgPty":{"Nm":"SNDR-397841","Id":{"PrvtId":{"DtAndPlcOfBirth":{"BirthDt":"1980-01-01","CityOfBirth":"Unknown","CtryOfBirth":"ZZ"},"Othr":[{"Id":"SNDR-397841","SchmeNm":{"Prtry":"TAZAMA_EID"}}]}},"CtctDtls":{"MobNb":"+27-000000000"}},"Dbtr":{"Nm":"SNDR-397841","Id":{"PrvtId":{"DtAndPlcOfBirth":{"BirthDt":"1980-01-01","CityOfBirth":"Unknown","CtryOfBirth":"ZZ"},"Othr":[{"Id":"SNDR-397841","SchmeNm":{"Prtry":"TAZAMA_EID"}}]}},"CtctDtls":{"MobNb":"+27-000000000"}},"DbtrAcct":{"Id":{"Othr":[{"Id":"SNDR-397841","SchmeNm":{"Prtry":"MSISDN"}}]},"Nm":"SNDR-397841-ACCOUNT"},"DbtrAgt":{"FinInstnId":{"ClrSysMmbId":{"MmbId":"fsp001"}}},"CdtrAgt":{"FinInstnId":{"ClrSysMmbId":{"MmbId":"fsp002"}}},"Cdtr":{"Nm":"RCVR-141913","Id":{"PrvtId":{"DtAndPlcOfBirth":{"BirthDt":"1990-01-01","CityOfBirth":"Unknown","CtryOfBirth":"ZZ"},"Othr":[{"Id":"RCVR-141913","SchmeNm":{"Prtry":"TAZAMA_EID"}}]}},"CtctDtls":{"MobNb":"+27-111111111"}},"CdtrAcct":{"Id":{"Othr":[{"Id":"RCVR-141913","SchmeNm":{"Prtry":"MSISDN"}}]},"Nm":"RCVR-141913-ACCOUNT"},"Purp":{"Cd":"MP2P"}},"RgltryRptg":{"Dtls":{"Tp":"BALANCE OF PAYMENTS","Cd":"100"}},"RmtInf":{"Ustrd":"Blind Ingestion POC Test"},"SplmtryData":{"Envlp":{"Doc":{"InitgPty":{"Glctn":{"Lat":"-3.1609","Long":"38.3588"}},"Xprtn":"2026-12-31T23:59:59.000Z"}}}},"TxTp":"pacs.008.001.10"}}
pacs.008 Accepted. Sending pacs.002...
pacs.002 Response: {"message":"Transaction is valid","data":{"FIToFIPmtSts":{"GrpHdr":{"MsgId":"POC-MSG-1782780666101649846","CreDtTm":"2026-04-28T14:12:00.000Z"},"TxInfAndSts":{"OrgnlInstrId":"instr-1782780666101649846","OrgnlEndToEndId":"E2E-1782780666101649846","TxSts":"ACCC","ChrgsInf":[{"Amt":{"Amt":0,"Ccy":"USD"},"Agt":{"FinInstnId":{"ClrSysMmbId":{"MmbId":"fsp001"}}}}],"AccptncDtTm":"2026-04-28T14:12:05.000Z","InstgAgt":{"FinInstnId":{"ClrSysMmbId":{"MmbId":"fsp001"}}},"InstdAgt":{"FinInstnId":{"ClrSysMmbId":{"MmbId":"fsp002"}}}}},"TxTp":"pacs.002.001.12"}}
```

Given the current configuration, it is the pacs002 messages which trigger the report.  So our message ID is `POC-MSG-1782780666101649846`.

### Getting the message report

To get the message result

```
curl -X GET "https://admin.beta.tazama.org/v1/admin/reports/getreportbymsgid?msgid=POC-MSG-1782780666101649846" \                                          
     -H "Authorization: Bearer $KEYCLOAK_TOKEN" \
     -H "Content-type: application/json"
```

The return value can be quite extensive, so here is a snippet formatted with `jq`.

```
{
  "message": "Report was found",
  "data": {
    "report": {
      "status": "NALT",
      "metaData": {
        "prcgTmDP": 3940329,
        "prcgTmED": 509857
      },
      "timestamp": "2026-06-30T00:51:07.050Z",
      "tadpResult": {
        "id": "004@1.0.0",
        "cfg": "1.0.0",
        "prcgTm": 1859210,
        "typologyResult": [
          {
            "id": "typology-processor@1.0.0",
            "cfg": "047@1.0.0",
            "prcgTm": 10270950,
            "result": 700,
            "review": false,
```
