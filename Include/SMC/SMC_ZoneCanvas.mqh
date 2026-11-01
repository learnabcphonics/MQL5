// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_ZONECANVAS_MQH
#define SMC_ZONECANVAS_MQH

#define SMC_ZONE_CANVAS_MAX_BOXES 500

struct SMC_ZoneCanvasBox
{
   int id;
   string name;
   bool keep;
   datetime left;
   datetime right;
   double top;
   double bottom;
   uint fillColor;
   uint borderColor;
   int layer;
};

SMC_ZoneCanvasBox SMC_ZoneCanvasBoxes[];
int SMC_ZoneCanvasNextBoxId=0;
uint SMC_ZoneCanvasPixels[];
string SMC_ZoneCanvasObjectName="";
string SMC_ZoneCanvasResource="";
int SMC_ZoneCanvasWidth=0;
int SMC_ZoneCanvasHeight=0;
ulong SMC_ZoneCanvasHash=0;

union SMC_ZoneCanvasDoubleBits
{
   double value;
   ulong bits;
};

ulong SMC_ZoneCanvasMix(const ulong hash,const ulong value)
{
   return (hash^value)*1099511628211;
}

ulong SMC_ZoneCanvasDoubleHash(const double value)
{
   SMC_ZoneCanvasDoubleBits bits;
   bits.value=value;
   return bits.bits;
}

uint SMC_ZoneCanvasArgb(const color value,const int transparency)
{
   int alpha=(int)MathRound(255.0*(100-MathMax(0,MathMin(100,transparency)))/100.0);
   return ColorToARGB(SMC_RGBColor(value),(uchar)alpha);
}

int SMC_ZoneCanvasLayer(const string name)
{
   if(StringFind(name,"PD_")>=0)
      return 0;
   if(StringFind(name,"FVG_")>=0)
      return 10;
   if(StringFind(name,"OB_Internal_")>=0)
      return 30;
   if(StringFind(name,"OB_Swing_")>=0)
      return 20;
   return 5;
}

int SMC_ZoneCanvasFind(const string name)
{
   for(int i=0;i<ArraySize(SMC_ZoneCanvasBoxes);i++)
      if(SMC_ZoneCanvasBoxes[i].name==name)
         return i;
   return -1;
}

void SMC_ZoneCanvasRemove(const string name)
{
   int index=SMC_ZoneCanvasFind(name);
   if(index<0)
      return;
   int count=ArraySize(SMC_ZoneCanvasBoxes);
   for(int i=index;i<count-1;i++)
      SMC_ZoneCanvasBoxes[i]=SMC_ZoneCanvasBoxes[i+1];
   if(ArrayResize(SMC_ZoneCanvasBoxes,count-1)!=count-1)
      PrintFormat("SMC: unable to remove zone canvas box (error=%d).",
                  GetLastError());
   SMC_ZoneCanvasHash=0;
}

void SMC_ZoneCanvasCollect()
{
   while(ArraySize(SMC_ZoneCanvasBoxes)>SMC_ZONE_CANVAS_MAX_BOXES)
   {
      int oldest=-1;
      for(int i=0;i<ArraySize(SMC_ZoneCanvasBoxes);i++)
      {
         if(SMC_ZoneCanvasBoxes[i].keep)
            continue;
         if(oldest<0 || SMC_ZoneCanvasBoxes[i].id<
                        SMC_ZoneCanvasBoxes[oldest].id)
            oldest=i;
      }
      if(oldest<0)
         return;
      string name=SMC_ZoneCanvasBoxes[oldest].name;
      ObjectDelete(0,name);
      SMC_ZoneCanvasRemove(name);
   }
}

void SMC_ZoneCanvasRemovePrefix(const string prefix)
{
   for(int i=ArraySize(SMC_ZoneCanvasBoxes)-1;i>=0;i--)
      if(StringFind(SMC_ZoneCanvasBoxes[i].name,prefix)==0)
         SMC_ZoneCanvasRemove(SMC_ZoneCanvasBoxes[i].name);
}

