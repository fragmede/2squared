class SamsonTrip extends LXPattern {
    final BasicParameter hue = new BasicParameter("Hue", 135, 0, 360);
    final BasicParameter y;

    int beatOffset = 0;

    SamsonTrip(LX lx) {
        super(lx);
        addParameter(hue);
        addParameter(y = new BasicParameter("Y", lx.model.yMin, lx.model.yMin, lx.model.yMax));
    }

    public void beat() {
        beatOffset = 0;
        println("Beat." + lx.tempo.ramp());
        //setColors(lx.hsb(hue.getValuef(), 100, 100));
    }

    public void run(double deltaMs) {
        //println(lx.tempo.rampf());
        int m = millis();
        int last = m + 100;
        if (last < m + 10) {
            ;
        }
        else if (lx.tempo.rampf() < .04){
            this.beat();
            last = m;
            for (Cube cube : model.cubes) {
                colors[cube.index] = lx.hsb(0, 0, 0);
            }
        }
        float var_y = float(beatOffset);
        for (Cube cube : model.cubes) {
            //var_y = y.getValuef();
            if (cube.y < var_y + 10 && cube.y > var_y - 10){
                //setColors(lx.hsb(hue.getValuef(), 100, 100));
                colors[cube.index] = lx.hsb(hue.getValuef(), 100, 100);
//            } else {
 //               colors[cube.index] = lx.hsb(0, 0, 0);
            }
        }
        beatOffset += 40;
    }

}
