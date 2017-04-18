{% set nodename = grains.nodename -%}
{% set ido_db_host = salt['pillar.get']("icinga2:master:db_host", "127.0.0.1") -%}
{% set ido_db_user = salt['pillar.get']("icinga2:master:db_user", "icinga2") -%}
{% set ido_db_password = salt['pillar.get']("icinga2:master:db_password", "1qa2ws3ed") -%}
{% set ido_db_name = salt['pillar.get']("icinga2:master:db_name", "icinga2-ido") -%}
include:
  - icinga2.repo
  - icinga2.addons

icinga2:
  pkg:
    - installed

dbconfig-common:
  pkg.installed

postgresql:
  pkg.installed

icinga2-ido-pgsql-create-role:
  postgres_user.present:
    - name: {{ ido_db_user }}
    - password: {{ ido_db_password }}

icinga2-ido-pgsql-create-database:
  postgres_database.present:
    - name: {{ ido_db_name }}
    - owner: {{ ido_db_user }}

dbconfig-icinga2-ido-pgsql:
  file.managed:
    - name : /etc/dbconfig-common/icinga2-ido-pgsql.conf
    - source: salt://icinga2/files/icinga2-ido-pgsql.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 0600
    - defaults:
      db_user: {{ ido_db_user }}
      db_password: {{ ido_db_password }}
      db_name: {{ ido_db_name }}
      db_host: {{ ido_db_host }}
    - require_in:
      - pkg: icinga2-ido-pgsql

skip-dbconfg-for-ido-pgsql:
  debconf.set:
    - name: icinga2-ido-pgsql
    - data:
        'icinga2-ido-pgsql/internal/skip-preseed': { 'type': 'boolean' , 'value': True }
        'icinga2-ido-pgsql/dbconfig-upgrade': { 'type': 'boolean' , 'value': False }
        'icinga2-ido-pgsql/dbconfig-install': { 'type': 'boolean' , 'value': False }
        'icinga2-ido-pgsql/dbconfig-reinstall': { 'type': 'boolean' , 'value': False }
    - prereq:
      - pkg: icinga2-ido-pgsql

icinga2-ido-pgsql:
  pkg:
    - installed

icinga2-ido-db-install:
  cmd.run:
    - user: postgres
    - name: 'echo "set role {{ ido_db_user }}; \\i /usr/share/icinga2-ido-pgsql/schema/pgsql.sql" | psql {{ ido_db_name }} '
    - timeout: 15

icinga2-ido-pgsql-config:
  file.managed:
    - name: /etc/icinga2/features-available/ido-pgsql.conf
    - source: salt://icinga2/files/ido-pgsql.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - defaults:
      db_user: {{ ido_db_user }}
      db_password: {{ ido_db_password }}
      db_name: {{ ido_db_name }}
      db_host: {{ ido_db_host }}
    - require:
      - pkg: icinga2-ido-pgsql

icinga2-ido-pgsql-config-symlink:
  file.symlink:
    - name: /etc/icinga2/features-enabled/ido-pgsql.conf
    - target: /etc/icinga2/features-available/ido-pgsql.conf
    - force: True

icinga2-master-ca-cert:
  file.managed:
    - name: /etc/icinga2/pki/ca.crt
    - user: nagios
    - group: nagios
    - mode: 644
    - contents: |
      {{ salt['pillar.get']("icinga2:master:ca_crt") | indent(8) }}

icinga2-master-ca-key:
  file.managed:
    - name: /etc/icinga2/pki/ca.key
    - user: nagios
    - group: nagios
    - mode: 644
    - contents: |
      {{ salt['pillar.get']("icinga2:master:ca_key") | indent(8) }}

{% set ssl_csr_path = salt['pillar.get']("icinga2:master:ssl_csr_path", "/etc/icinga2/pki/%s.csr" % nodename) -%}
{% set ssl_key_path = salt['pillar.get']("icinga2:master:ssl_key_path", "/etc/icinga2/pki/%s.key" % nodename) -%}
{% set ssl_cert_path = salt['pillar.get']("icinga2:master:ssl_cert_path", "/etc/icinga2/pki/%s.crt" % nodename) -%}

icinga2-pki-create-csr:
  cmd.run:
    - name: "icinga2 pki new-cert --cn '{{ nodename }}' --key '{{ ssl_key_path }}' --csr '{{ ssl_csr_path }}'"
    - unless:
      - file:
        - {{ ssl_key_path }}
        - {{ ssl_csr_path }}

icinga2-pki-create-crt:
  cmd.run:
    - require:
      - file: {{ ssl_csr_path }}
    - name: "icinga2 pki sign-csr --csr '{{ ssl_csr_path }}' --cert '{{ ssl_cert_path }}'"
    - unless:
      - file: {{ ssl_cert_path }}

icinga2-service:
  service.running:
    - enable: True
    - name: icinga2
    - require:
      - pkg: icinga2
