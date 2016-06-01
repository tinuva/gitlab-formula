#!jinja|yaml

{% from 'gitlab/defaults.yaml' import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('gitlab:lookup')  ) %}

include:
  - gitlab
  - gitlab._user_gitlab

gitlab_deppkgs:
  pkg:
    - installed
    - pkgs: {{ datamap.gitlab.pkgs|default([]) }}

dbdriver:
  pkg:
    - installed
    - pkgs: {{ datamap.db.pkgs|default([]) }}
