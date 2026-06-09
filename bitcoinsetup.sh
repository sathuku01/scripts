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

