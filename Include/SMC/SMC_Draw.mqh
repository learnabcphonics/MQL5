// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
// Drawing helpers receive presentation settings and analysis state explicitly.
#ifndef SMC_DRAW_MQH
#define SMC_DRAW_MQH

#include <SMC/SMC_Types.mqh>
#include <SMC/SMC_Palette.mqh>

ENUM_LINE_STYLE LineStyle(const ENUM_SMC_LINE_STYLE style)
{
   if(style == SMC_DASHED) return STYLE_DASH;
   if(style == SMC_DOTTED) return STYLE_DOT;
   return STYLE_SOLID;
}

color SMC_DrawBullColor(const SMC_DrawConfig &config,const bool internal)
{
   return SMC_COLOR_BULLISH;
}

color SMC_DrawBearColor(const SMC_DrawConfig &config,const bool internal)
{
   return SMC_COLOR_BEARISH;
}

string SMC_TimeframeLabel(const ENUM_TIMEFRAMES timeframe)
{
   string label=EnumToString(timeframe);
   StringReplace(label,"PERIOD_","");
   return label;
}

void DeleteObjectsWithPrefix(const string prefix)
{
   for(int i=ObjectsTotal(0,-1,-1)-1;i>=0;--i)
   {
      string name=ObjectName(0,i,-1,-1);
      if(StringFind(name,prefix)==0)
         ObjectDelete(0,name);
   }
}

int SMC_ZoneZOrder(const string objectName)
{
   if(StringFind(objectName,"PL_")==0)
      return -50;
   if(StringFind(objectName,"PD_")==0)
      return -40;
   if(StringFind(objectName,"FVG_")==0)
      return -30;
   if(StringFind(objectName,"OB_")==0)
      return -20;
   if(StringFind(objectName,"STR_")==0)
      return 0;
   if(StringFind(objectName,"SW_")==0)
      return 0;
   return -10;
}

double SMC_LabelOffsetPrice(const string objectName,const double basePrice,const double span)
{
   double step=MathMax(0.000001,MathAbs(span)*0.08);
   if(StringFind(objectName,"OB_")==0)
      return basePrice+step;
   if(StringFind(objectName,"FVG_")==0)
      return basePrice+step*0.5;
   if(StringFind(objectName,"PD_")==0)
      return basePrice+step*0.75;
   return basePrice;
}

bool SMC_ZoneRectanglesOverlap(const datetime leftA,const datetime rightA,
                               const double topA,const double bottomA,
                               const datetime leftB,const datetime rightB,
                               const double topB,const double bottomB)
{
   if(rightA<=leftB || rightB<=leftA)
      return false;
   double highA=MathMax(topA,bottomA);
   double lowA=MathMin(topA,bottomA);
   double highB=MathMax(topB,bottomB);
   double lowB=MathMin(topB,bottomB);
   return !(highA<=lowB || highB<=lowA);
}

void DeleteOverlappingZoneObjects(const string prefix,
                                 const datetime left,const datetime right,
                                 const double top,const double bottom)
{
   for(int i=ObjectsTotal(0,-1,-1)-1;i>=0;--i)
   {
      string name=ObjectName(0,i,-1,-1);
      if(StringFind(name,prefix)!=0)
         continue;
      if(ObjectFind(0,name)<0)
         continue;
      if(ObjectGetInteger(0,name,OBJPROP_TYPE)!=(int)OBJ_RECTANGLE)
         continue;
      datetime objLeft=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,0);
      datetime objRight=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,1);
      if(objRight<=objLeft)
         continue;
      double objTop=ObjectGetDouble(0,name,OBJPROP_PRICE,0);
      double objBottom=ObjectGetDouble(0,name,OBJPROP_PRICE,1);
      if(SMC_ZoneRectanglesOverlap(left,right,top,bottom,
                                  objLeft,objRight,objTop,objBottom))
      {
         ObjectDelete(0,name);
      }
   }
}

void DeleteSMCObjects(const string prefix)
{
   DeleteObjectsWithPrefix(prefix);
}

void MoveObjectPointIfChanged(const string name,const int point,
                              const datetime when,const double price)
{
   if(ObjectFind(0,name)<0)
      return;
   datetime currentTime=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,point);
   double currentPrice=ObjectGetDouble(0,name,OBJPROP_PRICE,point);
   if(currentTime!=when || currentPrice!=price)
      ObjectMove(0,name,point,when,price);
}

void DrawText(const string name,const datetime when,const double price,
              const string text,const color textColor,const ENUM_ANCHOR_POINT anchor,
              const int fontSize=8)
{
   if(ObjectFind(0,name)<0 && !ObjectCreate(0,name,OBJ_TEXT,0,when,price))
      return;
   MoveObjectPointIfChanged(name,0,when,price);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontSize);
   ObjectSetInteger(0,name,OBJPROP_COLOR,textColor);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,100);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
}

string BiasText(const int bias)
{
   if(bias>0) return "BULLISH";
   if(bias<0) return "BEARISH";
   return "UNSET";
}

