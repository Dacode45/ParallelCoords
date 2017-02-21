import java.util.List;
import java.util.ArrayList;
import java.util.Set;
import java.util.HashSet;
import java.util.Map;
import java.util.HashMap;

final float PIXELWIDTH_PER_CHAR = 12;
final float PIXELHEIGHT_PER_CHAR = 12;
List<Float> bucketPos;
class Graph {
  
  Table table;
  int numRows = 0;
  int[] DimensionDirection; // +1 for up, -1 for down.
  Boolean justClicked = false;
  int clickedFrames = 0;
  Boolean columnSelected = false;
  int selectedColumn;
  
  // View paramaters
  float draw_width;
  float draw_height;
  float draw_x;
  float draw_y;
  float padding = 20;
  
  // Bounding box 
  Boolean bboxStart = false;
  Point bboxStartPoint;
  Set<Line> bbox;
  Set<Line> selectedLines;
  
  ArrayList<Set<Line>> lineSets; //By column
  ArrayList<Set<Line>> lineGroups; // By Row
  Set<Line> allLines;
  
  Graph(Table t) {
    LoadTable(t);
  }
  
  // State functions
  void onMousePressed() {
    if (!bboxStart) {
      bboxStart = true;
      bboxStartPoint = new Point(mouseX, mouseY);
    }

  }
  
  void onMouseReleased() {
    
    if (bboxStart) {
        selectedLines = new HashSet<Line>();
        Set<Line> bbox = new HashSet<Line>();
        float lx = bboxStartPoint.x;
        float ly = bboxStartPoint.y;
        float mousex = mouseX;
        if (mousex == lx) {
           mousex ++;
        }
        
        bbox.add(new Line(new Point(lx, ly) , new Point(mousex, ly)));
        bbox.add(new Line(new Point(mousex, ly) , new Point(mousex+1, mouseY)));
        bbox.add(new Line(new Point(mousex+1, mouseY) , new Point(lx+1, mouseY)));
        bbox.add(new Line(new Point(lx+1, mouseY) , new Point(lx, ly)));
        
        Set<Line> result = highlightSelection(lineSets, bbox);
        for(Line l : result) {
           Set<Line> group = lineGroups.get(l.row);
           selectedLines.addAll(group);
        }
    }
 
    bboxStart = false;
    justClicked = true;
    columnSelected = false;
     
  }
  
  // Functions for drawing 
  
  void Resize(float x, float y, float w, float h) {
      draw_x = x;
      draw_y = y;
      draw_height = h;
      draw_width = w;
      LoadLines();
      
  }
  
  void DrawBBox() {
    if (bboxStart) {
      fill(color(255,204,0, 100));
      rect(bboxStartPoint.x, bboxStartPoint.y, (mouseX-bboxStartPoint.x), (mouseY-bboxStartPoint.y));
    }
  }
  
