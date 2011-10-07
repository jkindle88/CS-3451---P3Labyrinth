PImage myFace;                         // picture of author's face, read from file pic.jpg in data folder
int maxn = 10000;                       // max number of points
int n=0;                               // current number of points
int s=1;                               // number of subdivisions
float [] wallX = new float[maxn];          // X coordinates of wall
float [] wallY = new float[maxn];          // Y coordinates of wall
float X; float Y; float r = 10;           // Variables for the ball
float X0; float Y0;
int maxt=20; float t=1; float k=4; float dt = t/maxt;

int timer = 0;
int totaltime = 30; //in seconds -- CHANGE THIS ONE, NOT THE ONE BELOW
int maxtime = totaltime * 20; //convert

PVector G;  //accel
PVector V;  //vel
PVector V0; //utility vector
PVector P;  //collision point

boolean placingBall = false;    // track when the player is placing the ball
boolean placedBall = false;     // track when the ball has been placed
boolean go = false;             // track when the game has started
boolean win = false;
boolean lose = false;
boolean threeD = false;

String title ="CS3451 Fall 2011, Project P3 - Enter the Labyrinth", // text that will be displayed in the sketch window
       name ="Joe Kindle", 
       help="click to add points, ' ' to restart, 'b' to place the ball, 'g' to start the game,'l' to load, 3 to toggle 3D";
void setup() {                          // executed once at the beginning of the program
  size(600, 600, P3D);                       // specifies size of window
  myFace = loadImage("data/pic.jpg");  // load image from file pic.jpg in folder data
  X0 = 0;
  Y0 = 0;
  G = new PVector(0,0,0);
  V = new PVector(0,0,0);
  V0 = new PVector(0,0,0);
  timer = maxtime;
  sphereDetail(16); // *3D*
  textMode(SCREEN);
  frameRate(maxt);
}

void update()
{
  G.set(k*dt*(mouseX-(width/2)),k*dt*(mouseY-(height/2)),0);
  V.set(V0.x + (G.x*dt),V0.y + (G.y*dt),0);  //apply 1/20*G to V_initial to get V_final
  detectCollision();
  
  X = (X0 + dt*V.x);
  Y = (Y0 + dt*V.y);
  
  V0.set(V);                                 //V_final becomes V_initial for the next frame
  X0 = X;
  Y0 = Y; 
  
  if (timer == 0) {
    lose = true;
  }
}

void draw() {    // exected at each frame to refresh the screen
  background(255);  // erases the screen by painting a white background
  image(myFace, width-myFace.width/2,25,myFace.width/2,myFace.height/2); // displays the author's face at the top right
  displayTime();
  stroke(0,0,0); noFill();         //Draw timer bar
  rect(135,30,4*totaltime,12);
  stroke(255,0,0); fill(255,0,0);
  rect(135,30,4*(timer/20),12);
  
  if (win) {  //You win!
    background(255);
    go = false;  //stop the game
    stroke(0,0,255);
    text("You win!!",275,40);
    text("Hit 'r' or space to play again!",230,570);
  }
  if (lose) { //You fail!
    background(255);
    go = false;  //stop the game
    stroke(255,0,0);
    text("Hit 'r' or space to play again!",230,570);
    text("You lose! :(",275,40);
  }
  if(threeD) {
    directionalLight(250, 250, 250, 20, 100, -100);
    pushMatrix();
    translate(width/2, height/2, height/2-500); 
    rotateX(70*PI/180);
    rotateY(PI*(mouseX-300)/5000);
    if (mouseY > 180) {     // to prevent the maze from flipping over entirely when moving the mouse to the top of the screen.
      rotateX(-PI*(mouseY-300)/1200);
    }
    translate(-width/2, -height/2, 0);
    pushMatrix();
    stroke(75,75,75);
    fill(225,225,225);
    translate(0,0,-r);
    rect(0,0,600,600);
    translate(0,0,r);
    popMatrix();
    pushMatrix();
    drawWalls(threeD);
    popMatrix();
    pushMatrix();
    drawBall(threeD);
    popMatrix();
    if (go) {
      update();
      timer--;  //Called ~20 times per second
    }
    popMatrix();
  }
  else {
    fill(0); text(title,10,20); text(name,width-name.length()*9,20); text(help,10,height-10); noFill(); // writes the title, name, help
    drawWalls(threeD);  // plots the function in red using color as (R,G,B) between 0 and 255
    drawBall(threeD);
    if (go) {
      update();
      timer--; //Called ~20 times per second
    }
  } 
}

