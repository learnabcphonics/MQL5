// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWLEVELS_MQH
#define SMC_DRAWLEVELS_MQH

#include <SMC/SMC_DrawHelpers.mqh>
#include <SMC/SMC_DrawAreas.mqh>

void SMC_DrawSwingLabels(const SMC_DrawConfig &config,const datetime &time[],
                     const double &high[],const double &low[],
                     const int i,const int swingLength,
                     const PivotState &swingHigh,const PivotState &swingLow)
{
   if(!config.showSwingPoints)
   {
      SMC_DeleteObjectsWithPrefix(config.objectPrefix+"SW_High_");
      SMC_DeleteObjectsWithPrefix(config.objectPrefix+"SW_Low_");
      return;
   }
   int candidate=i+swingLength;
   bool drawHigh=(swingHigh.initialized && swingHigh.index==candidate);
   bool drawLow=(swingLow.initialized && swingLow.index==candidate);
   if(drawHigh)
      SMC_DrawText(config.objectPrefix+"SW_High_"+
                   (config.mode==SMC_HISTORICAL ?
                    IntegerToString((int)time[candidate]) : "Current"),
               time[candidate],
               high[candidate],(!swingHigh.previousInitialized ? "H" :
                                 swingHigh.current>swingHigh.previous ? "HH" : "LH"),
               SMC_COLOR_BEARISH,ANCHOR_LOWER);
   if(drawLow)
      SMC_DrawText(config.objectPrefix+"SW_Low_"+
                   (config.mode==SMC_HISTORICAL ?
                    IntegerToString((int)time[candidate]) : "Current"),
               time[candidate],
               low[candidate],(!swingLow.previousInitialized ? "L" :
                                swingLow.current<swingLow.previous ? "LL" : "HL"),
               SMC_COLOR_BULLISH,ANCHOR_UPPER);
}

void SMC_DrawPreviousPeriodLevels(const SMC_DrawConfig &config,
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
   SMC_PineLineSet(highName,highTime,previousHigh,finish,previousHigh,
                   lineColor,SMC_LineStyle(style),1,false,false,true,10);
   SMC_PineLineSet(lowName,lowTime,previousLow,finish,previousLow,
                   lineColor,SMC_LineStyle(style),1,false,false,true,10);
   string highLabel=(label=="PL_D" ? "Previous Daily High (PDH)" :
                     label=="PL_W" ? "Previous Weekly High (PWH)" :
                                      "Previous Monthly High (PMH)");
   string lowLabel=(label=="PL_D" ? "Previous Daily Low (PDL)" :
                    label=="PL_W" ? "Previous Weekly Low (PWL)" :
                                     "Previous Monthly Low (PML)");
   SMC_DrawText(config.objectPrefix+label+"H_Label",labelTime,previousHigh,
            highLabel,lineColor,ANCHOR_LEFT,8,true);
   SMC_DrawText(config.objectPrefix+label+"L_Label",labelTime,previousLow,
            lowLabel,lineColor,ANCHOR_LEFT,8,true);
}

