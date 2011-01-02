#!/bin/bash
#
# Initiate the public (i. e., assets) directory
#

THIN_PORT="${1:?'Missing port'}"

realpath=$( ruby -e "puts File.expand_path(\"$0\")")
cd $( dirname $realpath)/..
OS=`uname -s`

[ -e config/server.sh ] && source config/server.sh

# Set up sub-uri symlink for assets
find public -maxdepth 1 -type l -delete
sub_uri=$(./script/get_env.sh pod_uri.path)
if [  -n "$sub_uri" -a "$sub_uri"  != "/" ]; then
    cd public; ln -sf . ${sub_uri##/}; cd ..
fi

if [[ ! -e 'public/stylesheets/application.css' && "$INIT_PUBLIC" != 'no' ]]
then
    bundle exec thin \
        -d --pid log/thin.pid --address localhost --port $THIN_PORT \
            start
    pod_url=$(./script/get_env.sh pod_url)
    for ((i = 0; i < 30; i += 1)) do
        sleep 2
        wget -q -O tmp/server.html "$pod_url" && rm tmp/server.html \
            && break
    done
    bundle exec thin --pid log/thin.pid stop
    if [ -e tmp/server.html ]; then
        echo "Cannot get index.html from web server (aborted)" >&2
        return 2
    fi
    bundle exec jammit
fi

# Build the source tarball for AGPL compliance.
if [ ! -e  public/source.tar.gz ]; then
    branch=$( git branch | awk '/^[*]/ {print $2}')
    tar czf public/source.tar.gz  `git ls-tree -r $branch | awk '{print $4}'`
fi

# Create static public/well-known/host-meta if required
if [[ ! -e public/well-known/host-meta ||
          public/well-known/host-meta -ot config/app_config.yml ]]
then
    bundle exec rake host_meta file="public/well-known/host-meta"
fi


