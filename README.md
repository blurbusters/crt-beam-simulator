### *UPDATE Nov 2025: [New TestUFO Demo of CRT Simulator](https://testufo.com/crt)*

# Introduction

This is the genesis of a CRT temporal simulation shader, created by Mark Rejhon (@BlurBusters) and Timothy Lottes (@NOTimothyLottes).

Yes, it successfully reduces display motion blur, if configured correctly (see HOWTO at bottom).

See the comments at the top of the HLSL or GLSL shader file.

![Image](https://blurbusters.com/wp-content/uploads/2024/12/crt-simulation-animated.gif) 

Article at [www.blurbusters.com/crt](https://www.blurbusters.com/crt), also reported on [TechSpot](https://www.techspot.com/news/106111-gpu-based-shader-simulates-motion-clarity-classic-crt.html) and [TomsHardware](https://www.tomshardware.com/monitors/blur-busters-releases-authentic-crt-simulator-shader-for-high-refresh-oled-and-lcd-screens-240-hz-oled-recommended-for-the-best-experience?utm_campaign=socialflow&utm_medium=social&utm_source=twitter.com#xenforo-comments-3866757)! Shared to both [BlueSky](https://bsky.app/profile/blurbusters.com/post/3ldz4u6kovs2v) and [X.com](https://x.com/BlurBusters/status/1871340328965533777).

View online:

- *NEW!* TestUFO 3.0: [CRT Electron Beam Simulator on TestUFO](https://testufo.com/crt) (Easier than ShaderToy, auto-syncs to your Hz).
- Shadertoy Realtime Demo: [www.shadertoy.com/view/XfKfWd](https://www.shadertoy.com/view/XfKfWd) (Quit all apps and tabs; browsers stutters a lot)

Problems? Erratic flicker? Banding? See [HOWTO: Solutions To Known Issues](https://github.com/blurbusters/crt-beam-simulator/issues/4)

- If this flickers more than BFI, you have a settings problem or display problem, fix it first.
- Version 2 of this algorithm will come in early 2025 that will reduce artifacts (banding, color ghosting) via additional adjustments.
- For banding fix, gamma fix, chroma ghosting fix, and flicker fix, see HOWTO at https://github.com/blurbusters/crt-beam-simulator/issues/4
- Buying a new display?  More native:simulated Hz ratio the merrier.  OLEDs tends work much better with this algorithm, if you don't have any black/white levels clipping issues. Avoid FALD/localdimming unless it is a zero-latency FALD layer scanout perfectly in phase with LCD scanout.
  - 120Hz modern display can reduce motion blur up to 50% for 60fps content
  - 240Hz modern display can reduce motion blur up to 75% for 60fps content
  - 480Hz modern display can reduce motion blur up to 87.5% for 60fps content  
- Some local dimming panels (FALD, MiniLED) has problems with this algorithm due to backlight lagging behind panel.
- Apple: Shadertoy stutters more on Mac than iPhone/iPad - MacOS browsers (all of them) stutters more; even a lowly iPhone 11 thru 14 stutters much less than MacBook M4
- For 120Hz Apple Safari via WebGL/shadertoy, set "Prefer Page Rendering Updates Near 60fps" to OFF in Developer Flags of Safari, see screenshots on either [Twitter/X](https://www.twitter.com/TechLiandr/status/1805472820018778468) or [Google](https://www.google.com/search?q=iPhone+Prefer+Page+Rendering+Updates+Near+60fps&udm=2) for instructions.

# EDIT NOV 2025: New Software Implementing CRT Simulator

- TestUFO: CRT Simulator Demo
  https://testufo.com/crt
- RetroArch: Multiplatform emulator, enable subframe shaders:  
  https://www.libretro.com/index.php/retroarch-first-program-to-support-blurbusters-crt-beam-racing-simulator-shader/
- Vint Video Player (steam): Play video files with either CRT, or BFI, or interpolation (RIFE 'AI' neural network)"
  https://store.steampowered.com/app/3448910/Vint_Realtime_Video_Interpolation_and_CRT_Emulation/
- WibbleWobbleCore: Creates a window to a virtual world / 3D stereoscopic glasses
  https://github.com/PHARTGAMES/WibbleWobbleCore
- ShaderGlass: Work in progress as of August 2025:
  https://github.com/mausimus/ShaderGlass/pull/193
