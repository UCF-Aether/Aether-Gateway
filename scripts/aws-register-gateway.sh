
# Should've used Python...
# Check if aws cli is installed
if ! command -v aws &> /dev/null; then
    echo "The AWS CLI is required"
    exit 1
fi

set -e

get_gw_id() {
  echo $1 | jq -r '.Id'
}

subbands=1
rfregion=US915

gateway_thing_group_name="gateways"
gateway_thing_type_name="gateway"

[[ -z "$GATEWAY_EUI" ]] && echo "GATEWAY_EUI is required" && exit 1
[[ -z "$GATEWAY_NAME" ]] && echo "GATEWAY_NAME is required" && exit 1
[[ -z "$AWS_REGION" ]] && echo "AWS_REGION is required" && exit 1

echo $EXISTS
gateway=""
if [[ -z "$EXISTS" ]]; then
  # Will only create one of each name, fialing gracefully and returning existing type
  thing_group=$(aws iot describe-thing-group --thing-group-name $gateway_thing_group_name)
  thing_type=$(aws iot describe-thing-type --thing-type-name $gateway_thing_type_name)
  thing_type_arn=$(echo $thing_type | jq -r '.thingTypeArn')

  echo "Creating gateway"
  gateway=$(aws iotwireless create-wireless-gateway \
    --name $GATEWAY_NAME \
    --tags Key=application,Value=aether \
    --lorawan GatewayEui=$GATEWAY_EUI,RfRegion="$rfregion",SubBands=$subbands)
  gateway_id=$(get_gw_id "$gateway")

  echo "Creating thing for gateway"
  # Must be unique!
  thing=$(aws iot create-thing \
    --thing-name "$GATEWAY_EUI-$GATEWAY_NAME" \
    --thing-type-name $gateway_thing_type_name)
  thing_arn=$(echo $thing | jq -r '.thingArn')

  echo "Adding to thing group"
  aws iot add-thing-to-thing-group \
    --thing-group-name $gateway_thing_group_name \
    --thing-arn "$thing_arn"
  
  echo "Associating thing with gateway"
  aws iotwireless associate-wireless-gateway-with-thing \
    --id $gateway_id \
    --thing-arn "$thing_arn"
else
  echo "Reusing existing gateway" 
  gateway=$(aws iotwireless get-wireless-gateway --identifier $GATEWAY_EUI --identifier-type GatewayEui)
  gateway_id=$(get_gw_id "$gateway")
  echo "Disassociating certificates"
  cert_id=$(aws iotwireless get-wireless-gateway-certificate --id $gateway_id | jq -r '.IotCertificateId')
  aws iotwireless disassociate-wireless-gateway-from-certificate --id $gateway_id
  echo "Deleting certificate"
  aws iot update-certificate --certificate-id $cert_id --new-status INACTIVE
  # To fully delete, have to remove all policies - leaving as INACTIVE for now...
  # aws iot delete-certificate --certificate-id $cert_id
fi

echo $gateway
gateway_id=$(get_gw_id "$gateway")

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

cert_arn=$(echo $keys_and_certs | jq -r '.certificateArn')

echo "Associating certificates to gateway"
aws iotwireless associate-wireless-gateway-with-certificate \
  --id $gateway_id \
  --iot-certificate $(echo $keys_and_certs | jq -r '.certificateId')

echo "Attaching gateway policy to certificate"
aws iot attach-policy --policy-name GatewayPolicy --target "$cert_arn"

