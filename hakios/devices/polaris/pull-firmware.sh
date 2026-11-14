#!/bin/bash
# polaris 固件准备：全部来自**本机已保存的转储**，不连接手机、不调用 adb、不改手机任何状态。
# 2026-11-14。设备此刻在 fastboot；本机转储在 MIX2S-iOS-lab/device-private/firmware/。
#
#   fw-gpu/    本机 vendor 分区只读挂载时提取的 a630_gmu.bin / a630_sqe.fw / a630_zap.mdt / a630_zap.b02
#   fw-modem/  device-private/firmware/modem-image/ 整目录（492 个文件），含 modem.mdt/.b*、mba.mbn、
#              adsp.*、wlanmdsp.mbn、bdwlan.bin；根目录下另放 modem 启动需要的几个
#   fw-modem/ath10k/WCN3990/hw1.0/   firmware-5.bin / board-2.bin（linux-firmware，直连下载）
#
# 仍然缺、且必须从手机取（本脚本不伪造、不下载第三方设备固件）：
#   fw-bt/crbtfw21.tlv, crnv21.bin      WCN3990 蓝牙 rampatch / NVM，本机 bluetooth 分区
#   fw-modem/image/ipa_fws.mdt + .b*    IPA 固件，在 /vendor/firmware（LTE 数据才需要，Wi-Fi 不需要）
#   fw-modem/image/bdwlan.* 的本机校准变体（已有 bdwlan.bin，先按通用试）
#
# 用法：K=<hakios-xnu-kernel 路径> bash devices/polaris/pull-firmware.sh
set -e
HERE=$(cd -P "$(dirname "$0")" && pwd)
K=${K:-$(cd "$HERE/../.." 2>/dev/null && [ -f tools/hakios-config.py ] && pwd || echo "$(dirname "$HERE")/hakios-xnu-kernel")}
LAB=${LAB:-"F:/ai workspace HDD/MIX2S-iOS-lab"}
SRC="$LAB/device-private/firmware"
[ -f "$K/tools/hakios-config.py" ] || { echo "pull-firmware: no hakios-xnu-kernel at $K" >&2; exit 1; }
[ -d "$SRC/a630-live-20261106" ] || { echo "pull-firmware: 本机 GPU 转储不存在: $SRC/a630-live-20261106" >&2; exit 1; }
[ -d "$SRC/modem-image" ] || { echo "pull-firmware: 本机 modem 转储不存在: $SRC/modem-image" >&2; exit 1; }
cd "$K"

echo "pull-firmware: 只用本机转储，不连接手机"
mkdir -p fw-gpu fw-modem fw-bt

# GPU：本机四个 blob。SHA 与 6T 不同是预期的（zap 由 TrustZone 按设备签名），必须用本机的。
for f in a630_gmu.bin a630_sqe.fw a630_zap.mdt a630_zap.b02; do
	cp -f "$SRC/a630-live-20261106/$f" "fw-gpu/$f"
done
echo "pull-firmware: fw-gpu/ 4 files (本机专属, $(sha256sum fw-gpu/a630_zap.b02 | cut -c1-16)…)"

# Modem：整目录 + 根目录启动文件
rm -rf fw-modem/image
cp -a "$SRC/modem-image" fw-modem/image
for f in modem.mdt mba.mbn; do cp -f "fw-modem/image/$f" "fw-modem/$f" 2>/dev/null || true; done
for f in fw-modem/image/modem.b*; do [ -f "$f" ] && cp -f "$f" fw-modem/; done
echo "pull-firmware: fw-modem/image/ $(find fw-modem/image -type f | wc -l) files"

# Wi-Fi：开源固件（若已在位则保留）
WF=fw-modem/ath10k/WCN3990/hw1.0
mkdir -p "$WF"
for f in firmware-5.bin board-2.bin; do
	if [ ! -s "$WF/$f" ]; then
		curl -4 --noproxy '*' -sS -L -o "$WF/$f" \
			"https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/ath10k/WCN3990/hw1.0/$f"
	fi
done
echo "pull-firmware: $WF ready"

# 如实报告缺口，绝不伪造设备专属固件
for f in fw-bt/crbtfw21.tlv fw-bt/crnv21.bin fw-modem/image/ipa_fws.mdt; do
	[ -s "$f" ] || echo "pull-firmware: MISSING (需从本机分区取) $f"
done
echo "pull-firmware: done. 未连接手机，未写入手机任何分区。"
