# Host-side Klipper fragments for Fly Lite 2.1

These files are safe to include on any printer MCU. They do not define steppers or heaters.

CPU placement for the Klipper *process* is not in these fragments. The Lite image pins Klipper-family systemd units to CPUs 1–3 (`klipper/cpu-affinity/`) so 8189fs can keep CPU0, regardless of whether the user later runs KIAUH or Simple-AF.

See `docs/klipper-pins-and-macros.md` for the full pin and macro list.
