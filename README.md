# china-ip-rules

Turn China IP list([17mon@github/china_ip_list](https://github.com/17mon/china_ip_list)) into Shadowsocks clients rules, make all china IP and LAN IP request go directly.

## Releases

PAC for shadowsocks-windows:

[pac4shadowsocks_windows.js](https://raw.githubusercontent.com/dodowhat/china-ip-rules/master/releases/pac4shadowsocks_windows.js)

PAC for SwitchyOmega:

[pac4switchyomega.js](https://raw.githubusercontent.com/dodowhat/china-ip-rules/master/releases/pac4switchyomega.js)

Surge / ShadowRocket / Surfboard:

[surge3.conf](https://raw.githubusercontent.com/dodowhat/china-ip-rules/master/releases/surge3.conf)

Clash for Windows:

[clash.yml](https://raw.githubusercontent.com/dodowhat/china-ip-rules/master/releases/clash.yml)

## Script usage:

Prerequisite:

    # Based on Ubuntu 18.04 LTS
    sudo apt install ipset
    sudo apt install shadowsocks-libev

For config files:

    bundle
    ruby generate_config_files.rb "your-shadowsocks-config.json"

Enable/Disable bypass rules:

    sudo bash rules.sh enable [your-shadowsocks-config.json]
    sudo bash rules.sh disable

## ss-redir autostart on system boot

For Ubuntu 18.04, Edit `/etc/rc.local` with following content:

    #!/bin/sh

    ss-redir -c ss.json -f /var/run/ss-redir.pid

    exit 0

If the file is not exists, create it manually.

Then run `sudo chmod +x /etc/rc.local`

## DNS over TCP

    sudo apt install unbound

then edit `/etc/unbound/unbound.conf` with:

    tcp-upstream: yes
    forward-zone:
        name: "."
        forward-addr: 8.8.8.8
        forward-addr: 8.8.4.4
        forward-first: no

restart service

    sudo systemctl restart unbound
