# 猫咪大学生日常 Vlog · 8镜分镜脚本（修正版·猫为主角）

> 核心原则：**主角始终是真实的猫本身**（金渐层原型：虎斑纹、翠绿圆眼、白色嘴周胸口、圆脸毛茸茸）。拟人化的是**叙事与镜头语言**（大学生一天的 Vlog），**不是外形**。所有提示词均须排除 human / anthropomorphic。

---

## 固定角色描述（每个 Prompt 必带，保证同一只猫）

```
the SAME golden British Shorthair cat from the reference: round face, large round emerald green eyes, amber-golden tabby fur with darker markings, white muzzle and white chest, dense fluffy coat. A real cat, not a person.
```

**统一负面词（Negative）**
```
human, person, human face, human body, anthropomorphic, cartoon, anime, illustration, different cat, changed fur color, distorted face, extra limbs
```

**统一规格**：竖屏 9:16；真人 Vlog 质感、暖调、低对比、轻微胶片颗粒；镜头开头鱼眼/超广角，之后手持跟拍、中景、特写、宿舍纪实感。

**参考图（保持一致性的 resource_id）**：`7e8c43c61050490185975cbe90297741`（猫主角基准图）。每次生成把它作为 reference 输入。

---

## 镜头1 · 早八惊醒（鱼眼钩子）✅已出图

- **时长**：3–4s ｜ **时间**：7:00 AM
- **画面**：鱼眼怼脸，猫在宿舍床上被闹钟惊醒，绿眼瞪圆，一只爪子伸出去拍闹钟。
- **镜头**：鱼眼超广角近景，边缘畸变，轻微手持抖动。
- **口播/字幕**：「救命——早八还有十分钟！」｜**音效**：急促闹钟声 + 被褥摩擦声
- **生图 Prompt**：
```
Using the reference image, keep the SAME golden British Shorthair cat EXACTLY as is: round face, large round emerald green eyes, amber-golden tabby fur, white muzzle and chest, dense fluffy coat. This is a real CAT, not a person. Fisheye extreme close-up vlog shot: the cat is startled awake on a dorm bed in the morning, green eyes wide open in surprise, one paw reaching toward a buzzing alarm clock on the pillow, messy bedding, warm morning light through window, slight lens distortion, candid vlog style. Photorealistic pet photography, 9:16 vertical, high detail. No human, no anthropomorphic body, no changed appearance.
```
- **生视频 Prompt**（以本镜生图为首帧）：
```
Fisheye close-up, the cat's eyes snap wider, paw presses down the alarm clock, ears twitch, bedding shifts slightly, alarm display stops blinking, slight handheld shake, warm morning light, 9:16 vertical, photorealistic.
```

## 镜头2 · 猫式赖床

- **时长**：3–4s ｜ **时间**：7:05 AM
- **画面**：猫在床上摊开四肢伸懒腰、翻个身，一脸"不想起"。
- **镜头**：第一人称手持俯拍，缓慢从俯视转到平视。
- **口播/字幕**：「再躺五分钟…就五分钟…」
- **生图 Prompt**：
```
[固定角色描述]. This is a real CAT, not a person. POV handheld overhead shot: the cat stretches lazily on a dorm bed with paws spread out, back arched slightly, eyes half-closed sleepily, cozy messy bedding, warm morning light, candid vlog aesthetic. Photorealistic pet photography, 9:16 vertical, high detail. No human, no anthropomorphic body.
```
- **生视频 Prompt**：
```
The cat stretches slowly, back arches, paws extend, then rolls over and blinks sleepily, natural lazy motion, handheld camera tilts from overhead to eye level, 9:16 vertical.
```

## 镜头3 · 洗漱间的迷茫

- **时长**：3s ｜ **时间**：7:20 AM
- **画面**：猫蹲在宿舍洗漱台前，呆呆看着水龙头流水 / 镜子里的自己。
- **镜头**：镜子反射中景，手持轻微晃动，冷光与暖调滤镜碰撞。
- **口播/字幕**：「镜子里的这位…谁啊？」
- **生图 Prompt**：
```
[固定角色描述]. This is a real CAT, not a person. Mirror reflection handheld shot: the cat sits in front of a dorm bathroom sink, staring blankly at its own reflection in the mirror, a faucet dripping water, bathroom tiles, fluorescent light mixed with warm tone, sleepy funny expression, candid vlog style. Photorealistic pet photography, 9:16 vertical, high detail. No human, no anthropomorphic body.
```
- **生视频 Prompt**：
```
The cat stares at the mirror, head tilts slowly, one paw touches the mirror surface, water drips, slight handheld shake, 9:16 vertical.
```

## 镜头4 · 教室"被点名"（反差笑点）

- **时长**：3–4s ｜ **时间**：10:00 AM
- **画面**：猫端坐在阶梯教室课桌上，原本眯眼发呆，突然耳朵一竖、瞪大眼回头。
- **镜头**：手持跟拍中景 → 快速推至脸部特写。
- **口播/字幕**：「到！……啊？点的是谁？」
- **生图 Prompt**：
```
[固定角色描述]. This is a real CAT, not a person. Handheld medium shot: the cat sits on a desk in a university lecture hall, daydreaming with half-closed eyes, then ears perk up and green eyes widen, looking toward the camera as if called on, textbooks and notebook on desk, classroom light, candid vlog style. Photorealistic pet photography, 9:16 vertical, high detail. No human, no anthropomorphic body.
```
- **生视频 Prompt**：
```
The cat's ears snap up, eyes widen, head turns quickly toward camera, tail flicks, camera pushes in to face close-up, handheld shake, 9:16 vertical.
```