void SMC_DrawTrailingLevels(const SMC_DrawConfig &config,const PivotState &trailingTop,
                        const PivotState &trailingBottom,const int swingBias,
                        const datetime lastTime,const int periodSeconds)
{
   int seconds=MathMax(1,periodSeconds);
   datetime end=lastTime+seconds*20;
   datetime labelTime=lastTime+seconds*2;
   string hi=config.objectPrefix+"SW_High";
   string lo=config.objectPrefix+"SW_Low";
   string hiLabel=config.objectPrefix+"SW_High_Label";
   string loLabel=config.objectPrefix+"SW_Low_Label";
   bool showHigh=(swingBias<0 ? config.showStrongHigh : config.showWeakHigh);
   bool showLow=(swingBias>0 ? config.showStrongLow : config.showWeakLow);
   if(!showHigh)
   {
      SMC_PineDrawingDelete(hi);
      SMC_PineDrawingDelete(hiLabel);
   }
   if(!showLow)
   {
      SMC_PineDrawingDelete(lo);
      SMC_PineDrawingDelete(loLabel);
   }
   if(!trailingTop.initialized || !trailingBottom.initialized) return;
   if(showHigh)
   {
      SMC_PineLineSet(hi,trailingTop.time,trailingTop.current,end,
                      trailingTop.current,SMC_COLOR_BEARISH,
                      STYLE_SOLID,1,false,false,true,10);
      SMC_DrawText(hiLabel,labelTime,trailingTop.current,
               SMC_TimeframeLabel(config.chartTimeframe)+" "+
               (swingBias<0 ? "Strong High" : "Weak High"),
               SMC_COLOR_BEARISH,ANCHOR_LEFT,8,true);
   }
   if(showLow)
   {
      SMC_PineLineSet(lo,trailingBottom.time,trailingBottom.current,end,
                      trailingBottom.current,SMC_COLOR_BULLISH,
                      STYLE_SOLID,1,false,false,true,10);
      SMC_DrawText(loLabel,labelTime,trailingBottom.current,
               SMC_TimeframeLabel(config.chartTimeframe)+" "+
               (swingBias>0 ? "Strong Low" : "Weak Low"),
               SMC_COLOR_BULLISH,ANCHOR_LEFT,8,true);
   }
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
   bool showHigh=(swingBias<0 ? config.showStrongHigh : config.showWeakHigh);
   bool showLow=(swingBias>0 ? config.showStrongLow : config.showWeakLow);
   string highLine=config.objectPrefix+"SW_High";
   string lowLine=config.objectPrefix+"SW_Low";
   string highLabel=config.objectPrefix+"SW_High_Label";
   string lowLabel=config.objectPrefix+"SW_Low_Label";
   if(!showHigh)
   {
      SMC_PineDrawingDelete(highLine);
      SMC_PineDrawingDelete(highLabel);
   }
   if(!showLow)
   {
      SMC_PineDrawingDelete(lowLine);
      SMC_PineDrawingDelete(lowLabel);
   }
   if(trailingTop.initialized && trailingBottom.initialized)
   {
      datetime end=currentTime+seconds*20;
      datetime labelTime=currentTime+seconds*2;
      if(showHigh)
      {
         SMC_PineLineSet(highLine,trailingTop.time,trailingTop.current,end,
                         trailingTop.current,SMC_COLOR_BEARISH,
                         STYLE_SOLID,1,false,false,true,10);
         SMC_DrawText(highLabel,labelTime,trailingTop.current,
                      SMC_TimeframeLabel(config.chartTimeframe)+" "+
                      (swingBias<0 ? "Strong High" : "Weak High"),
                      SMC_COLOR_BEARISH,ANCHOR_LEFT,8,true);
      }
      if(showLow)
      {
         SMC_PineLineSet(lowLine,trailingBottom.time,trailingBottom.current,end,
                         trailingBottom.current,SMC_COLOR_BULLISH,
                         STYLE_SOLID,1,false,false,true,10);
         SMC_DrawText(lowLabel,labelTime,trailingBottom.current,
                      SMC_TimeframeLabel(config.chartTimeframe)+" "+
                      (swingBias>0 ? "Strong Low" : "Weak Low"),
                      SMC_COLOR_BULLISH,ANCHOR_LEFT,8,true);
      }
   }
   SMC_DrawPremiumDiscount(config,trailingTop,trailingBottom,trailingAnchorTime,
                       currentTime,seconds);
}

