// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_PINEDRAWINGS_MQH
#define SMC_PINEDRAWINGS_MQH

#define SMC_PINE_MAX_LABELS 500
#define SMC_PINE_MAX_LINES 500

struct SMC_PineLabel
{
   int id;
   string name;
   bool keep;
   bool screen;
   datetime time;
   double price;
   string text;
   color textColor;
   ENUM_ANCHOR_POINT anchor;
   int fontSize;
   int zOrder;
   ENUM_BASE_CORNER corner;
   int xOffset;
   int yOffset;
   ulong renderedHash;
   bool rendered;
};

struct SMC_PineLine
{
   int id;
   string name;
   bool keep;
   datetime firstTime;
   double firstPrice;
   datetime secondTime;
   double secondPrice;
   color lineColor;
   ENUM_LINE_STYLE style;
   int width;
   bool rayLeft;
   bool rayRight;
   int zOrder;
   ulong renderedHash;
   bool rendered;
};

SMC_PineLabel SMC_PineLabels[];
SMC_PineLine SMC_PineLines[];
int SMC_PineNextLabelId=0;
int SMC_PineNextLineId=0;

ulong SMC_PineMix(const ulong hash,const ulong value)
{
   return (hash^value)*1099511628211;
}

ulong SMC_PineDoubleHash(const double value)
{
   union SMC_PineDoubleBits
   {
      double number;
      ulong bits;
   } encoded;
   encoded.number=value;
   return encoded.bits;
}

ulong SMC_PineStringHash(const string value)
{
   ulong hash=1469598103934665603;
   for(int i=0;i<StringLen(value);i++)
      hash=SMC_PineMix(hash,(ulong)StringGetCharacter(value,i));
   return hash;
}

ulong SMC_PineLabelHash(const SMC_PineLabel &label)
{
   ulong hash=1469598103934665603;
   hash=SMC_PineMix(hash,(ulong)label.time);
   hash=SMC_PineMix(hash,SMC_PineDoubleHash(label.price));
   hash=SMC_PineMix(hash,SMC_PineStringHash(label.text));
   hash=SMC_PineMix(hash,(ulong)SMC_RGBColor(label.textColor));
   hash=SMC_PineMix(hash,(ulong)label.anchor);
   hash=SMC_PineMix(hash,(ulong)label.fontSize);
   hash=SMC_PineMix(hash,(ulong)label.zOrder);
   hash=SMC_PineMix(hash,(ulong)label.screen);
   hash=SMC_PineMix(hash,(ulong)label.corner);
   hash=SMC_PineMix(hash,(ulong)label.xOffset);
   hash=SMC_PineMix(hash,(ulong)label.yOffset);
   return hash;
}

ulong SMC_PineLineHash(const SMC_PineLine &line)
{
   ulong hash=1469598103934665603;
   hash=SMC_PineMix(hash,(ulong)line.firstTime);
   hash=SMC_PineMix(hash,SMC_PineDoubleHash(line.firstPrice));
   hash=SMC_PineMix(hash,(ulong)line.secondTime);
   hash=SMC_PineMix(hash,SMC_PineDoubleHash(line.secondPrice));
   hash=SMC_PineMix(hash,(ulong)SMC_RGBColor(line.lineColor));
   hash=SMC_PineMix(hash,(ulong)line.style);
   hash=SMC_PineMix(hash,(ulong)line.width);
   hash=SMC_PineMix(hash,(ulong)line.rayLeft);
   hash=SMC_PineMix(hash,(ulong)line.rayRight);
   hash=SMC_PineMix(hash,(ulong)line.zOrder);
   return hash;
}

int SMC_PineFindLabel(const string name)
{
   for(int i=0;i<ArraySize(SMC_PineLabels);i++)
      if(SMC_PineLabels[i].name==name)
         return i;
   return -1;
}

int SMC_PineFindLine(const string name)
{
   for(int i=0;i<ArraySize(SMC_PineLines);i++)
      if(SMC_PineLines[i].name==name)
         return i;
   return -1;
}

void SMC_PineRemoveLabelAt(const int index,const bool deleteChartObject)
{
   if(index<0 || index>=ArraySize(SMC_PineLabels))
      return;
   if(deleteChartObject && ObjectFind(0,SMC_PineLabels[index].name)>=0 &&
      !ObjectDelete(0,SMC_PineLabels[index].name))
      PrintFormat("SMC: unable to delete managed label '%s' (error=%d).",
                  SMC_PineLabels[index].name,GetLastError());
   int count=ArraySize(SMC_PineLabels);
   for(int i=index;i<count-1;i++)
      SMC_PineLabels[i]=SMC_PineLabels[i+1];
   if(ArrayResize(SMC_PineLabels,count-1)!=count-1)
      PrintFormat("SMC: unable to remove managed label (error=%d).",
                  GetLastError());
}

