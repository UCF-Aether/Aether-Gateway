policies_path=$(git rev-parse --show-toplevel)
gateway_policy_path=$policies_path/policies/gateway.json

aws iot create-thing-type --thing-type-name gateway
aws iot create-thing-group --thing-group-name gateways

aws iot create-policy \
  --policy-name GatewayPolicy \
  --policy-document file://$gateway_policy_path
