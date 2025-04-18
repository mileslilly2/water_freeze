import gifAnimation.*;

ArrayList<Molecule> molecules = new ArrayList<Molecule>();
GifMaker gifExport;

boolean freezing = false;
int freezeStart = 90;
int totalFrames = 180;
float zoom = 1;
float zoomTarget = 2;
PVector freezeCenter;

void setup() {
  size(500, 500);
  frameRate(30);

  for (int i = 0; i < 100; i++) {
    molecules.add(new Molecule(random(width), random(height)));
  }

  gifExport = new GifMaker(this, "ice_lattice_zoom_energy.gif");
  gifExport.setRepeat(0);
  gifExport.setQuality(10);
  gifExport.setDelay(33);
}

void draw() {
  background(25, 50, 100);

  float temperature = map(frameCount, 0, freezeStart, 1, 0);
  drawTemperatureBar(temperature);

  pushMatrix();

  if (freezing && zoom < zoomTarget) {
    zoom += 0.01;
  }

  float tx = freezeCenter != null ? freezeCenter.x : width / 2;
  float ty = freezeCenter != null ? freezeCenter.y : height / 2;

  translate(width / 2, height / 2); // Move origin to screen center
  scale(zoom);                      // Zoom
  translate(-tx, -ty);              // Pan to freeze center

  for (Molecule m : molecules) {
    m.update();
    m.display();
  }

  popMatrix();

  if (frameCount == freezeStart) {
    freezing = true;
    snapToHexLattice();
  }

  gifExport.addFrame();

  if (frameCount >= totalFrames) {
    gifExport.finish();
    println("GIF export finished.");
    exit();
  }
}

void drawTemperatureBar(float t) {
  noStroke();
  fill(255);
  rect(10, 10, 20, height - 20);

  int tempBarHeight = int((height - 20) * t);
  color tempColor = lerpColor(color(255, 0, 0), color(0, 150, 255), 1 - t);

  fill(tempColor);
  rect(10, height - 10 - tempBarHeight, 20, tempBarHeight);
}

class Molecule {
  PVector pos, vel;
  PVector target;
  boolean frozen = false;

  Molecule(float x, float y) {
    pos = new PVector(x, y);
    vel = PVector.random2D().mult(random(0.5, 2));
  }

  void update() {
    if (frozen) {
      pos.lerp(target, 0.1);
    } else {
      pos.add(vel);
      if (pos.x < 0 || pos.x > width) vel.x *= -1;
      if (pos.y < 0 || pos.y > height) vel.y *= -1;
    }
  }

  void display() {
    noStroke();
    fill(frozen ? color(200, 255, 255) : color(0, 120, 255), 180);
    ellipse(pos.x, pos.y, 10, 10);
  }

  void freezeTo(PVector t) {
    frozen = true;
    target = t.copy();
  }
}

void snapToHexLattice() {
  float radius = 25;
  float spacingX = radius * sqrt(3);
  float spacingY = radius * 1.5;
  int cols = int(width / spacingX);
  int rows = int(height / spacingY);

  float totalWidth = cols * spacingX;
  float totalHeight = rows * spacingY;
  float offsetX = (width - totalWidth) / 2;
  float offsetY = (height - totalHeight) / 2;

  // Set freeze center for panning
  freezeCenter = new PVector(
  offsetX + totalWidth / 2,
  offsetY + totalHeight / 2 - 50  // pan downward by 50 pixels
);


  int idx = 0;
  for (int row = 0; row < rows; row++) {
    for (int col = 0; col < cols; col++) {
      if (idx >= molecules.size()) return;

      float x = col * spacingX + (row % 2 == 0 ? spacingX / 2 : 0);
      float y = row * spacingY;

      x += offsetX;
      y += offsetY;

      if (x < width && y < height) {
        molecules.get(idx).freezeTo(new PVector(x, y));
        idx++;
      }
    }
  }
}
