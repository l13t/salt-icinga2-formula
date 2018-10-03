{% for feature in salt['pillar.get']("icinga2:features", []) -%}
icinga2_{{ feature }}_enable:
  file.symlink:
    - force: True
    - name: /etc/icinga2/features-enabled/{{ feature }}.conf
    - target: /etc/icinga2/features-available/{{ feature }}.conf

{% endfor -%}
