#!/bin/sh

fail() {
    notify-send -a Lumen "Screenshot failed" "$1"
    exit 1
}

case "$1" in
    screen)
        [ -n "$2" ] || fail "Could not identify the screen."
        set -- -o "$2"
        ;;
    window)
        monitors=$(hyprctl monitors -j) && clients=$(hyprctl clients -j) \
            || fail "Could not list open windows."
        windows=$(printf '%s\n' "$clients" | jq -r --argjson monitors "$monitors" '
            [$monitors[] | .activeWorkspace.id, (.specialWorkspace.id | select(. != 0))] as $workspaces
            | map(select(.mapped and .visible and (.hidden | not) and .stableId
                         and .size[0] > 0 and .size[1] > 0))
            | map(select(.pinned or (.workspace.id as $id | $workspaces | index($id) != null)))
            | sort_by(.focusHistoryID)[]
            | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.stableId)"
        ') || fail "Could not list open windows."
        [ -n "$windows" ] || fail "No windows on the visible workspaces."
        window=$(printf '%s\n' "$windows" | slurp -r -f '%l') || exit 0
        [ -n "$window" ] || exit 0
        set -- -T "$window"
        ;;
    area)
        # Slurp needs EOF on stdin before it opens the region selector.
        region=$(slurp -d </dev/null) || exit 0
        [ -n "$region" ] || exit 0
        set -- -g "$region"
        ;;
    *)
        fail "Unknown capture mode."
        ;;
esac

pictures=$(xdg-user-dir PICTURES 2>/dev/null)
directory="${pictures:-$HOME/Pictures}/Screenshots"
file="$directory/Screenshot-$(date +%Y-%m-%d_%H-%M-%S-%N).png"
mkdir -p "$directory" && grim "$@" "$file" || fail "Could not save the screenshot."

if wl-copy --type image/png < "$file"; then
    notify-send -a Lumen "Screenshot saved and copied" "$file"
else
    notify-send -a Lumen "Screenshot saved" "$file"
fi
