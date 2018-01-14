icinga2-repo:
  pkgrepo.managed:
    - humanname: icinga2
    - name: deb http://packages.icinga.com/ubuntu icinga-{{ distrib }} main
    - file: /etc/apt/sources.list.d/icinga2.list
    - key_url: http://packages.icinga.com/icinga.key

