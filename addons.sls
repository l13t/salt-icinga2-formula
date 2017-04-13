checks_and_plugins:
  pkg.installed:
    - pkgs:
      - monitoring-plugins-standard ### is not available in ubuntu 14.04
      - nagios-plugins-contrib
      - libmonitoring-plugin-perl ### is not available in ubuntu 14.04
      - nagios-plugins-standard
    - install_recommends: False
