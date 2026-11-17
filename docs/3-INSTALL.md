# 3 · Install FocusWave on her laptop

## Before you start — really important

1. **Back up her files.** Copy Documents, Pictures, Desktop, Downloads and anything else she cares about to an external drive or the cloud. Installing can erase the disk.
2. **Check that she's not losing an app she needs.** Windows programs don't run on Linux. Common gaps: Microsoft Office desktop apps (the web versions work), Adobe Photoshop/Premiere, some games with anti‑cheat, and iTunes. Look up her must‑haves first, or keep Windows next to FocusWave (dual boot, below).
3. **Find the Windows BitLocker recovery key** if you might keep Windows. Most new laptops encrypt the disk automatically. Get the key at <https://account.microsoft.com/devices/recoverykey> (her Microsoft account), or in Windows search for "Manage BitLocker" → *Back up your recovery key*.
4. Plug in the charger.

## Choose: replace Windows, or keep both?

| | Replace Windows | Keep both (dual boot) |
|---|---|---|
| Disk space for FocusWave | all ~932 GB | what you give it, e.g. 300–500 GB |
| Simplicity | simplest | a menu at startup lets her choose |
| Risk | Windows is gone | low, if you follow the steps |

### If you keep Windows: make room first, in Windows

1. In Windows, right‑click **Start → Disk Management**.
2. Right‑click the big **C:** partition → **Shrink Volume** → enter the amount to free, e.g. `400000` MB for ~400 GB → **Shrink**.
3. Leave the new space as **Unallocated**.
4. If BitLocker is on, it's easiest to **suspend** it first: search "Manage BitLocker" → *Suspend protection*.

## Install

1. Boot the FocusWave USB stick (see [2-TEST-IT.md](2-TEST-IT.md)) → **Start FocusWave**.
2. On the desktop, open **Install to Hard Drive**. It's on the desktop, or search for it in the Start menu.
3. Pick the **language** and **keyboard**. Add Hebrew as a second keyboard layout if she types in Hebrew; you can also do that later in Settings.
4. **Installation destination**: pick the laptop's internal SSD (≈ 932 GB).
   - **Replace Windows:** choose to use / reclaim the **entire disk** and confirm deleting the old partitions.
   - **Keep Windows:** choose **use free space**, which uses the unallocated space you made, and **don't** delete the Windows partitions.
   - Encryption: optional. If you turn it on, she types a password at every boot. It's a good idea on a laptop that leaves the house.
5. Start the installation. It takes ~5–10 minutes. Then **restart** and remove the USB stick when told.

## First start

1. Fedora's setup screens ask for her **name, username and password**, time zone and so on.
2. She logs in, and the **FocusWave welcome tour** opens: light/dark → favorite color → wallpaper → layout → window buttons → Focus Mode → done. Every choice applies live behind the window.
3. Open **Discover** (the shopping‑bag icon) → **Updates** and install any updates once.

That's it. Give her [USER-GUIDE.md](USER-GUIDE.md) (or just show her Meta+F and the Customize app).

## Keeping it up to date

- **Fedora and app updates** come through Discover as usual. Plasma tells you when updates are ready.
- **FocusWave's own packages** were built by you, so they don't update automatically. After a big Plasma update (for example 6.7 → 6.8), rebuild the RPMs (`bash ./build/build-rpms.sh` on Fedora, or the GitHub workflow's *FocusWave-RPMs* artifact) and install them with `sudo dnf install ./focuswave-*.rpm`. If the traffic‑light plugin ever stops matching Plasma, windows fall back to Breeze buttons, so nothing breaks.
- **Next Fedora release (46):** Discover offers the upgrade. FocusWave carries over.

## Undo / uninstall

- To remove FocusWave but keep Fedora KDE, open a terminal (Konsole) in the project folder and run:
  ```bash
  bash ./setup/focuswave-setup.sh uninstall
  ```
  This removes the packages and restores the settings backup made at install time, or falls back to stock Breeze.
- To go back to Windows only, reinstall Windows from Microsoft's media creation tool, or, with dual boot, delete the Fedora partitions from Windows Disk Management and run `bcdedit` to remove the boot entry.
