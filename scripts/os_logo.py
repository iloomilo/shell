import glob
import json
import os
import platform

CANDIDATE_SUBPATHS = (
    "{d}/{n}.svg",
    "{d}/{n}.png",
    "{d}/hicolor/scalable/apps/{n}.svg",
    "{d}/hicolor/256x256/apps/{n}.png",
    "{d}/hicolor/128x128/apps/{n}.png",
    "{d}/hicolor/64x64/apps/{n}.png",
)


def read_os_release():
    data = {}
    for path in ("/etc/os-release", "/usr/lib/os-release"):
        if not os.path.isfile(path):
            continue
        try:
            with open(path) as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    key, value = line.split("=", 1)
                    data[key] = value.strip().strip('"').strip("'")
            break
        except OSError:
            continue
    return data


def icon_dirs():
    dirs = []
    data_home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    data_dirs = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
    for base in [data_home] + data_dirs.split(":"):
        base = base.strip()
        if not base:
            continue
        for sub in ("icons", "pixmaps"):
            path = os.path.join(base, sub)
            if os.path.isdir(path) and path not in dirs:
                dirs.append(path)
    return dirs


def find_logo(names):
    dirs = icon_dirs()
    for name in names:
        if not name:
            continue
        for directory in dirs:
            for pattern in CANDIDATE_SUBPATHS:
                path = pattern.format(d=directory, n=name)
                if os.path.isfile(path):
                    return path
            for path in sorted(glob.glob("{d}/*/scalable/*/{n}.svg".format(d=directory, n=name))):
                if os.path.isfile(path):
                    return path
    return ""


release = read_os_release()

names = []
for key in ("LOGO", "ID"):
    value = release.get(key)
    if value and value not in names:
        names.append(value)
for value in (release.get("ID_LIKE") or "").split():
    if value not in names:
        names.append(value)
for value in ("distributor-logo", "start-here", "linux"):
    if value not in names:
        names.append(value)

print(json.dumps({
    "name": release.get("NAME") or release.get("PRETTY_NAME") or platform.system() or "Linux",
    "prettyName": release.get("PRETTY_NAME") or release.get("NAME") or platform.system() or "Linux",
    "id": release.get("ID") or "",
    "logo": find_logo(names),
    "kernel": platform.release(),
}))
