<p align="center">
<img src="https://user-images.githubusercontent.com/5152848/149237313-89df0f2a-c087-45f9-b91d-a8b97d5f91d6.png">
</p>


![](https://img.shields.io/static/v1?label=Made%20with&message=Ansible&color=ee0000&labelColor=000000&style=for-the-badge&logo=ansible)
![](https://img.shields.io/static/v1?label=Made%20with&message=GNU%20Bash&color=4EAA25&labelColor=000000&logoColor=ffffff&style=for-the-badge&logo=gnubash)


# Aether-Gateway
Automated Gateway install and configuration with Ansible.

## Requirements/Dependencies
### Ansible
`sudo pacman -S ansible`

#### Ansible Modules
`ansible-galaxy collection install community.general`

### AWS CLI
`sudo pacman -S aws-cli-v2-bin`

If not done so, configure the AWS CLI:

`aws configure`

In the case of this project, the region is "us-east-1".

The user you wish to use for deploying the gateway and credentials should have adaquate permissions. See the IoT Core [developer guide](https://docs.aws.amazon.com/iot/latest/developerguide/index.html) or [workshop](https://catalog.us-east-1.prod.workshops.aws/v2/workshops/b95a6659-bd4f-4567-8307-bddb43a608c4/en-US/) for more details. To use an account other than 'default', set the AWS_PROFILE environment variable to the name of the acount you want to use.

`export AWS_PROFILE=user1`

Next, if the account doesn't have an IAM role to manage IoT Core credentials (`IoTWirelessGatewayCertManagerRole`), follow [these](https://catalog.us-east-1.prod.workshops.aws/v2/workshops/b95a6659-bd4f-4567-8307-bddb43a608c4/en-US/200-gateway/250-add-cups-role) instructions.

## Creating the Installation Media
The script `mksd.sh` is responsible for automatically creating the Arch Linux ARM bootable SD card for the Raspberry Pi 3.

`sudo ./mksd.sh <device>`

Where `<device>` is the file path to the unmounted SD card (eg. /dev/sdc). The default login and password is "alarm". 

The default root password is "root". After running ansible, SSH keys will be generated to facilitate logging in and the passwords will be randomized and uploaded to your AWS account's secret manager.


## Installing Basic Station and Config via Ansible
If no errors were generated from creating the installation media, then the SD card is safe to be removed. Insert it in the Raspberry Pi and connect it through ethernet to a local network. First, get your local IP of the interface you're using to connect to the Pi:

`ip a`

You'll see an output similar to this:
```sh
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default ql
en 1000
    link/ether 18:c0:4d:66:01:f8 brd ff:ff:ff:ff:ff:ff
    altname enp6s0
    inet 192.168.0.230/24 brd 192.168.0.255 scope global dynamic noprefixroute eno1
       valid_lft 5278sec preferred_lft 5278sec
    inet6 fe80::76e2:372:f1e3:f9aa/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
3: wlp7s0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group defau
lt qlen 1000
    link/ether 86:3c:fa:b1:74:26 brd ff:ff:ff:ff:ff:ff permaddr a8:7e:ea:ca:e2:39
```

In my case, I'm using ethernet as well. Get the IP (including the /\*\*) `inet 192.168.0.230/24`. Then, run:

`sudo nmap -sn <ip>`

Where ip is your IP. In my case, it's `192.168.0.230/24`.

This will generate a report similar to this:
```sh
Starting Nmap 7.92 ( https://nmap.org ) at 2022-01-12 18:42 EST
Nmap scan report for 192.168.0.1
Host is up (0.00045s latency).
MAC Address: 6C:5A:B0:8E:22:20 (TP-Link Limited)
Nmap scan report for 192.168.0.53
Host is up (0.0012s latency).
MAC Address: B8:27:EB:2D:04:23 (Raspberry Pi Foundation)
Nmap scan report for 192.168.0.230
Host is up.
Nmap done: 256 IP addresses (3 hosts up) scanned in 1.95 seconds
```

Where you see `(Raspberry Pi Foundation)`, copy the first IP above it. So `192.168.0.53`.

### Running Ansible
Now, all that's left is to run ansible. To install everything on the Pi, run:

`ansible-playbook -u alarm --ask-pass -i <ip>, -K bootstrap.yml -e "gateway_name=<gwname>"`

Where, `<ip>` is the Pi IP address and `<gwname>` is the name you want for the gateway. NOTE: it's important to have a comma `,` after the IP! When ansible-playbook runs, it'll ask you for the shell and root password. Those are the defaults previously mentioned (`alarm` and `root`).
