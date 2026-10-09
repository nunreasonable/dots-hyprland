#!/usr/bin/env bash

get_pictures_dir() {
    if command -v xdg-user-dir &> /dev/null; then
        xdg-user-dir PICTURES
        return
    fi

    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"
    if [ -f "$config_file" ]; then
        local pictures_path
        pictures_path=$(source "$config_file" >/dev/null 2>&1; echo "$XDG_PICTURES_DIR")
        echo "${pictures_path/#\$HOME/$HOME}"
        return
    fi

    echo "$HOME/Pictures"
}

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
PICTURES_DIR=$(get_pictures_dir)
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$PICTURES_DIR/Wallpapers"
illogicalImpulseConfigPath="$HOME/.config/illogical-impulse/config.json"
userAgent=$(jq -r '.networking.userAgent // empty' "$illogicalImpulseConfigPath" 2>/dev/null)
configFlag() { [ "$(jq -r ".background.$1 // false" "$illogicalImpulseConfigPath" 2>/dev/null)" == "true" ]; }
tags=("width:>=1600" "height:>=900" "score:>=30")
site="https://konachan.net"
if configFlag konachanSpicy; then
    site="https://konachan.com"
else
    tags+=("rating:safe")
fi
configFlag konachanOnlyYuri && tags+=("yuri")
if configFlag konachanSpicy; then
    read -ra extraTags <<< "$(jq -r '.background.konachanExtraTags // empty' "$illogicalImpulseConfigPath" 2>/dev/null)"
    for tag in "${extraTags[@]}"; do
        [ ${#tags[@]} -ge 5 ] && break
        [[ "$tag" =~ ^(order|limit|page): ]] && continue
        tags+=("$tag")
    done
fi
tags+=("order:random")
response=$(curl -sG -A "$userAgent" "$site/post.json" -d limit=20 --data-urlencode "tags=${tags[*]}")
post=$(echo "$response" | jq -c '([.[] | select(.height > 0 and .width / .height >= 1.5 and .width / .height <= 2.4)][0]) // .[0] // empty')
link=$(echo "$post" | jq -r '.file_url // empty')
postId=$(echo "$post" | jq -r '.id // empty')
[ -z "$link" ] && { echo "Konachan returned no usable post" >&2; exit 1; }
ext=$(echo "$link" | awk -F. '{print $NF}')
downloadPath="$PICTURES_DIR/Wallpapers/konachan-$postId.$ext"
curl -sf -A "$userAgent" "$link" -o "$downloadPath.part" && mv "$downloadPath.part" "$downloadPath" \
    || { rm -f "$downloadPath.part"; echo "Download failed" >&2; exit 1; }
"$SCRIPT_DIR/../switchwall.sh" --image "$downloadPath"

currentWallpaperPath=$(jq -r '.background.wallpaperPath' "$illogicalImpulseConfigPath")
ls -1t "$PICTURES_DIR/Wallpapers"/konachan-* 2>/dev/null | grep -v '\.part$' | tail -n +11 | while read -r old; do
    [ "$old" != "$currentWallpaperPath" ] && rm -f "$old"
done