void SMC_PineRemoveLineAt(const int index,const bool deleteChartObject)
{
   if(index<0 || index>=ArraySize(SMC_PineLines))
      return;
   if(deleteChartObject && ObjectFind(0,SMC_PineLines[index].name)>=0 &&
      !ObjectDelete(0,SMC_PineLines[index].name))
      PrintFormat("SMC: unable to delete managed line '%s' (error=%d).",
                  SMC_PineLines[index].name,GetLastError());
   int count=ArraySize(SMC_PineLines);
   for(int i=index;i<count-1;i++)
      SMC_PineLines[i]=SMC_PineLines[i+1];
   if(ArrayResize(SMC_PineLines,count-1)!=count-1)
      PrintFormat("SMC: unable to remove managed line (error=%d).",
                  GetLastError());
}

void SMC_PineCollectLabels()
{
   while(ArraySize(SMC_PineLabels)>SMC_PINE_MAX_LABELS)
   {
      int oldest=-1;
      for(int i=0;i<ArraySize(SMC_PineLabels);i++)
      {
         if(SMC_PineLabels[i].keep)
            continue;
         if(oldest<0 || SMC_PineLabels[i].id<SMC_PineLabels[oldest].id)
            oldest=i;
      }
      if(oldest<0)
         return;
      SMC_PineRemoveLabelAt(oldest,true);
   }
}

void SMC_PineCollectLines()
{
   while(ArraySize(SMC_PineLines)>SMC_PINE_MAX_LINES)
   {
      int oldest=-1;
      for(int i=0;i<ArraySize(SMC_PineLines);i++)
      {
         if(SMC_PineLines[i].keep)
            continue;
         if(oldest<0 || SMC_PineLines[i].id<SMC_PineLines[oldest].id)
            oldest=i;
      }
      if(oldest<0)
         return;
      SMC_PineRemoveLineAt(oldest,true);
   }
}

bool SMC_PineRenderLabel(SMC_PineLabel &label)
{
   long type=label.screen ? OBJ_LABEL : OBJ_TEXT;
   if(ObjectFind(0,label.name)>=0 &&
      ObjectGetInteger(0,label.name,OBJPROP_TYPE)!=type)
   {
      if(!ObjectDelete(0,label.name))
      {
         PrintFormat("SMC: unable to replace managed label '%s' (error=%d).",
                     label.name,GetLastError());
         return false;
      }
      label.rendered=false;
   }
   ulong hash=SMC_PineLabelHash(label);
   if(ObjectFind(0,label.name)>=0 && label.rendered &&
      label.renderedHash==hash)
      return true;
   if(ObjectFind(0,label.name)<0 &&
      !ObjectCreate(0,label.name,(ENUM_OBJECT)type,0,label.time,label.price))
   {
      PrintFormat("SMC: unable to create managed label '%s' (error=%d).",
                  label.name,GetLastError());
      return false;
   }
   bool success=true;
   if(!label.screen && !ObjectMove(0,label.name,0,label.time,label.price))
      success=false;
   if(!ObjectSetString(0,label.name,OBJPROP_TEXT,label.text))
      success=false;
   if(!ObjectSetString(0,label.name,OBJPROP_FONT,"Arial"))
      success=false;
   if(!ObjectSetInteger(0,label.name,OBJPROP_FONTSIZE,label.fontSize))
      success=false;
   if(!ObjectSetInteger(0,label.name,OBJPROP_COLOR,SMC_RGBColor(label.textColor)))
      success=false;
   if(!ObjectSetInteger(0,label.name,OBJPROP_ANCHOR,label.anchor))
      success=false;
   if(!ObjectSetInteger(0,label.name,OBJPROP_BACK,false))
      success=false;
   if(!ObjectSetInteger(0,label.name,OBJPROP_ZORDER,label.zOrder))
      success=false;
   if(!ObjectSetInteger(0,label.name,OBJPROP_SELECTABLE,false))
      success=false;
   if(!ObjectSetInteger(0,label.name,OBJPROP_SELECTED,false))
      success=false;
   if(!ObjectSetInteger(0,label.name,OBJPROP_HIDDEN,true))
      success=false;
   if(!ObjectSetString(0,label.name,OBJPROP_TOOLTIP,"\n"))
      success=false;
   if(label.screen)
   {
      if(!ObjectSetInteger(0,label.name,OBJPROP_CORNER,label.corner))
         success=false;
      if(!ObjectSetInteger(0,label.name,OBJPROP_XDISTANCE,label.xOffset))
         success=false;
      if(!ObjectSetInteger(0,label.name,OBJPROP_YDISTANCE,label.yOffset))
         success=false;
   }
   if(!success)
   {
      PrintFormat("SMC: unable to update managed label '%s' (error=%d).",
                  label.name,GetLastError());
      label.rendered=false;
      return false;
   }
   label.renderedHash=hash;
   label.rendered=true;
   return true;
}

