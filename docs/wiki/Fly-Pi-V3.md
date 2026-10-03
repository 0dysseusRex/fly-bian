# Fly Pi V3

![Fly Pi V3](https://raw.githubusercontent.com/0dysseusRex/fly-bian/main/docs/boards/fly-pi-v3/fly-pi-v3.jpg)

**Status:** Next target after Fly Lite 2.1. **No Fly-bian public image yet.**

Board notes in the repo: [docs/boards/fly-pi-v3/README.md](https://github.com/0dysseusRex/fly-bian/blob/main/docs/boards/fly-pi-v3/README.md).

## Important

**Do not flash Fly Lite 2.1 images** (`Fly-Lite-2.1` in the filename) onto a Fly Pi V3. Wrong SoC / boot / device tree — it will not work and can waste a lot of time.

When Pi V3 images ship, filenames will look like:

- `Fly-bian-*_Fly-Pi-V3_Base.img.xz`
- `Fly-bian-*_Fly-Pi-V3_Simple-AF-*.img.xz`
- `Fly-bian-*_Fly-Pi-V3_KIAUH-*.img.xz`

…and the flash flow will match [Getting started](Getting-Started.md) (download → burn MicroSD → `FLY-SETUP` / wizard → SSH → `fly-start` or `fly-kiauh`).

## What we know from the board (bring-up TBD)

Visible on the PCB (for orientation only — pinmux and drivers still to be confirmed in Fly-bian):

- Marked **Fly-PI3**
- Ethernet + USB-A, fan header, reset  
- M.2-style **FLY-M2WE** wireless module with antenna connector  
- Large supercapacitor module on some units  

Fill-in hardware table, UART baud, storage (eMMC vs SD), and power rules will land in the board README during bring-up. Do not invent overlays from photos alone.

## Until images exist

- Follow Mellow’s own docs/firmware for Pi V3 if you need a working printer today.  
- Watch [Releases](https://github.com/0dysseusRex/fly-bian/releases) for the first `Fly-Pi-V3` artifacts.  
- Same three-flavor model as the Lite: **Base**, **Simple-AF**, **KIAUH**.

## Related

- [Getting started](Getting-Started.md) (Lite today; same pattern later for Pi V3)  
- [Fly Lite 2.1](Fly-Lite-2.1.md) — currently supported board  
