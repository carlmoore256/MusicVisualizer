import tracer.easings.*;
import tracer.*;
import tracer.renders.*;
import tracer.paths.*;

 import themidibus.*;

MidiBus myBus;
int numInst = 6;
Instrument[] instruments;


color bg;
int bg_sat = 10;
int bg_bright = 80;
float colorShift;
float colorSpread = 20;
float brightness;
float set_brightness = 35;
int colorcount;
int Y_AXIS = 1;
int X_AXIS = 2;

int eventCounter = 0;
boolean eventRf = false;

void setup() {
  size(800,800);
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
    instruments[i].colorVal = (((float)i/numInst) * 350);
  }
}

void draw() {
  
  ControlChange change = new ControlChange(0, 0, 0);
  myBus.sendControllerChange(change);
  
  eventCounter();
  
  if(set_brightness > 35) {
    set_brightness *= 0.9;
  }
  background(frameCount % 360, bg_sat, set_brightness);  
  noStroke();
  
  brightness = 0; //reset brightness val
  for(int i = 0; i < numInst; i++){
    Instrument thisInst = instruments[i];
    try{
      thisInst.display(eventRf); //sends the refresh flag
    } catch (Exception e) {
          println("something went wrong, skipping index" + i);
    }
  }
  eventRf = false; //sets refresh state back
}

int counterChange = 0;

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
}


  
  
void noteOn(Note note) {
  try{
    if(note.channel < numInst){ //<LEARN FROM THIS MISTAKE
      instruments[note.channel].noteon(note.pitch, note.velocity);
    }
    if (note.channel == 15) {
      eventCounter++;
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
