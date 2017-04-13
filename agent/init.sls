include:
  - icinga2.repo
  - icinga2.addons

icinga2:
  pkg:
    - installed

icinga2-service:
  service.running:
    - enable: True
    - name: icinga2
    - require:
      - pkg: icinga2

{% set nodename = grains['id'] -%}
{% set master_host = salt['pillar.get']('icinga2:masters')[0]['host'] -%}
{% set master_port = salt['pillar.get']('icinga2:masters')[0]['port']|default('5665') -%}

gen-icinga2.crt:
  cmd.run:
    - name: |
        icinga2 pki new-cert --cn {{ nodename }} --key /etc/icinga2/pki/{{ nodename }}.key --cert /etc/icinga2/pki/{{ nodename }}.crt &&
        icinga2 pki save-cert --key /etc/icinga2/pki/{{ nodename }}.key --cert /etc/icinga2/pki/{{ nodename }}.crt --trustedcert /etc/icinga2/pki/trusted-master.crt --host {{ master_host }} &&
        icinga2 pki save-cert --key /etc/icinga2/pki/{{ nodename }}.key --cert /etc/icinga2/pki/{{ nodename }}.crt --trustedcert /etc/icinga2/pki/trusted-master.crt --host {{ master_host }} --port {{ master_port }} &&
        ticket=$(icinga2 pki ticket --cn {{ nodename }} --salt {{ salt['pillar.get']('icinga2:master_ticket_salt', '') }})
        icinga2 pki request --host {{ master_host }} --port {{ master_port }} --ticket $ticket --key /etc/icinga2/pki/{{ nodename }}.key --cert /etc/icinga2/pki/{{ nodename }}.crt --trustedcert /etc/icinga2/pki/trusted-master.crt --ca /etc/icinga2/pki/ca.crt &&
        icinga2 node setup --ticket $ticket --endpoint {{ master_host }} --zone {{ nodename }} --master_host {{ master_host }} --trustedcert /etc/icinga2/pki/trusted-master.crt &&
        service icinga2 restart
    - unless: test -f /etc/icinga2/pki/{{ nodename }}.key -a -f /etc/icinga2/pki/{{ nodename }}.crt
    - order: last

gen-zones-file:
  file.managed:
    - name: /etc/icinga2/zones.conf
    - source: salt://icinga2/files/zones-agent.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - defaults:
      masters: salt['pillar.get']('icinga2:masters', {})
      satellites: salt['pillar.get']('icinga2:agents:%s:satellite' % nodename, {})
      agent: salt['pillar.get']('icinga2:agents:%s' % nodename, {})
      nodename: {{ nodename }}