bool SMC_PineRenderLine(SMC_PineLine &line)
{
   if(ObjectFind(0,line.name)>=0 &&
      ObjectGetInteger(0,line.name,OBJPROP_TYPE)!=(long)OBJ_TREND)
   {
      if(!ObjectDelete(0,line.name))
      {
         PrintFormat("SMC: unable to replace managed line '%s' (error=%d).",
                     line.name,GetLastError());
         return false;
      }
      line.rendered=false;
   }
   ulong hash=SMC_PineLineHash(line);
   if(ObjectFind(0,line.name)>=0 && line.rendered &&
      line.renderedHash==hash)
      return true;
   if(ObjectFind(0,line.name)<0 &&
      !ObjectCreate(0,line.name,OBJ_TREND,0,line.firstTime,line.firstPrice,
                    line.secondTime,line.secondPrice))
   {
      PrintFormat("SMC: unable to create managed line '%s' (error=%d).",
                  line.name,GetLastError());
      return false;
   }
   bool success=true;
   if(!ObjectMove(0,line.name,0,line.firstTime,line.firstPrice))
      success=false;
   if(!ObjectMove(0,line.name,1,line.secondTime,line.secondPrice))
      success=false;
   if(!ObjectSetInteger(0,line.name,OBJPROP_COLOR,SMC_RGBColor(line.lineColor)))
      success=false;
   if(!ObjectSetInteger(0,line.name,OBJPROP_STYLE,line.style))
      success=false;
   if(!ObjectSetInteger(0,line.name,OBJPROP_WIDTH,line.width))
      success=false;
   if(!ObjectSetInteger(0,line.name,OBJPROP_RAY_LEFT,line.rayLeft))
      success=false;
   if(!ObjectSetInteger(0,line.name,OBJPROP_RAY_RIGHT,line.rayRight))
      success=false;
   if(!ObjectSetInteger(0,line.name,OBJPROP_BACK,false))
      success=false;
   if(!ObjectSetInteger(0,line.name,OBJPROP_ZORDER,line.zOrder))
      success=false;
   if(!ObjectSetInteger(0,line.name,OBJPROP_SELECTABLE,false))
      success=false;
   if(!ObjectSetInteger(0,line.name,OBJPROP_SELECTED,false))
      success=false;
   if(!ObjectSetInteger(0,line.name,OBJPROP_HIDDEN,true))
      success=false;
   if(!ObjectSetString(0,line.name,OBJPROP_TOOLTIP,"\n"))
      success=false;
   if(!success)
   {
      PrintFormat("SMC: unable to update managed line '%s' (error=%d).",
                  line.name,GetLastError());
      line.rendered=false;
      return false;
   }
   line.renderedHash=hash;
   line.rendered=true;
   return true;
}

void SMC_PineLabelSet(const string name,const datetime time,const double price,
                      const string text,const color textColor,
                      const ENUM_ANCHOR_POINT anchor,const int fontSize=8,
                      const bool keep=false,const int zOrder=100)
{
   int index=SMC_PineFindLabel(name);
   if(index<0)
   {
      int count=ArraySize(SMC_PineLabels);
      if(ArrayResize(SMC_PineLabels,count+1)!=count+1)
      {
         PrintFormat("SMC: unable to store managed label (error=%d).",
                     GetLastError());
         return;
      }
      index=count;
      SMC_PineLabels[index].id=SMC_PineNextLabelId++;
      SMC_PineLabels[index].name=name;
   }
   SMC_PineLabels[index].keep=keep;
   SMC_PineLabels[index].screen=false;
   SMC_PineLabels[index].time=time;
   SMC_PineLabels[index].price=price;
   SMC_PineLabels[index].text=text;
   SMC_PineLabels[index].textColor=textColor;
   SMC_PineLabels[index].anchor=anchor;
   SMC_PineLabels[index].fontSize=fontSize;
   SMC_PineLabels[index].zOrder=zOrder;
   SMC_PineLabels[index].renderedHash=0;
   SMC_PineLabels[index].rendered=false;
   SMC_PineCollectLabels();
   index=SMC_PineFindLabel(name);
   if(index>=0)
      SMC_PineRenderLabel(SMC_PineLabels[index]);
}