void detectCollision()
{
  PVector N = new PVector(0,0,0);   // N = U(C,P) - C is the center of the ball, P is the collision point.  We know P and C.
  PVector W = new PVector(0,0,0);   // W = V - 2*(V dot N)*N - new velocity after the collision.  We know V and N.
  PVector util = new PVector(0,0,0);     // utility vector
  PVector closest = new PVector(0,0,0);  // closest point P
  for(int i = 0; i<n-1; i++)
  {
    P = getCollision(i,i+1);
    if(P.x != 0 || P.y != 0) // If either of these is non-zero, we have a collision.
    {
      // This is my reflection code.  I used the algorithm from the midterm.  It is wonky and imperfect, but it mostly works.
      
      closest = closestPoint(i,i+1); // We know which wall has been collided with, and we know the closest point to the collision.
      N.set(X0-closest.x,Y0-closest.y,0);   // Vector PC
      N.set(N.div(N,N.mag()));  // Make N unit
      util.set(N);
      util.mult(util,abs(V.dot(N)));
      util.mult(util,2);
      W.set(V.sub(V, util));
      W.set(-W.y,W.x,0);
      V.set(W);
    }
  } 
  if (n > 0) {
    P = getCollision(0,n-1);
    if(P.x != 0 || P.y != 0) {// If either of these is non-zero, we have a collision.  In this case, you win!
      win = true;
    }
  } 
}

// The next two collision detection methods were inspired by an article at the dowsa blog:
// http://doswa.com/2009/07/13/circle-segment-intersectioncollision.html
// The first finds the closest point to the ball for two given nodes.
// The second detects if there is a collision between the closest point and the ball.
PVector closestPoint(int i, int j)
{
  if(n > 1){
    PVector segment = new PVector (wallX[j] - wallX[i],wallY[j] - wallY[i],0);
    PVector circle = new PVector(X0 - wallX[i],Y0 - wallY[i],0);
    PVector segU = new PVector(segment.x/segment.mag(),segment.y/segment.mag()) ;
    float proj = circle.x*segU.x + circle.y*segU.y;
    if (proj <= 0) return new PVector(wallX[i],wallY[i],0);
    if (proj >= segment.mag()) return new PVector(wallX[j],wallY[j],0);
    PVector projVec = new PVector(segU.x*proj,segU.y*proj);
    PVector closest = new PVector(projVec.x + wallX[i],projVec.y + wallY[i],0);
    return closest;
  }
  return new PVector(0,0,0);
}
PVector getCollision(int i, int j)
{
  if(n > 1){
    PVector closest = closestPoint(i,j);
    PVector distance = new PVector(X0 - closest.x, Y0 - closest.y);
    if (distance.mag() > 10) 
      return new PVector(0,0);
    if (distance.mag() <= 0) 
      println("Circle's center is exactly on segment");
    PVector segment = new PVector (wallX[j] - wallX[i],wallY[j] - wallY[i],0); 
    PVector segU = new PVector(segment.x/segment.mag(),segment.y/segment.mag());
    float d = r - distance.mag();
    PVector offset = new PVector(segU.x*d,segU.y*d);
    return offset; 
  }
  return new PVector(0,0,0);
}