  void DrawAxis() {
    fill(color(0,0,0));
    stroke(color(0,0,0));
    strokeWeight(1);
    
    // left and bottom axis.
    line(l_x(), b_y(), l_x(), t_y());
    line(l_x(), b_y(), r_x(), b_y());
    
    // create parallel lines 
    float vert_tick = v_tick(2*padding);
    float hor_tick = h_tick();
    float top_y = t_y() + 2*padding;
   
   for (int i = 1; i <= NumColumns(); i++) {
     float axis_x = l_x() + hor_tick*i;
     line(axis_x, b_y(), axis_x, top_y);    
     
     // y tick marks for every line
     for (int j = 1; j <= 10; j++) {
         float axis_y = (top_y) + vert_tick*j;
         line(axis_x-10, axis_y , axis_x, axis_y);
     }
   }
   
   fill(0,0,0);
   // Fill the x axis titles. 
   for (int i = 1; i <= NumColumns(); i++) {
     float roundedMax = ((ceil(MaxForColumn(i-1))+9)/10)*10;
     String maxTitle = String.format("%.02f", roundedMax);
     String columnTitle = GetColumnTitle(i-1); 
     
      
     float axis_x = l_x() + hor_tick*i;
     text(maxTitle, axis_x - maxTitle.length()/2 * PIXELWIDTH_PER_CHAR, t_y() - padding);
     //rect(x, y, PIXELWIDTH_PER_CHAR * text.length() + padding, PIXELHEIGHT_PER_CHAR + padding);
     if (justClicked) {
       if(mouseX > axis_x - columnTitle.length()/2 * PIXELWIDTH_PER_CHAR - padding &&
           mouseX < axis_x + columnTitle.length()/2 * PIXELWIDTH_PER_CHAR + padding &&
            mouseY > t_y() &&
             mouseY < t_y() + padding ) {
         columnSelected = true;
         selectedColumn = i-1;
       }
     }
     if (columnSelected && selectedColumn == i-1) {
       fill(0, 0, 255);
     } else {
       fill(0,0,0);
     }
     DrawTextBox(axis_x - columnTitle.length()/2 * PIXELWIDTH_PER_CHAR - padding, t_y(), columnTitle);
     fill(0,0,0);
     // y tick marks 
     for (int j = 1; j <= 10; j++) {
       float tenths =(roundedMax/10.0);
       String tenthTitle = Float.toString(roundedMax - tenths*j);
       float text_x = axis_x ;
       float text_y;
       if (DimensionDirection[i-1] > 0) {
          text_y = top_y  + vert_tick*j + tenthTitle.length()/2 * PIXELWIDTH_PER_CHAR;
       } else {  
          text_y = top_y  + vert_tick*(11-j) + tenthTitle.length()/2 * PIXELWIDTH_PER_CHAR;
       }
       pushMatrix();
       translate(text_x, text_y);
       rotate(-HALF_PI);
       text(tenthTitle, 0, 0);
       popMatrix();
     }
   }
  }
  
  void DrawLine(Line l) {
    line(l.lpoint.x, l.lpoint.y, l.rpoint.x, l.rpoint.y);
  }
  
  void DrawLines() {
    color red = color(255, 0, 0);
    color yellow = color(255, 255, 0);
    strokeWeight(1);
      for (Line l : allLines) {
        stroke(lerpColor(red, yellow, float(l.row)/numRows));
         DrawLine(l);
      }
    
  }
  
  void DrawTextBox(float x, float y, String text) {
      rect(x, y, PIXELWIDTH_PER_CHAR * text.length() + padding/2, PIXELHEIGHT_PER_CHAR + padding);
      fill(255,255,255);
      text(text, x + (PIXELWIDTH_PER_CHAR * text.length() + padding/2)/2, y + PIXELHEIGHT_PER_CHAR + padding/2);
  }
  
  
  void DrawHover() {
    Point mouse = new Point(mouseX, mouseY);
    Line hoverLine = null;
      for (Line l : allLines) {
        if (l.containsPoint(mouse)) {
          hoverLine = l;
          break;
        }
    }
    if (hoverLine != null) {
      Set<Line> hoverLines = lineGroups.get(hoverLine.row);
       stroke(color(0,0,255));
       strokeWeight(5);
       for (Line l : hoverLines) {
          DrawLine(l);
       }
       String columnTitle = GetColumnTitle(NumColumns());
       TableRow row = table.getRow(hoverLine.row);
       String name = row.getString(columnTitle);
       DrawTextBox(mouseX+10, mouseY-10, name);
     
    }
  }
  
  void DrawArrow(float x1, float y1, float x2, float y2) {
    line(x1, y1, x2, y2);
    pushMatrix();
    translate(x2, y2);
    float a = atan2(x1-x2, y2-y1);
    rotate(a);
    line(0, 0, -10, -10);
    line(0, 0, 10, -10);
    popMatrix();
  } 

  void DrawDimensionFlip() {
    
       strokeWeight(1);
      for (int i = 1; i <= NumColumns(); i++) {
       float axis_x = l_x() + h_tick()*i;
       fill(0,0,255);
       rect(axis_x - padding/2, b_y(), padding, padding);
       if (justClicked) {
         if (mouseX > axis_x - padding/2 && mouseX < axis_x + padding/2 && mouseY > b_y() && mouseY < b_y() + padding) {
           DimensionDirection[i-1] *= -1;  
           LoadLines();
         }
       }
       stroke(0,0,0);
       if (DimensionDirection[i-1] > 0) {
         DrawArrow(axis_x, b_y() + padding, axis_x, b_y());
       } else {
         DrawArrow(axis_x, b_y(), axis_x, b_y()+padding);
       }
       
      }
  }
  
