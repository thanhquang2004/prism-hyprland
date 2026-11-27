#!/usr/bin/env bash
# Install the Prism SDDM theme and make it current.
#   install.sh            install + activate
#   install.sh --revert   go back to the theme that was active before
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")
conf=/etc/sddm.conf
backup=/etc/sddm.conf.bak-prism

if [[ ${1:-} == --revert ]]; then
    sudo cp "$backup" "$conf"
    echo "Restored $conf from $backup"
    exit 0
fi

[[ -f $backup ]] || sudo cp "$conf" "$backup"
sudo rm -rf /usr/share/sddm/themes/prism
sudo cp -r "$here/prism" /usr/share/sddm/themes/prism
sudo chmod -R a+rX /usr/share/sddm/themes/prism
if grep -q '^Current=' "$conf"; then
    sudo sed -i 's/^Current=.*/Current=prism/' "$conf"
else
    printf '\n[Theme]\nCurrent=prism\n' | sudo tee -a "$conf" >/dev/null
fi
echo "Prism SDDM theme installed and active (backup of the old config: $backup)"
