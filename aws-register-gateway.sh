
# Check if aws cli is installed
if ! command -v aws &> /dev/null; then
    echo "The AWS CLI is required"
    exit 1
fi

set -e

[[ -z "$GATEWAY_EUI" ]] && echo "GATEWAY_EUI is required" && exit 1
[[ -z "$GATEWAY_NAME" ]] && echo "GATEWAY_NAME is required" && exit 1
[[ -z "$AWS_REGION" ]] && echo "AWS_REGION is required" && exit 1

gateway=""
existing_gateway=$(aws iotwireless get-wireless-gateway \
  --identifier $GATEWAY_EUI \
  --identifier-type GatewayEui)

if [[ -z "$existing_gateway" ]]; then
  echo "Creating gateway"
  gateway=$(aws iotwireless create-wireless-gateway \
    --name $GATEWAY_NAME \
    --tags Key=application,Value=aether \
    --lorawan GatewayEui=$GATEWAY_EUI,RfRegion="US915")
else
  echo "Reusing existing gateway" 
  gateway=$existing_gateway
  gateway_id=$(echo $gateway | jq -r '.Id')
  echo "Disassociating certificates"
  cert_id=$(aws iotwireless get-wireless-gateway-certificate --id $gateway_id | jq -r '.IotCertificateId')
  aws iotwireless disassociate-wireless-gateway-from-certificate --id $gateway_id
  aws iot delete-certificate --id $cert_id
fi

echo $gateway
gateway_id=$(echo $gateway | jq -r '.Id')

echo "Getting CUPS and LNS endpoints"
cups_endpoint=$(aws iotwireless get-service-endpoint --service-type CUPS)
lns_endpoint=$(aws iotwireless get-service-endpoint --service-type LNS)
lns_endpoint_id=$(echo $lns_endpoint | jq -r '.')

echo $cups_endpoint | jq -r '.ServiceEndpoint' > cups.uri
echo $cups_endpoint | jq -r '.ServerTrust' > cups.trust
echo $lns_endpoint | jq -r '.ServiceEndpoint' > lns.uri
echo $lns_endpoint | jq -r '.ServerTrust' > lns.trust

echo "Creating certificates"
keys_and_certs=$(aws iot create-keys-and-certificate \
  --set-as-active \
  --certificate-pem-outfile cups.crt \
  --private-key-outfile cups.key)

echo "Associating certificates to gateway"
aws iotwireless associate-wireless-gateway-with-certificate \
  --id $gateway_id \
  --iot-certificate $(echo $keys_and_certs | jq -r '.certificateId')
