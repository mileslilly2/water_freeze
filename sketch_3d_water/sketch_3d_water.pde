/**
 * ice_freeze_3d.pde
 * 3‑D molecular freeze → lattice animation with GIF export.
 * Combines 2‑D zoom/temperature/GIF logic with the 3‑D scene.
 * -----------------------------------------------------------
 * Requires:   gifAnimation library
 * Resolution: 800 × 600 @ 30 fps, 6‑second GIF (180 frames)
 */

import gifAnimation.*;

// ───────────────────────────────────
// GLOBALS
// ───────────────────────────────────
ArrayList<Molecule> molecules = new ArrayList<Molecule>();
GifMaker gifExport;

boolean freezing   = false;
int     freezeStart = 90;   // start freeze on frame 90
int     totalFrames = 180;  // end animation on frame 180

// camera / easing
float zoom      = 200;  // camera start‑distance
float zoomTarget = 100; // where camera ends after zoom‑in
float panX = 0, panY = 0;
float panXTarget = 0, panYTarget = 0;

// will hold the geometric centre of the lattice after snap
PVector3D freezeCenter;

// slow orbit rotation
float rotationY = 0;

// ───────────────────────────────────
// SETUP
// ───────────────────────────────────
void setup() {
  size(800, 600, P3D);
  frameRate(30);

  // create 200 molecules in a 400³ cube
  for (int i = 0; i < 200; i++) {
    molecules.add(new Molecule(
      random(-200, 200),
      random(-200, 200),
      random(-200, 200)
    ));
  }

  gifExport = new GifMaker(this, "ice_freeze_3d.gif");
  gifExport.setRepeat(0);   // loop forever
  gifExport.setQuality(10); // 1 = best, 255 = worst
  gifExport.setDelay(33);   // 30 fps
}

// ───────────────────────────────────
// DRAW LOOP
// ───────────────────────────────────
void draw() {
  background(20, 40, 80);
  lights();

  // temperature bar (mapped to timeline)
  float temp = map(frameCount, 0, freezeStart, 1, 0);
  drawTemperatureBar(temp);

  // camera easing once freezing starts
  if (freezing) {
    zoom = lerp(zoom, zoomTarget, 0.05);
    panX = lerp(panX, panXTarget, 0.05);
    panY = lerp(panY, panYTarget, 0.05);
  }

  // camera position
  translate(width / 2 + panX, height / 2 + panY, -zoom);
  rotateY(rotationY);
  rotationY += 0.005;

  // render molecules
  pushMatrix();
  for (Molecule m : molecules) {
    m.update();
    m.display();
  }
  popMatrix();

  // trigger freeze once
  if (frameCount == freezeStart) {
    freezing = true;
    snapTo3DIceLattice();     // positions molecules
    zoomTarget = 300;         // camera end‑distance
    setCameraPanTarget();     // centre view on lattice
  }

  // add frame to GIF
  gifExport.addFrame();

  // finish & quit
  if (frameCount >= totalFrames) {
    gifExport.finish();
    println("✅ GIF export finished.");
    exit();
  }
}

// ───────────────────────────────────
// UI OVERLAY
// ───────────────────────────────────
void drawTemperatureBar(float t) {
  pushMatrix();
  camera();             // reset any 3‑D transforms
  noStroke();
  fill(255);
  rect(20, 20, 20, height - 40);

  int   barH  = int((height - 40) * t);
  color c     = lerpColor(color(255, 0, 0), color(0, 180, 255), 1 - t);
  fill(c);
  rect(20, height - 20 - barH, 20, barH);
  popMatrix();
}

// ───────────────────────────────────
// MOLECULE CLASS
// ───────────────────────────────────
class Molecule {
  PVector pos, vel, target;
  boolean frozen = false;

  Molecule(float x, float y, float z) {
    pos = new PVector(x, y, z);
    vel = PVector.random3D().mult(random(0.5, 2));
  }

  void update() {
    if (frozen) {
      pos.lerp(target, 0.1);
    } else {
      vel.mult(0.99);   // cooling
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

// ───────────────────────────────────
// LATTICE + CAMERA TARGET
// ───────────────────────────────────
void snapTo3DIceLattice() {
  float spacing = 40;
  int cols = 5, rows = 5, layers = 4;
  int idx = 0;

  ArrayList<PVector> frozenPositions = new ArrayList<PVector>();

  for (int z = 0; z < layers; z++) {
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (idx >= molecules.size()) break;

        float offsetX = (y % 2 == 0 ? spacing / 2 : 0);
        float offsetY = (z % 2 == 0 ? spacing / 2 : 0);
        float px = x * spacing + offsetX - cols   * spacing / 2;
        float py = y * spacing + offsetY - rows   * spacing / 2;
        float pz = z * spacing            - layers * spacing / 2;

        molecules.get(idx).freezeTo(new PVector(px, py, pz));
        frozenPositions.add(new PVector(px, py)); // store 2‑D footprint for centring
        idx++;
      }
    }
  }

  // compute centre for panning
  float cx = 0, cy = 0;
  for (PVector p : frozenPositions) {
    cx += p.x;
    cy += p.y;
  }
  cx /= frozenPositions.size();
  cy /= frozenPositions.size();
  freezeCenter = new PVector3D(cx, cy, 0);
}

void setCameraPanTarget() {
  // After freeze we translate by (width/2 + panX, height/2 + panY)
  // so pan = −freezeCentre (screen coords) will centre it
  panXTarget = -freezeCenter.x;
  panYTarget = -freezeCenter.y + 50; // optional downward offset, like 2‑D version
}

// helper container for clarity
class PVector3D extends PVector {
  PVector3D(float x, float y, float z) { super(x, y, z); }
}
