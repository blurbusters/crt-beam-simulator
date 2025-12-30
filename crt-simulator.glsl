// Update December 2025:
// Now available on TestUFO - https://testufo.com/crt
// Now available for Windows Desktop - https://github.com/mausimus/ShaderBeam
//
// From Shadertoy https://www.shadertoy.com/view/XfKfWd
// - Improved versions coming in 2026
// - See accompanying article https://blurbusters.com/crt
// - To study more about display science & physics, see Research Portal https://blurbusters.com/area51

#ifdef NOT_SHADERTOY
// We include these definitions to assist other environments (untested)
uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iTime;                 // shader playback time (in seconds)
uniform float     iTimeDelta;            // render time (in seconds)
uniform float     iFrameRate;            // shader frame rate
uniform int       iFrame;                // shader playback frame
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;             // input channel 0
uniform sampler2D iChannel1;             // input channel 1
uniform sampler2D iChannel2;             // input channel 2
uniform sampler2D iChannel3;             // input channel 3
uniform vec4      iDate;                 // (year, month, day, time in seconds)
#endif

/*********************************************************************************************************************/
//
//                     Blur Busters CRT Beam Simulator BFI
//                       With Seamless Gamma Correction
//
//         From Blur Busters Area 51 Display Science, Research & Engineering
//                      https://www.blurbusters.com/area51
//
//             The World's First Realtime Blur-Reducing CRT Simulator
//       Best for 60fps on 240-480Hz+ Displays, Still Works on 120Hz+ Displays
//                 Original Version 2022. Publicly Released 2024.
//
// CREDIT: Teamwork of Mark Rejhon @BlurBusters & Timothy Lottes @NOTimothyLottes
// Gamma corrected CRT simulator in a shader using clever formula-by-scanline trick
// (easily can generate LUTs, for other workflows like FPGAs or Javascript)
// - @NOTimothyLottes provided the algorithm for per-pixel BFI (Variable MPRT, higher MPRT for bright pixels)
// - @BlurBusters provided the algorithm for the CRT electron beam (2022, publicly released for first time)
//
// Contact Blur Busters for help integrating this in your product (emulator, fpga, filter, display firmware, video processor)
//
// This new algorithm has multiple breakthroughs:
//
// - Seamless; no banding*!  (*Monitor/OS configuration: SDR=on, HDR=off, ABL=off, APL=off, gamma=2.4)
// - Phosphor fadebehind simulation in rolling scan.
// - Works on LCDs and OLEDs.
// - Variable per-pixel MPRT. Spreads brighter pixels over more refresh cycles than dimmer pixels.
// - No image retention on LCDs or OLEDs.
// - No integer divisor requirement. Recommended but not necessary (e.g. 60fps 144Hz works!)
// - Gain adjustment (less motion blur at lower gain values, by trading off brightness)
// - Realtime (for retro & emulator uses) and slo-mo modes (educational)
// - Great for softer 60Hz motion blur reduction, less eyestrain than classic 60Hz BFI/strobe.
// - Algorithm can be ported to shader and/or emulator and/or FPGA and/or display firmware.
//
// For best real time CRT realism:
//
// - Reasonably fast performing GPU (many integrated GPUs are unable to keep up)
// - Fastest GtG pixel response (A settings-modified OLED looks good with this algorithm)
// - As much Hz per CRT Hz! (960Hz better than 480Hz better than 240Hz)
// - Integer divisors are still better (just not mandatory)
// - Brightest SDR display with linear response (no ABL, no APL), as HDR boost adds banding
//     (unless you can modify the firmware to make it linear brightness during a rolling scan)
//
// *** IMPORTANT ***
// *** DISPLAY REQUIREMENTS ***
//
// - Best for gaming LCD or OLED monitors with fast pixel response.
// - More Hz per simulated CRT Hz is better (240Hz, 480Hz simulates 60Hz tubes more accurately than 120Hz).
// - OLED (SDR mode) looks better than LCD, but still works on LCD
// - May have minor banding with very slow GtG, asymmetric-GtG (VA LCDs), or excessively-overdriven.
// - Designed for sample & hold displays with excess refresh rate (LCDs and OLEDs);
//     Not intended for use with strobed or impulsed displays. Please turn off your displays' BFI/strobing.
//     This is because we need 100% software control of the flicker algorithm to simulate a CRT beam.
//
// SDR MODE RECOMMENDED FOR NOW (Due to predictable gamma compensation math)
//
// - Best results occur on display configured to standard SDR gamma curve and ABL/APL disabled to go 100% bandfree
// - Please set your display gamma to 2.2 or 2.4, turn off ABL/APL in display settings, and set your OLED to SDR mode.  
// - Will NOT work well with some FALD and MiniLED due to backlight lagbehind effects.
// - Need future API access to OLED ABL/ABL algorithm to compensate for OLED ABL/APL windowing interference with algorithm.
// - This code is heavily commented because of the complexity of the algorithm.
//
/*********************************************************************************************************************/
//
// MIT License
// 
// Copyright 2024 Mark Rejhon (@BlurBusters) & Timothy Lottes (@NOTimothyLottes)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
/*********************************************************************************************************************/

