# 2 · Test FocusWave before installing it

Always try it first. Both ways below leave Windows and her files untouched.

## Check the download

The `.sha256` file holds the ISO's checksum. Compare it with yours:

- **Windows (PowerShell):** `Get-FileHash .\FocusWave-45-x86_64.iso -Algorithm SHA256`
- **macOS/Linux:** `sha256sum FocusWave-45-x86_64.iso` (macOS: `shasum -a 256 …`)

---

## Way 1 — In a virtual machine (no USB stick needed)

### On Windows: VirtualBox (free)

1. Install **VirtualBox 7** from <https://www.virtualbox.org>.
2. **New** → name it `FocusWave`, pick the ISO, type *Linux / Fedora (64‑bit)*, and tick **Skip Unattended Installation**.
3. Give it **6 GB RAM**, **4 CPUs**, tick **Enable EFI**, and a **40 GB** disk.
4. Before starting: **Settings → Display** → Video Memory **128 MB**, Graphics Controller **VMSVGA**.
5. **Start.** In the boot menu, choose **Start FocusWave**.

VMware Workstation Pro, which is free for personal use, usually gives smoother 3D and blur than VirtualBox.

### On Linux: GNOME Boxes or virt-manager

Create a VM from the ISO with UEFI firmware. Turn on **3D acceleration** (virtio‑gpu with OpenGL) so blur and animations run smoothly.

> In a VM, blur and animations can be slow because there's no real GPU. That's the VM, not FocusWave. On the real laptop, the Iris Xe GPU handles them easily.

---

## Way 2 — From a USB stick on the real laptop (the best test)

You need a USB stick of 8 GB or more. **It will be erased.**

1. Install **Fedora Media Writer** (<https://fedoraproject.org/workstation/download> → *Fedora Media Writer*, for Windows/macOS/Linux).
2. Choose **Select .iso file**, pick `FocusWave-45-x86_64.iso`, pick the USB stick, and click **Write**.
   - Rufus also works. If it asks, choose **DD image mode**.
   - Avoid Ventoy for now. Fedora 45 live ISOs have had boot problems with it.
3. Plug the stick into her laptop and restart. Right after the logo appears, press the **boot menu key**:

   | Brand | Key |
   |---|---|
   | Dell | F12 |
   | HP | Esc, then F9 |
   | Lenovo | F12 (or Fn+F12, or the small Novo button) |
   | ASUS | Esc or F8 |
   | Acer | F12 (may need enabling in BIOS) |
   | MSI | F11 |
   | Microsoft Surface | hold Volume Down while powering on |

4. Pick the USB stick, then **Start FocusWave**. Secure Boot can stay on, because Fedora is signed.

The live session runs from the USB stick. Nothing is installed and nothing on the laptop changes.

---

## What to check (≈10 minutes)

- [ ] It boots to the FocusWave desktop: top bar, floating dock, FocusWave wallpaper
- [ ] **Wi‑Fi** connects (top bar → network icon)
- [ ] **Sound** works (play a YouTube video in Zen, the browser in the dock; also tests the codecs)
- [ ] **Brightness and volume keys** work
- [ ] **Touchpad**: two‑finger scrolling and tap‑to‑click (Settings → Touchpad, if needed)
- [ ] **Focus Mode**: open Zen and Dolphin, then press **Meta+F**. Everything except the active window blurs. Press **Meta+F** again (or double‑click the blur) to leave. Also try the Focus button in the top bar, and right‑click a title bar → *Focus Mode* (possibly under *More Actions*).
- [ ] **Customize** (in the dock): switch Light/Dark, change the accent color, then *Layout* → pick *Mac‑like* → *Apply to my desktop*
- [ ] **Webcam** works (open a webcam test website in Zen)
- [ ] **External monitor / HDMI**, if she uses one
- [ ] **Sleep**: close the lid, open it again

If something doesn't work, note what. Wi‑Fi, sound and touchpad issues are usually hardware drivers, and Fedora's kernel 7.x supports 13th‑gen Intel laptops very well.

The welcome tour doesn't appear in the live session. It runs the first time she logs in after installing.