void mousePressed() {  // interrupt executed each time the mouse is pressed
  if (placingBall) {  //Place the ball
     X0 = mouseX; Y0 = mouseY;
     placingBall = false;
     placedBall = true;
  }
  else if (go) {    //The game has started.  Can only be executed if the ball has been placed.
    //
  }
  else if (!placedBall){
    if (n == 0) {
      wallX[n]=mouseX; wallY[n]=mouseY; // appends new point from mouse location
      n++;                      // increments point count
    }
    else {
      if(abs(mouseX - wallX[n-1]) > abs(mouseY - wallY[n-1])) {        //  if delta_x is greater than delta_y, change x, constrain y
        wallX[n]=mouseX; wallY[n]=wallY[n-1];
        n++;
      }
      else if (abs(mouseX - wallX[n-1]) < abs(mouseY - wallY[n-1])) {  //  if delta_y is greater than delta_x, change y, constrain x
        wallX[n]=wallX[n-1]; wallY[n]=mouseY;
        n++;
      }
      else {                                                            // delta_x = delta_y, so just handle that
        wallX[n]=mouseX; wallY[n]=mouseY;
        n++;
      }
    }
  }
}

void mouseMoved() {
  t=0;
  V0 = V;
}

void keyPressed() {  // interrupt executed each time a key is pressed
  if(key=='p') snapPicture();  // when 'p' is pressed, an image of the window is saved into the pictures subfolder of your sketch folder
  if(key==' ') {
    reset();
  }
  if (key=='r' && (lose || win)) {
    reset();
  }
  if((key=='b' || key=='B') && !placedBall) {
    placingBall = true;      // can now place the ball.  This can only be made false again by clicking to place the ball.
  }
  if(key=='g' || key=='G' && placedBall) go = !go;            // this key starts and stops the game.
  if(key=='S') savePts();
  if(key=='L') loadPts();
  if(key=='s') savePts();
  if(key=='l') loadPts();
  if(key=='2') threeD = false;
  if(key=='3') threeD = !threeD;
}
  
// Draw the ball, and compute its new position
void drawBall(boolean td) {
  if (!td) {  // 2D
    fill(0,0,255); stroke(0,0,0); strokeWeight(1); beginShape(); ellipse(X0,Y0,r,r); endShape(); 
  }
  else {      // 3D
    fill(0,0,255); stroke(0,0,0); strokeWeight(1); beginShape(); translate(X0,Y0,0);sphere(r); endShape(); 
  } 
}

