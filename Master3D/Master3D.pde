import tracer.easings.*;
import tracer.*;
import tracer.renders.*;
import tracer.paths.*;
 import themidibus.*;

/****************************************************
     Carl Moore - Multichannel MIDI visualizer  
****************************************************/


MidiBus myBus;
int numInst = 6;
//float[] shakeFactor = new float[] { 10,4,1,2,1,2 }; //hard coded-in values based on channels
//float[] shakeFactor;
Instrument[] instruments;


color bg;
int bg_sat = 10;
int bg_bright = 80;
float colorShift;
float colorSpread = 20;
float brightness;
float set_brightness = 35;
float colorRange = 128;
float colorPedestal = 100;
int colorcount;
int Y_AXIS = 1;
int X_AXIS = 2;

int eventCounter = 0;
boolean eventRf = false;
boolean fade = true;
boolean clearCanvas = false;
boolean fadeSwitch = false;
float alphaFade = 0;
float alphaFadeRate = 3;

//translation & rotation
float rotationX = 1;
float rotationY = 1;
float rotationZ = 1;
float rotationX_spd = 1;
float rotationY_spd = 1;
float rotationZ_spd = 1;

float rotation_mult = 0.01;


void setup() {
  size(1280,720, P3D);
  background(35);
  frameRate(30);
  colorMode(HSB, 360, 100, 100);

  MidiBus.list(); 
  myBus = new MidiBus(this, 0, 0);
  
  instruments = new Instrument[numInst];
  for(int i = 0; i < numInst; i++){
    instruments[i] = new Instrument();
    instruments[i].setup();
    instruments[i].channel = i;
    //instruments[i].colorVal = (((float)i/numInst) * 255);
    instruments[i].colorVal = ((colorRange/numInst) * i) + colorPedestal % 360;
    instruments[i].range = 1;
    //println(instruments[i].range);
    //instruments[i].range = shakeFactor[i]; //hard-coded values for shake
  }
}

void draw() {
  if(clearCanvas || fade == false){
    clear();
    clearCanvas = false;
  }
  push();
  
  /************************************************
                  CAMERA & ROTATION
   ************************************************/
   
  //rotationX = rotationX_target - rotationX;
  //rotationY = rotationY_target - rotationY;
  
  rotationX *= rotationX_spd;
  rotationY *= rotationY_spd;
  
  if(rotationX < 0.001){
    rotationX = 0;
  }
  if(rotationY < 0.001){
    rotationY = 0;  
  }
  
  //println(rotationX + " amt");
  //println(rotationX_spd + " spd");
  
  
  beginCamera();
  camera();
  camera(width/2.0, height/2.0, -1000, width/2.0, height/2.0, 0, 0, 1, 0);
  translate(width/2,height/2,-400);
  rotateX(rotationX);
  rotateY(rotationY);
  
  endCamera();

  /************************************************
                  MIDI CONTROL CHANGE
   ************************************************/
  
  ControlChange change = new ControlChange(0, 0, 0);
  myBus.sendControllerChange(change);
  
  if(frameCount % 10 == 0){ //add random inst (for testing)
    for(int i = 0; i < 10; i++){
      int numInst = (int)random(0,5);
      //instruments[numInst].noteon((int)random(1,127), (int)random(10,80));
    }
  }
  eventCounter();
  

  noStroke();
  
  /************************************************
                  INSTRUMENT CALL
  ************************************************/
   
  for(int i = 0; i < numInst; i++){
    Instrument thisInst = instruments[i];
    try{
      thisInst.display(eventRf); //sends the refresh flag
    } catch (Exception e) {
          println("something went wrong, skipping index" + i);
    }
  }
  eventRf = false; //sets refresh state back
  pop();
  
  /************************************************
                  BACKGROUND FADE FX
  ************************************************/
  
  if(fade){
    noStroke();
        
    if(fadeSwitch){
      alphaFade += alphaFadeRate; 
      alphaFade = constrain(alphaFade, 0, 255);
    } else {
      alphaFade -= alphaFadeRate;
      alphaFade =  constrain(alphaFade, 0, 255);
    }
    //println(alphaFade + " alpha fade  ");
    //println(fadeSwitch + " fade sw");
    //fill(0, ((cos(frameCount * 0.01) + 1) / 2) * 255);
    fill(0, alphaFade);
    rect(0, 0, width * 2, height * 2);
  }
}

  /************************************************
   --------------NOTE ON EVENT---------------------              
  ************************************************/

