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
      -e "s/{{RECEIVER}}/$RECEIVER/g" no_alert_pacs008.json > current_pacs008.json

  RESPONSE_008=$(curl -s -X POST "http://$HOST/v1/evaluate/iso20022/pacs.008.001.10" \
       -H "Content-Type: application/json" -d @current_pacs008.json)
  
  echo "pacs.008 Response: $RESPONSE_008"

  # Step 2: Prepare and send pacs.002
  if [[ $RESPONSE_008 == *"Transaction is valid"* ]]; then
    echo "pacs.008 Accepted. Sending pacs.002..."
    
    sed -e "s/{{ID}}/$TX_ID/g" \
        -e "s/{{SENDER}}/$SENDER/g" \
        -e "s/{{RECEIVER}}/$RECEIVER/g" no_alert_pacs002.json > current_pacs002.json

    RESPONSE_002=$(curl -s -X POST "http://$HOST/v1/evaluate/iso20022/pacs.002.001.12" \
         -H "Content-Type: application/json" -d @current_pacs002.json)
    echo "pacs.002 Response: $RESPONSE_002"
  fi

  echo -e "\n--------------------------------------------\n"
  sleep 2
done

rm current_pacs008.json current_pacs002.json