## 镜头5 · 食堂干饭（情绪高点）✅已出图

- **时长**：3–4s ｜ **时间**：12:15 PM
- **画面**：猫坐在食堂餐桌前，面前一盘饭菜+冰饮，绿眼放光盯着食物。
- **镜头**：第一视角手持跟拍，食物特写切脸部特写，热气腾腾。
- **口播/字幕**：「干饭人，干饭魂！」
- **生图 Prompt**：
```
[固定角色描述]. This is a real CAT, not a person. Handheld POV vlog shot: the cat sits at a college cafeteria table with a food tray in front, green eyes bright and excited, looking at the food, warm bustling cafeteria light, a candid funny 'foodie' moment, slight camera shake feel. Photorealistic pet photography, 9:16 vertical, high detail. No human, no anthropomorphic body, no changed appearance.
```
- **生视频 Prompt**：
```
The cat leans toward the food, eyes fixed on the plate, nose twitches, one paw reaches toward the tray, camera shifts from food close-up to face, warm cafeteria light, 9:16 vertical.
```

## 镜头6 · 取快递的"社死"（笑点）

- **时长**：3–4s ｜ **时间**：3:30 PM
- **画面**：猫被一个比它大很多的纸箱挡住/压着，小短腿艰难往前挪。
- **镜头**：鱼眼超广角第一人称，夸张透视，行走晃动感。
- **口播/字幕**：「我就买了个……手机壳？」（配气喘）
- **生图 Prompt**：
```
[固定角色描述]. This is a real CAT, not a person. Fisheye wide-angle handheld POV: the cat struggles under an oversized cardboard box bigger than itself on the way back from a campus delivery station, only its face and paws visible, stacked parcels around, comedic exaggerated perspective, afternoon light, vlog style. Photorealistic pet photography, 9:16 vertical, high detail. No human, no anthropomorphic body.
```
- **生视频 Prompt**：
```
The cat waddles forward slowly under the big box, body swaying, paws stepping carefully, camera shakes with each step, fisheye distortion, 9:16 vertical.
```

## 镜头7 · 图书馆的"假装学习"

- **时长**：3–4s ｜ **时间**：7:00 PM
- **画面**：猫趴在图书馆摊开的书本上，假装看书，实则眯眼打盹 / 爪子扒拉笔。
- **镜头**：俯拍书本特写 → 切中景猫脸，安静纪实感。
- **口播/字幕**：「我在学习，真的。（小声）别看我。」
- **生图 Prompt**：
```
[固定角色描述]. This is a real CAT, not a person. Overhead then medium shot: the cat lies on an open textbook on a quiet library desk, pretending to 'study', eyes half-closed drowsily, one paw on a pen, warm library lamps, stacks of books, quiet atmosphere, candid vlog style. Photorealistic pet photography, 9:16 vertical, high detail. No human, no anthropomorphic body.
```
- **生视频 Prompt**：
```
The cat blinks slowly, paw nudges the pen off the page, head droops drowsily then lifts as if alerted, camera cuts from overhead to medium shot, warm library light, 9:16 vertical.
```

## 镜头8 · 宿舍躺平（首尾呼应收尾）✅已出图

- **时长**：4–5s ｜ **时间**：10:30 PM
- **画面**：猫四脚朝天摊在宿舍床上，绿眼睁大看镜头，配"今日清单已勾选"。
- **镜头**：鱼眼超广角低机位仰拍（呼应原图躺姿），轻微畸变。
- **口播/字幕**：「今日任务：吃饭✓ 摸鱼✓ 快乐猫✓ ……早八？明天再说。」
- **生图 Prompt**：
```
[固定角色描述]. This is a real CAT, not a person. Low-angle fisheye vlog shot: the cat lies sprawled on its back on a dorm bed with paws in the air in a relaxed goofy 'flopped' pose, green eyes wide, looking up at the camera, cozy messy dorm room at night with warm desk lamp light, candid funny vlog ending shot, slight lens distortion. Photorealistic pet photography, 9:16 vertical, high detail. No human, no anthropomorphic body, no changed appearance.
```
- **生视频 Prompt**：
```
The cat wiggles its paws in the air, tail gives a small flick, eyes blink slowly at camera, bedding shifts slightly, warm lamp light, fisheye distortion, 9:16 vertical.
```

---

## 生成流程建议

1. **先出8张关键帧图**（ImageToImage，参考图 resource_id `7e8c43c61050490185975cbe90297741`），确认画风与原型一致。
2. **再逐张图生视频**（ImagesToVideo / FirstFrameToVideo），以关键帧为首帧，动作更稳、角色更一致。
3. 每张图约 7 积分、每条 4s 视频约 60 积分；当前账户余额不足以完成全部视频。
4. Flova 不交付烧录字幕，口播文案作为创作约束，建议后期剪辑时手动添加卡点字幕。
5. 始终用固定角色描述 + 统一负面词，避免模型把猫拟人化或换脸换毛色。