void UpdateMarketBiasLabel(const SMC_DrawConfig &config,const int swingBias,
                           const int internalBias)
{
   string name=config.objectPrefix+"BIAS";
   if(!config.showMarketBias)
   {
      ObjectDelete(0,name);
      return;
   }
   if(ObjectFind(0,name)<0 && !ObjectCreate(0,name,OBJ_LABEL,0,0,0))
      return;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,10);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,40);
   ObjectSetInteger(0,name,OBJPROP_COLOR,
                    swingBias>0 ? SMC_DrawBullColor(config,false) :
                    (swingBias<0 ? SMC_DrawBearColor(config,false) : SMC_COLOR_EQUILIBRIUM));
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetString(0,name,OBJPROP_TEXT,
                   "SMC ["+SMC_TimeframeLabel(config.chartTimeframe)+
                   "] Bias | Swing: "+BiasText(swingBias)+
                   " | Internal: "+BiasText(internalBias));
}

void DrawHorizontalStructure(const SMC_DrawConfig &config,
                             StructureDisplayState &latestStructures[],
                             bool &presentStructuresDirty,const string id,
                             const PivotState &pivot,
                             const datetime rightTime,const string tag,
                             const color lineColor,const bool internal,
                             const bool bullish,const ENUM_SMC_SIZE labelSize)
{
   int slot=(internal ? 0 : 2)+(bullish ? 0 : 1);
   if(latestStructures[slot].valid && latestStructures[slot].id!=id)
   {
      ObjectDelete(0,config.objectPrefix+"STR_Line_"+
                     latestStructures[slot].id);
      ObjectDelete(0,config.objectPrefix+"STR_Label_"+
                     latestStructures[slot].id);
   }
   latestStructures[slot].pivot=pivot;
   latestStructures[slot].rightTime=rightTime;
   latestStructures[slot].id=id;
   latestStructures[slot].tag=tag;
   latestStructures[slot].lineColor=lineColor;
   latestStructures[slot].internal=internal;
   latestStructures[slot].bullish=bullish;
   latestStructures[slot].labelSize=labelSize;
   latestStructures[slot].valid=true;
   presentStructuresDirty=true;
}

