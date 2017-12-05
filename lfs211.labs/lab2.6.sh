#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    sudo apt -y install stress-ng
fi

if [[ $OS == $OS_REDHAT ]]; then
    sudo yum install -y vsftpd ftp
fi

# test is foo service file is available
if [[ -f '/usr/lib/systemd/system/foo.service' ]]; then
    rm -f '/usr/lib/systemd/system/foo.service'
fi

# create foo.service file
cat >> '/usr/lib/systemd/system/foo.service' << EOF
[Unit]
Description=Example service to run stress
[Service]
ExecStart=/usr/bin/stress --cpu 4 --io 4 --vm 2 --vm-bytes 1G
[Install]
WantedBy=multi-user.target
EOF

# verify file
cat '/usr/lib/systemd/system/foo.service'

# start service
systemctl start foo
systemctl status foo -l
systemd-delta
systemctl stop foo

# create another foo.service in /etc if not there
if [[ -f '/etc/systemd/system/foo.service' ]]; then
    rm -f '/etc/systemd/system/foo.service'
fi
cat >> '/etc/systemd/system/foo.service' << EOF
[Unit]
Description=Example service to run stress
[Service]
ExecStart=/usr/bin/stress --cpu 2 --io 2 --vm 4 --vm-bytes 1G
[Install]
WantedBy=multi-user.target
EOF

# start service
systemctl start foo
systemctl status foo -l
systemd-delta
systemctl stop foo

# create drop-in directory
mkdir -p '/etc/systemd/system/foo.service.d/'
# create another foo.service in /etc if not there
if [[ -f '/etc/systemd/system/foo.service.d/foo.service' ]]; then
    rm -f '/etc/systemd/system/foo.service.d/foo.service'
fi
cat >> '/etc/systemd/system/foo.service.d/foo.service' << EOF
[Unit]
Description=Example service to run stress
[Service]
ExecStart=/usr/bin/stress --cpu 2 --io 2 --vm 4 --vm-bytes 1G
[Install]
WantedBy=multi-user.target
EOF

# add cgroup slice
cat >> '/etc/systemd/system/foo.slice' << EOF
[Unit]
Description=stress slice
[Slice]
CPUQuota=30%
EOF

# add slice to drop-in
echo 'Slice=foo.slice' >> '/etc/systemd/system/foo.service.d/foo.service'

# reload and see difference
systemctl daemon-reload
systemctl status foo -l
systemd-delta
top


