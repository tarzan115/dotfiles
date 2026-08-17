#! /bin/bash

# installing tools
sudo dnf install foot starship gcc helix fzf cmake jetbrainsmono-nerd-fonts bash-language-server carapace fastfetch -y

## zed
curl -f https://zed.dev/install.sh | sh

## brave
curl -fsS https://dl.brave.com/install.sh | sh

## rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

## kanata
cargo install cargo-binstall kanata topgrade cargo-update nu zoxide ripgrep bat cargo-expand fd-find yazi-fm

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
cp ./starship/starship.toml ~/.config/

## config foot
cp -r ./mango-config/foot ~/.config/
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

## zoxide config
zoxide init nushell | save -f ~/.zoxide.nu

## git delta (diff)
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global merge.conflictStyle zdiff3
git config --global delta.line-numbers true
git config --global delta.side-by-side true






### manual packages
echo -e "manual packages:\n\t* carapace: for autocomplete"
