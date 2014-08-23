#!jinja|yaml

{% from 'gitlab/defaults.yaml' import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('gitlab:lookup')  ) %}

include:
  - gitlab
  - gitlab._user_gitlab

#TODO move ruby installation to dedicated ruby formula

ruby:
{% if datamap.ruby.use_rvm|default(False) %}
{# TODO check redhat family specific code:
  pkg.installed:
    - pkgs:
    {% if grains['os_family'] == 'RedHat' %}
      - bash
      - bzip2
      - coreutils
      - curl
      - gawk
      - gzip
      - libtool
      - sed
      - zlib
      - zlib-devel
    {% endif %}
#}
  rvm:
    - installed
    - name: {{ datamap.ruby.rvm.name|default('ruby-2.1.0') }}
    - default: True
    - user: {{ datamap.git.user.name|default('git') }}
    # - require:
      #TODO - user: git-user
      #TODO - pkg: rvm-deps
  gem:
    - installed
    - user: {{ datamap.git.user.name|default('git') }}
    - ruby: {{ datamap.ruby.rvm.name|default('ruby-2.1.0') }}
{% else %}
  pkg:
    - installed
    - pkgs: {{ datamap.ruby.sys.pkgs|default([]) }}
  {% if grains['os_family'] == 'Debian' %}
  gem:
    - installed
    - name: bundler
  {% endif %}
{% endif %}

gitlab_deppkgs:
  pkg:
    - installed
    - pkgs: {{ datamap.gitlab.pkgs|default([]) }}

dbdriver:
  pkg:
    - installed
    - pkgs: {{ datamap.db.pkgs|default([]) }}
