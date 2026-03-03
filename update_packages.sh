#!/bin/bash

echo
echo "Install packages. - Navid200"
echo

# Reduce the number of snapshots kept from the default 3 to 2 to reduce disk space usage.
sudo snap set system refresh.retain=2

# Let's upgrade packages if available and install the missing needed packages.
/xDrip/scripts/wait_4_completion.sh
sudo apt-get update

#Ubuntu upgrade available
NextUbuntu="$(apt-get -s upgrade | grep 'Inst base' | awk '{print $4}' | sed 's/(//')"
if [ "$NextUbuntu" = "13ubuntu10.4" ] # Only upgrade if we have tested the next release (24.04.4)
then
  sudo apt-get -y upgrade
fi

# packages
whichpack=$(which gpg)
if [ "$whichpack" = "" ]
then
  /xDrip/scripts/wait_4_completion.sh
  sudo apt-get -y install jq net-tools gnupg
  # The last item on the above list of packages must be verified in Status.sh to have been installed.
fi 


# mongo
mongover="$(mongod --version 2>/dev/null | sed -n 's/^db version v//p' | head -n1)"

if [ -z "$mongover" ] || dpkg --compare-versions "$mongover" lt "8.0.17"
then
  /xDrip/scripts/wait_4_completion.sh

  if [ ! -f /usr/share/keyrings/mongodb-server-8.0.gpg ]; then
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
  fi


  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
  /xDrip/scripts/wait_4_completion.sh
  sudo apt-get update

  # allow upgrade if packages were previously held
  sudo apt-mark unhold mongodb-org mongodb-org-database mongodb-org-server mongodb-mongosh mongodb-org-mongos mongodb-org-tools || true

  sudo apt-get install -y mongodb-org=8.0.17 mongodb-org-database=8.0.17 mongodb-org-server=8.0.17 mongodb-mongosh mongodb-org-mongos=8.0.17 mongodb-org-tools=8.0.17

  # re-hold to prevent unintended upgrades
  sudo apt-mark hold mongodb-org mongodb-org-database mongodb-org-server mongodb-mongosh mongodb-org-mongos mongodb-org-tools

  /xDrip/scripts/wait_4_completion.sh
  sudo systemctl enable mongod
  sudo systemctl start mongod
fi


# node - Install Node 22.22.0
NODE_VERSION="22.22.0"
NODE_URL="https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz"
NODE_INSTALL_DIR="/usr/local/node-$NODE_VERSION"

check_node_candidate() {
    node -v 2>/dev/null
}

is_node22() {
    echo "$1" | grep -q '^v22\.22\.0'
}

install_node22() {
    candidate=$(check_node_candidate)
    if is_node22 "$candidate"; then
        echo "Node $NODE_VERSION is already installed, skipping."
        return
    fi

    echo "Installing Node $NODE_VERSION..."
    sudo rm -rf "$NODE_INSTALL_DIR"
    curl -fsSL "$NODE_URL" -o "/tmp/node-v$NODE_VERSION.tar.xz"
    sudo mkdir -p "$NODE_INSTALL_DIR"
    sudo tar -xf "/tmp/node-v$NODE_VERSION.tar.xz" -C "$NODE_INSTALL_DIR" --strip-components=1
    rm "/tmp/node-v$NODE_VERSION.tar.xz"

    export PATH="$NODE_INSTALL_DIR/bin:$PATH"
    sudo ln -sf "$NODE_INSTALL_DIR/bin/node" /usr/local/bin/node
    sudo ln -sf "$NODE_INSTALL_DIR/bin/npm" /usr/local/bin/npm
    sudo ln -sf "$NODE_INSTALL_DIR/bin/npx" /usr/local/bin/npx

    # Log after successful installation
    /xDrip/scripts/AddLog.sh "Node $NODE_VERSION installed successfully" /xDrip/Logs
}

whichpack=$(check_node_candidate)
if [ -z "$whichpack" ] || ! is_node22 "$whichpack"; then
    /xDrip/scripts/wait_4_completion.sh
    install_node22
fi
  
