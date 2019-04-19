#!/bin/bash

apt-get update
apt-get install -y g++ build-essential libboost-all-dev cscope bison cmake flex linux-tools-$(uname -r) linux-tools-generic autoconf libssl-dev openssl python-six maven doxygen

echo "LD_LIBRARY_PATH=/usr/local/lib" >> /etc/environment

cat <<EOF > /usr/bin/swap.sh
#!/bin/sh

# size of swapfile in megabytes
swapsize=16384

# does the swap file already exist?
grep -q "swapfile" /etc/fstab

# if not then create it
if [ \$? -ne 0 ]; then
        echo 'swapfile not found. Adding swapfile.'
        fallocate -l \${swapsize}M /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap defaults 0 0' >> /etc/fstab
else
        echo 'swapfile found. No changes made.'
fi

# output results to terminal
cat /proc/swaps
cat /proc/meminfo | grep Swap
EOF

chmod 755 /usr/bin/swap.sh
/usr/bin/swap.sh

cat <<EOF > /usr/bin/boost.sh
#!/bin/bash
wget https://sourceforge.net/projects/boost/files/boost/1.58.0/boost_1_58_0.tar.gz
tar zxvf boost_1_58_0.tar.gz
pushd boost_1_58_0
./bootstrap.sh --prefix=/usr/local/boost_1_58_0
./b2 cxxflags=-fPIC cflags=-fPIC -a
./b2 install --prefix=/usr/local/boost_1_58_0
popd
rm -Rf boost_1_58_0
rm boost_1_58_0.tar.gz
EOF

cat <<EOF > /usr/bin/libuv.sh
#!/bin/bash
git clone https://github.com/libuv/libuv.git --branch v1.x
pushd libuv
./autogen.sh
./configure
make -j8
sudo make install
popd
rm -Rf libuv
EOF

cat <<EOF > /usr/bin/rapidjson.sh
#!/bin/bash
git clone https://github.com/miloyip/rapidjson.git --branch v1.0.2 --depth 1
pushd rapidjson
cmake .
make
sudo make install
popd
rm -Rf rapidjson
EOF

cat <<EOF > /usr/bin/ovs.sh
#!/bin/bash
git clone https://github.com/openvswitch/ovs.git --branch v2.6.0 --depth 1
pushd ovs
ROOT=/usr/local
./boot.sh
./configure --prefix=\$ROOT --enable-shared
make -j4
sudo rm -rf \$ROOT/include/openvswitch
sudo make install
# OVS headers get installed to weird and inconsistent locations.  Try
# to clean things up
sudo mkdir -p \$ROOT/include/openvswitch/openvswitch
sudo mv \$ROOT/include/openvswitch/*.h \$ROOT/include/openvswitch/openvswitch
sudo mv \$ROOT/include/openflow \$ROOT/include/openvswitch
sudo cp -t "\$ROOT/include/openvswitch/" include/*.h
sudo find lib -name "*.h" -exec cp --parents -t "\$ROOT/include/openvswitch/" {} \;
popd
rm -Rf ovs
EOF

chmod 755 /usr/bin/boost.sh
/usr/bin/boost.sh
chmod 755 /usr/bin/libuv.sh
/usr/bin/libuv.sh
chmod 755 /usr/bin/rapidjson.sh
/usr/bin/rapidjson.sh
chmod 755 /usr/bin/ovs.sh
/usr/bin/ovs.sh

cat <<EOF > /usr/bin/opflex.sh
#!/bin/bash

set -x
if [ -z "\$1" ]; then
   echo "Doing Dynamic build"
elif [ \$1 == "static" ]; then
    echo "Doing Static build"
    BUILDOPTS="--with-static-boost --with-boost=/usr/local/boost_1_58_0"
fi

sudo rm /usr/local/lib/libmodelgbp*
sudo rm /usr/local/lib/libopflex*
sudo rm /usr/local/bin/opflex_agent
sudo rm /usr/local/bin/gbp_inspect
sudo rm /usr/local/bin/mcast_daemon
sudo rm /usr/local/bin/mock_server

pushd libopflex
make clean
./autogen.sh
CXXFLAGS="-g -O0" CFLAGS="-g -O0" CCASFLAGS="-g -O0" ./configure \$BUILDOPTS
make -j4
sudo make install
popd

pushd genie
mvn compile exec:java
popd

pushd genie/target/libmodelgbp
make clean
bash autogen.sh
CXXFLAGS="-g -O0" CFLAGS="-g -O0" CCASFLAGS="-g -O0" ./configure
make -j4
sudo make install
popd

pushd agent-ovs
make clean
./autogen.sh
CXXFLAGS="-g -O0" CFLAGS="-g -O0" CCASFLAGS="-g -O0" ./configure \$BUILDOPTS
make -j4
sudo make install
popd

pushd agent-ovs
make check
popd
EOF

chmod 755 /usr/bin/opflex.sh

mkdir -p /home/vagrant/work
cd /home/vagrant/work
rm -Rf *
git clone https://github.com/noironetworks/opflex.git
pushd opflex
/usr/bin/opflex.sh
popd

cat <<EOF > /usr/bin/run_mock.sh
#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
set -x
/usr/local/bin/mock_server --policy=/home/vagrant/data/sample-policy/policy.json --level=debug2
EOF

cat <<EOF > /usr/bin/run_opflex.sh
#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
set -x
opflex_agent -w -c /etc/opflex-agent-ovs/opflex-agent-ovs.conf -c /etc/opflex-agent-ovs/plugins.conf.d -c /etc/opflex-agent-ovs/conf.d
EOF

chmod 755 /usr/bin/run_mock.sh
chmod 755 /usr/bin/run_opflex.sh

rm -Rf /var/lib/opflex-agent-ovs
rm -Rf /etc/opflex-agent-ovs

cp -Rf /home/vagrant/data/sample-policy/var/lib/opflex-agent-ovs /var/lib
cp -Rf /home/vagrant/data/sample-policy/etc/opflex-agent-ovs /etc

export LD_LIBRARY_PATH=/usr/local/lib
/usr/local/share/openvswitch/scripts/ovs-ctl start
