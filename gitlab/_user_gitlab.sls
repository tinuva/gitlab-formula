#!jinja|yaml

{% from 'gitlab/defaults.yaml' import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('gitlab:lookup')  ) %}

gitlab_user:
  user:
    - present
    - name: {{ datamap.user.name|default('git') }}
    - home: {{ datamap.user.home|default('/home/git') }}
    - shell: {{ datamap.user.shell|default('/bin/bash') }} #TODO set to /bin/false ?
    - createhome: True
    - system: True

gitlab_user_cron_backup:
  cron:
    - present
    - user: {{ datamap.user.name|default('git') }}
    - name: cd /home/git/gitlab && PATH=/usr/local/bin:/usr/bin:/bin bundle exec rake gitlab:backup:create RAILS_ENV=production CRON=1
    - minute: 0
    - hour: 2
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'
    - comment: 'Create a full backup of the GitLab repositories and SQL database every day at 2am'