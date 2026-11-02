// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWSWINGLEVELS_MQH
#define SMC_DRAWSWINGLEVELS_MQH

#include <SMC/SMC_DrawHelpers.mqh>

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
                   time[candidate],high[candidate],
                   (!swingHigh.previousInitialized ? "H" :
                    swingHigh.current>swingHigh.previous ? "HH" : "LH"),
                   SMC_COLOR_BEARISH,ANCHOR_LOWER);
   if(drawLow)
      SMC_DrawText(config.objectPrefix+"SW_Low_"+
                   (config.mode==SMC_HISTORICAL ?
                    IntegerToString((int)time[candidate]) : "Current"),
                   time[candidate],low[candidate],
                   (!swingLow.previousInitialized ? "L" :
                    swingLow.current<swingLow.previous ? "LL" : "HL"),
                   SMC_COLOR_BULLISH,ANCHOR_UPPER);
}

void SMC_DrawTrailingLevels(const SMC_DrawConfig &config,
                            const PivotState &trailingTop,
                            const PivotState &trailingBottom,
                            const int swingBias,const datetime lastTime,
                            const int periodSeconds)
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
   if(!trailingTop.initialized || !trailingBottom.initialized)
      return;
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
   if(!trailingTop.initialized || !trailingBottom.initialized)
      return;

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

#endif // SMC_DRAWSWINGLEVELS_MQH
