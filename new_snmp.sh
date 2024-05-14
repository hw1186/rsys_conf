#!/bin/bash
# setup_linux.sh
# chmod 755 setup_linux.sh

echo "========================================================"
echo "rsysloh set up"
echo "========================================================"

sudo apt update
sudo apt install -y rsyslog
sudo apt install systemd 
sudo apt install curl 

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
*.*	@@localhost:5140;json-template
EOF

sudo systemctl restart rsyslog

echo "========================================================"
echo "Starting install Fluentd"
echo "========================================================"

curl -fsSL https://toolbelt.treasuredata.com/sh/install-ubuntu-jammy-fluent-package5.sh | sh
sudo systemctl start fluentd

echo "========================================================"
echo "setup Fluentd"
echo "========================================================"

sudo cp /etc/fluent/fluentd.conf /etc/fluent/fluentd.conf.bak

cat << EOF | sudo tee /etc/fluent/fluentd.conf
<source>
  @type tcp
  port 5140
  bind 0.0.0.0
  tag teiren.linux
  <parse>
    @type json
  </parse>
</source>

<match teiren.linux>
	@type http
	endpoint http://3.35.81.217:8088/linux_log
	json_array true
	<format>
	  @type json
	</format>
	<buffer>
	  flush_interval 10s
	</buffer>
</match>

# SNMP 로그 수집 설정 추가
<source>
  @type udp # SNMP는 UDP 프로토콜을 사용
  port 162 # SNMP의 기본 포트는 162
  bind 0.0.0.0
  tag teiren.snmp
  <parse>
    @type none # SNMP 메시지 형식은 다양할 수 있으니, 여기서는 파싱하지 않음
  </parse>
</source>

<match teiren.snmp>
	@type http
	endpoint http://3.35.81.217:8088/snmp_log # SNMP 로그를 보낼 엔드포인트
	<format>
	  @type json # JSON 형식으로 로그 전송
	</format>
	<buffer>
	  flush_interval 10s # 10초마다 버퍼의 로그를 전송
	</buffer>
</match>

EOF

sudo systemctl restart fluentd
