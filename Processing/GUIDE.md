How To Run Processing on Luminant Display
=========================================

It is highly recommended that you are running Processing 2.1.1 or later.
For the EnhancedMovie2Serial, if running on Windows OS it works on Processing 2.0.3, 2.1, and 2.1.2.  
The other versions of Processing have issues with Java and GStreamer.
Read about it here:
http://forum.processing.org/two/discussion/2716/windows-8-video-capture-issue/p1


This repository has some fun things to run on Luminant Display.
You need to have VideoDisplay all ready programmed to the Teensys.
All Teensys need to be programmed individually, pin 12 (Frame Sync) will take care of the rest
This is provided with the OctoWS2811 library in the Ardunio IDE examples.
Link: https://www.pjrc.com/teensy/td_libs_OctoWS2811.html


Here is the configuration of the code to send out to the Teensys.
The resolution of the display is 32x60 pixels and runs 2 Teensy 3.1.
It is important to note the orientation of the display (look at it): 
1) The Teensys are on the left handside
2) Power input is on the right side

For two Teensys, the LED width and height on the Luminant Display are defined as:

#define LED_WIDTH      60   // number of LEDs horizontally
#define LED_HEIGHT     16   // number of LEDs vertically (must be multiple of 8)
#define LED_LAYOUT     0    // 0 = even rows left->right, 1 = even rows right->left

For configuring the video, use the following:
(Make sure to comment the top or bottom one depending on the Teensy you are going to program - choose COM port)

//Teensy #1 (Top one)
#define VIDEO_XOFFSET  0
#define VIDEO_YOFFSET  0     // display upper half of video
#define VIDEO_WIDTH    100
#define VIDEO_HEIGHT   50

//Teensy #2 (Bottom one)
#define VIDEO_XOFFSET  0
#define VIDEO_YOFFSET  50    // display lower half of video
#define VIDEO_WIDTH    100
#define VIDEO_HEIGHT   50


Once VideoDisplay.ino has been programmed to the two Teensys using this configuration, there is not need to program them again.
Processing will take care of everything else on the PC and send out the data the Teensys.


Good luck and have fun!
