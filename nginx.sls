nginx-package-installed:
  pkg.installed:
    - name: nginx

create-web-example-directory:
  file.directory:
    - name: /var/www/html/web-example
    - mode: 0755

create-index-html-file:
  file.managed:
    - name: /var/www/html/hello-world/index.html
    - source: salt://module_name/index.html
    - template: jinja
    - context:
        hostname: {{ grains['host'] }}
    - mode: 0644

copy-index-html-file:
  file.managed:
    - name: /var/www/html/index.html
    - source: /var/www/html/hello-world/index.html
    - mode: 0644
    - require:
      - file: create-index-html-file

link-nginx-configuration:
  file.symlink:
    - target: /etc/nginx/sites-available/default
    - name: /etc/nginx/sites-enabled/default
    - require:
      - pkg: nginx-package-installed

restart-nginx:
  service.running:
    - name: nginx
    - enable: True
    - watch:
      - file: link-nginx-configuration