//------------------------------------------------------------------------------------------------
// Constants Definitions

// Play with the documented constants!
// - REALTIME: Use FRAMES_PER_HZ=4 for 240Hz and FRAMES_PER_HZ=8 for 480Hz, to simulate a 60Hz tube in realtime
// - SLOMO: Use crazy large FRAMES_PER_HZ numbers to watch a CRT tube like a slo-motion video. Try FRAMES_PER_HZ=100!
// - FRAMESTEP: Use low frame rates to inspect frames.  Try FRAMES_PER_HZ=8 and FPS_DIVISOR=0.02! 
// All are floats (keep a .0 for integers)

#define MOTION_SPEED    10.0

  // Ratio of native Hz per CRT Hz.  More native Hz per CRT Hz simulates CRT butter.
  //   - Use 4.0 for 60fps at 240Hz realtime.
  //   - Use 2.4 for 60fps at 144Hz realtime.
  //   - Use 2.75 for 60fps at 165Hz realtime.
  //   - Use ~100 for super-slo-motion.
  //   - Best to keep it integer divisor but not essential (works!)
#define FRAMES_PER_HZ   4.0

  // Your display's gamma value. Necessary to prevent horizontal-bands artifacts.
#define GAMMA           2.4

  // Brightness-vs-motionblur tradeoff for bright pixel.
  //   - Defacto simulates fast/slow phosphor. 
  //   - 1.0 is unchanged brightness (same as non-CRT, but no blur reduction for brightest pixels, only for dimmer piels).
  //   - 0.5 is half brightness spread over fewer frames (creates lower MPRT persistence for darker pixels).
  //   - ~0.7 recommended for 240Hz+, ~0.5 recommended for 120Hz due to limited inHz:outHz ratio.
#define GAIN_VS_BLUR    0.7

  // Splitscreen versus mode for comparing to non-CRT-simulated
#define SPLITSCREEN     1        // 1 to enable splitscreen to compare to non-CRT, 0 to disable splitscreen
#define SPLITSCREEN_X   0.50     // For user to compare; horizontal splitscreen percentage (0=verticals off, 0.5=left half, 1=full sim).
#define SPLITSCREEN_Y   0.00     // For user to compare; vertical splitscreen percentage (0=horizontal off, 0.5=bottom half, 1=full sim).
#define SPLITSCREEN_BORDER_PX 2  // Splitscreen border thickness in pixels
#define SPLITSCREEN_MATCH_BRIGHTNESS 1    // 1 to match brightness of CRT, 0 for original brightness of original frame

  // Reduced frame rate mode
  //   - This can be helpful to see individual CRT-simulated frames better (educational!)
  //   - 1.0 is framerate=Hz, 0.5 is framerate being half of Hz, 0.1 is framerate being 10% of real Hz.
#define FPS_DIVISOR     1.0    // Slow down or speed up the simulation

  // LCD SAVER SYSTEM
  //   - Prevents image retention from BFI interfering with LCD voltage polarity inversion algorithm
  //   - When LCD_ANTI_RETENTION is enabled:
  //     - Automatically prevents FRAMES_PER_HZ from remaining an even integer by conditionally adding a slew float.
  //     - FRAMES_PER_HZ 2 becomes 2.001, 4 becomes 4.001, and 6 becomes 6.001, etc.  
  //     - Scientific Reason: https://forums.blurbusters.com/viewtopic.php?t=7539 BFI interaction with LCD voltage polarity inversion 
  //     - Known Side effect: You've decoupled the CRT simulators' own VSYNC from the real displays' VSYNC.  But magically, there's no tearing artifacts :-)
  //     - Not needed for OLEDs, safe to turn off, but should be ON by default to be foolproof.
