This is the genesis of a CRT temporal simulation shader, created by Mark Rejhon (@BlurBusters) and Timothy Lottes (@NOTimothyLottes).

See the comments at the top of the shader file.

![Image](https://blurbusters.com/wp-content/uploads/2024/12/crt-simulation-animated.gif)

Shared to both [BlueSky](https://bsky.app/profile/blurbusters.com/post/3ldz4u6kovs2v) and [X.com](https://x.com/BlurBusters/status/1871340328965533777)

Article at [www.blurbusters.com/crt](https://www.blurbusters.com/crt)

Shadertoy Realtime Demo: [www.shadertoy.com/view/XfKfWd](https://www.shadertoy.com/view/XfKfWd)

UPDATE: Thanks for the popularity!
- Version 2 of this algorithm will come in early 2025 that will reduce artifacts (banding, color ghosting) via additional adjustments.
- For now, try to use SDR mode instead of HDR mode, and configure your display and OS to Adobe sRGB (due to the gamma2linear->(crt-stuff)->linear2gamma that is hard to keep truly linear to Talbot Plateau Theorem).
- To reduce or eliminate your banding, calibrate your display levels via [TestUFO Black Levels (PLUGE)](https://testufo.com/blacklevels) and [TestUFO White Levels (Clipping)](https://testufo.com/whitelevels) test, before running the CRT simulator in a production application such as RetroArch.
- Also if you are using an older TN LCD, try to use odd-number native:simulated Hz ratios.  LCD's voltage-polarity inversion algorithms tend to play better with odd-ratios.
- OLEDs tends work much better with this algorithm, if you don't have any black/white levels clipping issues.
- Some local dimming panels (FALD, MiniLED) has problems with this algorithm due to backlight lagging behind panel.
- Apple: <b>Please fix your MacOS compositor</b>; MacOS browsers (all of them) stutters more; even a lowly iPhone 11 thru 14 stutters much less than MacBook M4
- For 120Hz iDevices, set "Prefer Page Rendering Updates Near 60fps" to OFF in Developer Flags of Safari.
