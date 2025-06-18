install_dependencies:
  pkg.installed:
    - pkgs:
      - mariadb-server
      - mariadb
      - python3-PyMySQL
      - policycoreutils-python

create_mariadb_log_file:
  file.managed:
    - name: /var/log/mysqld.log
    - user: mysql
    - group: mysql
    - mode: 644
    - require:
      - pkg: install_dependencies

create_mariadb_pid_directory:
  file.directory:
    - name: /var/run/mysqld
    - user: mysql
    - group: mysql
    - mode: 755
    - require:
      - pkg: install_dependencies

configure_selinux_mysql:
  selinux.boolean:
    - name: mysql_connect_any
    - value: True
    - persist: True
    - require:
      - pkg: install_dependencies

start_mariadb:
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - file: create_mariadb_log_file
      - file: create_mariadb_pid_directory

create_database:
  mysql_database.present:
    - name: default_dbname
    - require:
      - service: start_mariadb

create_db_user:
  mysql_user.present:
    - name: default_dbuser
    - host: localhost
    - password: default_password
    - require:
      - mysql_database: create_database

copy_database_dump_file:
  file.managed:
    - name: /tmp/nodes_email.sql
    - source: salt://nodes_email.sql
    - mode: 644
    - require:
      - mysql_user: create_db_user

restore_database:
  mysql_database.import:
    - name: default_dbname
    - source: /tmp/nodes_email.sql
    - require:
      - file: copy_database_dump_file

# Optional: Reload salt-minion to register mysql module (only needed once)
reload_salt_minion:
  service.running:
    - name: salt-minion
    - enable: True
    - reload: True
    - watch:
      - pkg: install_dependencies
