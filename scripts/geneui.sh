length=$1
[[ -z "$length" ]] && length=16

printf "$(hostname)$(cat /etc/machine-id)$(ip link show eth0 | grep link/ether | awk '{print $2}')$(ip link show wlan0 | grep link/ether | awk '{print $2}')" \
  | sha256sum \
  | awk '{print $1}' \
  | awk "{print substr(\$1,0,$length)}"  \
  | tr -d '\n' \
  | tr -d '\r'
