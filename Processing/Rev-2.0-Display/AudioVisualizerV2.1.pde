/*  Audio Visualizer with Processing and Minim
    Original source code by: Benjamin Farahmand
    Link: https://gist.github.com/benfarahmand/6902359#file-audio-visualizer-atomic-sprocket

    This program uses the computer's microphone to provide stunning audio visualizations that 
    is compatible with Luminant Display

    Enhancements and modifications made by Tian Zhang and JP Allport
    1) Added the ability to adjust display brightness
    2) Made compatible with OctoWS2811 with Mapped out resolution to match Rev 2.0 Luminant Display
    3) Code clean up
    4) Updated commenting
    
    Works on Processing 2.1.1+
    
    Designed for use with the OctoWS2811 library available at:
    http://www.pjrc.com/teensy/td_libs_OctoWS2811.html
*/

import ddf.minim.analysis.*;
import ddf.minim.*;
import processing.serial.*;
import java.awt.Rectangle;

float gamma = 1.7;

float brightness = 0.5;  //Adjust brightness from 0 to 1.0

int numPorts=0;  // the number of serial ports in use
int maxPorts=24; // maximum number of serial ports

Serial[] ledSerial = new Serial[maxPorts];     // each port's actual Serial port
Rectangle[] ledArea = new Rectangle[maxPorts]; // the area of the movie each port gets, in % (0-100)
boolean[] ledLayout = new boolean[maxPorts];   // layout of rows, true = even is left->right
PImage[] ledImage = new PImage[maxPorts];      // image sent to each port
int[] gammatable = new int[256];
int errorCount=0;
float framerate=0;

PGraphics pg;
PGraphics pgAux;
float Rad;

Minim minim;
AudioPlayer jingle;
FFT fft;
AudioInput in;
float[] angle;
float[] y, x;
 
void setup()
{
  //size(screen.width, screen.height, P3D);
  size(600,320,P3D);
  pg = createGraphics (width, height, P2D);
  String[] list = Serial.list();
  delay(20);
  println("Serial Ports List:");
  println(list);
  serialConfigure("COM11");  // change these to your port names (if on Linux use: /dev/ ; otherwise Windows type COM in.)
  serialConfigure("COM12");
  if (errorCount > 0) exit();
  for (int i=0; i < 256; i++) {
    gammatable[i] = (int)(pow((float)i / 255.0, gamma) * 255.0 + 0.5);
  }
  
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 2048, 192000.0);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  y = new float[fft.specSize()];
  x = new float[fft.specSize()];
  angle = new float[fft.specSize()];
  frameRate(240);
}
 
void draw()
{
  pg.beginDraw();
  pg.background(0);
  //background(0);
  fft.forward(in.mix);
  doubleAtomicSprocket();
  pg.endDraw();
  PImage img = pg.get();
  framerate++;
  if(framerate > 3)
  {
    framerate = 60;
    for (int i=0; i < numPorts; i++) {    
    // copy a portion of the movie's image to the LED image
    int xoffset = percentage(img.width, ledArea[i].x);
    int yoffset = percentage(img.height, ledArea[i].y);
    int xwidth =  percentage(img.width, ledArea[i].width);
    int yheight = percentage(img.height, ledArea[i].height);
    //println(ledArea[i].x,ledArea[i].y,ledArea[i].width,ledArea[i].height);
    ledImage[i].copy(img, xoffset, yoffset, xwidth, yheight,
                     0, 0, ledImage[i].width, ledImage[i].height);
    // convert the LED image to raw data
    byte[] ledData =  new byte[(ledImage[i].width * ledImage[i].height * 3) + 3];
    image2data(ledImage[i], ledData, ledLayout[i]);
    if (i == 0) {
      ledData[0] = '*';  // first Teensy is the frame sync master
      int usec = (int)((1000000.0 / framerate) * 0.75);
      ledData[1] = (byte)(usec);   // request the frame sync pulse
      ledData[2] = (byte)(usec >> 8); // at 75% of the frame time
    } else {
      ledData[0] = '%';  // others sync to the master board
      ledData[1] = 0;
      ledData[2] = 0;
    }
    // send the raw data to the LEDs  :-)
    ledSerial[i].write(ledData); 
  }
  }
}

//This is where the animation is drawn and can be configured here
void doubleAtomicSprocket() {
  noStroke();
  pushMatrix();
  translate(width/2, height/2);
  for (int i = 0; i < fft.specSize() ; i++) {
    y[i] = y[i] + fft.getBand(i)/100;
    x[i] = x[i] + fft.getFreq(i)/100;
    angle[i] = angle[i] + fft.getFreq(i)/2000;
    rotateX(sin(angle[i]/2));
    rotateY(cos(angle[i]/2));
    //    stroke(fft.getFreq(i)*2,0,fft.getBand(i)*2);
    fill(fft.getFreq(i)*2, 0, fft.getBand(i)*2);
    pushMatrix();
    translate((x[i]+50)%width/3, (y[i]+50)%height/3);
    box(fft.getBand(i)/20+fft.getFreq(i)/15);
    popMatrix();
  }
  popMatrix();
  pushMatrix();
  translate(width/2, height/2, 0);
  for (int i = 0; i < fft.specSize() ; i++) {
    y[i] = y[i] + fft.getBand(i)/1000;
    x[i] = x[i] + fft.getFreq(i)/1000;
    angle[i] = angle[i] + fft.getFreq(i)/100000;
    rotateX(sin(angle[i]/2));
    rotateY(cos(angle[i]/2));
    //    stroke(fft.getFreq(i)*2,0,fft.getBand(i)*2);
    fill(0, 255-fft.getFreq(i)*2, 255-fft.getBand(i)*2);
    pushMatrix();
    translate((x[i]+250)%width, (y[i]+250)%height);
    box(fft.getBand(i)/20+fft.getFreq(i)/15);
    popMatrix();
  }
  popMatrix();
}
 
