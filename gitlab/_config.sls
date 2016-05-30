#!jinja|yaml

{% from 'gitlab/defaults.yaml' import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('gitlab:lookup')  ) %}

include:
  - gitlab

{% set gl_home = salt['user.info'](datamap.user.name|default('git')).home|default('/home/' ~ datamap.user.name|default('git')) %}
{% set gl_user = datamap.user.name|default('git') %}
{% set gl_group = datamap.group.name|default('git') %}

gitlab:
  git:
    - latest
    - name: https://gitlab.com/gitlab-org/gitlab-ce.git
    - rev: {{ salt['pillar.get']('gitlab:version', '7-5-stable') }}
    - user: {{ gl_user }}
    - target: {{ gl_home }}/gitlab
    - force_checkout: True
    - watch_in:
      - cmd: gitlab_gems
      - cmd: shell_setup
  file:
    - managed
    - name: {{ gl_home }}/gitlab/config/gitlab.yml
    - source: salt://gitlab/files/gitlab.yml
    - user: {{ gl_user }}
    - group: {{ gl_group }}
    - mode: 640
    - template: jinja

gitlab_gems:
  cmd:
    - wait
    - name: bundle install --verbose --deployment --without development test mysql aws
    - user: {{ gl_user }}
    - cwd: {{ gl_home }}/gitlab
    - shell: /bin/bash

home_dir:
  file:
    - directory
    - name: {{ gl_home }}
    - user: {{ gl_user }}
    - group: {{ gl_group }}
    - mode: 755

satellites_dir:
  file:
    - directory
    - name: {{ gl_home }}/gitlab-satellites
    - user: {{ gl_user }}
    - group: {{ gl_group }}
    - mode: 750

pids_dir:
  file:
    - directory
    - name: {{ gl_home }}/gitlab/tmp/pids
    - user: {{ gl_user }}
    - group: {{ gl_group }}
    - mode: 750

sockets_dir:
  file:
    - directory
    - name: {{ gl_home }}/gitlab/tmp/sockets
    - user: {{ gl_user }}
    - group: {{ gl_group }}
    - mode: 751

uploads_dir:
  file:
    - directory
    - name: {{ gl_home }}/gitlab/public/uploads
    - user: {{ gl_user }}
    - group: {{ gl_group }}
    - mode: 755

unicorn_config:
  file:
    - managed
    - name: {{ gl_home }}/gitlab/config/unicorn.rb
    - source: salt://gitlab/files/unicorn.rb
    - user: {{ gl_user }}
    - group: {{ gl_group }}
    - mode: 640
    - template: jinja

rack_attack_config:
  file:
    - managed
    - name: {{ gl_home }}/gitlab/config/initializers/rack_attack.rb
    - source: salt://gitlab/files/rack_attack.rb
    - user: {{ gl_user }}
    - group: {{ gl_group }}
    - mode: 640
    - template: jinja

#git_config:
#  file:
#    - managed
#    - name: /home/git/.gitconfig
#    - source: salt://gitlab/files/gitconfig
#    - template: jinja
#    - user: {{ datamap.user.name|default('git') }}
#    - group: {{ datamap.group.name|default('git') }}
#    - mode: 640

db_config:
  file:
    - managed
    - name: {{ gl_home }}/gitlab/config/database.yml
    - source: salt://gitlab/files/database.yml
    - user: {{ gl_user }}
    - group: {{ gl_group }}
    - mode: 640
    - template: jinja

shell_setup:
  cmd:
    - wait
    - name: bundle exec rake gitlab:shell:install[{{ salt['pillar.get']('gitlab:shell:version', 'v2.2.0') }}] REDIS_URL=redis://localhost:6379 RAILS_ENV=production
    - user: {{ gl_user }}
    - cwd: {{ gl_home }}/gitlab

shell_config:
  file:
    - managed
    - name: {{ gl_home }}/gitlab-shell/config.yml
    - source: salt://gitlab/files/shell-config.yml
    - user: {{ gl_user }}
    - group: {{ gl_group }}
    - mode: 644
    - template: jinja

initialize_db:
  cmd:
    - run
    - name: echo yes | bundle exec rake gitlab:setup RAILS_ENV=production
    - user: {{ gl_user }}
    - cwd: {{ gl_home }}/gitlab
    - shell: /bin/bash
    - unless: psql -h {{ salt['pillar.get']('gitlab:db:host', 'localhost') }} -U {{ salt['pillar.get']('gitlab:db:user', 'gitlab') }} {{ salt['pillar.get']('gitlab:db:name', 'gitlab') }} -c 'select * from users;'
    - env:
      - PGPASSWORD: {{ salt['pillar.get']('gitlab:db:password', 'gitlab') }}

migrate_db:
  cmd:
    - wait
    - name: bundle exec rake db:migrate RAILS_ENV=production
    - user: {{ gl_user }}
    - cwd: {{ gl_home }}/gitlab
    - shell: /bin/bash
    - watch:
      - git: gitlab

precompile_assets:
  cmd:
    - wait
    - name: bundle exec rake assets:clean assets:precompile RAILS_ENV=production
    - user: {{ datamap.user.name|default('git') }}
    - cwd: {{ gl_home }}/gitlab
    - shell: /bin/bash
    - watch:
      - git: gitlab

{#
clear_cache:
  cmd.wait:
    - user: {{ datamap.user.name|default('git') }}
    - cwd: /home/git/gitlab
    - name: bundle exec rake cache:clear RAILS_ENV=production
    - shell: /bin/bash
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-recompile-assets
#}

{#
# Needed to be able to update tree via git
gitlab_gitstash:
  cmd.wait:
    - user: {{ datamap.user.name|default('git') }}
    - cwd: /home/git/gitlab
    - name: git stash
    - watch:
      - git: gitlab-git
#}

{#
# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/support/logrotate/gitlab
gitlab-logrotate:
  file.managed:
    - name: /etc/logrotate.d/gitlab
    - source: salt://gitlab/files/logrotate
    - user: root
    - group: root
    - mode: 644
#}
