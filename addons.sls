{% set distrib_codename = grains.lsb_distrib_codename %}
checks_and_plugins:
  pkg.installed:
    - pkgs:
      {% if distrib_codename == 'trusty' %}
      - monitoring-plugins-standard ### is not available in ubuntu 14.04
      - libmonitoring-plugin-perl ### is not available in ubuntu 14.04
      {% endif %}
      - nagios-plugins-contrib
      - nagios-plugins-standard
    - install_recommends: False
