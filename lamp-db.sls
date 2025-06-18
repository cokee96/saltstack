{% set dbname = pillar.get('lamp_db:dbname') %}
{% set dbuser = pillar.get('lamp_db:dbuser') %}
{% set upassword = pillar.get('lamp_db:upassword') %}

mariadb-server:
  pkg.installed:
    - name: mariadb-server

mariadb_bind_address:
  file.line:
    - name: /etc/my.cnf.d/server.cnf
    - mode: ensure
    - content: 'bind-address = 0.0.0.0'
    - match: '^bind-address\s*=.*'
    - after: EOF
    - require:
      - pkg: mariadb-server
    - watch_in:
      - service: mariadb-service

mariadb-service:
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - file: mariadb_bind_address
      - pkg: mariadb-server

mysql_connect_any_boolean:
  selinux.boolean:
    - name: mysql_connect_any
    - value: on
    - persistent: True

create_db:
  mysql_database.present:
    - name: {{ dbname }}
    - require:
      - service: mariadb-service

create_user:
  mysql_user.present:
    - name: {{ dbuser }}
    - host: localhost
    - password: {{ upassword }}
    - require:
      - mysql_database: create_db

grant_privileges:
  mysql_grants.present:
    - name: {{ dbuser }}@localhost
    - grant: ['ALL PRIVILEGES']
    - database: {{ dbname }}
    - require:
      - mysql_user: create_user

/tmp/nodes_email.sql:
  file.managed:
    - source: salt://lamp/nodes_email.sql
    - user: root
    - group: root
    - mode: '0644'
    - require:
      - mysql_grants: grant_privileges

restore_database:
  cmd.run:
    - name: mysql -u {{ dbuser }} -p'{{ upassword }}' {{ dbname }} < /tmp/nodes_email.sql
    - unless: mysql -u {{ dbuser }} -p'{{ upassword }}' {{ dbname }} -e "SHOW TABLES" | grep usuarios
    - require:
      - file: /tmp/nodes_email.sql
      - mysql_grants: grant_privileges