#define LCD_ANTI_RETENTION  true
#define LCD_INVERSION_COMPENSATION_SLEW 0.001

  // CRT SCAN DIRECTION. Can be useful to counteract an OS rotation of your display
  //   - 0 global refresh, good to eliminate banding (best at FRAMES_PER_HZ >= 3)
  //   - 1 default (top to bottom), recommended
  //   - 2 reverse (bottom to top)
  //   - 3 portrait (left to right)
  //   - 4 reverse portrait (right to left)
#define SCAN_DIRECTION 1

//-------------------------------------------------------------------------------------------------
// Utility Macros

#define clampPixel(a) clamp(a, vec3(0.0), vec3(1.0))

// Selection Function: Returns 'b' if 'p' is true, else 'a'.
float SelF1(float a, float b, bool p) { return p ? b : a; }

#define IS_INTEGER(x) (floor(x) == x)
#define IS_EVEN_INTEGER(x) (IS_INTEGER(x) && IS_INTEGER(x/2.0))

// LCD SAVER (prevent image retention)
// Adds a slew to FRAMES_PER_HZ when ANTI_RETENTION is enabled and FRAMES_PER_HZ is an exact even integer.
// We support non-integer FRAMES_PER_HZ, so this is a magically convenient solution
const float EFFECTIVE_FRAMES_PER_HZ = (LCD_ANTI_RETENTION && IS_EVEN_INTEGER(float(FRAMES_PER_HZ))) 
                                      ? float(FRAMES_PER_HZ) + LCD_INVERSION_COMPENSATION_SLEW 
                                      : float(FRAMES_PER_HZ);

//-------------------------------------------------------------------------------------------------
// sRGB Encoding and Decoding Functions, to gamma correct/uncorrect

// Encode linear color to sRGB. (applies gamma curve)
float linear2srgb(float c){
    vec3 j = vec3(0.0031308 * 12.92, 12.92, 1.0 / GAMMA);
    vec2 k = vec2(1.055, -0.055);
    return clamp(j.x, c * j.y, pow(c, j.z) * k.x + k.y);
}
vec3 linear2srgb(vec3 c){
  return vec3(linear2srgb(c.r), linear2srgb(c.g), linear2srgb(c.b));
}

// Decode sRGB color to linear. (undoes gamma curve)
float srgb2linear(float c){
    vec3 j = vec3(0.04045, 1.0 / 12.92, GAMMA);
    vec2 k = vec2(1.0 / 1.055, 0.055 / 1.055);
    return SelF1(c * j.y, pow(c * k.x + k.y, j.z), c > j.x);
}
vec3 srgb2linear(vec3 c){
  return vec3(srgb2linear(c.r), srgb2linear(c.g), srgb2linear(c.b));
}

//------------------------------------------------------------------------------------------------
// Gets pixel from the unprocessed framebuffer.
//
// Placeholder for accessing the 3 trailing unprocessed frames (for simulating CRT on)
//   - Frame counter represents simulated CRT refresh cycle number.
//   - Always assign numbers to your refresh cycles. For reliability, keep a 3 frame trailing buffer.
//   - We index by frame counter because it is necessary for blending adjacent CRT refresh cycles, 
//      for the phosphor fade algorithm on old frame at bottom, and new frames at top.
//   - Framebuffer to retrieve from should be unscaled (e.g. original game resolution or emulator resolution).
//   - (If you do optional additional processing such as scaling+scanlines+masks, do it post-processing after this stage)
// DEMO version:
//   - We cheat by horizontally shifting shifted pixel reads from a texture.
// PRODUCTION version:
//   - Put your own code to retrieve a pixel from your series of unprocessed frame buffers.
//     IMPORTANT: For integration into firmware/software/emulators/games, this must be executed 
//     at refresh cycle granularity independently of your underlying games' framerate! 
//     There are three independent frequencies involved:
//     - Native Hz (your actual physical display)
//     - Simulated CRT Hz (Hz of simulated CRT tube)
//     - Underlying content frame rate (this shader doesn't need to know; TODO: Unless you plan to simulate VRR-CRT)
//
vec3 getPixelFromOrigFrame(vec2 uv, float getFromHzNumber, float currentHzCounter)
{

    // We simulate missing framebuffers (for accurate real world case)
    if ((getFromHzNumber > currentHzCounter) ||          // Frame not rendered yet
        (getFromHzNumber < currentHzCounter - 2.0)) {    // Frame over 3 frames ago
        return vec3(0.0, 0.0, 0.0);
    }

    // Continuous horizontal shift depending on hzCounter
    float shiftAmount = MOTION_SPEED / 1000.0;
    float baseShift = fract(getFromHzNumber * shiftAmount);

    // We'll offset uv.x by baseShift, and round-off to screen coordinates to avoid seam artifacts
    float px = 1.0 / iResolution.x;
    uv.x = mod(uv.x + baseShift + px*0.1, 1.0) - px*0.1;

    // Sample texture with no mip (textureLod)
    vec4 c = textureLod(iChannel0, uv, 0.0);
    return c.rgb;
}

