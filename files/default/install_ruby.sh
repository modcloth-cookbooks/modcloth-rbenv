#!/bin/bash

ACTION=$1
USER=$2
RUBY=$3

HOME="/home/${USER}"
TMPDIR="${HOME}"
PREFIX="${HOME}/.rbenv/versions/${RUBY}"
CONFIGURE_OPTS="--with-opt-dir=/opt/local"
LDFLAGS="-R/opt/local -L/opt/local/lib "

FILER="/net/filer/export/ModCloth/shared02/installations/rbenv"
OS_VERSION=`uname -v`

source .bashrc

if [ "${ACTION}" = "install" ]; then

  if [ -d $HOME/.rbenv/versions/${RUBY} ]; then
    echo "ruby #{ruby} already installed..."
  elif [ -f $FILER/$OS_VERSION/${USER}/${RUBY}.tar.gz ]; then
    echo "installing ruby ${RUBY} from filer..."
    mkdir -p $HOME/.rbenv/versions
    tar -xzf $FILER/$OS_VERSION/${USER}/${RUBY}.tar.gz -C $HOME/.rbenv/versions
  else
      if [ ! -d $FILER/$OS_VERSION/${USER} ]; then
        echo "creating pkg directory..."
        mkdir -p $FILER/$OS_VERSION/#{rbenv_user}
      fi
    echo "installing ruby ${RUBY} from source..."
    rbenv install ${RUBY}
    echo "putting ruby ${RUBY} on the filer for safe keeping..."
    cd .rbenv/versions/
    mkdir -p $FILER/$OS_VERSION/${USER}
    tar -czf $FILER/$OS_VERSION/${USER}/${RUBY}.tar.gz ${RUBY}
  fi

  rbenv rehash
  rbenv global ${RUBY}

  if rbenv which bundle; then
    echo 'bundler already installed'
  else
    gem install bundler
  fi
  
  rbenv rehash

fi
 