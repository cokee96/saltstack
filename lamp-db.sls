mariadb-server:
  pkg.installed:
    - name: mariadb-server

pymysql:
  pip.installed:
    - name: PyMySQL
    - bin_env: /usr/bin/pip3

mariadb_bind_address:
  file.replace:
    - name: /etc/my.cnf.d/server.cnf
    - pattern: '^bind-address.*'
    - repl: 'bind-address = 0.0.0.0'
    - append_if_not_found: True
    - require:
      - pkg: mariadb-server

mariadb-service:
  service.running:
    - name: mariadb
    - enable: True
    - watch:
      - file: mariadb_bind_address
    - require:
      - pkg: mariadb-server
      - pip: pymysql

mysql_connect_any_boolean:
  selinux.boolean:
    - name: mysql_connect_any
    - value: True
    - persist: True

create_db:
  mysql_database.present:
    - name: nodes_email
    - require:
      - service: mariadb-service

create_user:
  mysql_user.present:
    - name: db_user
    - password: db_password
    - host: localhost
    - require:
      - mysql_database: create_db

grant_privileges:
  mysql_grants.present:
    - grant: all privileges
    - database: nodes_email.*
    - user: db_user
    - host: localhost
    - require:
      - mysql_user: create_user

/tmp/nodes_email.sql:
  file.managed:
    - source: salt://lamp-db/files/nodes_email.sql
    - require:
      - mysql_grants: grant_privileges

restore_database:
  cmd.run:
    - name: mysql -u db_user -p'db_password' nodes_email < /tmp/nodes_email.sql
    - require:
      - file: /tmp/nodes_email.sql
      - mysql_grants: grant_privileges