void noteOn(Note note) {
  try{
    if(note.channel < numInst){ //<LEARN FROM THIS MISTAKE
      instruments[note.channel].noteon(note.pitch, note.velocity);
    }
    
    //EVENT SELECTOR
    if (note.channel == 15) {
      switch(note.pitch){
        case 60: //C3: event counter
        eventCounter++;
        break;
        
        case 61: //C#3: color shift
        for(int i = 0; i < numInst; i++){
          colorPedestal = random(0,360);
          instruments[i].colorVal = ((colorRange/numInst) * i) + colorPedestal % 360;
        }
        break;
        
        case 62: //D3: fade sw on
        fadeSwitch = true;
        alphaFadeRate = 1 - ((float)note.velocity / 127) * 5;
        //alphaFadeInRate = (note.velocity / 127) * 5;
        break;
        
        case 63: //D#3: fade sw off
        fadeSwitch = false;
        //alphaFade = ((float)note.velocity / 127) * 5;
        alphaFadeRate = 1 - ((float)note.velocity / 127) * 5;
        println(alphaFadeRate);
        break;
        
        case 64: //E3: alpha Fade Set
        alphaFade = note.velocity * 2;
        break;
        
        case 65: //F3: clear canvas
        clearCanvas = true;
        break;
        
        case 66: //F#3
        break;
        
        case 67: //G3: rotate x event
        rotationX = (((float)note.velocity / 127) * 360) * rotation_mult;
        //clearCanvas = true;
        break;
        
        case 68: //G#3: x rotation speed
        rotationX_spd = 1 - ((float)note.velocity / 127);
        break;
        
        case 69: //A3: rotate y event
        rotationY = ((((float)note.velocity / 127) * 360) * rotation_mult);
        //clearCanvas = true;
        break;
        
        case 70: //A#3: y rotation speed
        rotationY_spd = 1 - ((float)note.velocity / 127);
        break;
        
        case 71: //G3: rotate Z event
        rotationX = (((float)note.velocity / 127) * 360) * rotation_mult;
        break;
        
        case 72: //G#3: Z rotation speed
        rotationX_spd = 1 - ((float)note.velocity / 127);
        break;
        
        case 73: //A#3: y rotation speed
        rotationY_spd = 1 - ((float)note.velocity / 127);
        break;
        
        case 74: //G3: rotate Z event
        rotationX = (((float)note.velocity / 127) * 360) * rotation_mult;    
        break;
        
        case 75: //G#3: Z rotation speed
        rotationX_spd = 1 - ((float)note.velocity / 127);
        break;
      }
    }
  } catch (Exception e) {
    println("something went wrong with noteOn");
  }
}

void noteOff(Note note) {
  try{
    if(note.channel < numInst){
      //instruments[note.channel].noteoff(note.pitch);
    }
  } catch (Exception c) {
    println("something went wrong with noteOff");
  }
}
 
void controllerChange(ControlChange change) {
}


int counterChange = 0;
int sectionEvent = 0;
  

void eventCounter(){
    if(eventCounter % 4 == 3){
      //set_brightness += brightness;
    }
    if(eventCounter != counterChange) {
      if(eventCounter % 16 == 0){ //change gradient every 4th beat
        //bg = color(colorShift % 360, bg_sat, brightness);
        set_brightness = pow(brightness, 1.2);
        eventRf = true; 
      }
    }
    counterChange = eventCounter; 
    //if(eventCounter % 8 == 0){
    //  fadeSwitch = true;
    //} 
    
    //if(eventCounter % 8 == 3){
    //  fadeSwitch = false;
    //}
}
