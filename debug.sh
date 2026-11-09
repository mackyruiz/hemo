#!/bin/bash
godot --path . -- --unlock-all

# debug web
godot --headless --export-debug "Web Debug" build/web-debug/index.html && python3 -m http.server 8061 -d build/web-debug

# prod web
godot --headless --export-release "Web" build/web/index.html && python3 -m http.server 8060 -d build/web
