# Theme, completion, and prompt setup. Sourced from my.nu (see there for the
# overall load order). Files here are resolved relative to this file's dir.

# source ./cobalt-neon.nu   # alternate theme; swap with cobalt2 below
source ./cobalt2.nu
source $"($nu.cache-dir)/carapace.nu"

source ~/.config/starship.nu
