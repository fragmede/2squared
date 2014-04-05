import java.util.Iterator;

class Whisps extends LXPattern {
  
  final BasicParameter baseColor = new BasicParameter("COLR", 210, 360);
  final BasicParameter colorVariability = new BasicParameter("CVAR", 10, 180);
  final BasicParameter direction = new BasicParameter("DIR", 90, 360);
  final BasicParameter directionVariability = new BasicParameter("DVAR", 30, 180);
  final BasicParameter frequency = new BasicParameter("FREQ", 2, .5, 40);
  final BasicParameter thickness = new BasicParameter("WIDT", 2, 1, 20);
  final BasicParameter speed = new BasicParameter("SPEE", 10, 1, 100);
  
  // Possible other parameters:
  //  Distance
  //  Distance variability
  //  width variability
  //  Speed variability
  //  frequency variability
  //  Fade time
  
  double pauseTimerCountdown = 0;
  
  ArrayList<Whisp> whisps;
  
  Whisps(LX lx) {
    super(lx);
    
    whisps = new ArrayList<Whisp>();
    
    addParameter(baseColor);
    addParameter(colorVariability);
    addParameter(direction);
    addParameter(directionVariability);
    addParameter(frequency);
    addParameter(thickness);
    addParameter(speed);
  }
  
  public void run(double deltaMs) {
    clearColors();
    pauseTimerCountdown -= deltaMs;
    if (pauseTimerCountdown <= 0) {
      pauseTimerCountdown = 10000 / frequency.getValuef() / speed.getValuef() + LXUtils.random(-200, 200);
      
      Whisp whisp = new Whisp();
      whisp.runningTimer = 0;
      whisp.runningTimerEnd = 5000 / speed.getValuef();
      whisp.decayTime = whisp.runningTimerEnd;
      float pathDirection = (float)(direction.getValuef()
          + LXUtils.random(-directionVariability.getValuef(), directionVariability.getValuef())) % 360;
      whisp.pathDist = (float)LXUtils.random(80, min(450, 140 / max(0.01, abs(cos(PI * pathDirection / 180)))));
      whisp.startTheta = random(360);
      whisp.startY = (float)LXUtils.random(max(model.yMin, model.yMin - whisp.pathDist
                                                           * sin(PI * pathDirection / 180)),
                                           min(model.yMax, model.yMax - whisp.pathDist
                                                           * sin(PI * pathDirection / 180)));
      whisp.startPoint = new LXPoint(whisp.startTheta, whisp.startY);
      whisp.endTheta = whisp.startTheta + whisp.pathDist * cos(PI * pathDirection / 180);
      whisp.endY = whisp.startY + whisp.pathDist * sin(PI * pathDirection / 180);
      whisp.displayColor = (int)(baseColor.getValuef()
          + LXUtils.random(-colorVariability.getValuef(), colorVariability.getValuef())) % 360;
      whisp.thickness = thickness.getValuef() + (float)LXUtils.random(-.3, .3);
      whisps.add(whisp);
    }
    
    Iterator<Whisp> iter = whisps.iterator();
    while (iter.hasNext()) {
      Whisp whisp = iter.next();
      whisp.run(deltaMs);
      if (!whisp.running) {
        iter.remove();
      }
    }
    for (Cube cube : model.cubes) {
      LXPoint cubePoint = new LXPoint(cube.theta, cube.y);
      for (Whisp whisp : whisps) {
        addColor(cube.index, lx.hsb(whisp.displayColor, 100, whisp.getBrightnessForCube(cubePoint)));
      }
    }
  }
}

class Whisp {
  
  boolean running = true;
  
  float runningTimer;
  float runningTimerEnd;
  float decayTime;
  
  LXPoint startPoint;
  float startTheta;
  float startY;
  float endTheta;
  float endY;
  float pathDist;
  
  int displayColor;
  float thickness;
  
  float percentDone;
  LXPoint currentPoint;
  float currentTheta;
  float currentY;
  float globalFadeFactor;
  
  public void run(double deltaMs) {
    if (running) {
      runningTimer += deltaMs;
      if (runningTimer >= runningTimerEnd + decayTime) {
        running = false;
      } else {
        percentDone = min(runningTimer, runningTimerEnd) / runningTimerEnd;
        currentTheta = (float)LXUtils.lerp(startTheta, endTheta, percentDone);
        currentY = (float)LXUtils.lerp(startY, endY, percentDone);
        currentPoint = new LXPoint(currentTheta, currentY);
        globalFadeFactor = max((runningTimer - runningTimerEnd) / decayTime, 0);
      }
    }
  }
  
  float getBrightnessForCube(LXPoint cubePoint) {
    LXPoint closestPointToTrail = getClosestPointOnLineOnCylinder(startPoint, currentPoint, cubePoint);
    float distFromSource = (float)LXUtils.distance(currentTheta, currentY,
      closestPointToTrail.x, closestPointToTrail.y);
    
    float distFromTrail = sqrt(pow(LXUtils.wrapdistf(closestPointToTrail.x, cubePoint.x, 360), 2)
                         + pow(closestPointToTrail.y - cubePoint.y, 2));
    float tailFadeFactor = distFromSource / pathDist;
    return max(0, (100 - 10 * distFromTrail / thickness) * max(0, 1 - tailFadeFactor - globalFadeFactor));
  }
}