void RenderPresentStructures(const SMC_DrawConfig &config,
                             const StructureDisplayState &latestStructures[],
                             bool &presentStructuresDirty)
{
   if(!presentStructuresDirty)
      return;
   for(int i=0;i<ArraySize(latestStructures);i++)
   {
      if(!latestStructures[i].valid)
         continue;
      string lineName=config.objectPrefix+"STR_Line_"+latestStructures[i].id;
      string labelName=config.objectPrefix+"STR_Label_"+latestStructures[i].id;
      PivotState pivot=latestStructures[i].pivot;
      datetime rightTime=latestStructures[i].rightTime;
      if(ObjectFind(0,lineName)<0)
      {
         if(!ObjectCreate(0,lineName,OBJ_TREND,0,pivot.time,pivot.current,
                          rightTime,pivot.current))
            continue;
      }
      else
      {
         MoveObjectPointIfChanged(lineName,0,pivot.time,pivot.current);
         MoveObjectPointIfChanged(lineName,1,rightTime,pivot.current);
      }
      ObjectSetInteger(0,lineName,OBJPROP_COLOR,latestStructures[i].lineColor);
      ObjectSetInteger(0,lineName,OBJPROP_STYLE,
                       latestStructures[i].internal ? STYLE_DASH : STYLE_SOLID);
      ObjectSetInteger(0,lineName,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,lineName,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(0,lineName,OBJPROP_SELECTABLE,false);
      datetime middle=pivot.time+(rightTime-pivot.time)/2;
      DrawText(labelName,middle,pivot.current,
               SMC_TimeframeLabel(config.chartTimeframe)+" "+
               latestStructures[i].tag,
               latestStructures[i].lineColor,
               latestStructures[i].bullish ? ANCHOR_UPPER : ANCHOR_LOWER,
               (int)latestStructures[i].labelSize);
   }
   presentStructuresDirty=false;
}

void ExtendPresentStructures(const SMC_DrawConfig &config,
                             StructureDisplayState &latestStructures[],
                             const bool presentStructuresDirty,
                             const datetime rightTime)
{
   if(presentStructuresDirty)
      return;
   for(int i=0;i<ArraySize(latestStructures);i++)
   {
      if(!latestStructures[i].valid)
         continue;
      latestStructures[i].rightTime=rightTime;
      string lineName=config.objectPrefix+"STR_Line_"+latestStructures[i].id;
      string labelName=config.objectPrefix+"STR_Label_"+latestStructures[i].id;
      PivotState pivot=latestStructures[i].pivot;
      if(ObjectFind(0,lineName)>=0)
      {
         MoveObjectPointIfChanged(lineName,0,pivot.time,pivot.current);
         MoveObjectPointIfChanged(lineName,1,rightTime,pivot.current);
      }
      if(ObjectFind(0,labelName)>=0)
      {
         datetime middle=pivot.time+(rightTime-pivot.time)/2;
         MoveObjectPointIfChanged(labelName,0,middle,pivot.current);
      }
   }
}

void DrawZoneBox(const string name,const datetime startTime,const datetime endTime,
                 const double top,const double bottom,const color zoneColor)
{
   if(startTime<=0 || endTime<=startTime ||
      !MathIsValidNumber(top) || !MathIsValidNumber(bottom) || top==bottom)
   {
      ObjectDelete(0,name);
      return;
   }
   double zoneTop=MathMax(top,bottom);
   double zoneBottom=MathMin(top,bottom);
   // Recreate a rectangle if its actual RGB changed. This also migrates chart
   // objects created by older builds that cached an ARGB/black fill.
   color rgbColor=(color)((uint)zoneColor & 0xFFFFFF);
   if(ObjectFind(0,name)>=0)
   {
      color currentColor=(color)((uint)ObjectGetInteger(0,name,OBJPROP_COLOR)&0xFFFFFF);
      bool fillEnabled=ObjectGetInteger(0,name,OBJPROP_FILL)!=0;
      bool backgroundMode=ObjectGetInteger(0,name,OBJPROP_BACK)!=0;
      if(currentColor!=rgbColor || !fillEnabled || !backgroundMode)
         ObjectDelete(0,name);
   }
   if(ObjectFind(0,name)<0 &&
      !ObjectCreate(0,name,OBJ_RECTANGLE,0,startTime,zoneTop,endTime,zoneBottom))
      return;
   MoveObjectPointIfChanged(name,0,startTime,zoneTop);
   MoveObjectPointIfChanged(name,1,endTime,zoneBottom);
   ObjectSetInteger(0,name,OBJPROP_COLOR,rgbColor);
   ObjectSetInteger(0,name,OBJPROP_FILL,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,SMC_ZoneZOrder(name));
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
}

void DrawEqualLevelEvent(const SMC_DrawConfig &config,
                         const EqualLevelEvent &event,
                         const color lineColor,const ENUM_SMC_SIZE labelSize)
{
   if(!event.valid)
      return;
   string kind=(event.high ? "EQH" : "EQL");
   string id=IntegerToString((int)event.secondTime);
   string lineName=config.objectPrefix+kind+"_Line_"+id;
   string labelName=config.objectPrefix+kind+"_Label_"+id;
   ObjectDelete(0,lineName);
   ObjectDelete(0,labelName);
   if(!ObjectCreate(0,lineName,OBJ_TREND,0,event.firstTime,event.firstPrice,
                    event.secondTime,event.secondPrice))
      return;
   ObjectSetInteger(0,lineName,OBJPROP_COLOR,lineColor);
   ObjectSetInteger(0,lineName,OBJPROP_STYLE,STYLE_DOT);
   DrawText(config.objectPrefix+kind+"_Label_"+id,event.labelTime,
            event.secondPrice,SMC_TimeframeLabel(config.chartTimeframe)+" "+kind,
            lineColor,event.high ? ANCHOR_LOWER : ANCHOR_UPPER,(int)labelSize);
}

void DrawFairValueGap(const SMC_DrawConfig &config,const FairValueGapState &gap,
                      const color zoneColor)
{
   string id=(gap.bias>0 ? "Bull_" : "Bear_")+
             IntegerToString((int)gap.time);
   string firstName=config.objectPrefix+"FVG_"+id+"_1";
   string secondName=config.objectPrefix+"FVG_"+id+"_2";
   bool hasOverlap=false;
   for(int i=ObjectsTotal(0,-1,-1)-1;i>=0;--i)
   {
      string name=ObjectName(0,i,-1,-1);
      if(StringFind(name,config.objectPrefix+"OB_")==0 &&
         ObjectFind(0,name)>=0 &&
         ObjectGetInteger(0,name,OBJPROP_TYPE)==(int)OBJ_RECTANGLE)
      {
         datetime obLeft=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,0);
         datetime obRight=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,1);
         double obTop=ObjectGetDouble(0,name,OBJPROP_PRICE,0);
         double obBottom=ObjectGetDouble(0,name,OBJPROP_PRICE,1);
         if(SMC_ZoneRectanglesOverlap(gap.left,gap.right,
                                     gap.top,gap.bottom,
                                     obLeft,obRight,obTop,obBottom))
         {
            hasOverlap=true;
            break;
         }
      }
   }
   if(hasOverlap)
   {
      ObjectDelete(0,firstName);
      ObjectDelete(0,secondName);
      ObjectDelete(0,config.objectPrefix+"FVG_"+id+"_Label");
      return;
   }
   DrawZoneBox(firstName,gap.left,gap.right,
               gap.firstTop,gap.firstBottom,zoneColor);
   DrawZoneBox(secondName,gap.left,gap.right,
               gap.secondTop,gap.secondBottom,zoneColor);
   datetime middleTime=gap.left+(gap.right-gap.left)/2;
   double middlePrice=(gap.top+gap.bottom)*0.5;
   double labelPrice=SMC_LabelOffsetPrice(config.objectPrefix+"FVG_"+id,
                                         middlePrice,MathAbs(gap.top-gap.bottom));
   string label=SMC_TimeframeLabel(config.chartTimeframe)+" "+
                (gap.bias>0 ? "Bullish FVG" : "Bearish FVG");
   DrawText(config.objectPrefix+"FVG_"+id+"_Label",middleTime,labelPrice,
            label,SMC_COLOR_LABEL,ANCHOR_CENTER);
}

