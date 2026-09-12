import json
import subprocess
import sys

targets = [arg.strip().lower() for arg in sys.argv[1:] if arg.strip()]
if not targets:
    targets = ["spotify"]

try:
    res = subprocess.run(["niri", "msg", "--json", "windows"], capture_output=True, text=True, timeout=2)
    if res.returncode == 0 and res.stdout.strip():
        windows = json.loads(res.stdout)
        for t in targets:
            for w in windows:
                app_id = (w.get("app_id") or "").lower()
                title = (w.get("title") or "").lower()
                if t in app_id or t in title:
                    subprocess.run(["niri", "msg", "action", "focus-window", "--id", str(w["id"])])
                    sys.exit(0)
        for w in windows:
            app_id = (w.get("app_id") or "").lower()
            if any(k in app_id for k in ["spotify", "music", "firefox", "brave", "chromium", "vlc", "mpv"]):
                subprocess.run(["niri", "msg", "action", "focus-window", "--id", str(w["id"])])
                sys.exit(0)
except Exception:
    pass

try:
    res = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, timeout=2)
    if res.returncode == 0 and res.stdout.strip():
        clients = json.loads(res.stdout)
        for t in targets:
            for c in clients:
                cls = (c.get("class") or "").lower()
                title = (c.get("title") or "").lower()
                if t in cls or t in title:
                    subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{c['address']}"])
                    sys.exit(0)
except Exception:
    pass
