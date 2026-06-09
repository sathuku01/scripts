username=$(whoami)   

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install apt-get install -y build-essential cmake pkgconf python3 \
libevent-dev libboost-dev libsqlite3-dev git

cd /home/username/Desktop
git clone https://github.com/bitcoin/bitcoin.git
mkdir build && cd build
cmake -S . -B build -DENABLE_IPC=OFF   
cd ..
cmake --build build -j $(nproc)


# Define the directory and file path
BITCOIN_DIR="$HOME/.bitcoin"
CONF_FILE="$BITCOIN_DIR/bitcoin.conf"

# Create the directory if it doesn't exist
if [ ! -d "$BITCOIN_DIR" ]; then
    mkdir -p "$BITCOIN_DIR"
    echo "Created directory: $BITCOIN_DIR"
fi

# Write the configuration content to the file
# Using 'cat' with a heredoc to handle multi-line input cleanly
cat > "$CONF_FILE" <<EOF
regtest=1

[regtest]
server=1
daemon=1
rpcallowip=127.0.0.1
rpcbind=127.0.0.1
txindex=1
#set fallback fee for regtest
fallbackfee=0.0001
EOF

chmod 600 "$CONF_FILE"
echo "Configuration written to: $CONF_FILE"   
