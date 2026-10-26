// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
// Drawing helpers receive presentation settings and analysis state explicitly.
#ifndef SMC_DRAW_MQH
#define SMC_DRAW_MQH

#include <SMC/SMC_Types.mqh>

ENUM_LINE_STYLE LineStyle(const ENUM_SMC_LINE_STYLE style)
{
   if(style == SMC_DASHED) return STYLE_DASH;
   if(style == SMC_DOTTED) return STYLE_DOT;
   return STYLE_SOLID;
}

color SMC_DrawBullColor(const SMC_DrawConfig &config,const bool internal)
{
   if(config.style==SMC_MONOCHROME)
      return C'178,181,190';
   return internal ? config.internalBullishColor : config.swingBullishColor;
}

color SMC_DrawBearColor(const SMC_DrawConfig &config,const bool internal)
{
   if(config.style==SMC_MONOCHROME)
      return C'93,96,107';
   return internal ? config.internalBearishColor : config.swingBearishColor;
}

color SMC_DrawWithAlpha(const color base,const uchar alpha)
{
   return (color)ColorToARGB(base,alpha);
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
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
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
   string name=config.objectPrefix+"MarketBias";
   if(!config.showMarketBias)
   {
      ObjectDelete(0,name);
      return;
   }
   if(ObjectFind(0,name)<0 && !ObjectCreate(0,name,OBJ_LABEL,0,0,0))
      return;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,10);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,172);
   ObjectSetInteger(0,name,OBJPROP_COLOR,
                    swingBias>0 ? SMC_DrawBullColor(config,false) :
                    (swingBias<0 ? SMC_DrawBearColor(config,false) : C'135,139,148'));
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
      ObjectDelete(0,config.objectPrefix+"StructureLine_"+
                     latestStructures[slot].id);
      ObjectDelete(0,config.objectPrefix+"StructureLabel_"+
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
      string lineName=config.objectPrefix+"StructureLine_"+latestStructures[i].id;
      string labelName=config.objectPrefix+"StructureLabel_"+latestStructures[i].id;
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
      string lineName=config.objectPrefix+"StructureLine_"+latestStructures[i].id;
      string labelName=config.objectPrefix+"StructureLabel_"+latestStructures[i].id;
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
   if(ObjectFind(0,name)<0 &&
      !ObjectCreate(0,name,OBJ_RECTANGLE,0,startTime,zoneTop,endTime,zoneBottom))
      return;
   MoveObjectPointIfChanged(name,0,startTime,zoneTop);
   MoveObjectPointIfChanged(name,1,endTime,zoneBottom);
   ObjectSetInteger(0,name,OBJPROP_COLOR,zoneColor);
   ObjectSetInteger(0,name,OBJPROP_FILL,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}

void DrawEqualLevelEvent(const SMC_DrawConfig &config,
                         const EqualLevelEvent &event,
                         const color lineColor,const ENUM_SMC_SIZE labelSize)
{
   if(!event.valid)
      return;
   string kind=(event.high ? "EQH" : "EQL");
   DeleteObjectsWithPrefix(config.objectPrefix+kind+"_Line_");
   DeleteObjectsWithPrefix(config.objectPrefix+kind+"_Label_");
   string id=IntegerToString((int)event.secondTime);
   string lineName=config.objectPrefix+kind+"_Line_"+id;
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
   DrawZoneBox(config.objectPrefix+"FVG_"+id+"_1",gap.left,gap.right,
               gap.firstTop,gap.firstBottom,zoneColor);
   DrawZoneBox(config.objectPrefix+"FVG_"+id+"_2",gap.left,gap.right,
               gap.secondTop,gap.secondBottom,zoneColor);
   datetime middleTime=gap.left;
   double middlePrice=(gap.top+gap.bottom)*0.5;
   string label=SMC_TimeframeLabel(config.chartTimeframe)+" "+
                (gap.bias>0 ? "Bullish FVG" : "Bearish FVG");
   color labelColor=(gap.bias>0 ? SMC_DrawBullColor(config,false) :
                                  SMC_DrawBearColor(config,false));
   DrawText(config.objectPrefix+"FVG_"+id+"_Label",middleTime,middlePrice,
            label,labelColor,ANCHOR_CENTER);
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

void DrawOrderBlockObjects(const SMC_DrawConfig &config,
                           const OrderBlockState &orderBlocks[],
                           const datetime lastTime,const int periodSeconds)
{
   int internalCount=0,swingCount=0;
   int count=ArraySize(orderBlocks);
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
      color base;
      if(config.style==SMC_MONOCHROME)
         base=(block.bias<0 ? C'93,96,107' : C'178,181,190');
      else if(block.internal)
         base=(block.bias<0 ? config.internalBearishOBColor :
                              config.internalBullishOBColor);
      else
         base=(block.bias<0 ? config.swingBearishOBColor :
                              config.swingBullishOBColor);
      int safePeriodSeconds=MathMax(1,periodSeconds);
      int extendBars=MathMax(1,config.orderBlockExtend);
      long extensionSeconds=(long)safePeriodSeconds*extendBars;
      datetime rightTime=(datetime)((long)lastTime+extensionSeconds);
      if(rightTime<=block.time)
         rightTime=block.time+safePeriodSeconds;
      DrawZoneBox(objectName,block.time,
                  rightTime,block.high,block.low,
                  SMC_DrawWithAlpha(base,51));
      if(ObjectFind(0,objectName)<0)
         continue;
      DrawZoneBox(objectName+"_Origin",block.time,
                  MathMin(block.time+safePeriodSeconds,rightTime),
                  block.high,block.low,
                  SMC_DrawWithAlpha(base,150));
      datetime labelTime=block.time+(rightTime-block.time)/2;
      string label=(block.internal ? "Int " : "Swing ")+
                   (block.bias>0 ? "Bull OB" : "Bear OB");
      DrawText(objectName+"_Label",labelTime,(block.high+block.low)*0.5,
               SMC_TimeframeLabel(config.chartTimeframe)+" "+label,
               clrWhite,ANCHOR_CENTER);
   }
}

void DrawSwingLabels(const SMC_DrawConfig &config,const datetime &time[],
                     const double &high[],const double &low[],
                     const int i,const int swingLength,
                     const PivotState &swingHigh,const PivotState &swingLow)
{
   if(!config.showSwingPoints) return;
   int candidate=i+swingLength;
   bool drawHigh=(swingHigh.initialized && swingHigh.index==candidate);
   bool drawLow=(swingLow.initialized && swingLow.index==candidate);
   if(drawHigh || drawLow)
   {
      DeleteObjectsWithPrefix(config.objectPrefix+"SwingHigh_");
      DeleteObjectsWithPrefix(config.objectPrefix+"SwingLow_");
   }
   if(drawHigh)
      DrawText(config.objectPrefix+"SwingHigh_"+IntegerToString((int)time[candidate]),time[candidate],
               high[candidate],(!swingHigh.previousInitialized ? "H" :
                                swingHigh.current>swingHigh.previous ? "HH" : "LH"),
               SMC_DrawBearColor(config,false),ANCHOR_LOWER);
   if(drawLow)
      DrawText(config.objectPrefix+"SwingLow_"+IntegerToString((int)time[candidate]),time[candidate],
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
   string highLabel=(label=="D" ? "Previous Daily High (PDH)" :
                     label=="W" ? "Previous Weekly High (PWH)" :
                                   "Previous Monthly High (PMH)");
   string lowLabel=(label=="D" ? "Previous Daily Low (PDL)" :
                    label=="W" ? "Previous Weekly Low (PWL)" :
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
   if(!config.showStrongWeakHighLow || !trailingTop.initialized ||
      !trailingBottom.initialized) return;
   int seconds=MathMax(1,periodSeconds);
   datetime end=lastTime+seconds*20;
   datetime labelTime=lastTime+seconds*2;
   string hi=config.objectPrefix+"StrongWeak_High";
   string lo=config.objectPrefix+"StrongWeak_Low";
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
   DrawText(config.objectPrefix+"StrongWeak_High_Label",labelTime,trailingTop.current,
            SMC_TimeframeLabel(config.chartTimeframe)+" "+
            (swingBias<0 ? "Strong High" : "Weak High"),
            SMC_DrawBearColor(config,false),ANCHOR_LEFT);
   DrawText(config.objectPrefix+"StrongWeak_Low_Label",labelTime,trailingBottom.current,
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
   if(config.showStrongWeakHighLow && trailingTop.initialized &&
      trailingBottom.initialized)
   {
      datetime end=currentTime+seconds*20;
      datetime labelTime=currentTime+seconds*2;
      string highLine=config.objectPrefix+"StrongWeak_High";
      string lowLine=config.objectPrefix+"StrongWeak_Low";
      string highLabel=config.objectPrefix+"StrongWeak_High_Label";
      string lowLabel=config.objectPrefix+"StrongWeak_Low_Label";
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
   if(config.showPremiumDiscountZones)
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
      return;
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
   DrawZoneBox(config.objectPrefix+"Zone_Premium",start,finish,top,premiumBottom,
               SMC_DrawWithAlpha(config.premiumZoneColor,45));
   DrawZoneBox(config.objectPrefix+"Zone_Equilibrium",start,finish,eqTop,eqBottom,
               SMC_DrawWithAlpha(config.equilibriumZoneColor,45));
   DrawZoneBox(config.objectPrefix+"Zone_Discount",start,finish,discountTop,bottom,
               SMC_DrawWithAlpha(config.discountZoneColor,45));
   datetime middleTime=start+(finish-start)/2;
   DrawText(config.objectPrefix+"Zone_Premium_Label",middleTime,
            (top+premiumBottom)/2,"Premium",config.premiumZoneColor,
            ANCHOR_CENTER);
   DrawText(config.objectPrefix+"Zone_Equilibrium_Label",middleTime,
            (eqTop+eqBottom)/2,"Equilibrium",config.equilibriumZoneColor,
            ANCHOR_CENTER);
   DrawText(config.objectPrefix+"Zone_Discount_Label",middleTime,
            (discountTop+bottom)/2,"Discount",config.discountZoneColor,
            ANCHOR_CENTER);
}

void RenderPreviousLevels(const SMC_DrawConfig &config,const int ratesTotal,
                          const datetime &time[],
                          const double &high[],const double &low[])
{
   if(config.showDailyLevels)
      DrawPreviousPeriodLevels(config,PERIOD_D1,"D",config.dailyLevelsStyle,
                               config.dailyLevelsColor,
                               time[0],ratesTotal,time,high,low);
   if(config.showWeeklyLevels)
      DrawPreviousPeriodLevels(config,PERIOD_W1,"W",config.weeklyLevelsStyle,
                               config.weeklyLevelsColor,
                               time[0],ratesTotal,time,high,low);
   if(config.showMonthlyLevels)
      DrawPreviousPeriodLevels(config,PERIOD_MN1,"M",config.monthlyLevelsStyle,
                               config.monthlyLevelsColor,
                               time[0],ratesTotal,time,high,low);
}

#endif // SMC_DRAW_MQH
