// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWZONES_MQH
#define SMC_DRAWZONES_MQH

#include <SMC/SMC_DrawHelpers.mqh>

void SMC_DrawZoneBox(const string name,const datetime startTime,const datetime endTime,
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
   SMC_MoveObjectPointIfChanged(name,0,startTime,zoneTop);
   SMC_MoveObjectPointIfChanged(name,1,endTime,zoneBottom);
   ObjectSetInteger(0,name,OBJPROP_COLOR,rgbColor);
   ObjectSetInteger(0,name,OBJPROP_FILL,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,SMC_ZoneZOrder(name));
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
}

void SMC_DrawEqualLevelEvent(const SMC_DrawConfig &config,
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
   ObjectSetInteger(0,lineName,OBJPROP_BACK,false);
   ObjectSetInteger(0,lineName,OBJPROP_ZORDER,20);
   ObjectSetInteger(0,lineName,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,lineName,OBJPROP_HIDDEN,true);
   SMC_DrawText(config.objectPrefix+kind+"_Label_"+id,event.labelTime,
            event.secondPrice,SMC_TimeframeLabel(config.chartTimeframe)+" "+kind,
            lineColor,event.high ? ANCHOR_LOWER : ANCHOR_UPPER,(int)labelSize);
}

void SMC_DrawFairValueGap(const SMC_DrawConfig &config,const FairValueGapState &gap,
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
   SMC_DrawZoneBox(firstName,gap.left,gap.right,
               gap.firstTop,gap.firstBottom,zoneColor);
   SMC_DrawZoneBox(secondName,gap.left,gap.right,
               gap.secondTop,gap.secondBottom,zoneColor);
   datetime middleTime=gap.left+(gap.right-gap.left)/2;
   double middlePrice=(gap.top+gap.bottom)*0.5;
   double labelPrice=SMC_LabelOffsetPrice(config.objectPrefix+"FVG_"+id,
                                         middlePrice,MathAbs(gap.top-gap.bottom));
   string label=SMC_TimeframeLabel(config.chartTimeframe)+" "+
                (gap.bias>0 ? "Bullish FVG" : "Bearish FVG");
   SMC_DrawText(config.objectPrefix+"FVG_"+id+"_Label",middleTime,labelPrice,
            label,SMC_COLOR_LABEL,ANCHOR_CENTER);
}

void SMC_DeleteFairValueGap(const SMC_DrawConfig &config,
                        const FairValueGapState &gap)
{
   string id=(gap.bias>0 ? "Bull_" : "Bear_")+
             IntegerToString((int)gap.time);
   ObjectDelete(0,config.objectPrefix+"FVG_"+id+"_1");
   ObjectDelete(0,config.objectPrefix+"FVG_"+id+"_2");
   ObjectDelete(0,config.objectPrefix+"FVG_"+id+"_Label");
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

color SMC_OrderBlockBaseColor(const OrderBlockState &block)
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

void SMC_DrawOrderBlockObjects(const SMC_DrawConfig &config,
                           const OrderBlockState &orderBlocks[],
                           const datetime lastTime,const int periodSeconds)
{
   int totalInternal=0,totalSwing=0;
   int labelX[40],labelY[40],labelHalfWidths[40];
   int placedLabelCount=0;
   int count=ArraySize(orderBlocks);
   for(int i=0;i<count;i++)
   {
      if(orderBlocks[i].internal)
         totalInternal++;
      else
         totalSwing++;
   }
   int internalToSkip=MathMax(0,totalInternal-
                             MathMax(0,config.internalOrderBlocksToShow));
   int swingToSkip=MathMax(0,totalSwing-
                           MathMax(0,config.swingOrderBlocksToShow));
   int internalSeen=0,swingSeen=0;
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
   for(int i=ObjectsTotal(0,-1,-1)-1;i>=0;--i)
   {
      string existingName=ObjectName(0,i,-1,-1);
      if(StringFind(existingName,config.objectPrefix+"OB_")==0)
         ObjectDelete(0,existingName);
   }
   for(int i=0;i<count;i++)
   {
      OrderBlockState block=orderBlocks[i];
      string objectName=SMC_OrderBlockObjectName(config,block);
      bool visible;
      if(block.internal)
      {
         visible=config.showInternalOrderBlocks &&
                 internalSeen>=internalToSkip;
         internalSeen++;
      }
      else
      {
         visible=config.showSwingOrderBlocks && swingSeen>=swingToSkip;
         swingSeen++;
      }
      if(!visible)
         continue;

      color base=SMC_OrderBlockBaseColor(block);
      datetime rightTime=blockRight[i];
      SMC_DrawZoneBox(objectName,block.time,
                  rightTime,block.high,block.low,base);
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
      SMC_DrawText(objectName+"_Label",adjustedTime,adjustedPrice,
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

#endif // SMC_DRAWZONES_MQH