void SMC_ZoneCanvasUpsert(const string name,const datetime left,
                          const datetime right,const double top,
                          const double bottom,const color fill,
                          const int fillTransparency,const int borderTransparency,
                          const bool keep=false)
{
   int index=SMC_ZoneCanvasFind(name);
   if(index<0)
   {
      int count=ArraySize(SMC_ZoneCanvasBoxes);
      if(ArrayResize(SMC_ZoneCanvasBoxes,count+1)!=count+1)
      {
         PrintFormat("SMC: unable to store zone canvas box (error=%d).",
                     GetLastError());
         return;
      }
      index=count;
      SMC_ZoneCanvasBoxes[index].id=SMC_ZoneCanvasNextBoxId++;
      SMC_ZoneCanvasBoxes[index].name=name;
   }
   SMC_ZoneCanvasBoxes[index].keep=keep;
   SMC_ZoneCanvasBoxes[index].left=left;
   SMC_ZoneCanvasBoxes[index].right=right;
   SMC_ZoneCanvasBoxes[index].top=MathMax(top,bottom);
   SMC_ZoneCanvasBoxes[index].bottom=MathMin(top,bottom);
   SMC_ZoneCanvasBoxes[index].fillColor=
      SMC_ZoneCanvasArgb(fill,fillTransparency);
   SMC_ZoneCanvasBoxes[index].borderColor=
      SMC_ZoneCanvasArgb(fill,borderTransparency);
   SMC_ZoneCanvasBoxes[index].layer=SMC_ZoneCanvasLayer(name);
   SMC_ZoneCanvasCollect();
   SMC_ZoneCanvasHash=0;
}

void SMC_ZoneCanvasBlendPixel(const int index,const uint source)
{
   uint sourceAlpha=(source>>24)&0xFF;
   if(sourceAlpha==0)
      return;
   uint destination=SMC_ZoneCanvasPixels[index];
   uint destinationAlpha=(destination>>24)&0xFF;
   if(destinationAlpha==0 || sourceAlpha==255)
   {
      SMC_ZoneCanvasPixels[index]=source;
      return;
   }
   uint outputAlpha=sourceAlpha+destinationAlpha*(255-sourceAlpha)/255;
   uint red=((((source>>16)&0xFF)*sourceAlpha*255)+
             (((destination>>16)&0xFF)*destinationAlpha*(255-sourceAlpha)))/
            (outputAlpha*255);
   uint green=((((source>>8)&0xFF)*sourceAlpha*255)+
               (((destination>>8)&0xFF)*destinationAlpha*(255-sourceAlpha)))/
              (outputAlpha*255);
   uint blue=(((source&0xFF)*sourceAlpha*255)+
              ((destination&0xFF)*destinationAlpha*(255-sourceAlpha)))/
             (outputAlpha*255);
   SMC_ZoneCanvasPixels[index]=(outputAlpha<<24)|(red<<16)|(green<<8)|blue;
}

void SMC_ZoneCanvasBlendRow(const int y,const int left,const int right,
                            const uint colorValue)
{
   int row=y*SMC_ZoneCanvasWidth;
   for(int x=left;x<=right;x++)
      SMC_ZoneCanvasBlendPixel(row+x,colorValue);
}

bool SMC_ZoneCanvasCoordinates(const SMC_ZoneCanvasBox &box,
                               int &left,int &top,int &right,int &bottom)
{
   int x1=0,y1=0,x2=0,y2=0;
   if(!ChartTimePriceToXY(0,0,box.left,box.top,x1,y1) ||
      !ChartTimePriceToXY(0,0,box.right,box.bottom,x2,y2))
      return false;
   left=MathMin(x1,x2);
   right=MathMax(x1,x2);
   top=MathMin(y1,y2);
   bottom=MathMax(y1,y2);
   return true;
}

