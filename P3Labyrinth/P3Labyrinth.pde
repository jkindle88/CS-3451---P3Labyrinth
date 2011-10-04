// CS3451 - P1B : starting code provided by Jarek ROSSIGNAC on August 2011
PImage myFace;                         // picture of author's face, read from file pic.jpg in data folder
int maxn = 10000;                       // max number of points
int n=0;                               // current number of points
int s=1;                               // number of subdivisions
float [] wallX = new float[maxn];          // X coordinates of wall
float [] wallY = new float[maxn];          // Y coordinates of wall
float X; float Y; float r = 10;           // Variables for the ball
float X0; float Y0;
int maxt=20; float t=1; float k=3; float dt = t/maxt;
PVector G;  //accel
PVector V;  //vel
PVector V0; //utility vector
PVector P;  //collision point

boolean placingBall = false;    // track when the player is placing the ball
boolean placedBall = false;     // track when the ball has been placed
boolean go = false;             // track when the game has started
boolean win = false;
boolean threeD = false;

this is a gamebreaking change.  testing github version control.

String title ="CS3451 Fall 2011, Project P3 - Enter the Labyrinth", // text that will be displayed in the sketch window
       name ="Joe Kindle", 
       help="click to add points, ' ' to restart, 'b' to place the ball, 'g' to start the game, 's' to save, 'l' to load";
void setup() {                          // executed once at the beginning of the program
  size(600, 600, P3D);                       // specifies size of window
  myFace = loadImage("data/pic.jpg");  // load image from file pic.jpg in folder data
  X0 = -20;
  Y0 = -20;
  G = new PVector(0,0,0);
  V = new PVector(0,0,0);
  V0 = new PVector(0,0,0);
  sphereDetail(16); // *3D*
  textMode(SCREEN);
  frameRate(maxt);
}

void update()
{
  G.set(k*dt*(mouseX-(width/2)),k*dt*(mouseY-(height/2)),0);
  V.set(V0.x + (G.x*dt),V0.y + (G.y*dt),0);  //apply 1/20*G to V_initial to get V_final
  X = (X0 + dt*V.x);
  Y = (Y0 + dt*V.y);
  
  V0.set(V);                                 //V_final becomes V_initial for the next frame
  X0 = X;
  Y0 = Y; 
}

void draw() {    // exected at each frame to refresh the screen
  background(255);  // erases the screen by painting a white background
  image(myFace, width-myFace.width/2,25,myFace.width/2,myFace.height/2); // displays the author's face at the top right
  fill(0); text(title,10,20); text(name,width-name.length()*9,20); text(help,10,height-10); noFill(); // writes the title, name, help
  drawWalls(threeD);  // plots the function in red using color as (R,G,B) between 0 and 255
  drawBall(threeD);
  if (go) {
    //line(width/2,height/2,mouseX,mouseY);
    update();
    detectCollision();
  }
}

void detectCollision()
{
  for(int i = 0; i<n-1; i++)
  {
    P = getCollision(i,i+1);
    if(P.x != 0 || P.y != 0) // If either of these is non-zero, we have a collision.
    {
      V.set(-V.x,-V.y,0);    // TODO: add real reflection
    }
  }   
}

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
    println("going");
  }
  else if (!placedBall){
    wallX[n]=mouseX; wallY[n]=mouseY; // appends new point from mouse location
    n++;                      // increments point count
  }
}

void mouseMoved() {
  t=0;
  V0 = V;
}

void keyPressed() {  // interrupt executed each time a key is pressed
  if(key=='p') snapPicture();  // when 'p' is pressed, an image of the window is saved into the pictures subfolder of your sketch folder
  if(key==' ') {
    n=0;  // reset
    placedBall = false;
    go = false;
    X = -20;
    Y = -20;
  }
  if((key=='b' || key=='B') && !placedBall) {
    placingBall = true;      // can now place the ball.  This can only be made false again by clicking to place the ball.
  }
  if(key=='g' || key=='G' && placedBall) go = !go;            // this key starts and stops the game.
  if(key=='s') savePts();
  if(key=='l') loadPts();
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
    for(int i=0; i<n-1; i++) {
      fill(255,0,0); stroke(255,0,0); strokeWeight(1);
      translate(wallX[i],wallY[i],0);
      box(r/2);             // Draw each node in red
      noFill(); stroke(0,0,0); strokeWeight(2); 
      line(wallX[i],wallY[i],wallX[i+1],wallY[i+1]);  // Draw each wall in black
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
