install_mysql_python_fallback:
  pkg.installed:
    - name: python3-PyMySQL
    - failhard: False

install_dependencies:
  pkg.installed:
    - pkgs:
      - mariadb-server
      - mariadb
      - MySQL-python
    - require:
      - pkg: install_mysql_python_fallback

configure_selinux_mysql:
  selinux.boolean:
    - name: mysql_connect_any
    - value: True
    - persist: True

restart_mariadb:
  service.running:
    - name: mariadb
    - enable: True
    - watch:
      - pkg: install_dependencies

create_mariadb_log_file:
  file.managed:
    - name: /var/log/mysqld.log
    - user: mysql
    - group: mysql
    - mode: 0775
    - contents: ''
    - require:
      - service: restart_mariadb

create_mariadb_pid_directory:
  file.directory:
    - name: /var/run/mysqld
    - user: mysql
    - group: mysql
    - mode: 0775

start_mariadb:
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - file: create_mariadb_log_file
      - file: create_mariadb_pid_directory

create_database:
  mysql_database.present:
    - name: {{ pillar['lamp_db']['dbname'] }}
    - require:
      - pkg: install_dependencies

create_db_user:
  mysql_user.present:
    - name: {{ pillar['lamp_db']['dbuser'] }}
    - password: {{ pillar['lamp_db']['upassword'] }}
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
    - name: {{ pillar['lamp_db']['dbname'] }}
    - target: /tmp/nodes_email.sql
    - require:
      - file: copy_database_dump_file
