#!/usr/bin/env python3

import os

flavor = os.environ.get('FLAVOR', 'dev')
flavored_name = os.environ.get('FLAVORED_NAME', 'NESd dev')

format = "UDZO"

files = [(f'build/macos/Build/Products/Release-{flavor}/NESd.app', f'{flavored_name}.app')]

symlinks = { 'Applications': '/Applications' }

badge_icon = f'build/macos/Build/Products/Release-{flavor}/NESd.app/Contents/Resources/AppIcon.icns'

icon_locations = {
    f'{flavored_name}.app': (150, 350),
    'Applications': (350, 350),
}

background = 'ci/1-build/macos/background.tiff'

window_rect = ((200, 200), (512, 568))
