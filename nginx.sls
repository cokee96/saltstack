install_mariadb_packages:
  pkg.installed:
    - pkgs:
      - mariadb-server
      - MySQL-python

configure_selinux_mysql:
  selinux.boolean:
    - name: mysql_connect_any
    - value: True
    - persistent: True
    - require:
      - pkg: install_mariadb_packages

restart_mariadb:
  service.running:
    - name: mariadb
    - enable: True
    - reload: False
    - watch:
      - pkg: install_mariadb_packages

create_mariadb_log_file:
  file.managed:
    - name: /var/log/mysqld.log
    - user: mysql
    - group: mysql
    - mode: 0775
    - contents: ''
    - require:
      - pkg: install_mariadb_packages

create_mariadb_pid_directory:
  file.directory:
    - name: /var/run/mysqld
    - user: mysql
    - group: mysql
    - mode: 0775
    - require:
      - pkg: install_mariadb_packages

create_database:
  mysql_database.present:
    - name: {{ pillar.get('lamp_db:dbname', 'default_db') }}
    - require:
      - service: restart_mariadb

create_db_user:
  mysql_user.present:
    - name: {{ pillar.get('lamp_db:dbuser', 'default_user') }}
    - password: {{ pillar.get('lamp_db:upassword', 'default_pass') }}
    - host: '%'
    - privileges:
        - '*.*': 'ALL'
    - require:
        - mysql_database: create_database

copy_database_dump_file:
  file.managed:
    - name: /tmp/nodes_email.sql
    - source: salt://nodes_email.sql
    - mode: 0644
    - require:
        - mysql_user: create_db_user

restore_database:
  mysql_database.import:
    - name: {{ pillar.get('lamp_db:dbname', 'default_db') }}
    - target: /tmp/nodes_email.sql
    - require:
        - file: copy_database_dump_file
