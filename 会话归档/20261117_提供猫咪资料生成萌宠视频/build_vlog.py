# -*- coding: utf-8 -*-
"""把 8 条猫咪 Vlog 视频 + 8 段可爱慵懒配音拼成一支完整成片。
- 每段视频放慢到与配音时长一致（慢动作契合慵懒风格，声画同步）
- 烧录与旁白同步的中文字幕（微软雅黑，白字黑描边）
- 片头标题 + 片尾落版
"""
import os, sys, json, subprocess, glob, shutil

BASE = os.path.dirname(os.path.abspath(__file__))
os.chdir(BASE)

# ---------- 1. 定位 ffmpeg ----------
def find_bin(names):
    cands = []
    for root, dirs, files in os.walk(BASE):
        for n in names:
            if n in files:
                cands.append(os.path.join(root, n))
    return cands[0] if cands else None

ffmpeg = find_bin(["ffmpeg.exe"])
ffprobe = find_bin(["ffprobe.exe"])
if not ffmpeg or not ffprobe:
    # 尝试从 zip 解压
    zips = glob.glob(os.path.join(BASE, "ffmpeg*.zip"))
    if zips:
        print("extracting", zips[0])
        shutil.unpack_archive(zips[0], BASE)
        ffmpeg = find_bin(["ffmpeg.exe"])
        ffprobe = find_bin(["ffprobe.exe"])
if not ffmpeg or not ffprobe:
    sys.exit("ERROR: ffmpeg/ffprobe not found")
print("FFMPEG:", ffmpeg)
print("FFPROBE:", ffprobe)

def probe(path):
    out = subprocess.check_output([ffprobe, "-v", "error", "-print_format", "json",
                                   "-show_entries", "format=duration:stream=width,height,codec_type",
                                   path], text=True)
    return json.loads(out)

# ---------- 2. 探测素材 ----------
vids = [f"vid_s{i}.mp4" for i in range(1, 9)]
vos = [f"vo_s{i}.mp3" for i in range(1, 9)]
vinfo = [probe(v) for v in vids]
ainfo = [probe(a) for a in vos]
vdur = [float(x["format"]["duration"]) for x in vinfo]
adur = [float(x["format"]["duration"]) for x in ainfo]
W = vinfo[0]["streams"][0]["width"]
H = vinfo[0]["streams"][0]["height"]
print("VIDEO size:", W, "x", H)
print("VIDEO durs:", [round(d, 2) for d in vdur])
print("AUDIO durs:", [round(d, 2) for d in adur])

# ---------- 3. 时间轴：每段时长 = 配音时长 + 0.5s 呼吸 ----------
seg_dur = [max(round(d + 0.5, 2), 4.2) for d in adur]
starts = []
t = 0.0
for d in seg_dur:
    starts.append(t)
    t += d
TOTAL = t
print("SEG durs:", seg_dur)
print("TOTAL:", round(TOTAL, 2), "s")

# ---------- 4. 生成 ASS 字幕 ----------
subs = [
    "救命——早八还有十分钟！",
    "再躺五分钟……就五分钟……",
    "镜子里的这位……谁啊？",
    "到！……啊？点的是谁？",
    "干饭人，干饭魂！这盘我能吃三碗饭。",
    "我就买了个……手机壳？",
    "我在学习，真的。（小声）别看我。",
    "今日任务：吃饭✓摸鱼✓快乐猫✓\\N早八？明天再说。",
]
def ts(sec):
    h = int(sec // 3600); m = int(sec % 3600 // 60); s = sec % 60
    return f"{h}:{m:02d}:{s:05.2f}"

ass = []
ass.append("[Script Info]")
ass.append("ScriptType: v4.00+")
ass.append("PlayResX: {w}".format(w=W))
ass.append("PlayResY: {h}".format(h=H))
ass.append("WrapStyle: 2")
ass.append("ScaledBorderAndShadow: yes")
ass.append("")
ass.append("[V4+ Styles]")
ass.append("Format: Name,Fontname,Fontsize,PrimaryColour,SecondaryColour,OutlineColour,BackColour,Bold,Italic,Underline,StrikeOut,ScaleX,ScaleY,Spacing,Angle,BorderStyle,Outline,Shadow,Alignment,MarginL,MarginR,MarginV,Encoding")
# 白字、黑描边、轻微阴影，底部居中(Alignment=2)
ass.append("Style: CN,Microsoft YaHei,42,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,1,2,40,40,150,1")
# 片头标题 居中大号
ass.append("Style: TITLE,Microsoft YaHei,64,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,2,0,1,4,2,5,30,30,30,1")
ass.append("")
ass.append("[Events]")
ass.append("Format: Layer,Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text")
# 片头标题（前 2.2 秒）
ass.append(f"Dialogue: 0,{ts(0.2)},{ts(2.2)},TITLE,,0,0,0,,猫猫的早八日记")
for i, txt in enumerate(subs):
    st = starts[i] + 0.25
    en = min(starts[i] + adur[i] + 0.15, starts[i] + seg_dur[i] - 0.05)
    if i == 7:
        en = min(en, TOTAL - 2.0)  # 最后一句提前收，留出片尾落版
    ass.append(f"Dialogue: 0,{ts(st)},{ts(en)},CN,,0,0,0,,{txt}")
# 片尾落版
ass.append(f"Dialogue: 1,{ts(TOTAL-1.9)},{ts(TOTAL-0.1)},TITLE,,0,0,0,,— 喵 生 圆 满 —")
with open("sub.ass", "w", encoding="utf-8") as f:
    f.write("\n".join(ass))
print("sub.ass written")

# ---------- 5. 构建 filter_complex ----------
fc = []
for i in range(8):
    ratio = seg_dur[i] / vdur[i]
    fc.append(f"[{i}:v]setpts={ratio:.6f}*PTS,setsar=1,fps=30,format=yuv420p[v{i}]")
fc.append("".join(f"[v{i}]" for i in range(8)) + f"concat=n=8:v=1:a=0[vc]")
for i in range(8):
    delay = int((starts[i] + 0.2) * 1000)
    fc.append(f"[{8+i}:a]adelay={delay}|{delay},aresample=48000[a{i}]")
fc.append("".join(f"[a{i}]" for i in range(8)) + "amix=inputs=8:normalize=0:duration=longest,alimiter=limit=0.95[ac]")
# 字幕路径转义（Windows 盘符冒号）
ass_path = os.path.join(BASE, "sub.ass").replace("\\", "/").replace(":", "\\:")
fc.append(f"[vc]ass='{ass_path}'[vout]")
filter_script = ";\n".join(fc)
with open("filter.txt", "w", encoding="utf-8") as f:
    f.write(filter_script)

inputs = []
for v in vids: inputs += ["-i", v]
for a in vos: inputs += ["-i", a]

cmd = [ffmpeg, "-y"] + inputs + [
    "-filter_complex_script", "filter.txt",
    "-map", "[vout]", "-map", "[ac]",
    "-t", f"{TOTAL:.2f}",
    "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
    "-c:a", "aac", "-b:a", "192k", "-ar", "48000",
    "-movflags", "+faststart",
    "cat_vlog_final.mp4",
]
print("RUNNING ffmpeg...")
res = subprocess.run(cmd, text=True, capture_output=True)
if res.returncode != 0:
    print(res.stderr[-4000:])
    sys.exit("ERROR: ffmpeg failed")
print("DONE:", os.path.join(BASE, "cat_vlog_final.mp4"))
print("SIZE:", round(os.path.getsize("cat_vlog_final.mp4")/1024/1024, 1), "MB")
