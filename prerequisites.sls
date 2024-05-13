install-prerequisites:
  pkg.installed:
    - names:
        - httpd
        - nodejs
        - npm
        - mysql-server

start-services:
  service.running:
    - names: 
        - httpd
        - git
        - python3
        - python3-pip
        - nodejs
        - npm
        - mysql-server
    - enable: True