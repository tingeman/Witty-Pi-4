[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#!/bin/bash
# file: install.sh
#
# This script will install required software for Witty Pi.
# It is recommended to run it in your home directory.
#
# 2022-08 Thomas Ingeman-Nielsen, thin@dtu.dk
#             Updated download URL to forked repository
#             By default do not install UWI

# check if sudo is used
if [ "$(id -u)" != 0 ]; then
  echo 'Sorry, you need to run this script with sudo'
  exit 1
fi


# This install script may be sourced from other install scripts.
# In the parent script, set WITTYPI_USE_GLOBAL_SETTINGS=true to
# by pass definitions below.
if [[ -z $WITTYPI_USE_GLOBAL_SETTINGS || $WITTYPI_USE_GLOBAL_SETTINGS -ne true ]]; then

  echo "THIS SCRIPT MUST BE CALLED FROM THE dtu-ert-pi INSTALL SCRIPT... ABORTING."
  exit 1

  CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  WITTYPI_DIR="$CURRENT_DIR"/wittypi
  TMP_DIR="$CURRENT_DIR"/tmp

  WITTYPI_DOWNLOAD_URL="https://github.com/tingeman/Witty-Pi-4/archive/refs/heads/main.zip"
  # To install UUGEAR latest version instead, uncomment the following line:
  # WITTYPI_DOWNLOAD_URL="https://www.uugear.com/repo/WittyPi4/LATEST"
  # NB will require also changes to the unpacking commands etc. ...

  # Set following line to 'true' to install UUGEAR Web Interface
  INSTALL_UWI=false
  #UWI_DOWNLOAD_URL="https://www.uugear.com/repo/UWI/installUWI.sh"
else
  echo ">>> Using globaly defined settings."
fi


# error counter
ERR_WPI=0


echo '================================================================================'
echo '|                                                                              |'
echo '|                   Witty Pi Software Installation Script                      |'
echo '|                                                                              |'
echo '================================================================================'

# enable I2C on Raspberry Pi
echo '>>> Enable I2C'
if grep -q 'i2c-bcm2708' /etc/modules; then
  echo 'Seems i2c-bcm2708 module already exists, skip this step.'
else
  echo 'i2c-bcm2708' >> /etc/modules
fi
if grep -q 'i2c-dev' /etc/modules; then
  echo 'Seems i2c-dev module already exists, skip this step.'
else
  echo 'i2c-dev' >> /etc/modules
fi

i2c1=$(grep 'dtparam=i2c1=on' /boot/config.txt)
i2c1=$(echo -e "$i2c1" | sed -e 's/^[[:space:]]*//')
if [[ -z "$i2c1" ]]; then
    # if line is missing, insert it at end of file
    echo 'dtparam=i2c1=on' >> /boot/config.txt
    echo "Inserted missing line:   dtparam=i2c1=on"
elif [[  "$match" == "#"* ]]; then
    # if line is commented, uncomment it
    sed -i "s/^\s*#\s*\(dtparam=i2c1=on.*\)/\1/" /boot/config.txt
    echo "Found commented line and uncommented:  dtparam=i2c1=on"
else
    # if line exists, do nothing
    echo 'Seems i2c1 parameter already set, skip this step.'
fi

i2c_arm=$(grep 'dtparam=i2c_arm=on' /boot/config.txt)
i2c_arm=$(echo -e "$i2c_arm" | sed -e 's/^[[:space:]]*//')
if [[ -z "$i2c_arm" ]]; then
    # if line is missing, insert it at end of file
    echo 'dtparam=i2c_arm=on' >> /boot/config.txt
    echo "Inserted missing line:   dtparam=i2c_arm=on"
elif [[  "$match" == "#"* ]]; then
    # if line is commented, uncomment it
    sed -i "s/^\s*#\s*\(dtparam=i2c_arm=on.*\)/\1/" /boot/config.txt
    echo "Found commented line and uncommented:  dtparam=i2c_arm=on"
else
    # if line exists, do nothing
    echo 'Seems i2c_arm parameter already set, skip this step.'
fi

miniuart=$(grep 'dtoverlay=pi3-miniuart-bt' /boot/config.txt)
miniuart=$(echo -e "$miniuart" | sed -e 's/^[[:space:]]*//')
if [[ -z "$miniuart" || "$miniuart" == "#"* ]]; then
  echo 'dtoverlay=pi3-miniuart-bt' >> /boot/config.txt
else
  echo 'Seems setting Pi3 Bluetooth to use mini-UART is done already, skip this step.'
fi

miniuart=$(grep 'dtoverlay=miniuart-bt' /boot/config.txt)
miniuart=$(echo -e "$miniuart" | sed -e 's/^[[:space:]]*//')
if [[ -z "$miniuart" || "$miniuart" == "#"* ]]; then
  echo 'dtoverlay=miniuart-bt' >> /boot/config.txt
else
  echo 'Seems setting Bluetooth to use mini-UART is done already, skip this step.'
fi

core_freq=$(grep 'core_freq=250' /boot/config.txt)
core_freq=$(echo -e "$core_freq" | sed -e 's/^[[:space:]]*//')
if [[ -z "$core_freq" || "$core_freq" == "#"* ]]; then
  echo 'core_freq=250' >> /boot/config.txt
else
  echo 'Seems the frequency of GPU processor core is set to 250MHz already, skip this step.'
fi

if [ -f /etc/modprobe.d/raspi-blacklist.conf ]; then
  sed -i 's/^blacklist spi-bcm2708/#blacklist spi-bcm2708/' /etc/modprobe.d/raspi-blacklist.conf
  sed -i 's/^blacklist i2c-bcm2708/#blacklist i2c-bcm2708/' /etc/modprobe.d/raspi-blacklist.conf
else
  echo 'File raspi-blacklist.conf does not exist, skip this step.'
fi

# install i2c-tools
echo '>>> Install i2c-tools'
if hash i2cget 2>/dev/null; then
  echo 'Seems i2c-tools is installed already, skip this step.'
else
  apt-get install -y i2c-tools || ((ERR_WPI++))
fi

# make sure en_GB.UTF-8 locale is installed
echo '>>> Make sure en_GB.UTF-8 locale is installed'
locale_commentout=$(sed -n 's/\(#\).*en_GB.UTF-8 UTF-8/1/p' /etc/locale.gen)
if [[ $locale_commentout -ne 1 ]]; then
  echo 'Seems en_GB.UTF-8 locale has been installed, skip this step.'
else
  sed -i.bak 's/^.*\(en_GB.UTF-8[[:blank:]]\+UTF-8\)/\1/' /etc/locale.gen
  locale-gen
fi

# install wittyPi
if [ $ERR_WPI -eq 0 ]; then
  echo '>>> Install wittypi'
  if [ -d "$WITTYPI_DIR" ]; then
    echo 'Seems wittypi is installed already, skip this step.'
  else
    if [[ ! -d "$TMP_DIR" ]]; then
      mkdir -p "$TMP_DIR"
    fi
    if [[ ! -d "$WITTYPI_DIR" ]]; then
      mkdir -p "$WITTYPI_DIR"
    fi
    #wget https://www.uugear.com/repo/WittyPi4/LATEST -O wittyPi.zip || ((ERR_WPI++))
    wget $WITTYPI_DOWNLOAD_URL -O "$TMP_DIR"/wittyPi.zip || ((ERR_WPI++))
    unzip -q "$TMP_DIR"/wittyPi.zip -d "$TMP_DIR"/ || ((ERR_WPI++))
    SRC_DIR="$TMP_DIR"/"Witty-Pi-4-"$(basename $WITTYPI_DOWNLOAD_URL .zip)
    cp -rf "$SRC_DIR"/Software/wittypi/* "$WITTYPI_DIR"/
    cd "$WITTYPI_DIR"
    chmod +x wittyPi.sh
    chmod +x daemon.sh
    chmod +x runScript.sh
    chmod +x beforeScript.sh
    chmod +x afterStartup.sh
    chmod +x beforeShutdown.sh
    sed -e "s#/home/pi/wittypi#$WITTYPI_DIR#g" init.sh >/etc/init.d/wittypi
    chmod +x /etc/init.d/wittypi
    update-rc.d wittypi defaults || ((ERR_WPI++))
    touch "$WITTYPI_DIR"/wittyPi.log
    touch "$WITTYPI_DIR"/schedule.log
    cd "$CURRENT_DIR"
    chown -R $SUDO_USER:$(id -g -n $SUDO_USER) "$WITTYPI_DIR" || ((ERR_WPI++))
    sleep 2
    rm "$TMP_DIR"/wittyPi.zip
    rm -r "$SRC_DIR"
  fi
fi

if [[ -z $INSTALL_UWI || $INSTALL_UWI == true ]]; then
  # install UUGear Web Interface
  curl $UWI_DOWNLOAD_URL | bash
else
  echo 'Skipping installation of UWI...'
fi

echo

if [ $ERR_WPI -eq 0 ]; then
  echo '>>> All done. Please reboot your Pi :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
