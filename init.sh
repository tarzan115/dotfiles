#! /bin/bash

# installing tools
sudo dnf copr enable scottames/ghostty atim/starship avengemedia/dms -y

sudo dnf install ghostty nu starship gcc dms -y

## zed
curl -f https://zed.dev/install.sh | sh

## rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

## kanata
cargo install cargo-binstall kanata

## mangowc
sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release -y
sudo dnf install mangowc -y

# finishing up
## set nu as default shell
echo $(which nu) | sudo tee -a /etc/shells
chsh -s $(which nu)

## first config for nushell
echo "source $HOME/workspace/dotfiles/nushell/my.nu" >> ~/.config/nushell/config.nu

## starship config for nushell
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
wget -P ~/.config https://raw.githubusercontent.com/thm-unix/thm-zshtheme/main/starship.toml

## config ghostty
echo "command = /usr/bin/nu" >> ~/.config/ghostty/config

# git config
git config --global user.email "doanhlv@duck.com"
git config --global user.name "Doanh Van Luong"

# kanata config
sudo groupdel uinput 2>/dev/null
sudo groupadd --system uinput
sudo usermod -aG input $USER
sudo usermod -aG uinput $USER

sudo tee /etc/udev/rules.d/99-input.rules > /dev/null <<EOF
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

sudo udevadm control --reload-rules && sudo udevadm trigger

mkdir -p ~/.config/kanata
cp ./caps/kanata/config.kbd ~/.config/kanata/
mkdir -p ~/.config/systemd/user
cp ./caps/kanata/kanata.service ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable kanata.service
systemctl --user start kanata.service
systemctl --user status kanata.service   # check whether the service is running

## dms config
systemctl --user enable --now dsearch
dms setup

## mango config
git clone -b dms git@github.com:tarzan115/mango-config.git ~/.config/mango
