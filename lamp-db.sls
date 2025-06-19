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

create_db_and_user:
  cmd.run:
    - name: |
        mysql -uroot -e "CREATE DATABASE IF NOT EXISTS nodes_email CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        mysql -uroot -e "DROP USER 'coke'@'localhost';" || true
        mysql -uroot -e "CREATE USER 'coke'@'localhost' IDENTIFIED BY '658078381';"
        mysql -uroot -e "GRANT ALL PRIVILEGES ON nodes_email.* TO 'coke'@'localhost';"
        mysql -uroot -e "FLUSH PRIVILEGES;"
    - require:
      - service: mariadb-service

/tmp/nodes_email.sql:
  file.managed:
    - source: salt://nodes_email.sql
    - require:
      - cmd: create_db_and_user

restore_database:
  cmd.run:
    - name: >
        mysql -u{{ pillar['lamp_db']['dbuser'] }} -p'{{ pillar['lamp_db']['upassword'] }}' {{ pillar['lamp_db']['dbname'] }} < /tmp/nodes_email.sql
    - require:
      - file: /tmp/nodes_email.sql
