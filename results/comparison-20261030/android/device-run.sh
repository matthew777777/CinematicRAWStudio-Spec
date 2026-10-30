#!/system/bin/sh
set -eu
cd /data/local/tmp/craw-comparison-20261030
mkdir -p results

snapshot() {
  date -u
  dumpsys thermalservice
  dumpsys battery
  cat /proc/meminfo
  for f in /sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq; do echo "$f"; cat "$f" || true; done
}

echo '[1/130] take1-frame136-jxl-e1-mosaic-t1-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e1-mosaic 1 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e1-mosaic-t1-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e1-mosaic 1 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e1-mosaic-t1-s0.decode.json
echo '[2/130] take1-frame136-craw3-t4-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw3 4 encode payload.bin 5 0 1 > results/take1-frame136-craw3-t4-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw3 4 decode payload.bin 5 0 1 > results/take1-frame136-craw3-t4-s0.decode.json
echo '[3/130] take1-frame0-craw2-t1-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw2 1 encode payload.bin 5 0 1 > results/take1-frame0-craw2-t1-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw2 1 decode payload.bin 5 0 1 > results/take1-frame0-craw2-t1-s0.decode.json
echo '[4/130] take0-frame132-craw2-t1-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw2 1 encode payload.bin 5 0 1 > results/take0-frame132-craw2-t1-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw2 1 decode payload.bin 5 0 1 > results/take0-frame132-craw2-t1-s0.decode.json
echo '[5/130] take0-frame265-craw1-t1-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw1 1 encode payload.bin 5 0 1 > results/take0-frame265-craw1-t1-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw1 1 decode payload.bin 5 0 1 > results/take0-frame265-craw1-t1-s0.decode.json
echo '[6/130] take1-frame136-jxl-e1-planes-t1-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e1-planes 1 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e1-planes-t1-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e1-planes 1 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e1-planes-t1-s0.decode.json
echo '[7/130] take1-frame271-jxl-e2-mosaic-t1-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e2-mosaic 1 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e2-mosaic-t1-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e2-mosaic 1 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e2-mosaic-t1-s0.decode.json
echo '[8/130] take1-frame0-craw3-t1-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw3 1 encode payload.bin 5 0 1 > results/take1-frame0-craw3-t1-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw3 1 decode payload.bin 5 0 1 > results/take1-frame0-craw3-t1-s0.decode.json
echo '[9/130] take1-frame0-craw4-t4-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw4 4 encode payload.bin 5 0 1 > results/take1-frame0-craw4-t4-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw4 4 decode payload.bin 5 0 1 > results/take1-frame0-craw4-t4-s0.decode.json
echo '[10/130] take0-frame132-jxl-e1-mosaic-t4-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e1-mosaic 4 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e1-mosaic-t4-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e1-mosaic 4 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e1-mosaic-t4-s0.decode.json
echo '[11/130] take0-frame132-jxl-e2-planes-t4-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e2-planes 4 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e2-planes-t4-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e2-planes 4 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e2-planes-t4-s0.decode.json
echo '[12/130] take0-frame265-jxl-e2-planes-t4-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e2-planes 4 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e2-planes-t4-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e2-planes 4 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e2-planes-t4-s0.decode.json
echo '[13/130] take1-frame0-jxl-e2-mosaic-t1-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e2-mosaic 1 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e2-mosaic-t1-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e2-mosaic 1 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e2-mosaic-t1-s0.decode.json
echo '[14/130] take1-frame136-craw2-t4-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw2 4 encode payload.bin 5 0 1 > results/take1-frame136-craw2-t4-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw2 4 decode payload.bin 5 0 1 > results/take1-frame136-craw2-t4-s0.decode.json
echo '[15/130] take0-frame265-jxl-e1-mosaic-t4-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e1-mosaic 4 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e1-mosaic-t4-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e1-mosaic 4 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e1-mosaic-t4-s0.decode.json
echo '[16/130] take0-frame132-craw3-t1-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw3 1 encode payload.bin 5 0 1 > results/take0-frame132-craw3-t1-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw3 1 decode payload.bin 5 0 1 > results/take0-frame132-craw3-t1-s0.decode.json
echo '[17/130] take0-frame265-jxl-e2-planes-t1-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e2-planes 1 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e2-planes-t1-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e2-planes 1 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e2-planes-t1-s0.decode.json
echo '[18/130] take1-frame271-jxl-e1-mosaic-t4-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e1-mosaic 4 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e1-mosaic-t4-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e1-mosaic 4 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e1-mosaic-t4-s0.decode.json
echo '[19/130] take1-frame0-jxl-e3-mosaic-t1-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e3-mosaic 1 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e3-mosaic-t1-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e3-mosaic 1 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e3-mosaic-t1-s0.decode.json
echo '[20/130] take1-frame0-jxl-e2-planes-t1-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e2-planes 1 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e2-planes-t1-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e2-planes 1 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e2-planes-t1-s0.decode.json
echo '[21/130] take1-frame271-jxl-e3-planes-t1-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e3-planes 1 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e3-planes-t1-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e3-planes 1 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e3-planes-t1-s0.decode.json
echo '[22/130] take0-frame0-craw2-t1-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw2 1 encode payload.bin 5 0 1 > results/take0-frame0-craw2-t1-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw2 1 decode payload.bin 5 0 1 > results/take0-frame0-craw2-t1-s0.decode.json
echo '[23/130] take0-frame265-craw3-t4-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw3 4 encode payload.bin 5 0 1 > results/take0-frame265-craw3-t4-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw3 4 decode payload.bin 5 0 1 > results/take0-frame265-craw3-t4-s0.decode.json
echo '[24/130] take1-frame136-jxl-e2-planes-t1-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e2-planes 1 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e2-planes-t1-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e2-planes 1 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e2-planes-t1-s0.decode.json
echo '[25/130] take1-frame136-jxl-e1-planes-t4-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e1-planes 4 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e1-planes-t4-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e1-planes 4 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e1-planes-t4-s0.decode.json
echo '[26/130] take0-frame132-craw1-t4-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw1 4 encode payload.bin 5 0 1 > results/take0-frame132-craw1-t4-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw1 4 decode payload.bin 5 0 1 > results/take0-frame132-craw1-t4-s0.decode.json
echo '[27/130] take1-frame136-jxl-e2-mosaic-t1-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e2-mosaic 1 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e2-mosaic-t1-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e2-mosaic 1 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e2-mosaic-t1-s0.decode.json
echo '[28/130] take0-frame0-jxl-e1-mosaic-t1-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-mosaic 1 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e1-mosaic-t1-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-mosaic 1 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e1-mosaic-t1-s0.decode.json
echo '[29/130] take0-frame0-craw1-t4-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw1 4 encode payload.bin 5 0 1 > results/take0-frame0-craw1-t4-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw1 4 decode payload.bin 5 0 1 > results/take0-frame0-craw1-t4-s0.decode.json
echo '[30/130] take0-frame132-jxl-e2-mosaic-t1-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e2-mosaic 1 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e2-mosaic-t1-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e2-mosaic 1 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e2-mosaic-t1-s0.decode.json
echo '[31/130] take1-frame0-jxl-e1-mosaic-t1-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e1-mosaic 1 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e1-mosaic-t1-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e1-mosaic 1 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e1-mosaic-t1-s0.decode.json
echo '[32/130] take1-frame271-craw4-t1-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw4 1 encode payload.bin 5 0 1 > results/take1-frame271-craw4-t1-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw4 1 decode payload.bin 5 0 1 > results/take1-frame271-craw4-t1-s0.decode.json
echo '[33/130] take1-frame271-craw3-t4-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw3 4 encode payload.bin 5 0 1 > results/take1-frame271-craw3-t4-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw3 4 decode payload.bin 5 0 1 > results/take1-frame271-craw3-t4-s0.decode.json
echo '[34/130] take1-frame0-craw3-t4-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw3 4 encode payload.bin 5 0 1 > results/take1-frame0-craw3-t4-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw3 4 decode payload.bin 5 0 1 > results/take1-frame0-craw3-t4-s0.decode.json
echo '[35/130] take1-frame0-jxl-e3-mosaic-t4-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e3-mosaic 4 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e3-mosaic-t4-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e3-mosaic 4 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e3-mosaic-t4-s0.decode.json
echo '[36/130] take0-frame265-craw4-t1-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw4 1 encode payload.bin 5 0 1 > results/take0-frame265-craw4-t1-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw4 1 decode payload.bin 5 0 1 > results/take0-frame265-craw4-t1-s0.decode.json
echo '[37/130] take1-frame136-jxl-e3-mosaic-t4-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e3-mosaic 4 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e3-mosaic-t4-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e3-mosaic 4 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e3-mosaic-t4-s0.decode.json
echo '[38/130] take0-frame0-jxl-e2-planes-t1-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-planes 1 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e2-planes-t1-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-planes 1 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e2-planes-t1-s0.decode.json
echo '[39/130] take0-frame0-jxl-e3-mosaic-t4-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-mosaic 4 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e3-mosaic-t4-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-mosaic 4 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e3-mosaic-t4-s0.decode.json
echo '[40/130] take0-frame132-jxl-e3-planes-t4-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e3-planes 4 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e3-planes-t4-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e3-planes 4 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e3-planes-t4-s0.decode.json
echo '[41/130] take0-frame132-craw4-t4-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw4 4 encode payload.bin 5 0 1 > results/take0-frame132-craw4-t4-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw4 4 decode payload.bin 5 0 1 > results/take0-frame132-craw4-t4-s0.decode.json
echo '[42/130] take0-frame0-jxl-e2-mosaic-t4-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-mosaic 4 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e2-mosaic-t4-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-mosaic 4 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e2-mosaic-t4-s0.decode.json
echo '[43/130] take0-frame0-craw4-t1-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw4 1 encode payload.bin 5 0 1 > results/take0-frame0-craw4-t1-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw4 1 decode payload.bin 5 0 1 > results/take0-frame0-craw4-t1-s0.decode.json
echo '[44/130] take1-frame136-craw4-t4-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw4 4 encode payload.bin 5 0 1 > results/take1-frame136-craw4-t4-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw4 4 decode payload.bin 5 0 1 > results/take1-frame136-craw4-t4-s0.decode.json
echo '[45/130] take0-frame265-jxl-e3-planes-t4-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e3-planes 4 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e3-planes-t4-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e3-planes 4 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e3-planes-t4-s0.decode.json
echo '[46/130] take1-frame136-jxl-e1-mosaic-t4-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e1-mosaic 4 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e1-mosaic-t4-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e1-mosaic 4 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e1-mosaic-t4-s0.decode.json
echo '[47/130] take1-frame271-jxl-e3-mosaic-t1-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e3-mosaic 1 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e3-mosaic-t1-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e3-mosaic 1 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e3-mosaic-t1-s0.decode.json
echo '[48/130] take0-frame265-craw4-t4-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw4 4 encode payload.bin 5 0 1 > results/take0-frame265-craw4-t4-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw4 4 decode payload.bin 5 0 1 > results/take0-frame265-craw4-t4-s0.decode.json
echo '[49/130] take0-frame132-craw4-t1-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw4 1 encode payload.bin 5 0 1 > results/take0-frame132-craw4-t1-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw4 1 decode payload.bin 5 0 1 > results/take0-frame132-craw4-t1-s0.decode.json
echo '[50/130] take1-frame136-craw2-t1-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw2 1 encode payload.bin 5 0 1 > results/take1-frame136-craw2-t1-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw2 1 decode payload.bin 5 0 1 > results/take1-frame136-craw2-t1-s0.decode.json
echo '[51/130] take0-frame0-craw3-t4-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw3 4 encode payload.bin 5 0 1 > results/take0-frame0-craw3-t4-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw3 4 decode payload.bin 5 0 1 > results/take0-frame0-craw3-t4-s0.decode.json
echo '[52/130] take1-frame0-craw1-t1-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw1 1 encode payload.bin 5 0 1 > results/take1-frame0-craw1-t1-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw1 1 decode payload.bin 5 0 1 > results/take1-frame0-craw1-t1-s0.decode.json
echo '[53/130] take1-frame0-jxl-e1-planes-t1-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e1-planes 1 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e1-planes-t1-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e1-planes 1 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e1-planes-t1-s0.decode.json
echo '[54/130] take1-frame136-jxl-e2-planes-t4-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e2-planes 4 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e2-planes-t4-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e2-planes 4 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e2-planes-t4-s0.decode.json
echo '[55/130] take0-frame132-jxl-e3-mosaic-t4-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e3-mosaic 4 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e3-mosaic-t4-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e3-mosaic 4 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e3-mosaic-t4-s0.decode.json
echo '[56/130] take0-frame265-jxl-e3-mosaic-t4-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e3-mosaic 4 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e3-mosaic-t4-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e3-mosaic 4 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e3-mosaic-t4-s0.decode.json
echo '[57/130] take1-frame271-jxl-e2-planes-t4-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e2-planes 4 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e2-planes-t4-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e2-planes 4 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e2-planes-t4-s0.decode.json
echo '[58/130] take0-frame132-jxl-e1-planes-t4-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e1-planes 4 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e1-planes-t4-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e1-planes 4 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e1-planes-t4-s0.decode.json
echo '[59/130] take0-frame265-jxl-e1-planes-t4-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e1-planes 4 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e1-planes-t4-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e1-planes 4 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e1-planes-t4-s0.decode.json
echo '[60/130] take1-frame271-jxl-e2-mosaic-t4-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e2-mosaic 4 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e2-mosaic-t4-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e2-mosaic 4 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e2-mosaic-t4-s0.decode.json
echo '[61/130] take1-frame271-craw3-t1-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw3 1 encode payload.bin 5 0 1 > results/take1-frame271-craw3-t1-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw3 1 decode payload.bin 5 0 1 > results/take1-frame271-craw3-t1-s0.decode.json
echo '[62/130] take1-frame0-jxl-e3-planes-t4-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e3-planes 4 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e3-planes-t4-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e3-planes 4 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e3-planes-t4-s0.decode.json
echo '[63/130] take1-frame271-jxl-e1-planes-t4-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e1-planes 4 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e1-planes-t4-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e1-planes 4 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e1-planes-t4-s0.decode.json
echo '[64/130] take0-frame0-jxl-e2-mosaic-t1-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-mosaic 1 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e2-mosaic-t1-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-mosaic 1 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e2-mosaic-t1-s0.decode.json
echo '[65/130] take1-frame136-jxl-e3-mosaic-t1-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e3-mosaic 1 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e3-mosaic-t1-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e3-mosaic 1 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e3-mosaic-t1-s0.decode.json
echo '[66/130] take0-frame0-jxl-e3-mosaic-t1-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-mosaic 1 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e3-mosaic-t1-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-mosaic 1 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e3-mosaic-t1-s0.decode.json
echo '[67/130] take0-frame132-craw3-t4-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw3 4 encode payload.bin 5 0 1 > results/take0-frame132-craw3-t4-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw3 4 decode payload.bin 5 0 1 > results/take0-frame132-craw3-t4-s0.decode.json
echo '[68/130] take1-frame136-jxl-e3-planes-t4-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e3-planes 4 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e3-planes-t4-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e3-planes 4 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e3-planes-t4-s0.decode.json
echo '[69/130] take1-frame271-craw4-t4-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw4 4 encode payload.bin 5 0 1 > results/take1-frame271-craw4-t4-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw4 4 decode payload.bin 5 0 1 > results/take1-frame271-craw4-t4-s0.decode.json
echo '[70/130] take1-frame0-jxl-e2-mosaic-t4-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e2-mosaic 4 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e2-mosaic-t4-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e2-mosaic 4 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e2-mosaic-t4-s0.decode.json
echo '[71/130] take0-frame0-jxl-e1-mosaic-t4-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-mosaic 4 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e1-mosaic-t4-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-mosaic 4 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e1-mosaic-t4-s0.decode.json
echo '[72/130] take0-frame265-jxl-e3-planes-t1-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e3-planes 1 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e3-planes-t1-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e3-planes 1 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e3-planes-t1-s0.decode.json
echo '[73/130] take0-frame0-craw1-t1-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw1 1 encode payload.bin 5 0 1 > results/take0-frame0-craw1-t1-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw1 1 decode payload.bin 5 0 1 > results/take0-frame0-craw1-t1-s0.decode.json
echo '[74/130] take1-frame136-craw1-t1-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw1 1 encode payload.bin 5 0 1 > results/take1-frame136-craw1-t1-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw1 1 decode payload.bin 5 0 1 > results/take1-frame136-craw1-t1-s0.decode.json
echo '[75/130] take0-frame0-jxl-e3-planes-t4-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-planes 4 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e3-planes-t4-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-planes 4 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e3-planes-t4-s0.decode.json
echo '[76/130] take1-frame271-jxl-e3-mosaic-t4-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e3-mosaic 4 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e3-mosaic-t4-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e3-mosaic 4 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e3-mosaic-t4-s0.decode.json
echo '[77/130] take0-frame265-jxl-e1-mosaic-t1-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e1-mosaic 1 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e1-mosaic-t1-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e1-mosaic 1 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e1-mosaic-t1-s0.decode.json
echo '[78/130] take0-frame132-jxl-e3-planes-t1-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e3-planes 1 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e3-planes-t1-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e3-planes 1 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e3-planes-t1-s0.decode.json
echo '[79/130] take0-frame132-jxl-e1-planes-t1-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e1-planes 1 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e1-planes-t1-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e1-planes 1 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e1-planes-t1-s0.decode.json
echo '[80/130] take1-frame0-jxl-e3-planes-t1-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e3-planes 1 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e3-planes-t1-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e3-planes 1 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e3-planes-t1-s0.decode.json
echo '[81/130] take0-frame132-craw2-t4-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw2 4 encode payload.bin 5 0 1 > results/take0-frame132-craw2-t4-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw2 4 decode payload.bin 5 0 1 > results/take0-frame132-craw2-t4-s0.decode.json
echo '[82/130] take1-frame0-craw2-t4-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw2 4 encode payload.bin 5 0 1 > results/take1-frame0-craw2-t4-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw2 4 decode payload.bin 5 0 1 > results/take1-frame0-craw2-t4-s0.decode.json
echo '[83/130] take0-frame265-jxl-e1-planes-t1-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e1-planes 1 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e1-planes-t1-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e1-planes 1 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e1-planes-t1-s0.decode.json
echo '[84/130] take1-frame271-craw2-t4-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw2 4 encode payload.bin 5 0 1 > results/take1-frame271-craw2-t4-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw2 4 decode payload.bin 5 0 1 > results/take1-frame271-craw2-t4-s0.decode.json
echo '[85/130] take1-frame0-craw1-t4-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw1 4 encode payload.bin 5 0 1 > results/take1-frame0-craw1-t4-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw1 4 decode payload.bin 5 0 1 > results/take1-frame0-craw1-t4-s0.decode.json
echo '[86/130] take0-frame0-craw4-t4-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw4 4 encode payload.bin 5 0 1 > results/take0-frame0-craw4-t4-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw4 4 decode payload.bin 5 0 1 > results/take0-frame0-craw4-t4-s0.decode.json
echo '[87/130] take0-frame0-jxl-e1-planes-t4-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-planes 4 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e1-planes-t4-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-planes 4 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e1-planes-t4-s0.decode.json
echo '[88/130] take0-frame265-craw1-t4-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw1 4 encode payload.bin 5 0 1 > results/take0-frame265-craw1-t4-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw1 4 decode payload.bin 5 0 1 > results/take0-frame265-craw1-t4-s0.decode.json
echo '[89/130] take0-frame265-jxl-e2-mosaic-t4-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e2-mosaic 4 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e2-mosaic-t4-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e2-mosaic 4 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e2-mosaic-t4-s0.decode.json
echo '[90/130] take1-frame271-jxl-e3-planes-t4-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e3-planes 4 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e3-planes-t4-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e3-planes 4 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e3-planes-t4-s0.decode.json
echo '[91/130] take0-frame265-jxl-e3-mosaic-t1-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e3-mosaic 1 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e3-mosaic-t1-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e3-mosaic 1 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e3-mosaic-t1-s0.decode.json
echo '[92/130] take0-frame265-craw3-t1-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw3 1 encode payload.bin 5 0 1 > results/take0-frame265-craw3-t1-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw3 1 decode payload.bin 5 0 1 > results/take0-frame265-craw3-t1-s0.decode.json
echo '[93/130] take1-frame136-craw4-t1-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw4 1 encode payload.bin 5 0 1 > results/take1-frame136-craw4-t1-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw4 1 decode payload.bin 5 0 1 > results/take1-frame136-craw4-t1-s0.decode.json
echo '[94/130] take1-frame136-jxl-e3-planes-t1-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e3-planes 1 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e3-planes-t1-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e3-planes 1 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e3-planes-t1-s0.decode.json
echo '[95/130] take1-frame271-craw2-t1-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw2 1 encode payload.bin 5 0 1 > results/take1-frame271-craw2-t1-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw2 1 decode payload.bin 5 0 1 > results/take1-frame271-craw2-t1-s0.decode.json
echo '[96/130] take0-frame0-craw2-t4-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw2 4 encode payload.bin 5 0 1 > results/take0-frame0-craw2-t4-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw2 4 decode payload.bin 5 0 1 > results/take0-frame0-craw2-t4-s0.decode.json
echo '[97/130] take0-frame0-jxl-e1-planes-t1-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-planes 1 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e1-planes-t1-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-planes 1 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e1-planes-t1-s0.decode.json
echo '[98/130] take0-frame132-craw1-t1-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw1 1 encode payload.bin 5 0 1 > results/take0-frame132-craw1-t1-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 craw1 1 decode payload.bin 5 0 1 > results/take0-frame132-craw1-t1-s0.decode.json
echo '[99/130] take1-frame271-craw1-t1-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw1 1 encode payload.bin 5 0 1 > results/take1-frame271-craw1-t1-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw1 1 decode payload.bin 5 0 1 > results/take1-frame271-craw1-t1-s0.decode.json
echo '[100/130] take1-frame136-craw3-t1-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw3 1 encode payload.bin 5 0 1 > results/take1-frame136-craw3-t1-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw3 1 decode payload.bin 5 0 1 > results/take1-frame136-craw3-t1-s0.decode.json
echo '[101/130] take0-frame0-jxl-e3-planes-t1-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-planes 1 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e3-planes-t1-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-planes 1 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e3-planes-t1-s0.decode.json
echo '[102/130] take1-frame271-jxl-e2-planes-t1-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e2-planes 1 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e2-planes-t1-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e2-planes 1 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e2-planes-t1-s0.decode.json
echo '[103/130] take0-frame132-jxl-e3-mosaic-t1-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e3-mosaic 1 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e3-mosaic-t1-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e3-mosaic 1 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e3-mosaic-t1-s0.decode.json
echo '[104/130] take0-frame265-craw2-t4-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw2 4 encode payload.bin 5 0 1 > results/take0-frame265-craw2-t4-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw2 4 decode payload.bin 5 0 1 > results/take0-frame265-craw2-t4-s0.decode.json
echo '[105/130] take0-frame0-jxl-e2-planes-t4-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-planes 4 encode payload.bin 5 0 1 > results/take0-frame0-jxl-e2-planes-t4-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-planes 4 decode payload.bin 5 0 1 > results/take0-frame0-jxl-e2-planes-t4-s0.decode.json
echo '[106/130] take0-frame132-jxl-e2-planes-t1-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e2-planes 1 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e2-planes-t1-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e2-planes 1 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e2-planes-t1-s0.decode.json
echo '[107/130] take1-frame136-craw1-t4-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw1 4 encode payload.bin 5 0 1 > results/take1-frame136-craw1-t4-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 craw1 4 decode payload.bin 5 0 1 > results/take1-frame136-craw1-t4-s0.decode.json
echo '[108/130] take0-frame132-jxl-e2-mosaic-t4-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e2-mosaic 4 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e2-mosaic-t4-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e2-mosaic 4 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e2-mosaic-t4-s0.decode.json
echo '[109/130] take1-frame271-jxl-e1-mosaic-t1-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e1-mosaic 1 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e1-mosaic-t1-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e1-mosaic 1 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e1-mosaic-t1-s0.decode.json
echo '[110/130] take1-frame0-jxl-e2-planes-t4-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e2-planes 4 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e2-planes-t4-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e2-planes 4 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e2-planes-t4-s0.decode.json
echo '[111/130] take1-frame0-craw4-t1-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw4 1 encode payload.bin 5 0 1 > results/take1-frame0-craw4-t1-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 craw4 1 decode payload.bin 5 0 1 > results/take1-frame0-craw4-t1-s0.decode.json
echo '[112/130] take1-frame271-craw1-t4-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw1 4 encode payload.bin 5 0 1 > results/take1-frame271-craw1-t4-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 craw1 4 decode payload.bin 5 0 1 > results/take1-frame271-craw1-t4-s0.decode.json
echo '[113/130] take1-frame136-jxl-e2-mosaic-t4-s0'
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e2-mosaic 4 encode payload.bin 5 0 1 > results/take1-frame136-jxl-e2-mosaic-t4-s0.encode.json
./craw_compare measure take1-frame136.raw 4080 2040 10 2 jxl-e2-mosaic 4 decode payload.bin 5 0 1 > results/take1-frame136-jxl-e2-mosaic-t4-s0.decode.json
echo '[114/130] take0-frame0-craw3-t1-s0'
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw3 1 encode payload.bin 5 0 1 > results/take0-frame0-craw3-t1-s0.encode.json
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw3 1 decode payload.bin 5 0 1 > results/take0-frame0-craw3-t1-s0.decode.json
echo '[115/130] take0-frame265-jxl-e2-mosaic-t1-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e2-mosaic 1 encode payload.bin 5 0 1 > results/take0-frame265-jxl-e2-mosaic-t1-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 jxl-e2-mosaic 1 decode payload.bin 5 0 1 > results/take0-frame265-jxl-e2-mosaic-t1-s0.decode.json
echo '[116/130] take1-frame271-jxl-e1-planes-t1-s0'
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e1-planes 1 encode payload.bin 5 0 1 > results/take1-frame271-jxl-e1-planes-t1-s0.encode.json
./craw_compare measure take1-frame271.raw 4080 2040 10 2 jxl-e1-planes 1 decode payload.bin 5 0 1 > results/take1-frame271-jxl-e1-planes-t1-s0.decode.json
echo '[117/130] take0-frame265-craw2-t1-s0'
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw2 1 encode payload.bin 5 0 1 > results/take0-frame265-craw2-t1-s0.encode.json
./craw_compare measure take0-frame265.raw 4080 2040 10 2 craw2 1 decode payload.bin 5 0 1 > results/take0-frame265-craw2-t1-s0.decode.json
echo '[118/130] take1-frame0-jxl-e1-planes-t4-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e1-planes 4 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e1-planes-t4-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e1-planes 4 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e1-planes-t4-s0.decode.json
echo '[119/130] take0-frame132-jxl-e1-mosaic-t1-s0'
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e1-mosaic 1 encode payload.bin 5 0 1 > results/take0-frame132-jxl-e1-mosaic-t1-s0.encode.json
./craw_compare measure take0-frame132.raw 4080 2040 10 2 jxl-e1-mosaic 1 decode payload.bin 5 0 1 > results/take0-frame132-jxl-e1-mosaic-t1-s0.decode.json
echo '[120/130] take1-frame0-jxl-e1-mosaic-t4-s0'
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e1-mosaic 4 encode payload.bin 5 0 1 > results/take1-frame0-jxl-e1-mosaic-t4-s0.encode.json
./craw_compare measure take1-frame0.raw 4080 2040 10 2 jxl-e1-mosaic 4 decode payload.bin 5 0 1 > results/take1-frame0-jxl-e1-mosaic-t4-s0.decode.json
echo '[121/130] take0-frame0-craw1-t4-s60'
snapshot > results/take0-frame0-craw1-t4-s60.encode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw1 4 encode payload.bin 5 60 1 > results/take0-frame0-craw1-t4-s60.encode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-craw1-t4-s60.encode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-craw1-t4-s60.encode.thermal.txt 2>&1
snapshot > results/take0-frame0-craw1-t4-s60.decode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw1 4 decode payload.bin 5 60 1 > results/take0-frame0-craw1-t4-s60.decode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-craw1-t4-s60.decode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-craw1-t4-s60.decode.thermal.txt 2>&1
echo '[122/130] take0-frame0-craw2-t4-s60'
snapshot > results/take0-frame0-craw2-t4-s60.encode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw2 4 encode payload.bin 5 60 1 > results/take0-frame0-craw2-t4-s60.encode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-craw2-t4-s60.encode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-craw2-t4-s60.encode.thermal.txt 2>&1
snapshot > results/take0-frame0-craw2-t4-s60.decode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw2 4 decode payload.bin 5 60 1 > results/take0-frame0-craw2-t4-s60.decode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-craw2-t4-s60.decode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-craw2-t4-s60.decode.thermal.txt 2>&1
echo '[123/130] take0-frame0-craw3-t4-s60'
snapshot > results/take0-frame0-craw3-t4-s60.encode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw3 4 encode payload.bin 5 60 1 > results/take0-frame0-craw3-t4-s60.encode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-craw3-t4-s60.encode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-craw3-t4-s60.encode.thermal.txt 2>&1
snapshot > results/take0-frame0-craw3-t4-s60.decode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw3 4 decode payload.bin 5 60 1 > results/take0-frame0-craw3-t4-s60.decode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-craw3-t4-s60.decode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-craw3-t4-s60.decode.thermal.txt 2>&1
echo '[124/130] take0-frame0-craw4-t4-s60'
snapshot > results/take0-frame0-craw4-t4-s60.encode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw4 4 encode payload.bin 5 60 1 > results/take0-frame0-craw4-t4-s60.encode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-craw4-t4-s60.encode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-craw4-t4-s60.encode.thermal.txt 2>&1
snapshot > results/take0-frame0-craw4-t4-s60.decode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 craw4 4 decode payload.bin 5 60 1 > results/take0-frame0-craw4-t4-s60.decode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-craw4-t4-s60.decode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-craw4-t4-s60.decode.thermal.txt 2>&1
echo '[125/130] take0-frame0-jxl-e1-mosaic-t4-s60'
snapshot > results/take0-frame0-jxl-e1-mosaic-t4-s60.encode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-mosaic 4 encode payload.bin 5 60 1 > results/take0-frame0-jxl-e1-mosaic-t4-s60.encode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e1-mosaic-t4-s60.encode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e1-mosaic-t4-s60.encode.thermal.txt 2>&1
snapshot > results/take0-frame0-jxl-e1-mosaic-t4-s60.decode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-mosaic 4 decode payload.bin 5 60 1 > results/take0-frame0-jxl-e1-mosaic-t4-s60.decode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e1-mosaic-t4-s60.decode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e1-mosaic-t4-s60.decode.thermal.txt 2>&1
echo '[126/130] take0-frame0-jxl-e1-planes-t4-s60'
snapshot > results/take0-frame0-jxl-e1-planes-t4-s60.encode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-planes 4 encode payload.bin 5 60 1 > results/take0-frame0-jxl-e1-planes-t4-s60.encode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e1-planes-t4-s60.encode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e1-planes-t4-s60.encode.thermal.txt 2>&1
snapshot > results/take0-frame0-jxl-e1-planes-t4-s60.decode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e1-planes 4 decode payload.bin 5 60 1 > results/take0-frame0-jxl-e1-planes-t4-s60.decode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e1-planes-t4-s60.decode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e1-planes-t4-s60.decode.thermal.txt 2>&1
echo '[127/130] take0-frame0-jxl-e2-mosaic-t4-s60'
snapshot > results/take0-frame0-jxl-e2-mosaic-t4-s60.encode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-mosaic 4 encode payload.bin 5 60 1 > results/take0-frame0-jxl-e2-mosaic-t4-s60.encode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e2-mosaic-t4-s60.encode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e2-mosaic-t4-s60.encode.thermal.txt 2>&1
snapshot > results/take0-frame0-jxl-e2-mosaic-t4-s60.decode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-mosaic 4 decode payload.bin 5 60 1 > results/take0-frame0-jxl-e2-mosaic-t4-s60.decode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e2-mosaic-t4-s60.decode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e2-mosaic-t4-s60.decode.thermal.txt 2>&1
echo '[128/130] take0-frame0-jxl-e2-planes-t4-s60'
snapshot > results/take0-frame0-jxl-e2-planes-t4-s60.encode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-planes 4 encode payload.bin 5 60 1 > results/take0-frame0-jxl-e2-planes-t4-s60.encode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e2-planes-t4-s60.encode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e2-planes-t4-s60.encode.thermal.txt 2>&1
snapshot > results/take0-frame0-jxl-e2-planes-t4-s60.decode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e2-planes 4 decode payload.bin 5 60 1 > results/take0-frame0-jxl-e2-planes-t4-s60.decode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e2-planes-t4-s60.decode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e2-planes-t4-s60.decode.thermal.txt 2>&1
echo '[129/130] take0-frame0-jxl-e3-mosaic-t4-s60'
snapshot > results/take0-frame0-jxl-e3-mosaic-t4-s60.encode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-mosaic 4 encode payload.bin 5 60 1 > results/take0-frame0-jxl-e3-mosaic-t4-s60.encode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e3-mosaic-t4-s60.encode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e3-mosaic-t4-s60.encode.thermal.txt 2>&1
snapshot > results/take0-frame0-jxl-e3-mosaic-t4-s60.decode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-mosaic 4 decode payload.bin 5 60 1 > results/take0-frame0-jxl-e3-mosaic-t4-s60.decode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e3-mosaic-t4-s60.decode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e3-mosaic-t4-s60.decode.thermal.txt 2>&1
echo '[130/130] take0-frame0-jxl-e3-planes-t4-s60'
snapshot > results/take0-frame0-jxl-e3-planes-t4-s60.encode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-planes 4 encode payload.bin 5 60 1 > results/take0-frame0-jxl-e3-planes-t4-s60.encode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e3-planes-t4-s60.encode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e3-planes-t4-s60.encode.thermal.txt 2>&1
snapshot > results/take0-frame0-jxl-e3-planes-t4-s60.decode.thermal.txt 2>&1
./craw_compare measure take0-frame0.raw 4080 2040 10 2 jxl-e3-planes 4 decode payload.bin 5 60 1 > results/take0-frame0-jxl-e3-planes-t4-s60.decode.json &
worker=$!
while kill -0 "$worker" 2>/dev/null; do snapshot >> results/take0-frame0-jxl-e3-planes-t4-s60.decode.thermal.txt 2>&1; sleep 5; done
wait "$worker"
snapshot >> results/take0-frame0-jxl-e3-planes-t4-s60.decode.thermal.txt 2>&1
echo COMPLETE