//-------------------------------------------------------------------------------------------------
// CRT Rolling Scan Simulation With Phosphor Fade + Brightness Redistributor Algorithm
//
// New variable 'per-pixel MPRT' algorithm that mimics CRT phosphor decay too.
// - We emit as many photons as possible as early as possible, and if we can't emit it all (e.g. RGB 255)
//   then we continue emitting in the next refresh cycle until we've hit our target (gamma-compensated).
// - This is a clever trick to keep CRT simulation brighter but still benefit motion clarity of most colors.
//   Besides, real CRT tubes behave roughly similar too! (overexcited phosphor take longer to decay)
// - This also concurrently produces a phosphor-fade style behavior.
// - Win-win!
//
// Parameters:
// - c2: total brightness * framesPerHz per channel.
// - crtRasterPos: normalized raster position [0..1] representing current scan line
// - phaseOffset: fractional start of the brightness interval [0..1] (0.0 at top, 1.0 at bottom).
// - framesPerHz: Number of frames per Hz. (Does not have to be integer divisible!)
//
vec3 getPixelFromSimulatedCRT(vec2 uv, float crtRasterPos, float crtHzCounter, float framesPerHz)
{
    // Get pixels from three consecutive refresh cycles
    vec3 pixelPrev2 = srgb2linear(getPixelFromOrigFrame(uv, crtHzCounter - 2.0, crtHzCounter));
    vec3 pixelPrev1 = srgb2linear(getPixelFromOrigFrame(uv, crtHzCounter - 1.0, crtHzCounter));
    vec3 pixelCurr  = srgb2linear(getPixelFromOrigFrame(uv, crtHzCounter,      crtHzCounter));

    vec3 result = vec3(0.0);

    // Compute "photon budgets" for all three cycles
    float brightnessScale = framesPerHz * GAIN_VS_BLUR;
    vec3 colorPrev2 = pixelPrev2 * brightnessScale;
    vec3 colorPrev1 = pixelPrev1 * brightnessScale;
    vec3 colorCurr  = pixelCurr  * brightnessScale;
      
#if SCAN_DIRECTION == 0
    float tubePos = 0.0;           // Global refresh
#elif SCAN_DIRECTION == 1
    float tubePos = (1.0 - uv.y);  // Top to bottom
#elif SCAN_DIRECTION == 2
    float tubePos = uv.y;          // Bottom to top
#elif SCAN_DIRECTION == 3
    float tubePos = uv.x;          // Left to right
#elif SCAN_DIRECTION == 4
    float tubePos = (1.0 - uv.x);  // Right to left
#endif

    // Process each color channel independently
    for (int ch = 0; ch < 3; ch++) 
    {
        // Get brightness lengths for all three cycles
        float Lprev2 = colorPrev2[ch];
        float Lprev1 = colorPrev1[ch];
        float Lcurr  = colorCurr[ch];
        
        if (Lprev2 <= 0.0 && Lprev1 <= 0.0 && Lcurr <= 0.0) {
            result[ch] = 0.0;
            continue;
        }
        
        // TODO: Optimize to use only 2 frames.
        // Unfortunately I need all 3 right now because if I only do 2,
        // I get artifacts at either top OR bottom edge (can't eliminate both)
        // What I may do is use a phase offset (e.g. input framebuffer chain
        // rotates forward in middle of emulated CRT Hz), as a workaround, and
        // see if that solves the problem and reduces the queue to 2.
        // (Will attempt later)

        // Convert normalized values to frame space
        float tubeFrame = tubePos * framesPerHz;
        float fStart = crtRasterPos * framesPerHz;
        float fEnd = fStart + 1.0;

        // Define intervals for all three trailing refresh cycles
        float startPrev2 = tubeFrame - framesPerHz;
        float endPrev2   = startPrev2 + Lprev2;

        float startPrev1 = tubeFrame;
        float endPrev1   = startPrev1 + Lprev1;

        float startCurr  = tubeFrame + framesPerHz; // Fix seam for top edge
        float endCurr    = startCurr + Lcurr;
        
        // Calculate overlaps for all three cycles
        #define INTERVAL_OVERLAP(Astart, Aend, Bstart, Bend) max(0.0, min(Aend, Bend) - max(Astart, Bstart))
        float overlapPrev2 = INTERVAL_OVERLAP(startPrev2, endPrev2, fStart, fEnd);
        float overlapPrev1 = INTERVAL_OVERLAP(startPrev1, endPrev1, fStart, fEnd);
        float overlapCurr  = INTERVAL_OVERLAP(startCurr,  endCurr,  fStart, fEnd);

        // Sum all overlaps for final brightness
        result[ch] = overlapPrev2 + overlapPrev1 + overlapCurr;
    }

    return linear2srgb(result);
}