void SMC_ZoneCanvasPaintBox(const SMC_ZoneCanvasBox &box)
{
   int left=0,top=0,right=0,bottom=0;
   if(!SMC_ZoneCanvasCoordinates(box,left,top,right,bottom))
      return;
   int clippedLeft=MathMax(left,0);
   int clippedRight=MathMin(right,SMC_ZoneCanvasWidth-1);
   int clippedTop=MathMax(top,0);
   int clippedBottom=MathMin(bottom,SMC_ZoneCanvasHeight-1);
   if(clippedLeft>clippedRight || clippedTop>clippedBottom)
      return;
   for(int y=clippedTop;y<=clippedBottom;y++)
      SMC_ZoneCanvasBlendRow(y,clippedLeft,clippedRight,box.fillColor);
   if(((box.borderColor>>24)&0xFF)==0)
      return;
   if(top>=0 && top<SMC_ZoneCanvasHeight)
      SMC_ZoneCanvasBlendRow(top,clippedLeft,clippedRight,box.borderColor);
   if(bottom!=top && bottom>=0 && bottom<SMC_ZoneCanvasHeight)
      SMC_ZoneCanvasBlendRow(bottom,clippedLeft,clippedRight,box.borderColor);
   for(int y=MathMax(top+1,0);y<=MathMin(bottom-1,SMC_ZoneCanvasHeight-1);y++)
   {
      if(left>=0 && left<SMC_ZoneCanvasWidth)
         SMC_ZoneCanvasBlendPixel(y*SMC_ZoneCanvasWidth+left,box.borderColor);
      if(right!=left && right>=0 && right<SMC_ZoneCanvasWidth)
         SMC_ZoneCanvasBlendPixel(y*SMC_ZoneCanvasWidth+right,box.borderColor);
   }
}

ulong SMC_ZoneCanvasViewHash(const int width,const int height)
{
   ulong hash=1469598103934665603;
   hash=SMC_ZoneCanvasMix(hash,(ulong)width);
   hash=SMC_ZoneCanvasMix(hash,(ulong)height);
   long firstVisible=ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR);
   long visibleBars=ChartGetInteger(0,CHART_VISIBLE_BARS);
   hash=SMC_ZoneCanvasMix(hash,(ulong)firstVisible);
   hash=SMC_ZoneCanvasMix(hash,(ulong)visibleBars);
   hash=SMC_ZoneCanvasMix(hash,SMC_ZoneCanvasDoubleHash(
                            ChartGetDouble(0,CHART_PRICE_MAX)));
   hash=SMC_ZoneCanvasMix(hash,SMC_ZoneCanvasDoubleHash(
                            ChartGetDouble(0,CHART_PRICE_MIN)));
   for(int i=0;i<ArraySize(SMC_ZoneCanvasBoxes);i++)
   {
      SMC_ZoneCanvasBox box=SMC_ZoneCanvasBoxes[i];
      hash=SMC_ZoneCanvasMix(hash,(ulong)box.left);
      hash=SMC_ZoneCanvasMix(hash,(ulong)box.right);
      hash=SMC_ZoneCanvasMix(hash,SMC_ZoneCanvasDoubleHash(box.top));
      hash=SMC_ZoneCanvasMix(hash,SMC_ZoneCanvasDoubleHash(box.bottom));
      hash=SMC_ZoneCanvasMix(hash,(ulong)box.fillColor);
      hash=SMC_ZoneCanvasMix(hash,(ulong)box.borderColor);
      hash=SMC_ZoneCanvasMix(hash,(ulong)box.layer);
   }
   return hash;
}

