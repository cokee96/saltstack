# Install prerequisites packages at the latest version
install_prerequisites:
  pkg.installed:
    - names:
      - httpd
      - git
      - python3
      - python3-pip
      - nodejs
      - npm

# Start services after installation
start_services:
  service.running:
    - name: httpd
    - enable: True
    - watch:
      - pkg: install_prerequisites
    - require:
      - pkg: install_prerequisites