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