void stop()
{
  // always close Minim audio classes when you finish with them
  jingle.close();
  minim.stop();
 
  super.stop();
}

// OctoWS2811 stuff
// image2data converts an image to OctoWS2811's raw data format.
// The number of vertical pixels in the image must be a multiple
// of 8.  The data array must be the proper size for the image.
void image2data(PImage image, byte[] data, boolean layout) {
  int offset = 3;
  int x, y, xbegin, xend, xinc, mask;
  int linesPerPin = image.height / 8;
  int pixel[] = new int[8];
  
  for (y = 0; y < linesPerPin; y++) {
    if ((y & 1) == (layout ? 0 : 1)) {
      // even numbered rows are left to right
      xbegin = 0;
      xend = image.width;
      xinc = 1;
    } else {
      // odd numbered rows are right to left
      xbegin = image.width - 1;
      xend = -1;
      xinc = -1;
    }
    for (x = xbegin; x != xend; x += xinc) {
      for (int i=0; i < 8; i++) {
        // fetch 8 pixels from the image, 1 for each pin
        pixel[i] = image.pixels[x + (y + linesPerPin * i) * image.width];
        pixel[i] = colorWiring(pixel[i]);
      }
      // convert 8 pixels to 24 bytes
      for (mask = 0x800000; mask != 0; mask >>= 1) {
        byte b = 0;
        for (int i=0; i < 8; i++) {
          if ((pixel[i] & mask) != 0) b |= (1 << i);
        }
        data[offset++] = b;
      }
    }
  } 
}

// Modify red, green, blue hex values to change output values.
// Ttranslate the 24 bit color from RGB to the actual
// order used by the LED wiring.  GRB is the most common.
int colorWiring(int c) {
  int red = (c & 0xFF0000) >> 16;
  int green = (c & 0x00FF00) >> 8;
  int blue = (c & 0x0000FF);
  red = (int)(gammatable[red] * brightness);
  green = (int)(gammatable[green] * brightness);
  blue = (int)(gammatable[blue] * brightness);
  return (green << 16) | (red << 8) | (blue); // GRB - most common wiring
}

// Ask a Teensy board for its LED configuration, and set up the info for it.
void serialConfigure(String portName) {
  if (numPorts >= maxPorts) {
    println("too many serial ports, please increase maxPorts");
    errorCount++;
    return;
  }
  try {
    ledSerial[numPorts] = new Serial(this, portName);
    if (ledSerial[numPorts] == null) throw new NullPointerException();
    ledSerial[numPorts].write('?');
  } catch (Throwable e) {
    println("Serial port " + portName + " does not exist or is non-functional");
    errorCount++;
    return;
  }
  delay(50);
  String line = ledSerial[numPorts].readStringUntil(10);
  if (line == null) {
    println("Serial port " + portName + " is not responding.");
    println("Is it really a Teensy 3.0 running VideoDisplay?");
    errorCount++;
    return;
  }
  String param[] = line.split(",");
  if (param.length != 12) {
    println("Error: port " + portName + " did not respond to LED config query");
    errorCount++;
    return;
  }
  // only store the info and increase numPorts if Teensy responds properly
  ledImage[numPorts] = new PImage(Integer.parseInt(param[0]), Integer.parseInt(param[1]), RGB);
  ledArea[numPorts] = new Rectangle(Integer.parseInt(param[5]), Integer.parseInt(param[6]),
                     Integer.parseInt(param[7]), Integer.parseInt(param[8]));
  ledLayout[numPorts] = (Integer.parseInt(param[5]) == 0);
  numPorts++;
}

// scale a number by a percentage, from 0 to 100
int percentage(int num, int percent) {
  double mult = percentageFloat(percent);
  double output = num * mult;
  return (int)output;
}

// scale a number by the inverse of a percentage, from 0 to 100
int percentageInverse(int num, int percent) {
  double div = percentageFloat(percent);
  double output = num / div;
  return (int)output;
}

// convert an integer from 0 to 100 to a float percentage
// from 0.0 to 1.0.  Special cases for 1/3, 1/6, 1/7, etc
// are handled automatically to fix integer rounding.
double percentageFloat(int percent) {
  if (percent == 33) return 1.0 / 3.0;
  if (percent == 17) return 1.0 / 6.0;
  if (percent == 14) return 1.0 / 7.0;
  if (percent == 13) return 1.0 / 8.0;
  if (percent == 11) return 1.0 / 9.0;
  if (percent ==  9) return 1.0 / 11.0;
  if (percent ==  8) return 1.0 / 12.0;
  return (double)percent / 100.0;
}
