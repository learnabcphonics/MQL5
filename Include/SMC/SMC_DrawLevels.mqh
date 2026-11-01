// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWLEVELS_MQH
#define SMC_DRAWLEVELS_MQH

#include <SMC/SMC_DrawHelpers.mqh>
#include <SMC/SMC_DrawZones.mqh>

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
      SMC_DrawText(config.objectPrefix+"SW_High_"+IntegerToString((int)time[candidate]),time[candidate],
               high[candidate],(!swingHigh.previousInitialized ? "H" :
                                swingHigh.current>swingHigh.previous ? "HH" : "LH"),
               SMC_COLOR_BEARISH,ANCHOR_LOWER);
   if(drawLow)
      SMC_DrawText(config.objectPrefix+"SW_Low_"+IntegerToString((int)time[candidate]),time[candidate],
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
   if(ObjectFind(0,highName)<0)
      ObjectCreate(0,highName,OBJ_TREND,0,highTime,previousHigh,finish,previousHigh);
   else
   {
      SMC_MoveObjectPointIfChanged(highName,0,highTime,previousHigh);
      SMC_MoveObjectPointIfChanged(highName,1,finish,previousHigh);
   }
   if(ObjectFind(0,lowName)<0)
      ObjectCreate(0,lowName,OBJ_TREND,0,lowTime,previousLow,finish,previousLow);
   else
   {
      SMC_MoveObjectPointIfChanged(lowName,0,lowTime,previousLow);
      SMC_MoveObjectPointIfChanged(lowName,1,finish,previousLow);
   }
   ObjectSetInteger(0,highName,OBJPROP_COLOR,lineColor);
   ObjectSetInteger(0,lowName,OBJPROP_COLOR,lineColor);
   ObjectSetInteger(0,highName,OBJPROP_STYLE,SMC_LineStyle(style));
   ObjectSetInteger(0,lowName,OBJPROP_STYLE,SMC_LineStyle(style));
   ObjectSetInteger(0,highName,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,lowName,OBJPROP_RAY_RIGHT,false);
   string highLabel=(label=="PL_D" ? "Previous Daily High (PDH)" :
                     label=="PL_W" ? "Previous Weekly High (PWH)" :
                                      "Previous Monthly High (PMH)");
   string lowLabel=(label=="PL_D" ? "Previous Daily Low (PDL)" :
                    label=="PL_W" ? "Previous Weekly Low (PWL)" :
                                     "Previous Monthly Low (PML)");
   SMC_DrawText(config.objectPrefix+label+"H_Label",labelTime,previousHigh,
            highLabel,lineColor,ANCHOR_LEFT);
   SMC_DrawText(config.objectPrefix+label+"L_Label",labelTime,previousLow,
            lowLabel,lineColor,ANCHOR_LEFT);
}