  void DrawSelectedLines() {
    if (selectedLines == null) {
      return;  
    }
    for(Line l : selectedLines) {
      stroke(255,255,0);
      strokeWeight(3);
      DrawLine(l);
    }
  }
  
  
  void Draw() {
    DrawLines();
    DrawAxis(); 
    DrawBBox();
    DrawHover();
    DrawDimensionFlip();
    DrawSelectedLines();
 
    justClicked = false;
    
  }
    
  // Table Functions
  
  void LoadLines() {
    lineSets = new ArrayList<Set<Line>>();
    lineGroups = new ArrayList<Set<Line>>();
    allLines = new HashSet<Line>();
    bucketPos = new ArrayList<Float>();
    
    for (int i = 0; i < NumColumns(); i++) {
      lineSets.add(new HashSet<Line>());
    }
     
    float vert_tick = v_tick(2*padding);
    float hor_tick = h_tick();
    float top_y = t_y() + 2*padding;
   
    for (int i = 1; i < NumColumns(); i++) {
      float roundedMax0 = ((ceil(MaxForColumn(i-1))+9)/10)*10;  
      float roundedMax1 = ((ceil(MaxForColumn(i))+9)/10)*10;  
      bucketPos.add(l_x() + h_tick() * (i));
      int j = 0;
      numRows = 0;
      for (TableRow row : table.rows()) {
         if (j >= lineGroups.size()) {
           lineGroups.add(new HashSet<Line>());  
         }
         String columnTitle0 = row.getColumnTitle(i-1);
         float value0 = row.getFloat(columnTitle0);
         String columnTitle1 = row.getColumnTitle(i);
         float value1 = row.getFloat(columnTitle1);
         
         
         float x0 = l_x() + h_tick() * (i);
         float y0;
         if (DimensionDirection[i-1] > 0) {
           y0 = b_y() - ( b_y() - top_y) * (value0/roundedMax0);  
         } else {
           y0 = t_y() + ( b_y() - top_y) * (value0/roundedMax0);
         }
         
         float x1 = l_x() + h_tick() * (i+1);
         float y1;
         if (DimensionDirection[i] > 0) {
           y1 = b_y() - (b_y() - top_y) * (value1/roundedMax1);
         } else {
           y1 = t_y() + (b_y() - top_y) * (value1/roundedMax1);
         }
         
         Line l = new Line(new Point(x0,y0), new Point(x1,y1));
         l.key = i-1;
         l.row = j;
         Set<Line> set = lineSets.get(i-1);
         set.add(l);
         set = lineGroups.get(j);
         set.add(l);
         allLines.add(l);
         numRows++;
         j++;
      }
    }
  }

  void LoadTable(Table t) {
    table = t; 
    DimensionDirection = new int[NumColumns()+1];
    for(int i = 0; i < DimensionDirection.length; i++) {
        DimensionDirection[i] = -1;
    }
  }
  
  String GetColumnTitle(int index) {
    TableRow row = table.getRow(index);
    return row.getColumnTitle(index);
  }
  
  float MaxForColumn(int index) {
    
    float maxValue = Float.NEGATIVE_INFINITY;
    for (TableRow row : table.rows()) {  
      String columnTitle = row.getColumnTitle(index);
      maxValue = max(maxValue, row.getFloat(columnTitle));
    }
    return maxValue;   
  }
  
  float MinForColumn(int index) {
    
    float minValue = Float.POSITIVE_INFINITY;
    for (TableRow row : table.rows()) {  
      String columnTitle = row.getColumnTitle(index);
      minValue = max(minValue, row.getFloat(columnTitle));
    }
    return minValue;   
  }
  