void SMC_DrawPremiumDiscount(const SMC_DrawConfig &config,
                         const PivotState &trailingTop,
                         const PivotState &trailingBottom,
                         const datetime trailingAnchorTime,
                         const datetime lastTime,const int periodSeconds)
{
   if(!config.showPremiumDiscountZones || !trailingTop.initialized ||
      !trailingBottom.initialized || trailingTop.current<=trailingBottom.current)
   {
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Premium");
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Equilibrium");
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Discount");
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Premium_Label");
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Equilibrium_Label");
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Discount_Label");
      SMC_ZoneCanvasRemove(config.objectPrefix+"PD_Premium");
      SMC_ZoneCanvasRemove(config.objectPrefix+"PD_Equilibrium");
      SMC_ZoneCanvasRemove(config.objectPrefix+"PD_Discount");
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
   SMC_DrawZoneBox(config.objectPrefix+"PD_Premium",start,finish,top,premiumBottom,
               SMC_COLOR_BEARISH,80,100);
   SMC_DrawZoneBox(config.objectPrefix+"PD_Equilibrium",start,finish,eqTop,eqBottom,
               SMC_COLOR_EQUILIBRIUM,80,100);
   SMC_DrawZoneBox(config.objectPrefix+"PD_Discount",start,finish,discountTop,bottom,
               SMC_COLOR_BULLISH,80,100);
   datetime middleTime=start+(finish-start)/2;
   double premiumPrice=SMC_LabelOffsetPrice(config.objectPrefix+"PD_Premium",
                                           (top+premiumBottom)/2,MathAbs(top-premiumBottom));
   double equilibriumPrice=SMC_LabelOffsetPrice(config.objectPrefix+"PD_Equilibrium",
                                               (eqTop+eqBottom)/2,MathAbs(eqTop-eqBottom));
   double discountPrice=SMC_LabelOffsetPrice(config.objectPrefix+"PD_Discount",
                                            (discountTop+bottom)/2,MathAbs(discountTop-bottom));
   SMC_DrawText(config.objectPrefix+"PD_Premium_Label",middleTime,
            premiumPrice,"Premium",SMC_COLOR_LABEL,
            ANCHOR_CENTER,8,true);
   SMC_DrawText(config.objectPrefix+"PD_Equilibrium_Label",middleTime,
            equilibriumPrice,"Equilibrium",SMC_COLOR_LABEL,
            ANCHOR_CENTER,8,true);
   SMC_DrawText(config.objectPrefix+"PD_Discount_Label",middleTime,
            discountPrice,"Discount",SMC_COLOR_LABEL,
            ANCHOR_CENTER,8,true);
}

void SMC_RenderPreviousLevels(const SMC_DrawConfig &config,const int ratesTotal,
                          const datetime &time[],
                          const double &high[],const double &low[])
{
   if(config.showMonthlyLevels)
      SMC_DrawPreviousPeriodLevels(config,PERIOD_MN1,"PL_M",config.monthlyLevelsStyle,
                               SMC_COLOR_PREVIOUS_LEVEL,
                               time[0],ratesTotal,time,high,low);
   else
   {
      SMC_PineDrawingDelete(config.objectPrefix+"PL_MH");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_ML");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_MH_Label");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_ML_Label");
   }
   if(config.showWeeklyLevels)
      SMC_DrawPreviousPeriodLevels(config,PERIOD_W1,"PL_W",config.weeklyLevelsStyle,
                               SMC_COLOR_PREVIOUS_LEVEL,
                               time[0],ratesTotal,time,high,low);
   else
   {
      SMC_PineDrawingDelete(config.objectPrefix+"PL_WH");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_WL");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_WH_Label");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_WL_Label");
   }
   if(config.showDailyLevels)
      SMC_DrawPreviousPeriodLevels(config,PERIOD_D1,"PL_D",config.dailyLevelsStyle,
                               SMC_COLOR_PREVIOUS_LEVEL,
                               time[0],ratesTotal,time,high,low);
   else
   {
      SMC_PineDrawingDelete(config.objectPrefix+"PL_DH");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_DL");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_DH_Label");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_DL_Label");
   }
}

#endif // SMC_DRAWLEVELS_MQH
