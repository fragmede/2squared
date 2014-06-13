class SamsonTrip extends LXPattern {
  final BasicParameter hue = new BasicParameter("Hue", 135, 0, 360);
  final BasicParameter y;

  SamsonTrip(LX lx) {
    super(lx);
    addParameter(hue);
    addParameter(y = new BasicParameter("Y", lx.model.yMin, lx.model.yMin, lx.model.yMax));
  }
    
  public void run(double deltaMs) {
    float var_y;
    for (Cube cube : model.cubes) {
        var_y = y.getValuef();
        if (cube.y < var_y + 10 && cube.y > var_y - 10){
            //setColors(lx.hsb(hue.getValuef(), 100, 100));
            colors[cube.index] = lx.hsb(hue.getValuef(), 100, 100);
        } else {
            colors[cube.index] = lx.hsb(0, 0, 0);
        }
     }
    
  }
  
}
