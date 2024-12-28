This is the genesis of a CRT temporal simulation shader, created by Mark Rejhon (@BlurBusters) and Timothy Lottes (@NOTimothyLottes).

See the comments at the top of the shader file.

![Image](https://blurbusters.com/wp-content/uploads/2024/12/crt-simulation-animated.gif)

Shared to both [BlueSky](https://bsky.app/profile/blurbusters.com/post/3ldz4u6kovs2v) and [X.com](https://x.com/BlurBusters/status/1871340328965533777)

Article at [www.blurbusters.com/crt](https://www.blurbusters.com/crt)

Shadertoy Realtime Demo: [www.shadertoy.com/view/XfKfWd](https://www.shadertoy.com/view/XfKfWd)

UPDATE: Thanks for the popularity!
- Version 2 of this algorithm will come in early 2025 that will reduce artifacts (banding, color ghosting) via additional adjustments.  For now, try to use SDR mode instead of HDR mode, and configure your display and OS to Adobe sRGB (due to the gamma2linear->(crt-stuff)->linear2gamma that is hard to keep truly linear to Talbot Plateau Theorem).  Then adjust your levels via [TestUFO Black Levels (PLUGE)](https://testufo.com/blacklevels) and [TestUFO White Levels (Clipping)](https://testufo.com/whitelevels) test, before running the CRT simulator in a production application such as RetroArch.  Also if you are using an older TN LCD, try to use odd-number native:simulated Hz ratios.  LCD's voltage-polarity inversion algorithms tend to play better with odd-ratios.  OLEDs work much better with this algorithm, if you don't have any black/white levels clipping issues.
