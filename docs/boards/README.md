# Boards

Each supported or planned SBC has its **own README** with a deeper hardware overview. The [main project README](../../README.md) stays high-level (what Fly-bian is, what to flash, AI-first workflow).

| Board | Status | README |
| --- | --- | --- |
| **Fly Lite 2.1** | Supported (1.0) | [fly-lite-2.1/README.md](fly-lite-2.1/README.md) · [OOM / installs](fly-lite-2.1/oom.md) |
| **Fly Pi V3** | Next | [fly-pi-v3/README.md](fly-pi-v3/README.md) |
| **Other Mellow SBCs** | Notes only | [other-mellow/README.md](other-mellow/README.md) |

## README template (for new boards)

Every `docs/boards/<board>/README.md` should cover:

1. Status + vendor link + Armbian `BOARD` names + DTB  
2. **Hardware overview** table (SoC, RAM, storage, power, radio, USB, UART, displays)  
3. Connectors and cable gotchas  
4. Power / reset behavior  
5. Boot / firmware map (overlays, cmdline quirks)  
6. Displays and touch  
7. Memory limits (link `oom.md` if needed)  
8. Serial console settings  
9. Fly-bian software map / helpers  
10. Related docs  

Do not invent pinmux — leave TBD until measured on hardware.