void SMC_DrawTrailingLevels(const SMC_DrawConfig &config,const PivotState &trailingTop,
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
      SMC_MoveObjectPointIfChanged(hi,0,trailingTop.time,trailingTop.current);
      SMC_MoveObjectPointIfChanged(hi,1,end,trailingTop.current);
   }
   if(ObjectFind(0,lo)<0)
      ObjectCreate(0,lo,OBJ_TREND,0,trailingBottom.time,trailingBottom.current,
                   end,trailingBottom.current);
   else
   {
      SMC_MoveObjectPointIfChanged(lo,0,trailingBottom.time,trailingBottom.current);
      SMC_MoveObjectPointIfChanged(lo,1,end,trailingBottom.current);
   }
   ObjectSetInteger(0,hi,OBJPROP_COLOR,SMC_COLOR_BEARISH);
   ObjectSetInteger(0,lo,OBJPROP_COLOR,SMC_COLOR_BULLISH);
   ObjectSetInteger(0,hi,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,lo,OBJPROP_RAY_RIGHT,false);
   SMC_DrawText(config.objectPrefix+"SW_High_Label",labelTime,trailingTop.current,
            SMC_TimeframeLabel(config.chartTimeframe)+" "+
            (swingBias<0 ? "Strong High" : "Weak High"),
            SMC_COLOR_BEARISH,ANCHOR_LEFT);
   SMC_DrawText(config.objectPrefix+"SW_Low_Label",labelTime,trailingBottom.current,
            SMC_TimeframeLabel(config.chartTimeframe)+" "+
            (swingBias>0 ? "Strong Low" : "Weak Low"),
            SMC_COLOR_BULLISH,ANCHOR_LEFT);
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
         SMC_MoveObjectPointIfChanged(highLine,0,trailingTop.time,trailingTop.current);
         SMC_MoveObjectPointIfChanged(highLine,1,end,trailingTop.current);
      }
      if(ObjectFind(0,lowLine)>=0)
      {
         SMC_MoveObjectPointIfChanged(lowLine,0,trailingBottom.time,trailingBottom.current);
         SMC_MoveObjectPointIfChanged(lowLine,1,end,trailingBottom.current);
      }
      if(ObjectFind(0,highLabel)>=0)
      {
         SMC_MoveObjectPointIfChanged(highLabel,0,labelTime,trailingTop.current);
         ObjectSetString(0,highLabel,OBJPROP_TEXT,
                         SMC_TimeframeLabel(config.chartTimeframe)+" "+
                         (swingBias<0 ? "Strong High" : "Weak High"));
      }
      if(ObjectFind(0,lowLabel)>=0)
      {
         SMC_MoveObjectPointIfChanged(lowLabel,0,labelTime,trailingBottom.current);
         ObjectSetString(0,lowLabel,OBJPROP_TEXT,
                         SMC_TimeframeLabel(config.chartTimeframe)+" "+
                         (swingBias>0 ? "Strong Low" : "Weak Low"));
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
   SMC_DrawZoneBox(config.objectPrefix+"PD_Premium",start,finish,top,premiumBottom,
               SMC_COLOR_BEARISH);
   SMC_DrawZoneBox(config.objectPrefix+"PD_Equilibrium",start,finish,eqTop,eqBottom,
               SMC_COLOR_EQUILIBRIUM);
   SMC_DrawZoneBox(config.objectPrefix+"PD_Discount",start,finish,discountTop,bottom,
               SMC_COLOR_BULLISH);
   datetime middleTime=start+(finish-start)/2;
   double premiumPrice=SMC_LabelOffsetPrice(config.objectPrefix+"PD_Premium",
                                           (top+premiumBottom)/2,MathAbs(top-premiumBottom));
   double equilibriumPrice=SMC_LabelOffsetPrice(config.objectPrefix+"PD_Equilibrium",
                                               (eqTop+eqBottom)/2,MathAbs(eqTop-eqBottom));
   double discountPrice=SMC_LabelOffsetPrice(config.objectPrefix+"PD_Discount",
                                            (discountTop+bottom)/2,MathAbs(discountTop-bottom));
   SMC_DrawText(config.objectPrefix+"PD_Premium_Label",middleTime,
            premiumPrice,"Premium",SMC_COLOR_LABEL,
            ANCHOR_CENTER);
   SMC_DrawText(config.objectPrefix+"PD_Equilibrium_Label",middleTime,
            equilibriumPrice,"Equilibrium",SMC_COLOR_LABEL,
            ANCHOR_CENTER);
   SMC_DrawText(config.objectPrefix+"PD_Discount_Label",middleTime,
            discountPrice,"Discount",SMC_COLOR_LABEL,
            ANCHOR_CENTER);
}

void SMC_RenderPreviousLevels(const SMC_DrawConfig &config,const int ratesTotal,
                          const datetime &time[],
                          const double &high[],const double &low[])
{
   if(config.showDailyLevels)
      SMC_DrawPreviousPeriodLevels(config,PERIOD_D1,"PL_D",config.dailyLevelsStyle,
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
      SMC_DrawPreviousPeriodLevels(config,PERIOD_W1,"PL_W",config.weeklyLevelsStyle,
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
      SMC_DrawPreviousPeriodLevels(config,PERIOD_MN1,"PL_M",config.monthlyLevelsStyle,
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

#endif // SMC_DRAWLEVELS_MQH
