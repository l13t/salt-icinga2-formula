/etc/icinga2-classicui/cgi.cfg:
  file.managed:
    - source: salt://icinga2/files/cgi.cfg
    - template: jinja
    - user: root
    - group: root
    - mode: 644