void DeleteFairValueGap(const SMC_DrawConfig &config,
                        const FairValueGapState &gap)
{
   string id=(gap.bias>0 ? "Bull_" : "Bear_")+
             IntegerToString((int)gap.time);
   ObjectDelete(0,config.objectPrefix+"FVG_"+id+"_1");
   ObjectDelete(0,config.objectPrefix+"FVG_"+id+"_2");
   ObjectDelete(0,config.objectPrefix+"FVG_"+id+"_Label");
}

bool IsStructureVisible(const SMC_DrawConfig &config,const bool internal,
                        const bool bullish,const string tag)
{
   if(internal && !config.showInternalStructure) return false;
   if(!internal && !config.showSwingStructure) return false;
   ENUM_SMC_SHOW filter;
   if(internal)
      filter=bullish ? config.internalBullishStructure :
                       config.internalBearishStructure;
   else
      filter=bullish ? config.swingBullishStructure :
                       config.swingBearishStructure;
   if(filter==SMC_ALL) return true;
   if(filter==SMC_BOS) return tag=="BOS";
   return tag=="CHoCH";
}

string SMC_OrderBlockObjectName(const SMC_DrawConfig &config,
                                const OrderBlockState &block)
{
   string scope=(block.internal ? "Internal_" : "Swing_");
   return config.objectPrefix+"OB_"+scope+
          IntegerToString((long)block.time)+"_"+
          IntegerToString((long)block.created)+"_"+
          IntegerToString(block.bias);
}

bool SMC_OrderBlocksOverlap(const OrderBlockState &first,const datetime firstRight,
                            const OrderBlockState &second,const datetime secondRight)
{
   if(first.time>secondRight || second.time>firstRight)
      return false;
   if(first.internal!=second.internal || first.bias!=second.bias)
      return false;
   return first.high>=second.low && second.high>=first.low;
}

color SMC_OrderBlockBaseColor(const SMC_DrawConfig &config,
                              const OrderBlockState &block)
{
   return block.bias<0 ? SMC_COLOR_BEARISH : SMC_COLOR_BULLISH;
}

bool SMC_FindOrderBlockLabelPosition(const datetime baseTime,
                                     const double basePrice,
                                     const string label,
                                     const int &occupiedX[],
                                     const int &occupiedY[],
                                     const int &occupiedHalfWidths[],
                                     const int occupiedCount,
                                     datetime &labelTime,double &labelPrice,
                                     int &labelX,int &labelY,int &labelHalfWidth)
{
   int baseX=0,baseY=0;
   if(!ChartTimePriceToXY(0,0,baseTime,basePrice,baseX,baseY))
      return false;

   labelHalfWidth=StringLen(label)*3+2;
   int labelHalfHeight=7;
   for(int attempt=0;attempt<81;attempt++)
   {
      int offset=0;
      if(attempt>0)
      {
         int distance=((attempt+1)/2)*14;
         offset=(attempt%2==1 ? distance : -distance);
      }
      int candidateY=baseY+offset;
      bool overlaps=false;
      for(int i=0;i<occupiedCount;i++)
      {
         bool overlapsHorizontally=
            MathAbs(baseX-occupiedX[i])<labelHalfWidth+occupiedHalfWidths[i];
         bool overlapsVertically=MathAbs(candidateY-occupiedY[i])<labelHalfHeight*2;
         if(overlapsHorizontally && overlapsVertically)
         {
            overlaps=true;
            break;
         }
      }
      if(overlaps)
         continue;

      int subWindow=0;
      if(!ChartXYToTimePrice(0,baseX,candidateY,subWindow,labelTime,labelPrice))
         continue;
      labelX=baseX;
      labelY=candidateY;
      return true;
   }
   return false;
}

