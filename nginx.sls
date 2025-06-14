# Install nginx package
install_nginx:
  pkg.installed:
    - name: nginx

# Ensure /var/www/html exists
create_html_base:
  file.directory:
    - name: /var/www/html
    - mode: 0755

# Create directory for static content
create_directory:
  file.directory:
    - name: /var/www/html/web-example
    - mode: 0755
    - require:
      - file: create_html_base


create_index_html:
  file.managed:
    - name: /var/www/html/web-example/index.html
    - source: salt://index.html.j2
    - template: jinja
    - context:
        node: {{ grains['id'] }}
    - mode: 0644
    - require:
      - file: create_directory


# Copy "index.html" to default Nginx location
copy_index_html:
  file.managed:
    - name: /var/www/html/index.html
    - source: /var/www/html/web-example/index.html
    - mode: 0644

# Declare correct path for the web
update_nginx_conf:
  file.replace:
    - name: /etc/nginx/nginx.conf
    - pattern: '^(\s*root\s+/usr/share/nginx/html;)'
    - repl: '       root         /var/www/html/;'

# Restart Nginx
restart_nginx:
  service.running:
    - name: nginx
    - watch:
      - file: update_nginx_conf