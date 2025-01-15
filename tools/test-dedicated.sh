# Compile and copy files
./qc-compiler-gnu.sh
cp ../build/fte/* ~/nzp-mac/nzp/
cp ../build/fte/* ~/nzp-dedi/nzp/

# Start the dedicated server
cd ~/nzp-dedi/
nohup wine nzportable64.exe -dedicated +map ndu +hostname dedi-test > dedi.log 2>&1 &
disown
sleep 5

# Start the first client
cd ~/nzp-mac/
nohup wine nzportable-sdl64.exe +vid_width 640 +vid_height 480 +name client_1 +connect localhost > client_0.log 2>&1 &
disown
sleep 3

# Start the second client
nohup wine nzportable-sdl64.exe +vid_width 640 +vid_height 480 +name client_2 +connect localhost > client_1.log 2>&1 &
disown
sleep 3

Start the third client
nohup wine nzportable-sdl64.exe +vid_width 640 +vid_height 480 +name client_3 +connect localhost > client_1.log 2>&1 &
disown
sleep 3

Start the fourth client
nohup wine nzportable-sdl64.exe +vid_width 640 +vid_height 480 +name client_4 +connect localhost > client_1.log 2>&1 &
disown
sleep 3