void DrawOrderBlockObjects(const SMC_DrawConfig &config,
                           const OrderBlockState &orderBlocks[],
                           const datetime lastTime,const int periodSeconds)
{
   for(int i=ObjectsTotal(0,-1,-1)-1;i>=0;--i)
   {
      string existingName=ObjectName(0,i,-1,-1);
      if(StringFind(existingName,config.objectPrefix+"OB_")==0 &&
         StringFind(existingName,"_Origin")>=0)
         ObjectDelete(0,existingName);
   }
   int internalCount=0,swingCount=0;
   int labelX[40],labelY[40],labelHalfWidths[40];
   int placedLabelCount=0;
   int count=ArraySize(orderBlocks);
   datetime blockRight[];
   if(ArrayResize(blockRight,count)!=count)
      return;
   int safePeriodSecondsForCache=MathMax(1,periodSeconds);
   int extendBarsForCache=MathMax(1,config.orderBlockExtend);
   long extensionSecondsForCache=(long)safePeriodSecondsForCache*extendBarsForCache;
   string keepNames[];
   ArrayResize(keepNames,0);
   for(int i=0;i<count;i++)
   {
      blockRight[i]=(datetime)((long)lastTime+extensionSecondsForCache);
      if(blockRight[i]<=orderBlocks[i].time)
         blockRight[i]=orderBlocks[i].time+safePeriodSecondsForCache;
   }
   for(int i=count-1;i>=0;i--)
   {
      OrderBlockState block=orderBlocks[i];
      int limit=block.internal ? config.internalOrderBlocksToShow :
                                 config.swingOrderBlocksToShow;
      string objectName=SMC_OrderBlockObjectName(config,block);
      bool visible=true;
      if(block.internal)
      {
         visible=config.showInternalOrderBlocks && internalCount<limit;
         if(visible) internalCount++;
      }
      else
      {
         visible=config.showSwingOrderBlocks && swingCount<limit;
         if(visible) swingCount++;
      }
      if(!visible)
      {
         ObjectDelete(0,objectName);
         ObjectDelete(0,objectName+"_Label");
         ObjectDelete(0,objectName+"_Origin");
         continue;
      }

      bool hiddenByOverlap=false;
      for(int j=0;j<i;j++)
      {
         if(!SMC_OrderBlocksOverlap(block,blockRight[i],
                                   orderBlocks[j],blockRight[j]))
            continue;
         hiddenByOverlap=true;
         break;
      }
      if(hiddenByOverlap)
      {
         ObjectDelete(0,objectName);
         ObjectDelete(0,objectName+"_Label");
         ObjectDelete(0,objectName+"_Origin");
         continue;
      }

      color base=SMC_OrderBlockBaseColor(config,block);
      datetime rightTime=blockRight[i];
      color drawColor=base;
      for(int j=0;j<i;j++)
      {
         if(SMC_OrderBlocksOverlap(block,rightTime,
                                   orderBlocks[j],blockRight[j]))
         {
            drawColor=SMC_OrderBlockBaseColor(config,orderBlocks[j]);
            break;
         }
      }

      DrawZoneBox(objectName,block.time,
                  rightTime,block.high,block.low,drawColor);
      if(ObjectFind(0,objectName)<0)
         continue;
      ObjectDelete(0,objectName+"_Origin");
      ArrayResize(keepNames,ArraySize(keepNames)+1);
      keepNames[ArraySize(keepNames)-1]=objectName;
      ArrayResize(keepNames,ArraySize(keepNames)+1);
      keepNames[ArraySize(keepNames)-1]=objectName+"_Label";
      ArrayResize(keepNames,ArraySize(keepNames)+1);
      keepNames[ArraySize(keepNames)-1]=objectName+"_Origin";
      datetime labelTime=block.time+(rightTime-block.time)/2;
      string label=SMC_TimeframeLabel(config.chartTimeframe)+" "+
                   (block.internal ? "Int " : "Swing ")+ 
                   (block.bias>0 ? "Bull OB" : "Bear OB");
      double labelPrice=(block.high+block.low)*0.5;
      labelPrice=SMC_LabelOffsetPrice(objectName,labelPrice,
                                     MathAbs(block.high-block.low));
      int placedX=0,placedY=0,halfWidth=0;
      datetime adjustedTime=labelTime;
      double adjustedPrice=labelPrice;
      if(placedLabelCount<ArraySize(labelX) &&
         SMC_FindOrderBlockLabelPosition(labelTime,labelPrice,label,labelX,
                                         labelY,labelHalfWidths,
                                         placedLabelCount,adjustedTime,
                                         adjustedPrice,placedX,placedY,
                                         halfWidth))
      {
         labelX[placedLabelCount]=placedX;
         labelY[placedLabelCount]=placedY;
         labelHalfWidths[placedLabelCount]=halfWidth;
         placedLabelCount++;
      }
      DrawText(objectName+"_Label",adjustedTime,adjustedPrice,
               label,SMC_COLOR_LABEL,ANCHOR_CENTER);
   }
   for(int i=ObjectsTotal(0,-1,-1)-1;i>=0;--i)
   {
      string existingName=ObjectName(0,i,-1,-1);
      if(StringFind(existingName,config.objectPrefix+"OB_")==0)
      {
         bool keep=false;
         for(int j=0;j<ArraySize(keepNames);j++)
         {
            if(existingName==keepNames[j])
            {
               keep=true;
               break;
            }
         }
         if(!keep)
            ObjectDelete(0,existingName);
      }
   }
}

