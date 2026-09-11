import sys
import subprocess
import json

def get_status():
    powered = False
    try:
        p_show = subprocess.run(["bluetoothctl", "show"], capture_output=True, text=True, timeout=2)
        powered = "Powered: yes" in p_show.stdout
    except Exception:
        pass

    devices = []
    if powered:
        try:
            p_dev = subprocess.run(["bluetoothctl", "devices"], capture_output=True, text=True, timeout=2)
            for line in p_dev.stdout.strip().split("\n"):
                parts = line.split(" ", 2)
                if len(parts) >= 3 and parts[0] == "Device":
                    mac = parts[1]
                    name = parts[2]
                    info_out = ""
                    try:
                        p_info = subprocess.run(["bluetoothctl", "info", mac], capture_output=True, text=True, timeout=1)
                        info_out = p_info.stdout
                    except Exception:
                        pass

                    connected = "Connected: yes" in info_out
                    paired = "Paired: yes" in info_out
                    battery = -1
                    for iline in info_out.split("\n"):
                        if "Battery Percentage:" in iline:
                            try:
                                battery = int(iline.split("(")[1].split(")")[0])
                            except Exception:
                                pass

                    is_mac_name = len(name) == 17 and (name.count("-") == 5 or name.count(":") == 5)
                    if is_mac_name and not paired:
                        continue

                    icon = "bluetooth"
                    icon_val = ""
                    for iline in info_out.split("\n"):
                        if iline.strip().startswith("Icon:"):
                            icon_val = iline.split(":", 1)[1].strip().lower()

                    if icon_val == "phone":
                        icon = "smartphone"
                    elif any(k in icon_val for k in ["headset", "audio"]):
                        icon = "headphones"
                    elif "keyboard" in icon_val:
                        icon = "keyboard"
                    elif "mouse" in icon_val:
                        icon = "mouse"
                    else:
                        name_lower = name.lower()
                        if any(k in name_lower for k in ["buds", "earphone", "pods", "headphone", "headset"]):
                            icon = "headphones"
                        elif any(k in name_lower for k in ["galaxy", "iphone", "pixel", "phone"]):
                            icon = "smartphone"
                        elif "keyboard" in name_lower:
                            icon = "keyboard"
                        elif "mouse" in name_lower:
                            icon = "mouse"

                    devices.append({
                        "mac": mac,
                        "name": name,
                        "connected": connected,
                        "paired": paired,
                        "battery": battery,
                        "icon": icon
                    })
        except Exception:
            pass

    devices.sort(key=lambda d: (not d["connected"], not d["paired"], d["name"].lower()))
    return {"powered": powered, "devices": devices}

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "status"

    if action == "status":
        print(json.dumps(get_status()))
    elif action == "toggle":
        st = get_status()
        new_power = "off" if st["powered"] else "on"
        subprocess.run(["bluetoothctl", "power", new_power], capture_output=True)
        print(json.dumps(get_status()))
    elif action == "connect" and len(sys.argv) > 2:
        subprocess.run(["bluetoothctl", "connect", sys.argv[2]], capture_output=True)
    elif action == "disconnect" and len(sys.argv) > 2:
        subprocess.run(["bluetoothctl", "disconnect", sys.argv[2]], capture_output=True)
    elif action == "scan":
        subprocess.run(["bluetoothctl", "--timeout", "4", "scan", "on"], capture_output=True)
        print(json.dumps(get_status()))
