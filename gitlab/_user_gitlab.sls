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