bool SMC_RenderZoneCanvas(const string prefix)
{
   for(int i=ArraySize(SMC_ZoneCanvasBoxes)-1;i>=0;i--)
      if(ObjectFind(0,SMC_ZoneCanvasBoxes[i].name)<0)
         SMC_ZoneCanvasRemove(SMC_ZoneCanvasBoxes[i].name);
   int width=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
   int height=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   if(width<=0 || height<=0)
      return false;
   if(SMC_ZoneCanvasObjectName!=prefix+"ZONE_CANVAS")
   {
      if(SMC_ZoneCanvasObjectName!="" &&
         ObjectFind(0,SMC_ZoneCanvasObjectName)>=0)
         ObjectDelete(0,SMC_ZoneCanvasObjectName);
      if(SMC_ZoneCanvasResource!="")
         ResourceFree(SMC_ZoneCanvasResource);
      SMC_ZoneCanvasObjectName=prefix+"ZONE_CANVAS";
      SMC_ZoneCanvasResource="::"+SMC_ZoneCanvasObjectName;
      SMC_ZoneCanvasHash=0;
      SMC_ZoneCanvasWidth=0;
      SMC_ZoneCanvasHeight=0;
   }
   ulong hash=SMC_ZoneCanvasViewHash(width,height);
   if(hash==SMC_ZoneCanvasHash &&
      ObjectFind(0,SMC_ZoneCanvasObjectName)>=0)
      return true;
   if(ObjectFind(0,SMC_ZoneCanvasObjectName)<0)
   {
      if(!ObjectCreate(0,SMC_ZoneCanvasObjectName,OBJ_BITMAP_LABEL,0,0,0))
      {
         PrintFormat("SMC: unable to create zone canvas (error=%d).",
                     GetLastError());
         return false;
      }
      ObjectSetInteger(0,SMC_ZoneCanvasObjectName,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,SMC_ZoneCanvasObjectName,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0,SMC_ZoneCanvasObjectName,OBJPROP_XDISTANCE,0);
      ObjectSetInteger(0,SMC_ZoneCanvasObjectName,OBJPROP_YDISTANCE,0);
      ObjectSetInteger(0,SMC_ZoneCanvasObjectName,OBJPROP_BACK,true);
      ObjectSetInteger(0,SMC_ZoneCanvasObjectName,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,SMC_ZoneCanvasObjectName,OBJPROP_HIDDEN,true);
      ObjectSetString(0,SMC_ZoneCanvasObjectName,OBJPROP_TOOLTIP,"\n");
   }
   if(width!=SMC_ZoneCanvasWidth || height!=SMC_ZoneCanvasHeight)
   {
      if(ArrayResize(SMC_ZoneCanvasPixels,width*height)!=width*height)
      {
         PrintFormat("SMC: unable to allocate zone canvas pixels (error=%d).",
                     GetLastError());
         return false;
      }
      SMC_ZoneCanvasWidth=width;
      SMC_ZoneCanvasHeight=height;
      ObjectSetInteger(0,SMC_ZoneCanvasObjectName,OBJPROP_XSIZE,width);
      ObjectSetInteger(0,SMC_ZoneCanvasObjectName,OBJPROP_YSIZE,height);
   }
   ArrayInitialize(SMC_ZoneCanvasPixels,0);
   for(int layer=0;layer<=30;layer+=10)
      for(int i=0;i<ArraySize(SMC_ZoneCanvasBoxes);i++)
         if(SMC_ZoneCanvasBoxes[i].layer==layer)
            SMC_ZoneCanvasPaintBox(SMC_ZoneCanvasBoxes[i]);
   if(!ResourceCreate(SMC_ZoneCanvasResource,SMC_ZoneCanvasPixels,
                      SMC_ZoneCanvasWidth,SMC_ZoneCanvasHeight,0,0,
                      SMC_ZoneCanvasWidth,COLOR_FORMAT_ARGB_NORMALIZE))
   {
      PrintFormat("SMC: unable to render zone canvas resource (error=%d).",
                  GetLastError());
      return false;
   }
   if(!ObjectSetString(0,SMC_ZoneCanvasObjectName,OBJPROP_BMPFILE,0,
                       SMC_ZoneCanvasResource))
   {
      PrintFormat("SMC: unable to attach zone canvas resource (error=%d).",
                  GetLastError());
      return false;
   }
   SMC_ZoneCanvasHash=hash;
   ChartRedraw(0);
   return true;
}

void SMC_ZoneCanvasRelease(const string prefix)
{
   SMC_ZoneCanvasRemovePrefix(prefix);
   if(SMC_ZoneCanvasObjectName==prefix+"ZONE_CANVAS")
   {
      ObjectDelete(0,SMC_ZoneCanvasObjectName);
      if(SMC_ZoneCanvasResource!="")
         ResourceFree(SMC_ZoneCanvasResource);
      SMC_ZoneCanvasObjectName="";
      SMC_ZoneCanvasResource="";
      SMC_ZoneCanvasWidth=0;
      SMC_ZoneCanvasHeight=0;
      SMC_ZoneCanvasHash=0;
      ArrayResize(SMC_ZoneCanvasPixels,0);
   }
}

#endif // SMC_ZONECANVAS_MQH
