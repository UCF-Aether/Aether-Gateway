[[ -z $1 ]] && echo "usage aws-does-gw-exist.sh <eui>" && exit 1
aws iotwireless list-wireless-gateways | jq "any(.WirelessGatewayList[]; .LoRaWAN.GatewayEui == \"$1\")"
