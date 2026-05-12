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
