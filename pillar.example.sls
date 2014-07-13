gitlab:
  db:
    host: postgreshost.domain.local
    password: myultracryptopassword42
  gravatar:
    enabled: False
  domain: gitlabhost.domain.local
  https: true
  shell:
    ca_file: /etc/ssl/certs/gitlabhost.domain.local.ca.pem
    ca_path: /etc/ssl/certs/


# PostgreSQL DB backend with https://github.com/bechtoldt/postgresql-formula
postgresql:
  lookup:
    server:
      config:
        pg_hba:
          config:
            - name: allow access from gitlab system to gitlab db
              type: host
              database: gitlab
              user: gitlab
              address: {{ salt['dig.A']('gitlabhost.domain.local')[0] }}/32
              auth_method: md5
  users:
    - name: gitlab
      password: myultracryptopassword42
  databases:
    - name: gitlab
      encoding: SQL_ASCII
      lc_collate: C
      lc_ctype: C
      template: template1
