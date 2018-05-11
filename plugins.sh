#!/bin/bash
# symlink all plugins
for source in =$(ls -d /opt/xen-orchestra/packages/xo-server-*); do
    ln -s "$source" /usr/local/lib/node_modules/
done
systemctl restart xo-server.service