void DrawSwingLabels(const SMC_DrawConfig &config,const datetime &time[],
                     const double &high[],const double &low[],
                     const int i,const int swingLength,
                     const PivotState &swingHigh,const PivotState &swingLow)
{
   if(!config.showSwingPoints)
   {
      DeleteObjectsWithPrefix(config.objectPrefix+"SW_High_");
      DeleteObjectsWithPrefix(config.objectPrefix+"SW_Low_");
      return;
   }
   int candidate=i+swingLength;
   bool drawHigh=(swingHigh.initialized && swingHigh.index==candidate);
   bool drawLow=(swingLow.initialized && swingLow.index==candidate);
   if(drawHigh)
      DrawText(config.objectPrefix+"SW_High_"+IntegerToString((int)time[candidate]),time[candidate],
               high[candidate],(!swingHigh.previousInitialized ? "H" :
                                swingHigh.current>swingHigh.previous ? "HH" : "LH"),
               SMC_DrawBearColor(config,false),ANCHOR_LOWER);
   if(drawLow)
      DrawText(config.objectPrefix+"SW_Low_"+IntegerToString((int)time[candidate]),time[candidate],
               low[candidate],(!swingLow.previousInitialized ? "L" :
                                swingLow.current<swingLow.previous ? "LL" : "HL"),
               SMC_DrawBullColor(config,false),ANCHOR_UPPER);
}

void DrawPreviousPeriodLevels(const SMC_DrawConfig &config,
                              const ENUM_TIMEFRAMES timeframe,const string label,
                              const ENUM_SMC_LINE_STYLE style,const color lineColor,
                              const datetime lastTime,const int ratesTotal,
                              const datetime &time[],const double &high[],
                              const double &low[])
{
   if(PeriodSeconds(config.chartTimeframe)>PeriodSeconds(timeframe)) return;
   int shift=1;
   double previousHigh=iHigh(config.symbol,timeframe,shift);
   double previousLow=iLow(config.symbol,timeframe,shift);
   datetime start=iTime(config.symbol,timeframe,shift);
   if(start==0 || previousHigh==0 || previousLow==0) return;
   datetime periodEnd=iTime(config.symbol,timeframe,0);
   if(periodEnd==0) return;
   datetime highTime=start,lowTime=start;
   bool highAnchorFound=false,lowAnchorFound=false;
   int oldestShift=iBarShift(config.symbol,config.chartTimeframe,start,false);
   int newestShift=iBarShift(config.symbol,config.chartTimeframe,periodEnd-1,false);
   if(oldestShift>=0 && newestShift>=0 && oldestShift>=newestShift)
   {
      for(int i=oldestShift;i>=newestShift;i--)
      {
         if(time[i]<start || time[i]>=periodEnd) continue;
         if(!highAnchorFound && high[i]==previousHigh)
         {
            highTime=time[i];
            highAnchorFound=true;
         }
         if(!lowAnchorFound && low[i]==previousLow)
         {
            lowTime=time[i];
            lowAnchorFound=true;
         }
         if(highAnchorFound && lowAnchorFound)
            break;
      }
   }
   int chartPeriodSeconds=MathMax(1,PeriodSeconds(config.chartTimeframe));
   datetime finish=lastTime+chartPeriodSeconds*20;
   datetime labelTime=lastTime+chartPeriodSeconds*2;
   string highName=config.objectPrefix+label+"H";
   string lowName=config.objectPrefix+label+"L";
   if(ObjectFind(0,highName)<0)
      ObjectCreate(0,highName,OBJ_TREND,0,highTime,previousHigh,finish,previousHigh);
   else
   {
      MoveObjectPointIfChanged(highName,0,highTime,previousHigh);
      MoveObjectPointIfChanged(highName,1,finish,previousHigh);
   }
   if(ObjectFind(0,lowName)<0)
      ObjectCreate(0,lowName,OBJ_TREND,0,lowTime,previousLow,finish,previousLow);
   else
   {
      MoveObjectPointIfChanged(lowName,0,lowTime,previousLow);
      MoveObjectPointIfChanged(lowName,1,finish,previousLow);
   }
   ObjectSetInteger(0,highName,OBJPROP_COLOR,lineColor);
   ObjectSetInteger(0,lowName,OBJPROP_COLOR,lineColor);
   ObjectSetInteger(0,highName,OBJPROP_STYLE,LineStyle(style));
   ObjectSetInteger(0,lowName,OBJPROP_STYLE,LineStyle(style));
   ObjectSetInteger(0,highName,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,lowName,OBJPROP_RAY_RIGHT,false);
   string highLabel=(label=="PL_D" ? "Previous Daily High (PDH)" :
                     label=="PL_W" ? "Previous Weekly High (PWH)" :
                                      "Previous Monthly High (PMH)");
   string lowLabel=(label=="PL_D" ? "Previous Daily Low (PDL)" :
                    label=="PL_W" ? "Previous Weekly Low (PWL)" :
                                     "Previous Monthly Low (PML)");
   DrawText(config.objectPrefix+label+"H_Label",labelTime,previousHigh,
            highLabel,lineColor,ANCHOR_LEFT);
   DrawText(config.objectPrefix+label+"L_Label",labelTime,previousLow,
            lowLabel,lineColor,ANCHOR_LEFT);
}