  // NumColumns returns the number of data columns (n-1)
  int NumColumns() {
     return table.getColumnCount() - 1;
  }
  
  float v_tick(float padding) {
    return (b_y() - t_y() - ( padding) ) / 11; 
  }
  
  // Functions for drawing
  float h_tick() {
    return (r_x() - l_x())/NumColumns();
  }
  
  float l_x() {
    return draw_x + padding;
  }
  float r_x() {
    return draw_x + draw_width - padding;
  }
  
  float t_y() {
    return draw_y + padding;
  }
  
  float b_y() {
    return draw_y + draw_height - padding; 
  }
}  

Graph graph;
void setup() {
 size(800, 900);
 frameRate(30);
 textSize(PIXELWIDTH_PER_CHAR);
 textAlign(CENTER, BOTTOM);
 Table table = loadTable("auto-mpg.csv", "header");
 
 graph = new Graph(table);
 graph.Resize(100, 100, 600, 600);
 surface.setResizable(true);
}

void draw() {
 background(255, 255, 255, 1);
 if (graph.draw_width != 0.8*width || graph.draw_height != 0.8 * height) {
   print("Resizing");
   graph.Resize(0.1*width, 0.1*height, 0.8*width, 0.8*height); 
 }
 graph.Draw();
}

void mousePressed() {
 graph.onMousePressed(); 
}

void mouseReleased() {
 graph.onMouseReleased(); 
}
/************************************
Zay
************************************/

class Point {
  float x, y;
  
  public Point(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  public String toString() {
    return "(" + x + "," + y + ")";
  }
}

class Line {
  Point lpoint, rpoint;
  float a, b;  //y = ax - b
  int key; // for indexing.
  int row;
  
  public Line(Point lpoint, Point rpoint, float a, float b) {
    this.lpoint = lpoint;
    this.rpoint = rpoint;
    this.a = a;
    this.b = b;
  }
  
  public Line(Point lpoint, Point rpoint) {
    float m = (rpoint.y - lpoint.y)/(rpoint.x - lpoint.x);
    float b = (m * -1 * rpoint.x) + rpoint.y;
    if (rpoint.x < lpoint.x) {
      Point tmp = lpoint;
      lpoint = rpoint;
      rpoint = tmp;
    }
    this.lpoint = lpoint;
    this.rpoint = rpoint;
    this.a = m;
    this.b = b;
  }
  
  public Boolean containsPoint(Point p) {
    if (p.x < min(lpoint.x, rpoint.x) || p.x > max(lpoint.x, rpoint.x) || p.y < min(lpoint.y, rpoint.y) || p.y > max(lpoint.y, rpoint.y)) {
      return false;  
    }
    float y = a*p.x + b;
    return (y > p.y-1 && y < p.y+1);
  }
  
  
  public String toString() {
    return lpoint + " " + rpoint + " " + a + " " + b;
  }
}

class PrimalDualData {
  String primalType, dualType;
  Point point;
  Line line;
  
  PrimalDualData(Line line) {
    this.primalType = "line";
    this.dualType = "point";
    this.line = line;
    this.point = convertToPoint(this.line);
  }
  
  PrimalDualData(Point point) {
    this.primalType = "point";
    this.dualType = "line";
    this.point = point;
    this.line = convertToLine(this.point);
  }
  
  private Point convertToPoint(Line line) {
    return new Point(line.a, line.b);
  }
  
  private Line convertToLine(Point point) {
    return new Line(null, null, point.x, point.y);
  }
  
