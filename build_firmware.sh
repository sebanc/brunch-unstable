#!/bin/bash

if ( ! test -z {,} ); then echo "Must be ran with \"sudo bash\""; exit 1; fi
if [ $(whoami) != "root" ]; then echo "Please run with sudo"; exit 1; fi

cwd="$(pwd)"

download_sof()
{
    #url="$(curl -s https://api.github.com/repos/thesofproject/sof-bin/releases/latest \
#        | grep tarball_url \
#        | sed 's/  "tarball_url": "//g' | sed "s/\",//g")"
    local page="https://arch.mirror.kescher.at/extra/os/x86_64/"
    local file=""

    file="$(curl -s $page | grep sof-firmware |  cut -d '"' -f4 | gre -v sig)"

    wget -O "$1" "${page}""${file}"
}

download_alsa_conf()
{
    curl -L -o "$1" https://github.com/alsa-project/alsa-ucm-conf/archive/refs/heads/master.tar.gz
}

if [ -d ./firmware ]; then rm -r ./firmware; fi
if [ -d ./final ]; then rm -r ./final; fi

mkdir final

git clone --depth=1 -b main https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git || { echo "Failed to clone the linux firmware git"; exit 1; }
cd ./linux-firmware || { echo "Failed to enter the linux firmware directory"; exit 1; }
make -j"$NTHREADS" DESTDIR=./tmp ZSTD_CLEVEL=19 FIRMWAREDIR=/lib/firmware install-zst || { echo "Failed to install firmwares in temporary directory"; exit 1; }
mv ./tmp/lib/firmware ./out || { echo "Failed to move the firmwares temporary directory"; exit 1; }
rm -rf ./out/bnx2x*
rm -rf ./out/dpaa2*
rm -rf ./out/liquidio*
rm -rf ./out/mellanox*
rm -rf ./out/mrvl/prestera*
rm -rf ./out/netronome*
rm -rf ./out/qcom*
rm -rf ./out/qed*
rm -rf ./out/ti-connectivity*
curl -L https://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git/plain/regulatory.db -o ./out/regulatory.db || { echo "Failed to download the regulatory db"; exit 1; }
curl -L https://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git/plain/regulatory.db.p7s -o ./out/regulatory.db.p7s || { echo "Failed to download the regulatory db"; exit 1; }
curl -L https://archlinux.org/packages/core/any/amd-ucode/download/ -o /tmp/amd-ucode.tar.zst || { echo "Failed to download amd ucode"; exit 1; }
tar -C ./out -xf /tmp/amd-ucode.tar.zst boot/amd-ucode.img --strip 1 || { echo "Failed to extract amd ucode"; exit 1; }
rm /tmp/amd-ucode.tar.zst || { echo "Failed to cleanup amd ucode"; exit 1; }
curl -L https://archlinux.org/packages/extra/any/intel-ucode/download/ -o /tmp/intel-ucode.tar.zst || { echo "Failed to download intel ucode"; exit 1; }
tar -C ./out -xf /tmp/intel-ucode.tar.zst boot/intel-ucode.img --strip 1 || { echo "Failed to extract intel ucode"; exit 1; }
rm /tmp/intel-ucode.tar.zst || { echo "Failed to cleanup intel ucode"; exit 1; }
mkdir -p ${cwd}/final/lib
mv ./out ${cwd}/final/lib/firmware
cd ${cwd}


#for sof firmware
download_sof ./sof.tar.zst
mkdir sof
tar -xvf ./sof.tar.zst -C sof
cp -r sof/usr/lib/firmware/* ${cwd}/final/lib/firmware

#for alsa conf
mkdir -p ./final/usr/share/alsa
download_alsa_conf alsa-ucm-conf.tar.gz
tar xvzf alsa-ucm-conf.tar.gz -C ./final/usr/share/alsa --strip-components=1 --wildcards "*/ucm" "*/ucm2"

# compress all firmwares and ucm conf
tar --owner=0 --group=0 -C final -zcvf /tmp/firmware.tar.gz ./
rm -r ./linux-firmware || { echo "Failed to cleanup firmwares directory"; exit 1; }
