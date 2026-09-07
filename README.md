# Fly Lite V2.1 + SimpleAF

A feasibility guide for running a custom Debian-based distro on a **Mellow Fly Lite V2.1** so you can install [SimpleAF for RPi](https://pellcorp.github.io/creality-wiki/rpi/).

## Verdict

The Lite V2.1 is an Allwinner H3 Linux host, not a microcontroller. It boots from a MicroSD card, so a custom Debian image is possible.

Stock **FlyOS-FAST cannot host SimpleAF**. FAST is root-only, mostly read-only, and ships without a normal package manager. SimpleAF needs Debian 11–13, `apt`, git, a non-root sudo user, and a clean host.

**Full Fly hardware support is the hard part.** USB to the printer MCU is realistic. Onboard 2.4 GHz Wi-Fi, the FPC-TFT/HDMI ports, and Mellow extras depend on Fly’s device tree. 512 MB RAM also forces a lean install: no webcam stack, no KlipperScreen.

## Run locally

```bash
npm install
npm run dev
```

Open [http://127.0.0.1:43187](http://127.0.0.1:43187).

## What this is not

This is not an OS image and not a SimpleAF installer. It is a reading of public Mellow and SimpleAF docs so you can decide whether to keep the Lite as the host or move SimpleAF to a Pi-class board.
