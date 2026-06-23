#!/bin/bash
# Rule 901

curl -X POST "http://localhost:3100/v1/admin/configuration/rule"   -H "Content-Type: application/json"   -d '{
    "id": "902@1.0.0",
    "cfg": "1.0.0",
    "desc": "Number of incoming transactions - creditor",
    "config": {
        "bands": [
            {
                "reason": "The creditor has received one transaction to date",
                "subRuleRef": ".01",
                "upperLimit": 2
            },
            {
                "reason": "The creditor has received two transactions to date",
                "lowerLimit": 2,
                "subRuleRef": ".02",
                "upperLimit": 3
            },
            {
                "reason": "The creditor has received three or more transactions to date",
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