  public String toString() {
    return point + " " + line;
  }
}


void setup2() {
  bucketPos.add(0.0);
  bucketPos.add(100.0);
  
  Set<Line> bbox = new HashSet<Line>();
  bbox.add(new Line(new Point(2,2), new Point(6,2), 0, -2));
  bbox.add(new Line(new Point(3,6), new Point(7,6), 0, -6));
  bbox.add(new Line(new Point(2,2), new Point(3,6), 4, 6));
  bbox.add(new Line(new Point(6,2), new Point(7,6), 4, 22));
  
  List<Set<Line>> lines = new ArrayList<Set<Line>>();
  Set<Line> line_set = new HashSet<Line>();
  line_set.add(new Line(new Point(0,0), new Point(10,10), 1, 0));
  line_set.add(new Line(new Point(1,1), new Point(10,1), 0, 1));
  lines.add(line_set);
  
  Set<Line> result = highlightSelection(lines, bbox);
  
  for (Line line : result) {
    for (Set<Line> lineSet : lines) {
      if (lineSet.contains(line)) {
        println("true");
      }
    }
  }
}

Set<Line> highlightSelection(List<Set<Line>> lines, Set<Line> bbox) {
  //Initialize variables
  Set<Line> result = new HashSet<Line>();
  
  Map<PrimalDualData, PrimalDualData> intersection_to_line;
  Set<PrimalDualData> result_intersections = new HashSet<PrimalDualData>();
  
  Set<PrimalDualData> processed_lines = new HashSet<PrimalDualData>();
  Set<PrimalDualData> processed_bbox = new HashSet<PrimalDualData>();
  
  float minX = Float.MAX_VALUE;
  float maxX = Float.MIN_VALUE;
  float minY = Float.MAX_VALUE;
  float maxY = Float.MIN_VALUE;
  
  //Get bbox boundaries
  for (Line line : bbox) {
    minX = min(minX, line.lpoint.x);
    maxX = max(maxX, line.rpoint.x);
    minY = min(minY, line.lpoint.y);
    maxY = max(maxY, line.rpoint.y);
  }
  
  //Get buckets that contain lines of interest
  int minBucket = 0;
  int maxBucket = 0;
  for (int i = 0; i < bucketPos.size(); i++) {
    if (minX > bucketPos.get(i)) {
      minBucket = i;
    }
    if (bucketPos.get(i) < maxX) {
      maxBucket = i;
    }
  }
  
  //Get dual plane data
  for (int i = minBucket; i < maxBucket + 1; i++) {
    for (Line line : lines.get(i)) {
      processed_lines.add(new PrimalDualData(line));
    }
  }
  
  for (Line line : bbox) {
    processed_bbox.add(new PrimalDualData(line));
  }
  
  //Find intersections
  intersection_to_line = getIntersectionFromDualPoints(processed_lines, processed_bbox);

  //Filter results
  for (PrimalDualData intersection : intersection_to_line.keySet()) {
    if (-intersection.point.x >= minX && -intersection.point.x <= maxX &&
        -intersection.point.y >= minY && -intersection.point.y <= maxY) {
      result_intersections.add(intersection);
    }
  }
  
  //Get relevant line data
  for (PrimalDualData intersection : result_intersections) {
    result.add(intersection_to_line.get(intersection).line);
  }
  
  return result;
}

Map<PrimalDualData, PrimalDualData> getIntersectionFromDualPoints(Set<PrimalDualData> processed_lines, Set<PrimalDualData> processed_bbox) {
  Map<PrimalDualData, PrimalDualData> intersection_to_line = new HashMap<PrimalDualData, PrimalDualData>();
  float slope, yint;
  
  for (PrimalDualData bbox_data : processed_bbox) {
    for (PrimalDualData data : processed_lines) {
      slope = (data.point.y - bbox_data.point.y) / (data.point.x - bbox_data.point.x);
      yint = (slope * data.point.x) - data.point.y;
      intersection_to_line.put(new PrimalDualData(new Line(null, null, slope, yint)), data);
    }
  }
  return intersection_to_line;
}

/*
 void DrawLabel() {
    float hor_tick = (r_x() - l_x())/(numRows/8);
    int i = 0;
    for (TableRow row : table.rows()) {
      color red = color(255, 0, 0);
      color yellow = color(255, 255, 0);
      strokeWeight(5);
      
      float axis_x = l_x() + hor_tick*(i/3) + hor_tick/2 * (i%2);
      float axis_y = b_y() + 2*padding + PIXELHEIGHT_PER_CHAR*(i%8);
      
      String columnTitle = GetColumnTitle(NumColumns());
      String name = row.getString(columnTitle);
      
      text(name, axis_x, axis_y);
      i++;
    }
  }
 */