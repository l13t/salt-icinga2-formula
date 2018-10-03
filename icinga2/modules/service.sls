icinga2-service:
  service.running:
    - enable: True
    - name: icinga2
    - require:
      - pkg: icinga2