void SMC_PineScreenLabelSet(const string name,const string text,
                            const color textColor,const ENUM_BASE_CORNER corner,
                            const int xOffset,const int yOffset,
                            const int fontSize=10,const bool keep=true)
{
   int index=SMC_PineFindLabel(name);
   if(index<0)
   {
      int count=ArraySize(SMC_PineLabels);
      if(ArrayResize(SMC_PineLabels,count+1)!=count+1)
      {
         PrintFormat("SMC: unable to store managed screen label (error=%d).",
                     GetLastError());
         return;
      }
      index=count;
      SMC_PineLabels[index].id=SMC_PineNextLabelId++;
      SMC_PineLabels[index].name=name;
   }
   SMC_PineLabels[index].keep=keep;
   SMC_PineLabels[index].screen=true;
   SMC_PineLabels[index].time=0;
   SMC_PineLabels[index].price=0.0;
   SMC_PineLabels[index].text=text;
   SMC_PineLabels[index].textColor=textColor;
   SMC_PineLabels[index].anchor=ANCHOR_LEFT_UPPER;
   SMC_PineLabels[index].fontSize=fontSize;
   SMC_PineLabels[index].zOrder=100;
   SMC_PineLabels[index].corner=corner;
   SMC_PineLabels[index].xOffset=xOffset;
   SMC_PineLabels[index].yOffset=yOffset;
   SMC_PineLabels[index].renderedHash=0;
   SMC_PineLabels[index].rendered=false;
   SMC_PineCollectLabels();
   index=SMC_PineFindLabel(name);
   if(index>=0)
      SMC_PineRenderLabel(SMC_PineLabels[index]);
}

void SMC_PineLineSet(const string name,const datetime firstTime,
                     const double firstPrice,const datetime secondTime,
                     const double secondPrice,const color lineColor,
                     const ENUM_LINE_STYLE style=STYLE_SOLID,const int width=1,
                     const bool rayLeft=false,const bool rayRight=false,
                     const bool keep=false,const int zOrder=20)
{
   int index=SMC_PineFindLine(name);
   if(index<0)
   {
      int count=ArraySize(SMC_PineLines);
      if(ArrayResize(SMC_PineLines,count+1)!=count+1)
      {
         PrintFormat("SMC: unable to store managed line (error=%d).",
                     GetLastError());
         return;
      }
      index=count;
      SMC_PineLines[index].id=SMC_PineNextLineId++;
      SMC_PineLines[index].name=name;
   }
   SMC_PineLines[index].keep=keep;
   SMC_PineLines[index].firstTime=firstTime;
   SMC_PineLines[index].firstPrice=firstPrice;
   SMC_PineLines[index].secondTime=secondTime;
   SMC_PineLines[index].secondPrice=secondPrice;
   SMC_PineLines[index].lineColor=lineColor;
   SMC_PineLines[index].style=style;
   SMC_PineLines[index].width=width;
   SMC_PineLines[index].rayLeft=rayLeft;
   SMC_PineLines[index].rayRight=rayRight;
   SMC_PineLines[index].zOrder=zOrder;
   SMC_PineLines[index].renderedHash=0;
   SMC_PineLines[index].rendered=false;
   SMC_PineCollectLines();
   index=SMC_PineFindLine(name);
   if(index>=0)
      SMC_PineRenderLine(SMC_PineLines[index]);
}

void SMC_PineDrawingDelete(const string name)
{
   int label=SMC_PineFindLabel(name);
   if(label>=0)
      SMC_PineRemoveLabelAt(label,false);
   int line=SMC_PineFindLine(name);
   if(line>=0)
      SMC_PineRemoveLineAt(line,false);
   if(ObjectFind(0,name)>=0 && !ObjectDelete(0,name))
      PrintFormat("SMC: unable to delete drawing '%s' (error=%d).",
                  name,GetLastError());
}

void SMC_PineDrawingDeletePrefix(const string prefix)
{
   for(int i=ArraySize(SMC_PineLabels)-1;i>=0;i--)
      if(StringFind(SMC_PineLabels[i].name,prefix)==0)
         SMC_PineRemoveLabelAt(i,false);
   for(int i=ArraySize(SMC_PineLines)-1;i>=0;i--)
      if(StringFind(SMC_PineLines[i].name,prefix)==0)
         SMC_PineRemoveLineAt(i,false);
}

void SMC_RenderPineDrawings()
{
   for(int i=0;i<ArraySize(SMC_PineLabels);i++)
      SMC_PineRenderLabel(SMC_PineLabels[i]);
   for(int i=0;i<ArraySize(SMC_PineLines);i++)
      SMC_PineRenderLine(SMC_PineLines[i]);
}

#endif // SMC_PINEDRAWINGS_MQH
