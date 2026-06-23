#!/bin/bash
# Network map

curl -X POST "http://localhost:3100/v1/admin/configuration/network_map"   -H "Content-Type: application/json"   -d '{
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
}'
