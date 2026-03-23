#!/bin/sh

killall bs20 2>/dev/null
killall wapp 2>/dev/null
sleep 2

br0_mac=$(cat /sys/class/net/br-lan/address)
ctrlr_al_mac=$br0_mac
agent_al_mac=$br0_mac
ra0=0
rax0=0

sed -i "s/map_controller_alid=.*/map_controller_alid=${ctrlr_al_mac}/g" /etc/map/1905d.cfg
sed -i "s/map_agent_alid=.*/map_agent_alid=${agent_al_mac}/g" /etc/map/1905d.cfg

uciget() {
    val="$(uci get "$1" 2>/dev/null)"
    [ -z "$val" ] && val=0
    echo "$val"
}

ra0_7981="$(uciget wireless.MT7981_1_1.bandsteering)"
ra0_7986="$(uciget wireless.MT7986_1_1.bandsteering)"
if [ "$ra0_7981" -eq 1 ] || [ "$ra0_7986" -eq 1 ]; then
    ra0=1
    rax0=1
fi

ra0_7981="$(uciget wireless.MT7981_1_1.ieee80211r)"
ra0_7986="$(uciget wireless.MT7986_1_1.ieee80211r)"
if [ "$ra0_7981" -eq 1 ] || [ "$ra0_7986" -eq 1 ]; then
    ra0=1
fi

ra0_7981="$(uciget wireless.default_MT7981_1_2.steeringthresold)"
ra0_7986="$(uciget wireless.default_MT7986_1_2.steeringthresold)"
if [ "$ra0_7981" -lt 0 ] || [ "$ra0_7986" -lt 0 ]; then
    ra0=1
fi

ra0_7981="$(uciget wireless.default_MT7981_1_1.disabled)"
ra0_7986="$(uciget wireless.default_MT7986_1_1.disabled)"
if [ "$ra0_7981" -eq 1 ] || [ "$ra0_7986" -eq 1 ]; then
    ra0=0
    rax0=0
fi

rax0_7981="$(uciget wireless.MT7981_1_2.ieee80211r)"
rax0_7986="$(uciget wireless.MT7986_1_2.ieee80211r)"
if [ "$rax0_7981" -eq 1 ] || [ "$rax0_7986" -eq 1 ]; then
    rax0=1
fi

rax0_7981="$(uciget wireless.default_MT7981_1_2.steeringthresold)"
rax0_7986="$(uciget wireless.default_MT7986_1_2.steeringthresold)"
if [ "$rax0_7981" -lt 0 ] || [ "$rax0_7986" -lt 0 ]; then
    rax0=1
fi

rax0_7981="$(uciget wireless.default_MT7981_1_2.disabled)"
rax0_7986="$(uciget wireless.default_MT7986_1_2.disabled)"
if [ "$rax0_7981" -eq 1 ] || [ "$rax0_7986" -eq 1 ]; then
    rax0=0
fi

if [ "$rax0" -eq 1 ] && [ "$ra0" -eq 1 ]; then
    wapp -d1 -v2 -cra0 -crax0 >/dev/null &
elif [ "$ra0" -eq 1 ] && [ "$rax0" -eq 0 ]; then
    wapp -d1 -v2 -cra0 >/dev/null &
elif [ "$rax0" -eq 1 ] && [ "$ra0" -eq 0 ]; then
    wapp -d1 -v2 -crax0 >/dev/null &
fi

sleep 1

if [ "$rax0" -eq 1 ] || [ "$ra0" -eq 1 ]; then
    for iface in ra0 rax0; do
        iwpriv $iface set mapR2Enable=0
        iwpriv $iface set mapTSEnable=0
        iwpriv $iface set mapR3Enable=0
        iwpriv $iface set DppEnable=0
        iwpriv $iface set mapEnable=2
    done

    bs20 &

    wappctrl rax0 mbo reset_default
    wappctrl ra0  mbo reset_default

    rax0_7981="$(uciget wireless.default_MT7981_1_2.steeringbssid)"
    [ "$rax0_7981" != 0 ] && sh /sbin/setbssid rax0 "$rax0_7981"

    rax0_7986="$(uciget wireless.default_MT7986_1_2.steeringbssid)"
    [ "$rax0_7986" != 0 ] && sh /sbin/setbssid rax0 "$rax0_7986"

    ra0_7981="$(uciget wireless.default_MT7981_1_1.steeringbssid)"
    [ "$ra0_7981" != 0 ] && sh /sbin/setbssid ra0 "$ra0_7981"

    ra0_7986="$(uciget wireless.default_MT7986_1_1.steeringbssid)"
    [ "$ra0_7986" != 0 ] && sh /sbin/setbssid ra0 "$ra0_7986"
fi
