#!/bin/bash -e

if [ $# == 0 ] ; then
   echo "please input params, nodeID1,nodeID2,nodeID3 nodeType1,nodeType2,nodeType3 apiIp apiKey serverName email token"
   exit 0
fi
NodeIDStr=$1
NodeTypeStr=$2
ApiHost=$3
ApiKey=$4
ServerName=$5
Email=$6
Token=$7
core="sing"

mkdir -p "/docker/v2x/"

config_path="/docker/v2x/config.json"
sing_config_path="/docker/v2x/sing_origin.json"

echo "check Docker......"
sudo docker -v
if [ $? -eq  0 ]; then
    echo "check Docker installed!"
else
    echo "install docekr..."
    sudo wget -qO- https://get.docker.com/ | sudo sh
fi

#split param 1
IFS=','
read -r -a nodeIds <<< "$NodeIDStr"
read -r -a nodeTypes <<< "$NodeTypeStr"

# define config file
node_config=""

index=0
for nodeId in "${nodeIds[@]}"; do
    NodeType=${nodeTypes[$index]}
     node_config=$(cat <<EOF
{
        "Core": "$core",
        "ApiHost": "$ApiHost",
        "ApiKey": "$ApiKey",
        "NodeID": $nodeId,
        "NodeType": "$NodeType",
        "Timeout": 30,
        "ListenIP": "0.0.0.0",
        "SendIP": "0.0.0.0",
        "DeviceOnlineMinTraffic": 1000,
        "EnableProxyProtocol": false,
        "EnableUot": true,
        "EnableTFO": true,
        "DNSType": "UseIPv4",
        "CertConfig": {
            "CertMode": "dns",
            "RejectUnknownSni": false,
            "CertDomain": "$ServerName",
            "CertFile": "/etc/v2x/fullchain.pem",
            "KeyFile": "/etc/v2x/cert.key",
            "Email": "$Email",
            "Provider": "cloudflare",
            "DNSEnv": {
                "CF_DNS_API_TOKEN": "$Token"
            }
        }
    }
EOF
    )

nodes_config+=("$node_config")
    index=$((index + 1))
done

#add core config

cores_config="["

cores_config+="
    {
        \"Type\": \"sing\",
        \"Log\": {
            \"Level\": \"error\",
            \"Timestamp\": true
        },
        \"NTP\": {
            \"Enable\": false,
            \"Server\": \"time.apple.com\",
            \"ServerPort\": 0
        },
        \"OriginalPath\": \"/etc/v2x/sing_origin.json\"
    }"
cores_config+="]"

rm -f $config_path
nodes_config_str="${nodes_config[*]}"
formatted_nodes_config="${nodes_config_str%,}"

# create config.json file
cat <<EOF > $config_path
{
    "Log": {
        "Level": "error",
        "Output": "/var/log/v2x/v2x.log"
    },
    "Cores": $cores_config,
    "Nodes": [$formatted_nodes_config]
}
EOF

#create sing route，out，int file
cat <<EOF > $sing_config_path
{
  "dns": {
    "servers": [
      {
        "tag": "cf",
        "address": "1.1.1.1",
        "strategy": "prefer_ipv4"
      }
    ]
  },
  "outbounds": [
    {
      "tag": "direct",
      "type": "direct",
      "domain_strategy": "prefer_ipv4"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "rules": [
      {
        "ip_is_private": true,
        "outbound": "block"
      },
      {
        "domain_regex": [
            "(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
            "(.+.|^)(360|so).(cn|com)",
            "(Subject|HELO|SMTP)",
            "(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
            "(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
            "(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
            "(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
            "(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
            "(.+.|^)(360).(cn|com|net)",
            "(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
            "(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
            "(.*.||)(netvigator|torproject).(com|cn|net|org)",
            "(..||)(visa|mycard|gash|beanfun|bank).",
            "(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
            "(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
            "(.*.||)(mycard).(com|tw)",
            "(.*.||)(gash).(com|tw)",
            "(.bank.)",
            "(.*.||)(pincong).(rocks)",
            "(.*.||)(taobao).(com)",
            "(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
            "(flows|miaoko).(pages).(dev)"
        ],
        "outbound": "block"
      },
      {
        "outbound": "direct",
        "network": [
          "udp","tcp"
        ]
      }
    ]
  },
  "experimental": {
    "cache_file": {
      "enabled": true
    }
  }
}
EOF


