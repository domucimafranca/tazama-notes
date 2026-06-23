#!/bin/bash
# Rule 901

curl -X POST "http://localhost:3100/v1/admin/configuration/rule"   -H "Content-Type: application/json"   -d '{
    "id": "901@1.0.0",
    "cfg": "1.0.0",
    "desc": "Number of outgoing transactions - debtor",
    "config": {
        "bands": [
            {
                "reason": "The debtor has performed one transaction to date",
                "subRuleRef": ".01",
                "upperLimit": 2
            },
            {
                "reason": "The debtor has performed two transactions to date",
                "lowerLimit": 2,
                "subRuleRef": ".02",
                "upperLimit": 3
            },
            {
                "reason": "The debtor has performed three or more transactions to date",
                "lowerLimit": 3,
                "subRuleRef": ".03"
            }
        ],
        "parameters": {
            "maxQueryRange": 86400000
        },
        "exitConditions": [
            {
                "reason": "Incoming transaction is unsuccessful",
                "subRuleRef": ".x00"
            }
        ]
    },
    "tenantId": "DEFAULT"
}'
