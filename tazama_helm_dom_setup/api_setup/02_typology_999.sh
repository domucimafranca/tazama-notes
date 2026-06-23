#!/bin/bash
# Set up Typology 999
curl -X POST "http://localhost:3100/v1/admin/configuration/typology" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "typology-processor@1.0.0",
    "cfg": "999@1.0.0",
    "rules": [
        {
            "id": "901@1.0.0",
            "cfg": "1.0.0",
            "wghts": [
                {
                    "ref": ".err",
                    "wght": "0"
                },
                {
                    "ref": ".x00",
                    "wght": "100"
                },
                {
                    "ref": ".01",
                    "wght": "100"
                },
                {
                    "ref": ".02",
                    "wght": "200"
                },
                {
                    "ref": ".03",
                    "wght": "400"
                }
            ],
            "termId": "v901at100at100"
        },
        {
            "id": "902@1.0.0",
            "cfg": "1.0.0",
            "wghts": [
                {
                    "ref": ".err",
                    "wght": "0"
                },
                {
                    "ref": ".x00",
                    "wght": "100"
                },
                {
                    "ref": ".01",
                    "wght": "100"
                },
                {
                    "ref": ".02",
                    "wght": "200"
                },
                {
                    "ref": ".03",
                    "wght": "400"
                }
            ],
            "termId": "v902at100at100"
        },
        {
            "id": "EFRuP@1.0.0",
            "cfg": "none",
            "wghts": [
                {
                    "ref": ".err",
                    "wght": "0"
                },
                {
                    "ref": "override",
                    "wght": "0"
                },
                {
                    "ref": "non-overridable-block",
                    "wght": "0"
                },
                {
                    "ref": "overridable-block",
                    "wght": "0"
                },
                {
                    "ref": "none",
                    "wght": "0"
                }
            ],
            "termId": "vEFRuPat100atnone"
        }
    ],
    "tenantId": "DEFAULT",
    "workflow": {
        "flowProcessor": "EFRuP@1.0.0",
        "alertThreshold": 300,
        "interdictionThreshold": 500
    },
    "expression": [
        "Add",
        "v901at100at100",
        "v902at100at100"
    ],
    "typology_name": "Typology-999-Rule-901-and-902"
}'
