import ddf.minim.*;
import ddf.minim.analysis.*;

abstract class BeatDetectingPattern extends LXPattern {

    final BasicParameter hue = new BasicParameter("Hue", 135, 0, 360);
    final BasicParameter y;

    Minim minim;
    AudioInput in;
    BeatDetect beat;

    int beatOffset = 0;

    BeatDetectingPattern(LX lx) {
        super(lx);
        addParameter(hue);
        addParameter(y = new BasicParameter("Y", lx.model.yMin, lx.model.yMin, lx.model.yMax));
        minim = new Minim(this);
        in = minim.getLineIn(Minim.STEREO, int(1024));
        println("did linein");
        beat = new BeatDetect(1024, 44000);
        //beat = new BeatDetect(in.timeSize(), 44000);
        beat.setSensitivity(20);
        println("did beatdet");
    }

    public void beat() {
        beatOffset = 0;
        //println("Beat. " + lx.tempo.ramp());
        //setColors(lx.hsb(hue.getValuef(), 100, 100));
    }

    abstract boolean isBeat();

    public void run(double deltaMs) {
        beat.detect(in.mix);
        //if ( beat.isOnset() ) {
        //if ( beat.isSnare () ) {
        //if ( beat.isKick() ) {
        //if ( beat.isHat() ) {
        if ( isBeat() ) {
            this.beat();
/*
            for (Cube cube : model.cubes) {
                colors[cube.index] = lx.hsb(0, 0, 0);
            }
*/
        }
        float var_y = float(beatOffset);
        for (Cube cube : model.cubes) {
            //if (cube.y < var_y + 10 && cube.y > var_y - 10){
            if (cube.y < var_y + 10){
                colors[cube.index] = lx.hsb(hue.getValuef(), 100, 100);
            } else {
                colors[cube.index] = lx.hsb(0, 100, 0);
            }
        }
        beatOffset += 30;
    }
}

class BeatPattern extends BeatDetectingPattern {
    BeatPattern(LX lx) {
        super(lx);
        hue.setValue(235);
    }
    public boolean isBeat(){ return beat.isOnset(); }
}

class SnarePattern extends BeatDetectingPattern {
    SnarePattern(LX lx) {
        super(lx);
        hue.setValue(135);
    }
    public boolean isBeat(){ return beat.isSnare(); }
}

class KickPattern extends BeatDetectingPattern {
    KickPattern(LX lx) {
        super(lx);
        hue.setValue(35);
    }
    public boolean isBeat(){ return beat.isKick(); }
}
