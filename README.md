# vagrant-opflexdev

## Vagrant Environment for Opflex Development

**To bring up a standalone Opflex dev environment**

cd ubuntu-bionic64/
vagrant up
vagrant ssh

**The above commands bring up all the components
required for opflex development
Additionally the latest opflex tree is built
and checked out in /home/vagrant/work/opflex.
A sample policy and config is located under
data/sample-policy
To setup the bridges for this sample run**

/home/vagrant/data/sample-policy/setup.sh

**To start mock server run**

/usr/bin/run_mock.sh

**From another window start opflex_agent**

/usr/bin/run_opflex.sh
