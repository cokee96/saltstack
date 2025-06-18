{% set lamp_db = salt['pillar.get']('lamp_db', {}) %}
{% set dbname = lamp_db.get('dbname', 'default_dbname') %}
{% set dbuser = lamp_db.get('dbuser', 'default_dbuser') %}
{% set upassword = lamp_db.get('upassword', 'default_password') %}

# Instalar paquetes necesarios para MariaDB y módulos SaltStack
install_dependencies:
  pkg.installed:
    - names:
      - mariadb-server
      - python3-PyMySQL
      - policycoreutils-python-utils  # o policycoreutils-python en CentOS/RHEL 7

# Crear archivo de log para MariaDB
create_mariadb_log_file:
  file.managed:
    - name: /var/log/mysqld.log
    - mode: '0775'
    - user: mysql
    - group: mysql
    - contents: ''
    - require:
      - pkg: install_dependencies

# Crear directorio de PID de MariaDB
create_mariadb_pid_directory:
  file.directory:
    - name: /var/run/mysqld
    - mode: '0775'
    - user: mysql
    - group: mysql
    - require:
      - pkg: install_dependencies

# Configurar SELinux para permitir conexiones MySQL en cualquier puerto
configure_selinux_mysql:
  selinux.boolean:
    - name: mysql_connect_any
    - value: True
    - persist: True
    - require:
      - pkg: install_dependencies

# Asegurarse de que el servicio MariaDB esté corriendo
start_mariadb:
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - file: create_mariadb_log_file
      - file: create_mariadb_pid_directory

# Crear la base de datos
create_database:
  mysql_database.present:
    - name: "{{ dbname }}"
    - require:
      - service: start_mariadb

# Crear el usuario de la base de datos con privilegios
create_db_user:
  mysql_user.present:
    - name: "{{ dbuser }}"
    - password: "{{ upassword }}"
    - host: '%'
    - priv: "*.*:ALL"
    - require:
      - mysql_database: create_database

# Copiar el archivo dump de la base de datos
copy_database_dump_file:
  file.managed:
    - name: /tmp/nodes_email.sql.j2
    - source: salt://nodes_email.sql.j2
    - mode: '0644'
    - require:
      - mysql_user: create_db_user

# Restaurar la base de datos
restore_database:
  mysql_database.import:
    - name: "{{ dbname }}"
    - source: /tmp/nodes_email.sql.j2
    - require:
      - file: copy_database_dump_file
