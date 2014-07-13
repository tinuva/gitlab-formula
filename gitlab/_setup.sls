#!jinja|yaml

{% from 'gitlab/defaults.yaml' import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('gitlab:lookup')) %}

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

{# TODO check redhat pkgs:
      - autoconf
      - automake
      - binutils
      - bison
      - byacc
      - crontabs
      - cscope
      - ctags
      - cvs
      - db4-devel
      - diffstat
      - doxygen
      - elfutils
      - expat-devel
      - flex
      - gcc
      - gcc-c++
      - gcc-gfortran
      - gdbm-devel
      - gettext
      - git
      - glibc-devel
      - indent
      - intltool
      - libffi
      - libffi-devel
      - libicu
      - libicu-devel
      - libcurl-devel
      - libtool
      - libxml2
      - libxml2-devel
      - libxslt
      - libxslt-devel
      - libyaml
      - libyaml-devel
      - logrotate
      - logwatch
      - make
      - ncurses-devel
      - openssl-devel
      - patch
      - patchutils
      - perl-Time-HiRes
      - pkgconfig
      - postgresql-devel
      - python-devel
      - rcs
      - readline
      - readline-devel
      - redhat-rpm-config
      - redis
      - rpm-build
      - sqlite-devel
      - subversion
      - sudo
      - swig
      - system-config-firewall-tui
      - systemtap
      - tcl-devel
      - vim-enhanced
      - wget
    - require:
      - pkgrepo: PUIAS_6_computational
#}

dbdriver:
  pkg:
    - installed
    - pkgs: {{ datamap.db.pkgs|default([]) }}
