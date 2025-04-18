import gifAnimation.*;

ArrayList<Molecule> molecules = new ArrayList<Molecule>();
GifMaker gifExport;

boolean freezing = false;
int freezeStart = 90;
int totalFrames = 180;
float zoom = 500;
float zoomTarget = 300;

float rotationY = 0;

void setup() {
  size(800, 600, P3D);
  frameRate(30);

  for (int i = 0; i < 200; i++) {
    molecules.add(new Molecule(
      random(-200, 200),
      random(-200, 200),
      random(-200, 200)
    ));
  }

  gifExport = new GifMaker(this, "ice_freeze_3d.gif");
  gifExport.setRepeat(0);
  gifExport.setQuality(10);
  gifExport.setDelay(33);
}

void draw() {
  background(20, 40, 80);
  lights();

  // Draw energy/temperature bar
  float temp = map(frameCount, 0, freezeStart, 1, 0);
  drawThermometer(temp);

  // Camera zoom and slight rotation
  translate(width * 0.65, height * 0.5, -zoom);
  rotateY(rotationY);
  rotationY += 0.005;

  if (freezing && zoom > zoomTarget) zoom -= 2;

  // Center origin
  pushMatrix();
  translate(0, 0, 0);

  for (Molecule m : molecules) {
    m.update();
    m.display();
  }

  popMatrix();

  if (frameCount == freezeStart) {
    freezing = true;
    snapTo3DIceLattice();
  }

  gifExport.addFrame();

  if (frameCount >= totalFrames) {
    gifExport.finish();
    println("GIF saved.");
    exit();
  }
}

void drawThermometer(float t) {
  pushMatrix();
  camera();  // Reset view
  noStroke();
  fill(255);
  rect(20, 20, 20, height - 40);

  int h = int((height - 40) * t);
  color c = lerpColor(color(255, 0, 0), color(0, 180, 255), 1 - t);
  fill(c);
  rect(20, height - 20 - h, 20, h);
  popMatrix();
}

class Molecule {
  PVector pos, vel;
  PVector target;
  boolean frozen = false;

  Molecule(float x, float y, float z) {
    pos = new PVector(x, y, z);
    vel = PVector.random3D().mult(random(0.5, 2));
  }

  void update() {
    if (frozen) {
      pos.lerp(target, 0.1);
    } else {
      pos.add(vel);
      if (abs(pos.x) > 250) vel.x *= -1;
      if (abs(pos.y) > 250) vel.y *= -1;
      if (abs(pos.z) > 250) vel.z *= -1;
    }
  }

  void display() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    fill(frozen ? color(200, 255, 255) : color(0, 100, 255));
    noStroke();
    sphere(10);
    popMatrix();
  }

  void freezeTo(PVector t) {
    frozen = true;
    target = t.copy();
  }
}

// Freeze into 3D hexagonal prism grid
void snapTo3DIceLattice() {
  float spacing = 40;
  int cols = 5;
  int rows = 5;
  int layers = 4;
  int idx = 0;

  for (int z = 0; z < layers; z++) {
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (idx >= molecules.size()) return;

        float offsetX = (y % 2 == 0 ? spacing / 2 : 0);
        float offsetY = (z % 2 == 0 ? spacing / 2 : 0);

        float px = x * spacing + offsetX - cols * spacing / 2;
        float py = y * spacing + offsetY - rows * spacing / 2;
        float pz = z * spacing - layers * spacing / 2;

        molecules.get(idx).freezeTo(new PVector(px, py, pz));
        idx++;
      }
    }
  }
}
