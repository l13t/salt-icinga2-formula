{% set nodename = grains.id -%}
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
        'icinga2-ido-pgsql/dbconfig-upgrade': { 'type': 'boolean' , 'value': True }
        'icinga2-ido-pgsql/dbconfig-install': { 'type': 'boolean' , 'value': True }
        'icinga2-ido-pgsql/dbconfig-reinstall': { 'type': 'boolean' , 'value': True }
        'icinga2-ido-pgsql/enable': { 'type': 'boolean', 'value': True }
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

{% for feature in salt['pillar.get']("icinga2:master:features", "ido-pgsql") -%}
{% endfor -%}

icinga2-ido-pgsql-config-symlink:
  file.symlink:
    - name: /etc/icinga2/features-enabled/ido-pgsql.conf
    - target: /etc/icinga2/features-available/ido-pgsql.conf
    - force: True

icinga2-pki-new-ca:
  cmd.run:
    - name: "icinga2 pki new-ca"
    - unless:
      - file:
        - /var/lib/icinga2/ca/ca.crt
        - /var/lib/icinga2/ca/ca.key

{% set node_name = salt['pillar.get']("icinga2:master:nodename", nodename) -%}
{% set cert_path = salt['pillar.get']("icinga2:master:cert_path", "/var/lib/icinga2/certs") -%}
icinga2-pki-create-csr:
  cmd.run:
    - name: "icinga2 pki new-cert --cn '{{ node_name }}' --key '{{ cert_path }}/{{ node_name }}.key' --csr '{{ cert_path }}/{{ node_name }}.csr'"
    - unless:
      - file:
        - {{ cert_path }}/{{ node_name }}.key
        - {{ cert_path }}/{{ node_name }}.csr

icinga2-pki-create-crt:
  cmd.run:
    - require:
      - file: {{ ssl_csr_path }}
    - name: "icinga2 pki sign-csr --csr '{{ cert_path }}/{{ node_name }}.csr' --cert '{{ cert_path }}/{{ node_name }}.crt'"
    - unless:
      - file: icinga2-pki-create-csr

icinga2-service:
  service.running:
    - enable: True
    - name: icinga2
    - require:
      - pkg: icinga2

