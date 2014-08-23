#!jinja|yaml

{% from 'gitlab/defaults.yaml' import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('gitlab:lookup')  ) %}

include:
  - gitlab

{% set gl_home = salt['user.info'](datamap.user.name|default('git')).home|default('/home/' ~ datamap.user.name|default('git')) %}

{% if grains['os_family'] == 'RedHat' and grains['osmajorrelease'][0] == '7' %}
## Followed guide for SystemD at
## https://github.com/gitlabhq/gitlab-recipes/tree/master/init/systemd
sidekiq_systemd:
  file:
    - managed
    - name: /etc/systemd/system/gitlab-sidekiq.service
    - source: salt://gitlab/files/gitlab-sidekiq.service
    - user: root
    - group: root
    - mode: 644
  service:
    - running
    - name: gitlab-sidekiq
    - enable: True
    - watch:
      - git: gitlab
      - file: gitlab
      - cmd: shell_setup

unicorn_systemd:
  file:
    - managed
    - name: /etc/systemd/system/gitlab-unicorn.service
    - source: salt://gitlab/files/gitlab-unicorn.service
    - user: root
    - group: root
    - mode: 644
  service:
    - running
    - name: gitlab-unicorn
    - enable: True
    - watch:
      - git: gitlab
      - file: gitlab
      - cmd: shell_setup

gitlab_systemd:
  file:
    - managed
    - name: /etc/systemd/system/gitlab.target
    - source: salt://gitlab/files/gitlab.target
    - user: root
    - group: root
    - mode: 644
  service:
    - enabled
    - name: gitlab.target
    - enable: True

{% else %}
defaults_file:
  file:
    - managed
    - name: {{ datamap.gitlab.config.defaults_file.path|default('/etc/default/gitlab') }}
    - source: salt://gitlab/files/defaults_file.{{ salt['grains.get']('oscodename') }}
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: gitlab_srv

gitlab_srv:
  file:
    - symlink
    - name: /etc/init.d/gitlab
    - target: {{ gl_home }}/gitlab/lib/support/init.d/gitlab
  service:
    - running
    - name: gitlab
    - enable: True
{% endif %}