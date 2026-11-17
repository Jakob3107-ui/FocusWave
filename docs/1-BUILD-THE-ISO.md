# 1 · Build the FocusWave ISO

You need about an hour, mostly waiting. Two ways:

- **GitHub (no Linux needed).** Use this if you're on Windows or macOS.
- **A Fedora computer or VM.** Faster to retry, and gives you full control.

---

## Option A — Build on GitHub (free, no Linux needed)

GitHub provides free Linux build machines for public projects. The workflow in `.github/workflows/build-iso.yml` does all the work.

1. **Create a GitHub account** at <https://github.com> if you don't have one.
2. **Create a new repository.** Click **+** → **New repository**. Name it `focuswave` and choose **Public**.
   > Why public? GitHub gives public projects unlimited free build storage. Private projects only get 500 MB, which is too small for a ~3 GB ISO. Nothing personal is in this project.
3. **Upload the project.** On the new repository's page, click **uploading an existing file**. Drag in **everything inside** the `focuswave` folder, including the hidden `.github` folder. Then click **Commit changes**.
   - On Windows, if `.github` doesn't show up: in File Explorer, open **View → Show → Hidden items**.
   - Or use GitHub Desktop: *File → Add local repository* → pick the folder → *Publish repository* (untick "Keep this code private").
4. **Start the build.** Open the **Actions** tab. If asked, click **I understand my workflows, go ahead and enable them**. Pick **Build FocusWave ISO** on the left, then **Run workflow** → **Run workflow**.
5. **Wait.** It usually takes 40–90 minutes. A green check ✅ means it worked.
6. **Download the ISO.** Click the finished run, scroll to **Artifacts**, and download **FocusWave-ISO**. It's a `.zip` file; unzip it to get `FocusWave-45-x86_64.iso` and its `.sha256` checksum. Downloads are kept for 7 days.

**If it fails (red ❌):** download **FocusWave-build-logs** from the same page. The interesting part is usually near the end of `livemedia.log` or `anaconda/packaging.log`. Paste the last ~50 lines into Claude together with the kickstart file, and ask for a fix.

---

## Option B — Build on Fedora

Use a Fedora 45 computer or a Fedora 45 virtual machine. A VM with 4 CPUs, 8 GB RAM and 60 GB of disk is enough. You need ~25 GB of free space.

```bash
cd focuswave
sudo bash ./build/build-iso.sh
```

The script installs the build tools, builds the FocusWave packages, and then builds the ISO into `output/`:

```
output/FocusWave-45-x86_64.iso
output/FocusWave-45-x86_64.iso.sha256
output/rpms/                  ← the FocusWave packages (useful for setup/focuswave-setup.sh --rpms)
output/logs/                  ← logs if something goes wrong
```

**Other Linux distributions** (Ubuntu, Arch, …) with podman or docker:

```bash
bash ./build/build-in-container.sh
```

### Settings you can change

| Variable | Default | Meaning |
|---|---|---|
| `FEDORA_VERSION` | 45 | Fedora release to base on |
| `OUTPUT_DIR` | `./output` | where the ISO goes |
| `WORK_DIR` | `/var/tmp/focuswave-build` | scratch space (build-iso.sh) |
| `SCRATCH_DIR` | — | scratch space on a big disk (build-in-container.sh) |

---

## What's inside the ISO

- Fedora 45 KDE Plasma (Wayland) with the Fedora installer
- FocusWave packages: `focuswave-desktop`, plus `focuswave-decoration` if it built
- Web browser: **Zen Browser** from Flathub, set as the default, with Intel video acceleration and codecs inside its sandbox. If Zen can't be downloaded during the build, Firefox is kept instead, so there's always a browser.
- Apps: Dolphin (files), Discover (app store, with Flathub), Gwenview (photos), Okular (PDF), Haruna (video), Elisa (music), Spectacle (screenshots), Ark, KWrite, Calculator, KDE Connect (phone link), Filelight, System Monitor, Partition Manager, Konsole
- RPM Fusion: full `ffmpeg` codecs and `intel-media-driver` for hardware video decoding on Iris Xe
- `thermald` for the Intel CPU, no boot-delaying network wait, no splash screen
- Leaner than stock: no email/PIM suite and no bundled games (she can install them from Discover)

If the traffic-light decoration doesn't compile, the build still succeeds. Windows then get Breeze buttons on the left instead of the colored traffic lights, and everything else works the same.
