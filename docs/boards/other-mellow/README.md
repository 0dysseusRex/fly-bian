# Other Mellow SBCs — notes only

**Status:** Documentation stubs — **not** supported Fly-bian targets yet.

This folder is for hardware notes on Mellow / Fly hosts we are **not** actively baking images for. Goal: stop people from flashing the wrong card image and capture facts as we learn them.

---

## Rules

1. **Do not** flash `Fly-bian-*_Fly-Lite-2.1_*.img.xz` onto a different SBC.  
2. **Do not** assume Orange Pi / Raspberry Pi images match Mellow pinmux or Wi-Fi.  
3. Prefer Mellow’s official docs / FlyOS for unsupported boards until a board README here says “Supported”.  
4. When a board becomes real work, promote it to `docs/boards/<board>/README.md` with a full hardware overview (see [Fly Lite 2.1](../fly-lite-2.1/README.md) as the template).

---

## Known product names (placeholders)

Expand each into its own board directory when we have hardware in hand.

| Product (vendor naming varies) | Notes for contributors |
| --- | --- |
| Fly Pi (earlier / non-V3) | Different SoC/layout than Lite 2.1 — confirm before any overlay reuse |
| Fly Gemini / related hosts | Often community images exist elsewhere; not Fly-bian |
| Other Mellow SBCs | Add rows with SoC, RAM, storage, UART as discovered |

### Per-board stub template

When you open a new board directory, copy the structure from [Fly Pi V3](../fly-pi-v3/README.md): hardware table, connectors, power/reset, boot map, displays, memory, serial, then software map.

---

## Related

- [Board index](../README.md)  
- [Main project README](../../../README.md)  
- [Fly Lite 2.1](../fly-lite-2.1/README.md) — only supported board at 1.0  
