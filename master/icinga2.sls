include:
  - icinga2.repo

icinga2:
  pkg:
    - installed
  service.running:
    enabled: True
    require:
      - pkg: icinga2-repo