// Assumes thetaA as a reference point
// Moves thetaB to within 180 degrees, letting thetaB go beyond [0, 360)
float moveThetaToSamePlane(float thetaA, float thetaB) {
  if (thetaA - thetaB > 180) {
    return thetaB + 360;
  } else if (thetaB - thetaA > 180) {
    return thetaB - 360;
  } else {
    return thetaB;
  }
}
  
// Gets the closest point on a line segment [a, b] to another point p
// Assumes points are in the form (theta, y) and are on a cylinder.
LXPoint getClosestPointOnLineOnCylinder(LXPoint a, LXPoint b, LXPoint p) {
  // Unwrap the cylinder at 0 degrees to calculate
  // Assume a and b are already on the same plane (aka theta would be negative already)
  
  // Move p onto the same plane as a, if needed
  LXPoint pPrime = new LXPoint(moveThetaToSamePlane(a.x, p.x), p.y);
  
  return getClosestPointOnLine(a, b, pPrime);
}
  
// Gets the closest point on a line segment [a, b] to another point p
// Assumes points are in the form (theta, y)
LXPoint getClosestPointOnLine(LXPoint a, LXPoint b, LXPoint p) {
  
  // adapted from http://stackoverflow.com/a/3122532
  
  // Storing vector A->P
  LXPoint a_to_p = new LXPoint(p.x - a.x, p.y - a.y);
  // Storing vector A->B
  LXPoint a_to_b = new LXPoint(b.x - a.x, b.y - a.y);

  //   Basically finding the squared magnitude of a_to_b
  float atb2 = pow(a_to_b.x, 2) + pow(a_to_b.y, 2);

  // The dot product of a_to_p and a_to_b
  float atp_dot_atb = a_to_p.x*a_to_b.x + a_to_p.y*a_to_b.y;

  // The normalized "distance" from a to your closest point
  float t = LXUtils.constrainf(atp_dot_atb / atb2, 0, 1);

  // Add the distance to A, moving towards B
  return new LXPoint(a.x + a_to_b.x*t, a.y + a_to_b.y*t);
}

class Bubbles extends LXPattern {
  
  boolean running = false;
  double pauseTimerCountdown = 0;
  float startTheta;
  float endTheta;
  float startY;
  float endY;
  double runningTimer;
  double runningTimerEnd;
  
  Bubbles(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    if (running) {
      runningTimer += deltaMs;
      if (runningTimer >= runningTimerEnd) {
        running = false;
        pauseTimerCountdown = 1000;
      }
      for (Cube cube : model.cubes) {
        float distVal = sqrt(pow((LXUtils.wrapdistf((float)LXUtils.lerp(startTheta, endTheta, runningTimer/runningTimerEnd), cube.theta, 360)) * 0.8, 2)
                             + pow((float)LXUtils.lerp(startY, endY, runningTimer/runningTimerEnd) - cube.y, 2));
        colors[cube.index] = lx.hsb(
          200,
          100,
          max(0, 100 - 2 * distVal)
        );
      }
    } else {
      pauseTimerCountdown -= deltaMs;
      if (pauseTimerCountdown <= 0) {
        running = true;
        runningTimer = 0;
        runningTimerEnd = 500;
        startTheta = 0;
        endTheta = 180;
        startY = 200;
        endY = 250;
      }
      for (Cube cube : model.cubes) {
        colors[cube.index] = lx.hsb(
          200,
          100,
          0
        );
      }
    }
  }
}

class Strobe extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("DELA", 100, 30, 2000);
  final SquareLFO toggle = new SquareLFO(0, 100, speed);
  
  Strobe(LX lx) {
    super(lx);
    addParameter(speed);
    addModulator(toggle.start());
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        0,
        toggle.getValuef(),
        100 - toggle.getValuef()
      );
    }
  }
}

class RandomColor extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("Speed", 1, 1, 10);
  
  int frameCount = 0;
  
  RandomColor(LX lx) {
    super(lx);
    addParameter(speed);
  }
  
  public void run(double deltaMs) {
    frameCount++;
    if (frameCount >= speed.getValuef()) {
      for (Cube cube : model.cubes) {
        colors[cube.index] = lx.hsb(
          random(360),
          100,
          100
        );
      }
      frameCount = 0;
    }
  }
}

class RandomColorSync extends LXPattern {
  
  RandomColorSync(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    int colr = (int)random(360);
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        colr,
        100,
        100
      );
    }
  }
}

class RandomColorGlitch extends LXPattern {
  
  RandomColorGlitch(LX lx) {
    super(lx);
  }
  
  final int brokenCubeIndex = (int)random(model.cubes.size());
  final int cubeColor = (int)random(360);
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      if (cube.index == brokenCubeIndex) {
        colors[cube.index] = lx.hsb(
          random(360),
          100,
          100
        );
      } else {
        colors[cube.index] = lx.hsb(
          cubeColor,
          100,
          100
        );
      }
    }
  }
}

class Fade extends LXPattern {
  
  final SinLFO colr = new SinLFO(0, 360, 11000);
  
  Fade(LX lx) {
    super(lx);
    addModulator(colr.start());
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        (int)colr.getValuef(),
        100,
        100
      );
    }
  }
}

class Palette extends LXPattern {
  
  Palette(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        cube.index % 360,
        100,
        100
      );
    }
  }
}
