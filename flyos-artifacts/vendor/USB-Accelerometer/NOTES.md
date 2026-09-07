# USB accelerometer

Upstream: https://github.com/Mellow-3D/USB-Accelerometer

Lite 2.1 cannot drive a bare SPI/I2C ADXL on host pins. Use a USB LIS2DW (or a toolboard accel). Official Klipper section is `klipper/host-fragments/usb-lis2dw.cfg`.

Docs:

- https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/advanced/adxl/
- https://mellow.klipper.cn/en/docs/ProductDoc/ToolBoard/fly-usb-adxl/fly-usb-lis2dw/cfg
