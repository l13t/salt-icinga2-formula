include:
  - icinga2.repo

icinga2:
  pkg.installed:
    - require:
      - pkgrepo: icinga2-repo

gen-icinga2.crt:
  cmd.run:
    - name: |
        icinga2 pki new-cert --cn {{ grains['nodename'] }} --key /etc/icinga2/pki/{{ grains['nodename'] }}.key --cert /etc/icinga2/pki/{{ grains['nodename'] }}.crt &&
        icinga2 pki save-cert --key /etc/icinga2/pki/{{ grains['nodename'] }}.key --cert /etc/icinga2/pki/{{ grains['nodename'] }}.crt --trustedcert /etc/icinga2/pki/trusted-master.crt --host {{ salt['pillar.get']('icinga2:endpoints')[0]['host'] }} &&
        icinga2 pki save-cert --key /etc/icinga2/pki/{{ grains['nodename'] }}.key --cert /etc/icinga2/pki/{{ grains['nodename'] }}.crt --trustedcert /etc/icinga2/pki/trusted-master.crt --host {{ salt['pillar.get']('icinga2:endpoints')[0]['host'] }} --port {{ salt['pillar.get']('icinga2:endpoints')[0]['port'] }} &&
        ticket=$(icinga2 pki ticket --cn {{ grains['nodename'] }} --salt {{ salt['pillar.get']('icinga2:master_ticket_salt', '') }})
        icinga2 pki request --host {{ salt['pillar.get']('icinga2:endpoints')[0]['host'] }} --port {{ salt['pillar.get']('icinga2:endpoints')[0]['port'] }} --ticket $ticket --key /etc/icinga2/pki/{{ grains['nodename'] }}.key --cert /etc/icinga2/pki/{{ grains['nodename'] }}.crt --trustedcert /etc/icinga2/pki/trusted-master.crt --ca /etc/icinga2/pki/ca.crt &&
        icinga2 node setup --ticket $ticket --endpoint {{ salt['pillar.get']('icinga2:endpoints')[0]['host'] }} --zone {{ grains['nodename'] }} --master_host {{ salt['pillar.get']('icinga2:endpoints')[0]['host'] }} --trustedcert /etc/icinga2/pki/trusted-master.crt &&
        service icinga2 restart
    - unless: test -f /etc/icinga2/pki/{{ grains['nodename'] }}.key -a -f /etc/icinga2/pki/{{ grains['nodename'] }}.crt
    - order: last
