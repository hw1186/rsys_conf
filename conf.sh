#!/bin/bash

sudo apt update
sudo apt install -y rsyslog

cat << EOF | sudo tee /etc/rsyslog.d/01-json-parser.conf
template(name="json-template"
  type="list") {
    constant(value="{")
      constant(value="\"@timestamp\":\"")     property(name="timereported" dateFormat="rfc3339")
      constant(value="\",\"@version\":\"1")
      constant(value="\",\"message\":\"")     property(name="msg" format="json")
      constant(value="\",\"sysloghost\":\"")  property(name="hostname")
      constant(value="\",\"formhost-ip\":\"")  property(name="fromhost-ip")
      constant(value="\",\"severity\":\"")    property(name="syslogseverity-text")
      constant(value="\",\"facility\":\"")    property(name="syslogfacility-text")
      constant(value="\",\"programname\":\"") property(name="programname")
      constant(value="\",\"procid\":\"")      property(name="procid")
    constant(value="\"}\n")
}
EOF

cat << EOF | sudo tee /etc/rsyslog.d/60-fluentd.conf
*.*							@@localhost:5140;json-template
EOF

sudo systemctl restart rsyslog

