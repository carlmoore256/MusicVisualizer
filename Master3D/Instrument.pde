class Instrument {
  int channel;
  int numVoices;
  float colorVal;
  float sizeRatio = 0.3;
  float decayRatio = 0.95;
  float strokeDecay = 0.3;
  int childThresh = 45;
  int numChildren;
  int childInc = 0;
  
  float lastStroke;
  int lineThresh = 5; //number of incoming notes to trip lines
  float timeThreshold = 100; //time in ms for next line detection
  float lastTime;

  int recentDraws = 0;
  
  int[] notes = new int[127];
  int[] colors = new int[127];
  int[] idx_x = new int[127];
  int[] idx_y = new int[127];
  int[] idx_z = new int[127];
  float[] sizes = new float[127];

  float range;
  int brownianIter = 127;
  int ax[];
  int ay[];
  int az[];
  int currentIterations = 0;
  int maxIterations = 10000;
  int refreshClock = 0;
  
  int x_axis = 250;
  int y_axis = 250;
  int z_axis = 250;

  void setup(){
    ax = new int[brownianIter];
    ay = new int[brownianIter]; //127 max
    az = new int[brownianIter];
    refreshClock = (int)random(0,2);
    
    for (int i = 0; i < brownianIter; i++ ) {
      ax[i] = x_axis/2;
      ay[i] = y_axis/2;
      az[i] = z_axis/2;
    }
    
    idx_x = new int[127];
    idx_y = new int[127];
    
    for(int j = 0; j < 127; j++){
      idx_x[j] = (int)random(-x_axis, x_axis);
      idx_y[j] = (int)random(-y_axis, y_axis);
      idx_z[j] = (int)random(-z_axis, z_axis);
      //float noise = random(-10,10);
      colors[j] = color(frameCount % 360, 80, 200);
    }
    numVoices = 0;
    lastStroke = 255;
  }
  
  void display(boolean refresh){
    
    boolean allowRf = false;
    if (recentDraws >= lineThresh){ //if recentDraws passes this threshold, force a refresh
      allowRf = true;
      refreshClock = 1; //set clock the furthest from a new refresh
      if(lastStroke > 1){
        lastStroke *= 0.9;
      } else {
        lastStroke = 0;
      }
      color newStroke = color(360,0,255,lastStroke);
      stroke(newStroke);
      int lastIdx = 0;
      int firstIdx = 0;
      boolean firstIdxFlg = true;
      for(int a = 0; a < notes.length; a++){
        if(notes[a] > 0){
          if(firstIdxFlg){
            firstIdx = a;
            firstIdxFlg = false;
          }
          if(a != notes.length && !firstIdxFlg){
             line((ax[a] + idx_x[a]), (ay[a] + idx_y[a]), (az[a] + idx_z[a]), (ax[lastIdx] + idx_x[lastIdx]), (ay[lastIdx] + idx_y[lastIdx]), (az[lastIdx] + idx_z[lastIdx]));
          } else if(a == notes.length){
             line((ax[a] + idx_x[a]), (ay[a] + idx_y[a]), (az[a] + idx_z[a]), (ax[firstIdx] + idx_x[firstIdx]), (ay[firstIdx] + idx_y[firstIdx]), (az[firstIdx] + idx_z[firstIdx]));
          }
          lastIdx = a;
        }
      }
      if(lastIdx != firstIdx) {
        //line((ax[firstIdx -1] + idx_x[firstIdx - 1]) % width,(ay[firstIdx - 1 ] + idx_y[firstIdx -1]) % height,(ax[lastIdx] + idx_x[lastIdx]) % width,(ay[lastIdx] + idx_y[lastIdx]) % height);
      }
      
      allowRf = false;
    }
    if(numVoices > 0){
      brownianMotion(brownianIter, range, allowRf);
      for(int j = 1; j < notes.length; j++){
        if(notes[j] > 0) {
          noStroke();
          color c = color((colorVal) % 360, 30, 200);
          fill(c);
          push();
          translate((ax[j] + idx_x[j]) % x_axis, (ay[j] + idx_y[j]) % y_axis, (az[j] + idx_z[j]) % z_axis);
          sphere(notes[j] * sizeRatio);
          pop();
          push();
          if(numChildren > 0){ //create child moons
            for(int k = 0; k < numChildren; k++){
              fill(map(k,0,numChildren,100,255));
              fill(360,0,255,map(k,0,numChildren,100,255));
              noStroke();
              float radius = 50 + ((cos(childInc * 0.1) + 1) /2) * 20;
              float coords_x =  (ax[j] + idx_x[j]) % x_axis + radius * (cos(childInc * 0.005 + map(k,0,numChildren,0,359))) * cos(k); //fancy math
              float coords_y =  (ay[j] + idx_y[j]) % y_axis + radius * (sin(childInc * 0.005 + map(k,0,numChildren,0,359))) * sin(k);
              float coords_z =  (az[j] + idx_z[j]) % z_axis + radius * (cos(childInc * 0.005 + map(k,0,numChildren,0,359))) * cos(k); 
              float thisSize = notes[j] * sizeRatio * 0.5;
              translate(coords_x, coords_y, coords_z);
              sphere(thisSize);
              if(k == childInc % numChildren){ //draw lines from parent to child
                //line((ax[j] + idx_x[j]) % width,(ay[j] + idx_y[j]) % height, coords_x, coords_y);
              }
              
            }
          }
          pop();
          if(notes[j] > 1){
            notes[j] *= decayRatio;
          } else {
            notes[j] = 0; //remove it from the whole thing
            numVoices--;
          } 
        }
      } 
    }
    allowRf = false;
    childInc++;
  
  }
  
  void recentDraw(){ //ratio of incoming noteOn messages to draw calls
    float thisTime = millis();
    float deltaTime = thisTime - lastTime;
    if(deltaTime < timeThreshold){
      recentDraws++;
      lastStroke = 255;
      //println("added to recent draws " + recentDraws);
    } else if(recentDraws > 0) {
      recentDraws--;
    }
    lastTime = millis();
    
    //on our next draw call, if the threshold of recent draws is tripped, a refresh will be performed causing dramatic visuals
  }
     
  
  void brownianMotion(int iter, float range, boolean refresh){
    currentIterations++;
    if(currentIterations >= maxIterations){
      for (int i = 1; i < iter; i++ ) { //generate new map
        ax[i] = x_axis/2;
        ay[i] = y_axis/2;
        az[i] = z_axis/2;
      }
      currentIterations = 0;
    } 

    for (int i = 1; i < iter; i++ ) {
      if(refresh){
        ax[i] = x_axis/2;
        ay[i] = y_axis/2;
        az[i] = z_axis/2;
        float noise = random(-10,10); //this adds color variation
        colors[i]= color(colorVal + noise, colorVal + noise, 200);
      }
      ax[i - 1] = ax[i];
      ay[i - 1] = ay[i];
      az[i - 1] = az[i];
    }
    
    ax[iter - 1] += random(-range, range);
    ay[iter - 1] += random(-range, range);
    az[iter - 1] += random(-range, range);
  
    ax[iter - 1] = constrain(ax[iter - 1], 0, x_axis);
    ay[iter - 1] = constrain(ay[iter - 1], 0, y_axis);
    az[iter - 1] = constrain(ay[iter - 1], 0, z_axis);
  }

  
  void noteon(int pitch, int velocity){
    notes[pitch] = velocity;
    if(velocity > childThresh){
      float nc = map(velocity - childThresh, childThresh, 127, 0, 8);
      if(nc > 0){
        numChildren = (int) nc;
      }
    }
    numVoices = 0; // prepare to incrememnt up
    for(int i = 0; i < notes.length; i++){
      if(notes[i] > 0){ //determines which voices are active
        numVoices++;
      }
    }
    recentDraw();
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
