# installing tools
sudo dnf copr enable scottames/ghostty atim/starship -y

sudo dnf install ghostty nu starship -y

## zed
curl -f https://zed.dev/install.sh | sh

#

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