// Draw the walls
void drawWalls(boolean td) {
  if (n == 1) {
    fill(255,0,0); stroke(255,0,0); strokeWeight(1);
    ellipse(wallX[0],wallY[0],r/2,r/2);             // Draw each node in red
  }
  if (!td) {    // 2D
    beginShape(); 
    for(int i=0; i<n-1; i++) {
      fill(255,0,0); stroke(255,0,0); strokeWeight(1);
      ellipse(wallX[i],wallY[i],r/2,r/2);             // Draw each node in red
      noFill(); stroke(0,0,0); strokeWeight(2); 
      line(wallX[i],wallY[i],wallX[i+1],wallY[i+1]);  // Draw each wall in black
    }
    if (n>1) {
      fill(255,0,0); stroke(255,0,0); strokeWeight(1);
      ellipse(wallX[n-1],wallY[n-1],r/2,r/2);
    }
    endShape(); 
    if (go) {
      noFill(); strokeWeight(2); stroke(0,255,255);
      if (n >= 1) //so we don't error out if there are no walls when the game starts
        line(wallX[0],wallY[0],wallX[n-1],wallY[n-1]);  // After the game has started, draw exit in teal
    }
  }
  else {    //3D
    PVector AB = new PVector(0,0,0);
    PVector P1 = new PVector(0,0,0);
    PVector P2 = new PVector(0,0,0);
    PVector P3 = new PVector(0,0,0);
    PVector P4 = new PVector(0,0,0);
    float x = 5; // half the width of the wall.  we will move out x in both directions.
    if (n == 1) {
      pushMatrix();
      fill(255,0,0); stroke(255,0,0); strokeWeight(1);
      translate(wallX[0],wallY[0],0);
      box(r/2);             // Draw each node in red
      popMatrix();
    }
    for(int i=0; i<n-1; i++) {
      fill(255,0,0); stroke(255,0,0); strokeWeight(1);
      translate(wallX[i],wallY[i],0);
      box(r);             // Draw each node in red
      noFill(); stroke(0,0,0); strokeWeight(2);
      AB.set(wallX[i+1]-wallX[i],wallY[i+1]-wallY[i],0);  // Vector that represents one line segment in 2D
      
      //Draw lots of lines to represent the walls
      P1.set(AB.cross(new PVector(0,0,-1))); // R(AB)
      P1.set(P1.div(P1,P1.mag())); // U(P1)
      P1.set(P1.mult(P1,x));
      line(0,0,P1.x,P1.y);
      translate(P1.x,P1.y,0);
      line(0,0,AB.x,AB.y);
      translate(-P1.x,-P1.y,0);  
    
      P2.set(P2.mult(P1,-1));
      line(0,0,P2.x,P2.y);
      translate(P2.x,P2.y,0);
      line(0,0,AB.x,AB.y);
      translate(-P2.x,-P2.y,0);
      
      P3.set(P1.x,P1.y,-r/2);
      line(P1.x,P1.y,P3.x,P3.y);
      translate(P3.x,P3.y,P3.z);
      line(0,0,AB.x,AB.y);
      translate(-P3.x,-P3.y,-P3.z);
      
      P4.set(P2.x,P2.y,-r/2);
      line(P2.x,P2.y,P4.x,P4.y);
      translate(P4.x,P4.y,P4.z);
      line(0,0,AB.x,AB.y);
      translate(-P4.x,-P4.y,-P4.z);
      
      translate(-wallX[i],-wallY[i],0);               // Naive, "untranslate" here
      //line(wallX[i],wallY[i],wallX[i+1],wallY[i+1]);  // Draw each wall in black
    }
    if (n > 1) {
      pushMatrix();
      fill(255,0,0); stroke(255,0,0); strokeWeight(1);
      translate(wallX[n-1],wallY[n-1],0);
      box(r);             // Draw each node in red
      popMatrix();
    }
    if (go) {
      noFill(); strokeWeight(2); stroke(0,255,255);
      if (n >= 1) //so we don't error out if there are no walls when the game starts
        line(wallX[0],wallY[0],wallX[n-1],wallY[n-1]);  // After the game has started, draw exit in teal
    }
  }
}  
  
int pictureCounter=0; // counter used to give different names to the pictures you snap in the same session (save them elsewhere to avoid overwriting)
void snapPicture() {saveFrame("pictures/P"+nf(pictureCounter++,3)+".jpg");} // creates file P000.jpg, P001.jpg... in /pictures/

// ************************************** SAVE TO FILE AND READ BACK *********************************
void savePts() {
  savePts("data/P.pts");
}
void savePts(String fn) { 
  String [] inppts = new String [n+2];
  int s=0; 
  inppts[s++]=str(X)+","+str(Y);
  inppts[s++]=str(n); 
  for (int i=0; i<n; i++) {
    inppts[s++]=str(wallX[i])+","+str(wallY[i]);
  }
  saveStrings(fn, inppts);
}
  
void loadPts(){
  loadPts("data/P.pts");
}
void loadPts(String fn){
  String [] ss = loadStrings(fn);
  int s=0;
  int comma;
  n = int(ss[1]);
  String SS= ss[0];
  comma = SS.indexOf(',');
  X = int(ss[0].substring(0,comma));
  Y = int(ss[0].substring(comma+1, SS.length()));
  int j = 2;
  for(int i=0; i<n; i++)
  {
    SS = ss[j];
    j++;
    comma =SS.indexOf(',');
    wallX[i] = float(SS.substring(0,comma));
    wallY[i] = float(SS.substring(comma+1,SS.length()));
  }
};  //end IO

void displayTime() {
  if (!win && !lose) {
    text("Time left: "+(timer/20),275,40);
  }
  else {
    text("Total time (sec): "+(timer/20),285,40);
  } 
}

void reset () {
  n=0;  // reset
  X0 = 0;
  Y0 = 0;
  G.set(0,0,0);
  V.set(0,0,0);
  placedBall = false;
  go = false;
  timer = maxtime;
  win = false;
  lose = false;
}
