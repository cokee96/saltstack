{% set lamp_web = salt['pillar.get']('lamp_web', {}) %}
{% set automation_repository = lamp_web.get('dbname', 'automation_repository') %}
# Install httpd and php
install_httpd_php:
  pkg.installed:
    - names:
      - httpd
      - php
      - php-mysql

# Install web role specific dependencies
install_git:
  pkg.installed:
    - name: git

# Ensure httpd service is started and enabled
start_httpd:
  service.running:
    - name: httpd
    - enable: True

# Configure SELinux to allow httpd to connect to remote database
configure_selinux:
  selinux.boolean:
    - name: httpd_can_network_connect_db
    - value: True
    - persist: True

# Copy the code from repository
copy_code:
  git.latest:
    - name: {{ automation_repository }}
    - target: /var/www/html/
    - force: True