void DrawTrailingLevels(const SMC_DrawConfig &config,const PivotState &trailingTop,
                        const PivotState &trailingBottom,const int swingBias,
                        const datetime lastTime,const int periodSeconds)
{
   if(!config.showStrongWeakHighLow)
   {
      ObjectDelete(0,config.objectPrefix+"SW_High");
      ObjectDelete(0,config.objectPrefix+"SW_Low");
      ObjectDelete(0,config.objectPrefix+"SW_High_Label");
      ObjectDelete(0,config.objectPrefix+"SW_Low_Label");
      return;
   }
   if(!trailingTop.initialized || !trailingBottom.initialized) return;
   int seconds=MathMax(1,periodSeconds);
   datetime end=lastTime+seconds*20;
   datetime labelTime=lastTime+seconds*2;
   string hi=config.objectPrefix+"SW_High";
   string lo=config.objectPrefix+"SW_Low";
   if(ObjectFind(0,hi)<0)
      ObjectCreate(0,hi,OBJ_TREND,0,trailingTop.time,trailingTop.current,
                   end,trailingTop.current);
   else
   {
      MoveObjectPointIfChanged(hi,0,trailingTop.time,trailingTop.current);
      MoveObjectPointIfChanged(hi,1,end,trailingTop.current);
   }
   if(ObjectFind(0,lo)<0)
      ObjectCreate(0,lo,OBJ_TREND,0,trailingBottom.time,trailingBottom.current,
                   end,trailingBottom.current);
   else
   {
      MoveObjectPointIfChanged(lo,0,trailingBottom.time,trailingBottom.current);
      MoveObjectPointIfChanged(lo,1,end,trailingBottom.current);
   }
   ObjectSetInteger(0,hi,OBJPROP_COLOR,SMC_DrawBearColor(config,false));
   ObjectSetInteger(0,lo,OBJPROP_COLOR,SMC_DrawBullColor(config,false));
   ObjectSetInteger(0,hi,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,lo,OBJPROP_RAY_RIGHT,false);
   DrawText(config.objectPrefix+"SW_High_Label",labelTime,trailingTop.current,
            SMC_TimeframeLabel(config.chartTimeframe)+" "+
            (swingBias<0 ? "Strong High" : "Weak High"),
            SMC_DrawBearColor(config,false),ANCHOR_LEFT);
   DrawText(config.objectPrefix+"SW_Low_Label",labelTime,trailingBottom.current,
            SMC_TimeframeLabel(config.chartTimeframe)+" "+
            (swingBias>0 ? "Strong Low" : "Weak Low"),
            SMC_DrawBullColor(config,false),ANCHOR_LEFT);
}

void SMC_DrawUpdateTrailingLevels(const SMC_DrawConfig &config,
                                  const PivotState &trailingTop,
                                  const PivotState &trailingBottom,
                                  const int swingBias,
                                  const datetime trailingAnchorTime,
                                  const datetime currentTime,
                                  const int periodSeconds)
{
   int seconds=MathMax(1,periodSeconds);
   if(!config.showStrongWeakHighLow)
   {
      ObjectDelete(0,config.objectPrefix+"SW_High");
      ObjectDelete(0,config.objectPrefix+"SW_Low");
      ObjectDelete(0,config.objectPrefix+"SW_High_Label");
      ObjectDelete(0,config.objectPrefix+"SW_Low_Label");
   }
   if(config.showStrongWeakHighLow && trailingTop.initialized &&
      trailingBottom.initialized)
   {
      datetime end=currentTime+seconds*20;
      datetime labelTime=currentTime+seconds*2;
      string highLine=config.objectPrefix+"SW_High";
      string lowLine=config.objectPrefix+"SW_Low";
      string highLabel=config.objectPrefix+"SW_High_Label";
      string lowLabel=config.objectPrefix+"SW_Low_Label";
      if(ObjectFind(0,highLine)>=0)
      {
         MoveObjectPointIfChanged(highLine,0,trailingTop.time,trailingTop.current);
         MoveObjectPointIfChanged(highLine,1,end,trailingTop.current);
      }
      if(ObjectFind(0,lowLine)>=0)
      {
         MoveObjectPointIfChanged(lowLine,0,trailingBottom.time,trailingBottom.current);
         MoveObjectPointIfChanged(lowLine,1,end,trailingBottom.current);
      }
      if(ObjectFind(0,highLabel)>=0)
      {
         MoveObjectPointIfChanged(highLabel,0,labelTime,trailingTop.current);
         ObjectSetString(0,highLabel,OBJPROP_TEXT,
                         SMC_TimeframeLabel(config.chartTimeframe)+" "+
                         (swingBias<0 ? "Strong High" : "Weak High"));
      }
      if(ObjectFind(0,lowLabel)>=0)
      {
         MoveObjectPointIfChanged(lowLabel,0,labelTime,trailingBottom.current);
         ObjectSetString(0,lowLabel,OBJPROP_TEXT,
                         SMC_TimeframeLabel(config.chartTimeframe)+" "+
                         (swingBias>0 ? "Strong Low" : "Weak Low"));
      }
   }
   DrawPremiumDiscount(config,trailingTop,trailingBottom,trailingAnchorTime,
                       currentTime,seconds);
}

