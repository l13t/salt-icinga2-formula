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

{% set node_name = salt['pillar.get']('icinga2:agent:nodename', grains.nodename) -%}
{% set master_host = salt['pillar.get']('icinga2:masters')[0]['host']|default('icinga2-master') -%}
{% set master_port = salt['pillar.get']('icinga2:masters')[0]['port']|default('5665') -%}

gen-icinga2.crt:
  cmd.run:
    - name: |
        icinga2 pki new-cert --cn {{ node_name }} --key /etc/icinga2/pki/{{ node_name }}.key --cert /etc/icinga2/pki/{{ node_name }}.crt &&
        icinga2 pki save-cert --key /etc/icinga2/pki/{{ node_name }}.key --cert /etc/icinga2/pki/{{ node_name }}.crt --trustedcert /etc/icinga2/pki/trusted-master.crt --host {{ master_host }} &&
        icinga2 pki save-cert --key /etc/icinga2/pki/{{ node_name }}.key --cert /etc/icinga2/pki/{{ node_name }}.crt --trustedcert /etc/icinga2/pki/trusted-master.crt --host {{ master_host }} --port {{ master_port }} &&
        ticket=$(icinga2 pki ticket --cn {{ node_name }} --salt {{ salt['pillar.get']('icinga2:master_ticket_salt', '') }})
        icinga2 pki request --host {{ master_host }} --port {{ master_port }} --ticket $ticket --key /etc/icinga2/pki/{{ node_name }}.key --cert /etc/icinga2/pki/{{ node_name }}.crt --trustedcert /etc/icinga2/pki/trusted-master.crt --ca /etc/icinga2/pki/ca.crt &&
        icinga2 node setup --ticket $ticket --endpoint {{ master_host }} --zone {{ node_name }} --master_host {{ master_host }} --trustedcert /etc/icinga2/pki/trusted-master.crt &&
        service icinga2 restart
    - unless: test -f /etc/icinga2/pki/{{ node_name }}.key -a -f /etc/icinga2/pki/{{ node_name }}.crt
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
      masters: {{ salt['pillar.get']('icinga2:masters', {}) }}
      satellites: {{ salt['pillar.get']('icinga2:agents:%s:satellite' % node_name, {}) }}
      agent: {{ salt['pillar.get']('icinga2:agents:%s' % node_name, {}) }}
      nodename: {{ node_name }}

