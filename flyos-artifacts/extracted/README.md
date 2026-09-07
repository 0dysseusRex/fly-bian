# Extracted official FlyOS image

Put DTB, overlays, and firmware here after:

```bash
./scripts/extract-flyos.sh /path/to/FlyOS_h3_*.img
cp -a out/flyos-extract/. flyos-artifacts/extracted/
```

Official image page (Lite2 and Lite2.1 share it):

https://mellow.klipper.cn/en/docs/ResDownload/system-img/fly-lite2/

Do not commit the raw `.img` or `.img.xz`.
