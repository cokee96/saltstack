{% set lamp_web = salt['pillar.get']('lamp_web', {}) %}
{% set automation_repository = lamp_web.get('dbname', 'automation_repository') %}

install_httpd_php:
  pkg.installed:
    - names:
      - httpd
      - php
      - php-mysql

install_git:
  pkg.installed:
    - name: git

start_httpd:
  service.running:
    - name: httpd
    - enable: True

configure_selinux:
  cmd.run:
    - name: setsebool -P httpd_can_network_connect_db on
    - unless: getsebool httpd_can_network_connect_db | grep -q 'on$'

copy_code:
  git.latest:
    - name: {{ automation_repository }}
    - target: /var/www/html/
