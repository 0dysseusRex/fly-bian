# Armbian userpatches for Fly Lite 2.1

Copy this tree into an [Armbian build](https://github.com/armbian/build) checkout as `userpatches/`. Full contract: [`docs/build-named-image.md`](../docs/build-named-image.md).

```bash
git clone --depth=1 https://github.com/armbian/build.git
cp -a userpatches/. build/userpatches/
# also stage first-boot + klipper/cpu-affinity into userpatches/overlay/ (see customize-image.sh)
```
