/**
 * Visualisation of dq0 transform
 *
 * Copyright (c) 2012 Steven Blair
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

final int MAX_WIDTH = 750;
final int MAX_HEIGHT = 650;
final int X_START = 250;
final int PHASORS_START_Y = 85;
final int PHASORS_START_X = 70;
final int PHASOR_HEIGHT = 50;
final int PHASOR_LINE_WIDTH = 3;
final int ONE_PU_HEIGHT = 100;
final int WAVEFORMS_START_X = PHASORS_START_X + 130;
final int WAVEFORMS_END_X = 650;
final int WAVEFORMS_LABEL_X = WAVEFORMS_END_X + 35;

final int Y_INTERVAL = 300;
final int THREE_PHASE_START = 150;
final int DQ0_START = THREE_PHASE_START + Y_INTERVAL;

final float TWO_PI_OVER_THREE = 2.0943951023931954923084289221863;
final float NEG_TWO_PI_OVER_THREE = -2.0943951023931954923084289221863;

final int DQ0_TYPE_MATLAB = 0;
final int DQ0_TYPE_CLASSIC = 1;
final int DQ0_TYPE_WIKIPEDIA = 2;

final int ZERO_SEQ = 0;
final int POS_SEQ = 1;
final int NEG_SEQ = 2;

final float zeroSeq[] = {0.0, 0.0, 0.0};
final float posSeq[] = {0.0, NEG_TWO_PI_OVER_THREE, TWO_PI_OVER_THREE};
final float negSeq[] = {0.0, TWO_PI_OVER_THREE, NEG_TWO_PI_OVER_THREE};

final color VaColor = color(180, 33, 38);     // red
final color VbColor = color(222, 215, 20);    // yellow
final color VcColor = color(36, 78, 198);     // blue

final color posColor = color(226, 99, 102);   // salmon
final color negColor = color(226, 99, 150);   // pink
final color zeroColor = color(226, 226, 226); // light grey

final color dColor = color(36, 78, 198);      // blue
final color qColor = color(34, 177, 76);      // green
final color oColor = color(200, 191, 231);    // blueish
final color white = color(255, 255, 255);     // white

// initial values defined in JavaScript code
float posMag;
float posPhase;
float negMag;
float negPhase;
float zeroMag;
float zeroPhase;
int harmonicNumber;
int harmonicSeq;
float harmonicMag;
float harmonicPhase;
int dq0Type;

final float f = 50.0;
final float w = 2 * PI * f;        // system angular speed
float theta = 0.0;

final float Ts = 0.00002;
final float totalTime = 0.040;
final int ITERATIONS = int(totalTime / Ts);

float Va[] = new float[ITERATIONS];
float Vb[] = new float[ITERATIONS];
float Vc[] = new float[ITERATIONS];

float d[] = new float[ITERATIONS];
float q[] = new float[ITERATIONS];
float o[] = new float[ITERATIONS];


void updateValues() {
  posMag = Processing.data.posMag;
  posPhase = Processing.data.posPhase * PI / 180.0;
  negMag = Processing.data.negMag;
  negPhase = Processing.data.negPhase * PI / 180.0;
  zeroMag = Processing.data.zeroMag;
  zeroPhase = Processing.data.zeroPhase * PI / 180.0;
  harmonicNumber = Processing.data.harmonicNumber;
  harmonicSeq = Processing.data.harmonicSeq;
  harmonicMag = Processing.data.harmonicMag;
  harmonicPhase = Processing.data.harmonicPhase * PI / 180.0;
  dq0Type = Processing.data.dq0Type;
}

float harmonic(float wt, int phaseNumber) {
  float seqAngle = 0.0;

  if (harmonicSeq == 1) {
    seqAngle = posSeq[phaseNumber];
  }
  else if (harmonicSeq == 2) {
    seqAngle = negSeq[phaseNumber];
  }

  return harmonicMag * sin(wt * harmonicNumber + harmonicPhase + seqAngle);
}

void drawPhasors(float m, float ang, int x, int y, color c, boolean zeroSequence) {
  // draw axes
  stroke(50);
  strokeWeight(2);
  line(x - PHASOR_HEIGHT, y, x + PHASOR_HEIGHT, y);
  line(x, y - PHASOR_HEIGHT, x, y + PHASOR_HEIGHT);

  float mDraw = m * PHASOR_HEIGHT;

  for (int j = 0; j < 3; j++) {
    // shift phases B and C by 120deg (-/+ respectively)
    if (zeroSequence == false) {
      if (j == 1) {
        ang -= radians(120);
      }
      else if (j == 2) {
        ang += radians(240);
      }
    }

    strokeWeight(PHASOR_LINE_WIDTH);
    stroke(c, 255 - j * 70);
    line(x, y, x + mDraw*cos(ang), y - mDraw*sin(ang));
  }
}

void plot(float[] data, int startY, int colour, boolean drawAxis) {
  if (drawAxis) {
    stroke(50);
    strokeWeight(2);
    line(WAVEFORMS_START_X - 20, startY, WAVEFORMS_END_X + 20, startY);                                   // x-axis
    line(WAVEFORMS_START_X, startY - ONE_PU_HEIGHT - 20, WAVEFORMS_START_X, startY + ONE_PU_HEIGHT + 20); // y-axis
    text("0.0", WAVEFORMS_START_X - 35, startY + 4);
    text("1.0", WAVEFORMS_START_X - 35, startY - ONE_PU_HEIGHT + 4);
  }

  // draw waveform
  strokeWeight(2);
  stroke(colour, 255);
  noFill();
  beginShape(POLYGON);

  for (int t = 0; t < ITERATIONS; t++) {
    vertex(WAVEFORMS_START_X + (float(t) * float(WAVEFORMS_END_X - WAVEFORMS_START_X)) / ITERATIONS, startY - (data[t] * ONE_PU_HEIGHT));
  }

  endShape();
}

void setup() {
  size(MAX_WIDTH, MAX_HEIGHT);
  background(0);

  font = createFont("SansSerif.plain", 12, true);
  textFont(font);
  textSize(14);
  //textLeading(10);
  textAlign(CENTER);

  smooth();
  colorMode(HSB);
  frameRate(60);

  updateValues();

  reset();  // implemented in JavaScript
}

void draw() {
  if (Processing.data.change == true) {
    Processing.data.change = false;
    
    updateValues();

    background(0);
    textFont(font);
    fill(white);

    drawPhasors(posMag, posPhase, PHASORS_START_X, PHASORS_START_Y, posColor, false);
    drawPhasors(negMag, negPhase, PHASORS_START_X, PHASORS_START_Y + 125, negColor, false);
    drawPhasors(zeroMag, zeroPhase, PHASORS_START_X, PHASORS_START_Y + 250, zeroColor, true);

    color harmonicColour;

    if (harmonicSeq == 1) {
      harmonicColour = posColor;
    }
    else if (harmonicSeq == 2) {
      harmonicColour = negColor;
    }
    else if (harmonicSeq == 0) {
      harmonicColour = zeroColor;
    }

    drawPhasors(harmonicMag, harmonicPhase, PHASORS_START_X, PHASORS_START_Y + 450, harmonicColour, false);

    // compute input waveforms at each time-step
    for (int t = 0; t < ITERATIONS; t++) {
      theta = w * (float(t) * Ts);

      Va[t] = posMag*sin(theta + posPhase) + negMag*sin(theta + negPhase) + zeroMag*sin(theta + zeroPhase) + harmonic(theta, 0);
      Vb[t] = posMag*sin(NEG_TWO_PI_OVER_THREE + theta + posPhase) + negMag*sin(TWO_PI_OVER_THREE + theta + negPhase) + zeroMag*sin(theta + zeroPhase) + harmonic(theta, 1);
      Vc[t] = posMag*sin(TWO_PI_OVER_THREE + theta + posPhase) + negMag*sin(NEG_TWO_PI_OVER_THREE + theta + negPhase) + zeroMag*sin(theta + zeroPhase) + harmonic(theta, 2);

      if (dq0Type == 0) {
        d[t] = (2.0 / 3.0) * (Va[t] * sin(theta) + Vb[t] * sin(theta - TWO_PI_OVER_THREE) + Vc[t] * sin(theta + TWO_PI_OVER_THREE));
        q[t] = (2.0 / 3.0) * (Va[t] * cos(theta) + Vb[t] * cos(theta - TWO_PI_OVER_THREE) + Vc[t] * cos(theta + TWO_PI_OVER_THREE));
      }
      else if (dq0Type == 1) {
        d[t] = (2.0 / 3.0) * (Va[t] * cos(theta) + Vb[t] * cos(theta - TWO_PI_OVER_THREE) + Vc[t] * cos(theta + TWO_PI_OVER_THREE));
        q[t] = (2.0 / 3.0) * (Va[t] * -sin(theta) + Vb[t] * -sin(theta - TWO_PI_OVER_THREE) + Vc[t] * -sin(theta + TWO_PI_OVER_THREE));
      }
      else if (dq0Type == 2) {
        d[t] = (2.0 / 3.0) * (Va[t] * cos(theta) + Vb[t] * cos(theta - TWO_PI_OVER_THREE) + Vc[t] * cos(theta + TWO_PI_OVER_THREE));
        q[t] = (2.0 / 3.0) * (Va[t] * sin(theta) + Vb[t] * sin(theta - TWO_PI_OVER_THREE) + Vc[t] * sin(theta + TWO_PI_OVER_THREE));
      }
      o[t] = (1.0 / 3.0) * (Va[t] + Vb[t] + Vc[t]);
    }

    fill(VaColor);
    text("A", WAVEFORMS_LABEL_X, THREE_PHASE_START + 4);
    fill(VbColor);
    text("B", WAVEFORMS_LABEL_X + 15, THREE_PHASE_START + 4);
    fill(VcColor);
    text("C", WAVEFORMS_LABEL_X + 30, THREE_PHASE_START + 4);
    fill(white);
    plot(Va, THREE_PHASE_START, VaColor, true);
    plot(Vb, THREE_PHASE_START, VbColor, false);
    plot(Vc, THREE_PHASE_START, VcColor, false);

    fill(dColor);
    text("d", WAVEFORMS_LABEL_X, DQ0_START + 4);
    fill(qColor);
    text("q", WAVEFORMS_LABEL_X + 15, DQ0_START + 4);
    fill(oColor);
    text("0", WAVEFORMS_LABEL_X + 30, DQ0_START + 4);
    plot(d, DQ0_START, dColor, true);
    plot(q, DQ0_START, qColor, false);
    plot(o, DQ0_START, oColor, false);
  }
}