//-------------------------------------------------------------------------------------------------
// Main Image Function
//
void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    // uv: Normalized coordinates ranging from (0,0) at the bottom-left to (1,1) at the top-right.
    vec2 uv = fragCoord / iResolution.xy;
    
    vec4 c = vec4(0.0, 0.0, 0.0, 1.0);

    //-------------------------------------------------------------------------------------------------
    // CRT beam calculations
    
    // Frame counter, which may be compensated by slo-mo modes (FPS_DIVISOR). Does not need to be integer divisible.
    float effectiveFrame = floor(float(iFrame) * FPS_DIVISOR);

    // Normalized raster position [0..1] representing current position of simulated CRT electron beam
    float crtRasterPos = mod(effectiveFrame, EFFECTIVE_FRAMES_PER_HZ) / EFFECTIVE_FRAMES_PER_HZ;

    // CRT refresh cycle counter
    float crtHzCounter = floor(effectiveFrame / EFFECTIVE_FRAMES_PER_HZ);

#if SPLITSCREEN == 1
    //-------------------------------------------------------------------------------------------------
    // Splitscreen processing

    // crtTube: Boolean indicating whether the current pixel is within the CRT-BFI region.
    // When splitscreen is off, apply CRT-BFI to entire screen
    bool crtArea = !((uv.x > SPLITSCREEN_X) && (uv.y > SPLITSCREEN_Y));

    // Calculate border regions (in pixels)
    float borderXpx = abs(fragCoord.x - SPLITSCREEN_X * iResolution.x);
    float borderYpx = abs(fragCoord.y - SPLITSCREEN_Y * iResolution.y);
    
    // Border only exists in the non-BFI region (x > SPLITSCREEN_X || y > SPLITSCREEN_Y)
    bool inBorderX = borderXpx < float(SPLITSCREEN_BORDER_PX) && uv.y > SPLITSCREEN_Y;
    bool inBorderY = borderYpx < float(SPLITSCREEN_BORDER_PX) && uv.x > SPLITSCREEN_X;
    bool inBorder = (SPLITSCREEN == 1) && (inBorderX || inBorderY);

    // We #ifdef the if statement away for shader efficiency (though this specific one didn't affect performance)
    if (crtArea) {
#endif

        //-----------------------------------------------------------------------------------------
        // Get CRT simulated version of pixel
        fragColor.rgb = getPixelFromSimulatedCRT(uv, crtRasterPos, crtHzCounter, EFFECTIVE_FRAMES_PER_HZ);

#if SPLITSCREEN == 1
    }
    else if (!inBorder) {
        fragColor.rgb = getPixelFromOrigFrame(uv, crtHzCounter, crtHzCounter);
#if SPLITSCREEN_MATCH_BRIGHTNESS == 1
        // Brightness compensation for unprocessed pixels through similar gamma-curve (match gamma of simulated CRT)
        fragColor.rgb = srgb2linear(fragColor.rgb) * GAIN_VS_BLUR;
        fragColor.rgb = clampPixel(linear2srgb(fragColor.rgb));
#endif
    }
#endif
}

//-------------------------------------------------------------------------------------------------
// Credits Reminder:
// Please credit BLUR BUSTERS & TIMOTHY LOTTE if this algorithm is used in your project/product.
// Hundreds of hours of research was done on related work that led to this algorithm.
//-------------------------------------------------------------------------------------------------
