# hakios/ — the upstream-HakiOS device layer for polaris

`devices/polaris/` and `socs/sdm845/` are the self-contained HakiOS device
repository, developed inside a checkout of
`kiwiiiii-eth/hakios-xnu-kernel` @ `fajita-v0.1-beta`
(`devices/polaris/` and `socs/sdm845/` there). The workflow
`.github/workflows/hakios-polaris.yml` fetches that kernel tree, overlays this
directory, and builds U-Boot + kernel + loader into a RAM-only
`fastboot boot` image (`out/hakios-u-boot-polaris.img`).

To change device files, edit them in the kernel-tree checkout
(`F:\ai workspace HDD\MIX2S-iOS-lab\fajita-port\kernel-src\
hakios-xnu-kernel-fajita-v0.1-beta\devices\polaris\`), then mirror the changed
files here. See `polaris/NOTES.md` in the ios-sweet lab for the live handoff.

The first-build `configs/polaris.config` leaves every phone driver out
(first-boot milestone, docs/porting/index.md step 2); the previous staged
config is kept as `configs/polaris-full-staged.config.txt` for the later
driver bring-up order.