void DrawPremiumDiscount(const SMC_DrawConfig &config,
                         const PivotState &trailingTop,
                         const PivotState &trailingBottom,
                         const datetime trailingAnchorTime,
                         const datetime lastTime,const int periodSeconds)
{
   if(!config.showPremiumDiscountZones || !trailingTop.initialized ||
      !trailingBottom.initialized || trailingTop.current<=trailingBottom.current)
   {
      ObjectDelete(0,config.objectPrefix+"PD_Premium");
      ObjectDelete(0,config.objectPrefix+"PD_Equilibrium");
      ObjectDelete(0,config.objectPrefix+"PD_Discount");
      ObjectDelete(0,config.objectPrefix+"PD_Premium_Label");
      ObjectDelete(0,config.objectPrefix+"PD_Equilibrium_Label");
      ObjectDelete(0,config.objectPrefix+"PD_Discount_Label");
      return;
   }
   double top=trailingTop.current,bottom=trailingBottom.current;
   datetime start=trailingAnchorTime;
   if(start==0)
      start=(trailingTop.time>trailingBottom.time ?
             trailingTop.time : trailingBottom.time);
   datetime finish=lastTime+periodSeconds*20;
   double premiumBottom=0.95*top+0.05*bottom;
   double eqTop=0.525*top+0.475*bottom;
   double eqBottom=0.525*bottom+0.475*top;
   double discountTop=0.95*bottom+0.05*top;
   DrawZoneBox(config.objectPrefix+"PD_Premium",start,finish,top,premiumBottom,
               SMC_COLOR_BEARISH);
   DrawZoneBox(config.objectPrefix+"PD_Equilibrium",start,finish,eqTop,eqBottom,
               SMC_COLOR_EQUILIBRIUM);
   DrawZoneBox(config.objectPrefix+"PD_Discount",start,finish,discountTop,bottom,
               SMC_COLOR_BULLISH);
   datetime middleTime=start+(finish-start)/2;
   double premiumPrice=SMC_LabelOffsetPrice(config.objectPrefix+"PD_Premium",
                                           (top+premiumBottom)/2,MathAbs(top-premiumBottom));
   double equilibriumPrice=SMC_LabelOffsetPrice(config.objectPrefix+"PD_Equilibrium",
                                               (eqTop+eqBottom)/2,MathAbs(eqTop-eqBottom));
   double discountPrice=SMC_LabelOffsetPrice(config.objectPrefix+"PD_Discount",
                                            (discountTop+bottom)/2,MathAbs(discountTop-bottom));
   DrawText(config.objectPrefix+"PD_Premium_Label",middleTime,
            premiumPrice,"Premium",SMC_COLOR_LABEL,
            ANCHOR_CENTER);
   DrawText(config.objectPrefix+"PD_Equilibrium_Label",middleTime,
            equilibriumPrice,"Equilibrium",SMC_COLOR_LABEL,
            ANCHOR_CENTER);
   DrawText(config.objectPrefix+"PD_Discount_Label",middleTime,
            discountPrice,"Discount",SMC_COLOR_LABEL,
            ANCHOR_CENTER);
}

void RenderPreviousLevels(const SMC_DrawConfig &config,const int ratesTotal,
                          const datetime &time[],
                          const double &high[],const double &low[])
{
   if(config.showDailyLevels)
      DrawPreviousPeriodLevels(config,PERIOD_D1,"PL_D",config.dailyLevelsStyle,
                               SMC_COLOR_PREVIOUS_LEVEL,
                               time[0],ratesTotal,time,high,low);
   else
   {
      ObjectDelete(0,config.objectPrefix+"PL_DH");
      ObjectDelete(0,config.objectPrefix+"PL_DL");
      ObjectDelete(0,config.objectPrefix+"PL_DH_Label");
      ObjectDelete(0,config.objectPrefix+"PL_DL_Label");
   }
   if(config.showWeeklyLevels)
      DrawPreviousPeriodLevels(config,PERIOD_W1,"PL_W",config.weeklyLevelsStyle,
                               SMC_COLOR_PREVIOUS_LEVEL,
                               time[0],ratesTotal,time,high,low);
   else
   {
      ObjectDelete(0,config.objectPrefix+"PL_WH");
      ObjectDelete(0,config.objectPrefix+"PL_WL");
      ObjectDelete(0,config.objectPrefix+"PL_WH_Label");
      ObjectDelete(0,config.objectPrefix+"PL_WL_Label");
   }
   if(config.showMonthlyLevels)
      DrawPreviousPeriodLevels(config,PERIOD_MN1,"PL_M",config.monthlyLevelsStyle,
                               SMC_COLOR_PREVIOUS_LEVEL,
                               time[0],ratesTotal,time,high,low);
   else
   {
      ObjectDelete(0,config.objectPrefix+"PL_MH");
      ObjectDelete(0,config.objectPrefix+"PL_ML");
      ObjectDelete(0,config.objectPrefix+"PL_MH_Label");
      ObjectDelete(0,config.objectPrefix+"PL_ML_Label");
   }
}

#endif // SMC_DRAW_MQH
