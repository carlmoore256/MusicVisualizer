class Instrument {
  int channel;
  int numVoices;
  float colorVal;
  float sizeRatio = 1;
  float decayRatio = 0.95;
  
  int[] notes = new int[127];
  int[] idx_x = new int[127];
  int[] idx_y = new int[127];
  float[] sizes = new float[127];
  
  int range = 3;
  int brownianIter = 127;
  int ax[];
  int ay[];
  int currentIterations = 0;
  int maxIterations = 10000;
  int refreshClock = 0;
  
  
  void setup(){
    ax = new int[brownianIter];
    ay = new int[brownianIter]; //127 max
    
    for (int i = 0; i < brownianIter; i++ ) {
      ax[i] = width/2;
      ay[i] = width/2;
    }
    
    idx_x = new int[127];
    idx_y = new int[127];
    
    for(int j = 0; j < 127; j++){
      idx_x[j] = (int)random(-width/2,width/2);
      idx_y[j] = (int)random(-height/2,height/2);
    }
    numVoices = 0;
    
  }
  
  void display(boolean refresh){
    boolean allowRf = false;
    if(refresh){
      refreshClock++;
      if(refreshClock % 3 == 0){
        allowRf = true;
      }
    }
    if(numVoices > 0){
      brownianMotion(brownianIter, range, allowRf);
      for(int j = 1; j < notes.length; j++){
        if(notes[j] > 0) {
          float colorMult = colorVal * ((float)notes[j] / 127); // mulitplied to get full range
          color c = color(notes[j],notes[j-1],200,255); //rgba vals, with vel determining alpha
          fill(c);
          stroke(255);
          line(ax[j-1],ay[j-1],ax[j],ay[j]);
          ellipse((ax[j] + idx_x[j]) % width,(ay[j] + idx_y[j]) % height,notes[j],notes[j]);
          
          if(notes[j] > 1){
            notes[j] *= decayRatio;
          } else {
            notes[j] = 0; //remove it from the whole thing
            numVoices--;
          } 
        }
      } 
    }
  }
  
  
  
  void brownianMotion(int iter, int range, boolean refresh){
    currentIterations++;
    if(currentIterations >= maxIterations){
      for (int i = 1; i < iter; i++ ) { //generate new map
        ax[i] = width/2;
        ay[i] = height/2;
      }
      currentIterations = 0;
    } 

    for (int i = 1; i < iter; i++ ) {
      if(refresh){
        ax[i] = width/2;
        ay[i] = width/2;
      }
      ax[i - 1] = ax[i];
      ay[i - 1] = ay[i];
    }
    
    ax[iter - 1] += random(-range, range);
    ay[iter - 1] += random(-range, range);
  
    ax[iter - 1] = constrain(ax[iter - 1], 0, width);
    ay[iter - 1] = constrain(ay[iter - 1], 0, height);
  }

  
  void noteon(int pitch, int velocity){
    notes[pitch] = velocity;
    numVoices = 0; // prepare to incrememnt up
    for(int i = 0; i < notes.length; i++){
      if(notes[i] > 0){ //determines which voices are active
        numVoices++;
      }
    }
  }
  
  void noteoff(int pitch){
    notes[pitch] = 0;
    numVoices = 0;
    for(int i = 0; i < notes.length; i++){
      if(notes[i] > 0){ //determines which voices are active
        numVoices++;
      }
    }
  }
  
  void cleardata() {
    for(int i = 0; i < notes.length; i++){
      notes[i] = 0;
    } //<>//
    numVoices = 0;
    ax = new int[brownianIter];
    ay = new int[brownianIter]; //127 max
  }
}
