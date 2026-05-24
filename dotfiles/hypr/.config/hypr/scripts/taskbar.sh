#!/bin/bash
# DimArch taskbar — window list for current workspace

WORKSPACE=$(hyprctl activeworkspace -j | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
ACTIVE=$(hyprctl activewindow -j | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('address',''))" 2>/dev/null)

hyprctl clients -j | python3 -c "
import sys, json
clients = json.load(sys.stdin)
ws = $WORKSPACE
active = '$ACTIVE'
parts = []
for c in clients:
    if c['workspace']['id'] == ws and c['title'] != '' and c['mapped']:
        dot = '●' if c['address'] == active else '·'
        title = c['title'][:25]
        parts.append(f'{dot} {title}')
text = '   '.join(parts) if parts else ''
print(json.dumps({'text': text, 'class': 'taskbar'}))
"
