// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWPREVIOUSLEVELS_MQH
#define SMC_DRAWPREVIOUSLEVELS_MQH

#include <SMC/SMC_DrawHelpers.mqh>

void SMC_DrawPreviousPeriodLevels(const SMC_DrawConfig &config,
                                  const ENUM_TIMEFRAMES timeframe,
                                  const string label,
                                  const ENUM_SMC_LINE_STYLE style,
                                  const color lineColor,
                                  const datetime lastTime,
                                  const int ratesTotal,
                                  const datetime &time[],
                                  const double &high[],
                                  const double &low[])
{
   if(PeriodSeconds(config.chartTimeframe)>PeriodSeconds(timeframe))
      return;
   int shift=1;
   double previousHigh=iHigh(config.symbol,timeframe,shift);
   double previousLow=iLow(config.symbol,timeframe,shift);
   datetime start=iTime(config.symbol,timeframe,shift);
   if(start==0 || previousHigh==0 || previousLow==0)
      return;
   datetime periodEnd=iTime(config.symbol,timeframe,0);
   if(periodEnd==0)
      return;
   datetime highTime=start,lowTime=start;
   bool highAnchorFound=false,lowAnchorFound=false;
   int oldestShift=iBarShift(config.symbol,config.chartTimeframe,start,false);
   int newestShift=iBarShift(config.symbol,config.chartTimeframe,periodEnd-1,false);
   if(oldestShift>=0 && newestShift>=0 && oldestShift>=newestShift)
   {
      for(int i=oldestShift;i>=newestShift;i--)
      {
         if(time[i]<start || time[i]>=periodEnd)
            continue;
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

void SMC_RenderPreviousLevels(const SMC_DrawConfig &config,
                              const int ratesTotal,
                              const datetime &time[],
                              const double &high[],
                              const double &low[])
{
   if(config.showMonthlyLevels)
      SMC_DrawPreviousPeriodLevels(config,PERIOD_MN1,"PL_M",
                                   config.monthlyLevelsStyle,
                                   SMC_COLOR_PREVIOUS_LEVEL,time[0],
                                   ratesTotal,time,high,low);
   else
   {
      SMC_PineDrawingDelete(config.objectPrefix+"PL_MH");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_ML");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_MH_Label");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_ML_Label");
   }
   if(config.showWeeklyLevels)
      SMC_DrawPreviousPeriodLevels(config,PERIOD_W1,"PL_W",
                                   config.weeklyLevelsStyle,
                                   SMC_COLOR_PREVIOUS_LEVEL,time[0],
                                   ratesTotal,time,high,low);
   else
   {
      SMC_PineDrawingDelete(config.objectPrefix+"PL_WH");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_WL");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_WH_Label");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_WL_Label");
   }
   if(config.showDailyLevels)
      SMC_DrawPreviousPeriodLevels(config,PERIOD_D1,"PL_D",
                                   config.dailyLevelsStyle,
                                   SMC_COLOR_PREVIOUS_LEVEL,time[0],
                                   ratesTotal,time,high,low);
   else
   {
      SMC_PineDrawingDelete(config.objectPrefix+"PL_DH");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_DL");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_DH_Label");
      SMC_PineDrawingDelete(config.objectPrefix+"PL_DL_Label");
   }
}

#endif // SMC_DRAWPREVIOUSLEVELS_MQH
