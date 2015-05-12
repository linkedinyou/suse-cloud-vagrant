#!/bin/bash

set -e

cd /var/lib/firstboot

patch -d /opt/dell -p1 < barclamp-pacemaker-ignore-target-role-changes.patch
patch -d /opt/dell -p1 < fix-chef-client-when-cluster-down.patch

# Scrap pointless 45 second tcpdump per interface
sed -i 's/45/1/' /opt/dell/chef/cookbooks/ohai/files/default/plugins/crowbar.rb

# Create the directory for shared glance storage
mkdir -p /var/lib/glance

# Create the NFS export for shared storage for HA PostgreSQL and RabbitMQ
mkdir -p /nfs/{postgresql,rabbitmq}
echo '/nfs <%= @admin_subnet %>/<%= @admin_netmask %>(rw,async,no_root_squash,no_subtree_check)' >> /opt/dell/chef/cookbooks/nfs-server/templates/default/exports.erb

# Bypass the provisioner's check for HAE repos, since we're already
# providing these via the special SUSE-CLOUD-SLE11-SP3-DEPS installation media
# in /srv/tftpboot/suse-11.3/install
for repo in SLE11-HAE-SP3-{Pool,Updates}; do
    ln -s ../suse-11.3/install /srv/tftpboot/repos/$repo
done

# atftp required at build-time for oemboot/suse-SLES11 bug
# but conflicts with tftp crowbar wants
if rpm -q --quiet atftp; then
    echo "Deinstalling atftp ..."
    zypper -n rm atftp
fi