# FocusWave

A sleek, simple and very customizable desktop OS for an Intel laptop: Fedora Linux 45 + KDE Plasma 6, redesigned to feel like a mix of Windows 11 and macOS. It also adds **Focus Mode**, which blurs everything except the window you're working in.

Tuned for: Intel Core i7‑1355U · 16 GB RAM · Intel Iris Xe graphics · 1 TB SSD.

## What you get

| | |
|---|---|
| **Look** | Slim macOS‑style top bar (app menu, Focus button, tray, clock) and a floating, translucent Windows‑11‑style dock with a Start menu. Rounded corners, glass blur, smooth animations, Inter font, Papirus icons. |
| **Light / Dark / Automatic** | Light by day and dark at night. FocusWave wallpapers have matching light and dark versions. |
| **Accent color** | 11 presets or any color you like. It colors highlights, buttons, switches and selections. |
| **Window buttons** | macOS traffic lights (red/yellow/green, on the left) or Windows‑style buttons on the right. |
| **Layouts** | *Mix* (default), *Mac‑like* (menu bar, Launchpad, Trash) or *Windows‑like* (one centered taskbar). Change dock size, position, floating, auto‑hide and transparency. |
| **Focus Mode** | Press **Meta+F** (the Windows key + F), click the Focus button in the top bar, or use the window's menu. Everything else gets a real GPU blur until you turn it off. You can set blur strength, background darkening, whether the dock stays visible, and the fade animation. |
| **Customize app** | One simple app with live previews. Save your looks as themes, then export and import them as `.fwtheme` files. *Advanced* opens the full KDE settings. |
| **Welcome tour** | The first time she logs in, she picks light/dark, a color, a wallpaper, a layout and button style, then tries Focus Mode. Each choice applies live. |
| **Fast & long battery life** | No splash screen, light file indexing, `thermald` for Intel CPUs, full Intel hardware video decoding (`intel-media-driver`), and full codecs from RPM Fusion. |
| **Web browser** | **Zen Browser**: a sleek, Arc‑style browser with vertical tabs, split view, workspaces and a compact mode. It's built on Firefox's engine, so it's light on memory and runs Firefox add‑ons. It follows light/dark mode and uses Iris Xe hardware video decoding. |
| **App store** | Discover with Flathub, so nothing day‑to‑day needs a terminal. |

## Get the ISO — pick one way

**A. No Linux needed (recommended): build it free on GitHub.** See [docs/1-BUILD-THE-ISO.md](docs/1-BUILD-THE-ISO.md). You upload this folder to a GitHub repository and press **Run workflow**. About an hour later you download `FocusWave-45-x86_64.iso`.

**B. On any Fedora computer or VM:**
```bash
sudo bash ./build/build-iso.sh            # ISO ends up in ./output/
```
On other Linux distributions with podman or docker: `bash ./build/build-in-container.sh`

**C. Already have Fedora KDE installed?** Skip the ISO:
```bash
bash ./setup/focuswave-setup.sh install --codecs     # undo any time: bash ./setup/focuswave-setup.sh uninstall
```

Then: **[test it](docs/2-TEST-IT.md)** in a virtual machine or from a USB stick → **[install it](docs/3-INSTALL.md)** → give her the **[user guide](docs/USER-GUIDE.md)**.

> **Honest note:** this was written without access to a Fedora 45 machine, so nothing has been built or booted yet. If the first build stops with an error, the `FocusWave-build-logs` download (or the `output/logs` folder) shows the error to fix. Test in a VM or from USB before installing over Windows.

## Project layout

```
focuswave/
├── README.md                     ← you are here
├── docs/                         build, test, install, user guide, how it works
├── .github/workflows/build-iso.yml   one-click ISO build on GitHub
├── build/
│   ├── build-iso.sh              Fedora → ISO (livemedia-creator)
│   ├── build-in-container.sh     same thing inside a Fedora container
│   └── build-rpms.sh             builds the two FocusWave packages
├── kickstart/focuswave.ks.in     what goes into the ISO (packages, tuning, codecs)
├── packaging/                    RPM specs (focuswave-desktop, focuswave-decoration)
├── setup/focuswave-setup.sh      install/undo on an existing Fedora KDE system
├── src/
│   ├── kwin-script/              Focus Mode logic (KWin script, Meta+F, window menu)
│   ├── focus-overlay/            Focus Mode blur layer (small C++/Qt helper)
│   ├── plasmoid/                 Focus Mode button for the top bar
│   ├── decoration/               traffic-light window buttons (C++ KDecoration3 plugin)
│   └── customize/focuswave/      engine + Customize app + welcome tour (Python, QML)
├── theme/                        colors, wallpapers, icons, global theme, system defaults
├── data/                         launchers, .desktop files, systemd timer
└── tools/                        generators for colors/wallpapers, file installer
```

How the pieces fit together is in [docs/HOW-IT-WORKS.md](docs/HOW-IT-WORKS.md).

## License

Code: GPL‑3.0‑or‑later. Wallpapers and icons: CC BY‑SA 4.0. Built on Fedora Linux and KDE Plasma.
