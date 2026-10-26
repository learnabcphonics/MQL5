// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_ENGINE_MQH
#define SMC_ENGINE_MQH

#include <SMC/SMC_Types.mqh>

void SMC_ShiftPivotIndex(PivotState &pivot)
{
   if(pivot.initialized)
      pivot.index++;
}

void SMC_UpdateTrailingLevels(const bool enabled,const datetime currentTime,
                              const double currentHigh,const double currentLow,
                              PivotState &trailingTop,
                              PivotState &trailingBottom)
{
   if(!enabled)
      return;
   if(trailingTop.initialized && currentHigh>=trailingTop.current)
   {
      trailingTop.current=currentHigh;
      trailingTop.time=currentTime;
      trailingTop.index=0;
   }
   if(trailingBottom.initialized && currentLow<=trailingBottom.current)
   {
      trailingBottom.current=currentLow;
      trailingBottom.time=currentTime;
      trailingBottom.index=0;
   }
}

void SMC_ShiftCalculationIndices(PivotState &swingHigh,PivotState &swingLow,
                                 PivotState &internalHigh, PivotState &internalLow,
                                 PivotState &equalHigh,PivotState &equalLow,
                                 PivotState &trailingTop,PivotState &trailingBottom,
                                 StructureDisplayState &latestStructures[])
{
   SMC_ShiftPivotIndex(swingHigh);
   SMC_ShiftPivotIndex(swingLow);
   SMC_ShiftPivotIndex(internalHigh);
   SMC_ShiftPivotIndex(internalLow);
   SMC_ShiftPivotIndex(equalHigh);
   SMC_ShiftPivotIndex(equalLow);
   SMC_ShiftPivotIndex(trailingTop);
   SMC_ShiftPivotIndex(trailingBottom);
   for(int i=0;i<ArraySize(latestStructures);i++)
      SMC_ShiftPivotIndex(latestStructures[i].pivot);
}

void SMC_UpdateCurrentCalculationValues(const double currentHigh,
                                       const double currentLow,
                                       const double previousClose,
                                       const int ratesTotal,
                                       const ENUM_SMC_FILTER filter,
                                       const double cumulativeRangeClosedSum,
                                       double &parsedHighs[],double &parsedLows[],
                                       double &atrCache[],double &meanRangeCache[],
                                       double &trueRangeCache[])
{
   int count=ArraySize(parsedHighs);
   if(count<2 || ratesTotal<2)
      return;
   double trueRange=MathMax(currentHigh-currentLow,
                     MathMax(MathAbs(currentHigh-previousClose),
                             MathAbs(currentLow-previousClose)));
   trueRangeCache[0]=trueRange;
   meanRangeCache[0]=(cumulativeRangeClosedSum+trueRange)/(ratesTotal-1);
   if(atrCache[1]==DBL_MAX)
   {
      double seedSum=0.0;
      for(int i=1;i<count;i++)
         seedSum+=trueRangeCache[i];
      atrCache[0]=(seedSum+trueRange)/count;
   }
   else
      atrCache[0]=(atrCache[1]*199.0+trueRange)/200.0;

   double volatilityMeasure=(filter==SMC_ATR ? atrCache[0] : meanRangeCache[0]);
   bool volatileBar=(currentHigh-currentLow)>=2.0*volatilityMeasure;
   parsedHighs[0]=(volatileBar ? currentLow : currentHigh);
   parsedLows[0]=(volatileBar ? currentHigh : currentLow);
}

bool SMC_InitializeCalculationCaches(const int ratesTotal,const int count,
                                     const double &high[],const double &low[],
                                     const double &close[],
                                     const ENUM_SMC_FILTER filter,
                                     double &parsedHighs[],double &parsedLows[],
                                     double &atrCache[],double &meanRangeCache[],
                                     double &trueRangeCache[],
                                     double &cumulativeRangeClosedSum)
{
   double cumulativeRange=0.0;
   for(int i=ratesTotal-1;i>=count;i--)
   {
      double previousClose=(i+1<ratesTotal ? close[i+1] : close[i]);
      cumulativeRange+=MathMax(high[i]-low[i],
                        MathMax(MathAbs(high[i]-previousClose),
                                MathAbs(low[i]-previousClose)));
   }
   for(int i=count-1;i>=0;i--)
   {
      double previousClose=(i+1<ratesTotal ? close[i+1] : close[i]);
      double trueRange=MathMax(high[i]-low[i],
                        MathMax(MathAbs(high[i]-previousClose),
                                MathAbs(low[i]-previousClose)));
      trueRangeCache[i]=trueRange;
      cumulativeRange+=trueRange;
      int barIndex=ratesTotal-1-i;
      meanRangeCache[i]=(barIndex>0 ? cumulativeRange/barIndex : DBL_MAX);
      atrCache[i]=DBL_MAX;
   }
   int oldest=count-1;
   int seedIndex=MathMin(oldest,MathMax(0,count-200));
   int seedCount=MathMin(200,count-seedIndex);
   double seedSum=0.0;
   for(int i=seedIndex;i<seedIndex+seedCount;i++)
   {
      double previousClose=(i+1<ratesTotal ? close[i+1] : close[i]);
      seedSum+=MathMax(high[i]-low[i],
                       MathMax(MathAbs(high[i]-previousClose),
                               MathAbs(low[i]-previousClose)));
   }
   atrCache[seedIndex]=(seedCount>0 ? seedSum/seedCount :
                                      trueRangeCache[seedIndex]);
   for(int i=seedIndex-1;i>=0;i--)
      atrCache[i]=(atrCache[i+1]*199.0+trueRangeCache[i])/200.0;
   for(int i=oldest;i>=0;i--)
   {
      double volatilityMeasure=(filter==SMC_ATR ? atrCache[i] : meanRangeCache[i]);
      bool volatileBar=(high[i]-low[i])>=2.0*volatilityMeasure;
      parsedHighs[i]=(volatileBar ? low[i] : high[i]);
      parsedLows[i]=(volatileBar ? high[i] : low[i]);
   }
   cumulativeRangeClosedSum=cumulativeRange-trueRangeCache[0];
   return true;
}

bool SMC_AdvanceCalculationCaches(const int ratesTotal,const int lastRatesTotal,
                                 const int maxBars,const double &high[],
                                 const double &low[],const double &close[],
                                 const ENUM_SMC_FILTER filter,
                                 double &cumulativeRangeClosedSum,
                                 double &parsedHighs[],double &parsedLows[],
                                 double &atrCache[],double &meanRangeCache[],
                                 double &trueRangeCache[],
                                 PivotState &swingHigh,PivotState &swingLow,
                                 PivotState &internalHigh,PivotState &internalLow,
                                 PivotState &equalHigh,PivotState &equalLow,
                                 PivotState &trailingTop,PivotState &trailingBottom,
                                 StructureDisplayState &latestStructures[])
{
   int oldCount=ArraySize(parsedHighs);
   int newCount=MathMin(ratesTotal,maxBars);
   if(oldCount<2 || ArraySize(parsedLows)!=oldCount ||
      ArraySize(atrCache)!=oldCount || ArraySize(meanRangeCache)!=oldCount ||
      ArraySize(trueRangeCache)!=oldCount ||
      oldCount!=MathMin(lastRatesTotal,maxBars) ||
      ratesTotal<lastRatesTotal || ratesTotal>lastRatesTotal+1)
      return false;
   if(ArrayResize(parsedHighs,newCount)!=newCount ||
      ArrayResize(parsedLows,newCount)!=newCount ||
      ArrayResize(atrCache,newCount)!=newCount ||
      ArrayResize(meanRangeCache,newCount)!=newCount ||
      ArrayResize(trueRangeCache,newCount)!=newCount)
   {
      PrintFormat("SMC: unable to advance calculation caches (error=%d).",
                  GetLastError());
      return false;
   }

   double closedBarTrueRange=MathMax(high[1]-low[1],
                              MathMax(MathAbs(high[1]-close[2]),
                                      MathAbs(low[1]-close[2])));
   cumulativeRangeClosedSum+=closedBarTrueRange;
   for(int i=newCount-1;i>=1;i--)
   {
      int source=i-1;
      if(source<oldCount)
      {
         parsedHighs[i]=parsedHighs[source];
         parsedLows[i]=parsedLows[source];
         atrCache[i]=atrCache[source];
         meanRangeCache[i]=meanRangeCache[source];
         trueRangeCache[i]=trueRangeCache[source];
      }
   }
   ArraySetAsSeries(parsedHighs,true);
   ArraySetAsSeries(parsedLows,true);
   ArraySetAsSeries(atrCache,true);
   ArraySetAsSeries(meanRangeCache,true);
   ArraySetAsSeries(trueRangeCache,true);
   trueRangeCache[1]=closedBarTrueRange;
   meanRangeCache[1]=(ratesTotal>2 ?
                      cumulativeRangeClosedSum/(ratesTotal-2) : DBL_MAX);
   if(atrCache[2]==DBL_MAX)
   {
      double seedSum=closedBarTrueRange;
      for(int i=2;i<newCount;i++)
         seedSum+=trueRangeCache[i];
      atrCache[1]=seedSum/newCount;
   }
   else
      atrCache[1]=(atrCache[2]*199.0+closedBarTrueRange)/200.0;
   double closedVolatility=(filter==SMC_ATR ? atrCache[1] : meanRangeCache[1]);
   bool closedVolatile=(high[1]-low[1])>=2.0*closedVolatility;
   parsedHighs[1]=(closedVolatile ? low[1] : high[1]);
   parsedLows[1]=(closedVolatile ? high[1] : low[1]);
   double previousClose=(ratesTotal>1 ? close[1] : close[0]);
   SMC_UpdateCurrentCalculationValues(high[0],low[0],previousClose,ratesTotal,
                                      filter,cumulativeRangeClosedSum,
                                      parsedHighs,parsedLows,atrCache,
                                      meanRangeCache,trueRangeCache);
   SMC_ShiftCalculationIndices(swingHigh,swingLow,internalHigh,internalLow,
                               equalHigh,equalLow,trailingTop,trailingBottom,
                               latestStructures);
   return true;
}

bool SMC_RemoveMitigatedOrderBlocks(const double high,const double low,
                                    const double close,const datetime barTime,
                                    const ENUM_SMC_MITIGATION mitigation,
                                    OrderBlockState &orderBlocks[],
                                    OrderBlockState &removed[],
                                    int &removedCount)
{
   removedCount=0;
   if(ArrayResize(removed,ArraySize(orderBlocks))!=ArraySize(orderBlocks))
   {
      PrintFormat("SMC: unable to allocate mitigated order block results (error=%d).",
                  GetLastError());
      return false;
   }
   double bearishSource=(mitigation==SMC_CLOSE ? close : high);
   double bullishSource=(mitigation==SMC_CLOSE ? close : low);
   for(int i=ArraySize(orderBlocks)-1;i>=0;i--)
   {
      if(orderBlocks[i].created==barTime)
         continue;
      bool mitigated=(orderBlocks[i].bias<0 &&
                      bearishSource>orderBlocks[i].high) ||
                     (orderBlocks[i].bias>0 &&
                      bullishSource<orderBlocks[i].low);
      if(!mitigated)
         continue;
      removed[removedCount]=orderBlocks[i];
      removedCount++;
      for(int j=i;j<ArraySize(orderBlocks)-1;j++)
         orderBlocks[j]=orderBlocks[j+1];
      int newSize=ArraySize(orderBlocks)-1;
      if(ArrayResize(orderBlocks,newSize)!=newSize)
      {
         PrintFormat("SMC: unable to remove mitigated order block (error=%d).",
                     GetLastError());
         return false;
      }
   }
   return true;
}

void SMC_UpdatePivot(PivotState &pivot,const double level,const datetime pivotTime,
                     const int pivotIndex)
{
   pivot.previousInitialized=pivot.initialized;
   pivot.previous=pivot.current;
   pivot.current=level;
   pivot.crossed=false;
   pivot.time=pivotTime;
   pivot.index=pivotIndex;
   pivot.initialized=true;
}

void SMC_StoreOrderBlock(const PivotState &pivot,const bool internal,const int bias,
                         const datetime &time[],const double &parsedHighs[],
                         const double &parsedLows[],const int ratesTotal,
                         const int currentIndex,const bool enabled,
                         OrderBlockState &orderBlocks[])
{
   if(!enabled)
      return;
   int oldest=currentIndex+1;
   int newest=pivot.index;
   if(oldest<0 || newest<oldest || newest>=ratesTotal ||
      newest>=ArraySize(parsedHighs) || newest>=ArraySize(parsedLows))
      return;
   double extreme=(bias<0 ? -DBL_MAX : DBL_MAX);
   int selected=newest;
   for(int i=newest;i>=oldest;i--)
   {
      double value=(bias<0 ? parsedHighs[i] : parsedLows[i]);
      if((bias<0 && value>extreme) || (bias>0 && value<extreme))
      {
         extreme=value;
         selected=i;
      }
   }
   OrderBlockState block;
   block.high=MathMax(parsedHighs[selected],parsedLows[selected]);
   block.low=MathMin(parsedHighs[selected],parsedLows[selected]);
   block.time=time[selected];
   block.created=time[currentIndex];
   block.bias=bias;
   block.internal=internal;
   int count=ArraySize(orderBlocks);
   if(ArrayResize(orderBlocks,count+1)!=count+1)
   {
      PrintFormat("SMC: unable to store order block (error=%d).",GetLastError());
      return;
   }
   orderBlocks[count]=block;
}

void SMC_DetectStructure(const bool internal,const int legSize,int &legState,
                         PivotState &pivotHigh,PivotState &pivotLow,
                         int &trendBias,const int i,const int ratesTotal,
                         const datetime &time[],const double &open[],
                         const double &high[],const double &low[],
                         const double &close[],const bool confluenceFilter,
                         const ENUM_SMC_SIZE labelSize,
                         const PivotState &swingHigh,const PivotState &swingLow,
                         PivotState &trailingTop,PivotState &trailingBottom,
                         datetime &trailingAnchorTime,
                         const double &parsedHighs[],const double &parsedLows[],
                         const bool storeOrderBlocks,
                         OrderBlockState &orderBlocks[],
                         StructureEvent &events[],int &eventCount)
{
   eventCount=0;
   int candidate=i+legSize;
   if(candidate>=ratesTotal)
      return;
   double priorHigh=-DBL_MAX,priorLow=DBL_MAX;
   for(int j=i;j<candidate;j++)
   {
      if(high[j]>priorHigh) priorHigh=high[j];
      if(low[j]<priorLow) priorLow=low[j];
   }
   bool newHigh=high[candidate]>priorHigh;
   bool newLow=low[candidate]<priorLow;
   int nextLeg=legState;
   if(newHigh) nextLeg=0;
   else if(newLow) nextLeg=1;
   if(nextLeg!=legState)
   {
      bool pivotLowFound=(nextLeg-legState)==1;
      if(pivotLowFound)
      {
         SMC_UpdatePivot(pivotLow,low[candidate],time[candidate],candidate);
         if(!internal)
         {
            trailingBottom=pivotLow;
            trailingAnchorTime=pivotLow.time;
         }
      }
      else
      {
         SMC_UpdatePivot(pivotHigh,high[candidate],time[candidate],candidate);
         if(!internal)
         {
            trailingTop=pivotHigh;
            trailingAnchorTime=pivotHigh.time;
         }
      }
      legState=nextLeg;
   }

   bool bullish=(pivotHigh.initialized &&
                 close[i]>pivotHigh.current && close[i+1]<=pivotHigh.current);
   bool bearish=(pivotLow.initialized &&
                 close[i]<pivotLow.current && close[i+1]>=pivotLow.current);
   bool bullishConfluence=true,bearishConfluence=true;
   if(internal && confluenceFilter)
   {
      double upperWick=high[i]-MathMax(close[i],open[i]);
      double lowerBody=MathMin(close[i],open[i])-low[i];
      bullishConfluence=upperWick>lowerBody;
      bearishConfluence=upperWick<lowerBody;
   }
   if(bullish && !pivotHigh.crossed && bullishConfluence &&
      (!internal || !swingHigh.initialized ||
       pivotHigh.current!=swingHigh.current))
   {
      events[eventCount].pivot=pivotHigh;
      events[eventCount].time=time[i];
      events[eventCount].tag=(trendBias<0 ? "CHoCH" : "BOS");
      events[eventCount].internal=internal;
      events[eventCount].bullish=true;
      events[eventCount].liveBar=(i==1);
      events[eventCount].labelSize=labelSize;
      eventCount++;
      pivotHigh.crossed=true;
      trendBias=1;
      SMC_StoreOrderBlock(pivotHigh,internal,1,time,parsedHighs,parsedLows,
                          ratesTotal,i,storeOrderBlocks,orderBlocks);
   }
   if(bearish && !pivotLow.crossed && bearishConfluence &&
      (!internal || !swingLow.initialized ||
       pivotLow.current!=swingLow.current))
   {
      events[eventCount].pivot=pivotLow;
      events[eventCount].time=time[i];
      events[eventCount].tag=(trendBias>0 ? "CHoCH" : "BOS");
      events[eventCount].internal=internal;
      events[eventCount].bullish=false;
      events[eventCount].liveBar=(i==1);
      events[eventCount].labelSize=labelSize;
      eventCount++;
      pivotLow.crossed=true;
      trendBias=-1;
      SMC_StoreOrderBlock(pivotLow,internal,-1,time,parsedHighs,parsedLows,
                          ratesTotal,i,storeOrderBlocks,orderBlocks);
   }
}

void SMC_DetectEqualHighLow(const int size,int &legState,
                            PivotState &equalHigh,PivotState &equalLow,
                            const int i,const int ratesTotal,
                            const datetime &time[],const double &high[],
                            const double &low[],const double &atr[],
                            const double threshold,EqualLevelEvent &event)
{
   ZeroMemory(event);
   int candidate=i+size;
   if(candidate>=ratesTotal)
      return;
   double priorHigh=-DBL_MAX,priorLow=DBL_MAX;
   for(int j=i;j<candidate;j++)
   {
      priorHigh=MathMax(priorHigh,high[j]);
      priorLow=MathMin(priorLow,low[j]);
   }
   int nextLeg=legState;
   if(high[candidate]>priorHigh)
      nextLeg=0;
   else if(low[candidate]<priorLow)
      nextLeg=1;
   if(nextLeg==legState)
      return;

   bool pivotLow=(nextLeg-legState)==1;
   PivotState previousPivot=(pivotLow ? equalLow : equalHigh);
   double currentLevel=(pivotLow ? low[candidate] : high[candidate]);
   bool atrOk=(i<ArraySize(atr) && MathIsValidNumber(atr[i]) &&
               atr[i]<DBL_MAX);
   if(atrOk && previousPivot.initialized &&
      MathAbs(previousPivot.current-currentLevel)<threshold*atr[i])
   {
      event.valid=true;
      event.high=!pivotLow;
      event.firstTime=previousPivot.time;
      event.secondTime=time[candidate];
      event.labelTime=time[(previousPivot.index+candidate)/2];
      event.firstPrice=previousPivot.current;
      event.secondPrice=currentLevel;
      event.liveBar=(i==1);
   }

   if(pivotLow)
      SMC_UpdatePivot(equalLow,currentLevel,time[candidate],candidate);
   else
      SMC_UpdatePivot(equalHigh,currentLevel,time[candidate],candidate);
   legState=nextLeg;
}

bool SMC_HasFairValueGap(const datetime gapTime,const int bias,
                         const FairValueGapState &gaps[])
{
   for(int i=0;i<ArraySize(gaps);i++)
      if(gaps[i].time==gapTime && gaps[i].bias==bias)
         return true;
   return false;
}

bool SMC_AddFairValueGap(const datetime gapTime,const int bias,
                         const double mitigationLevel,const double otherLevel,
                         const datetime left,const datetime right,
                         const double firstTop,const double firstBottom,
                         const double secondTop,const double secondBottom,
                         FairValueGapState &gaps[])
{
   if(SMC_HasFairValueGap(gapTime,bias,gaps))
      return false;
   int count=ArraySize(gaps);
   if(ArrayResize(gaps,count+1)!=count+1)
   {
      PrintFormat("SMC: unable to store FVG state (error=%d).",GetLastError());
      return false;
   }
   gaps[count].top=(bias>0 ? otherLevel : mitigationLevel);
   gaps[count].bottom=(bias>0 ? mitigationLevel : otherLevel);
   gaps[count].time=gapTime;
   gaps[count].bias=bias;
   gaps[count].left=left;
   gaps[count].right=right;
   gaps[count].firstTop=firstTop;
   gaps[count].firstBottom=firstBottom;
   gaps[count].secondTop=secondTop;
   gaps[count].secondBottom=secondBottom;
   return true;
}

double SMC_CalculateFVGThreshold(const MqlRates &bars[],const double point)
{
   int copied=ArraySize(bars);
   double cumulativeDelta=0.0;
   int sampleCount=0;
   for(int i=copied-2;i>=1;i--)
   {
      double change=(bars[i].close-bars[i].open)/
                    MathMax(MathAbs(bars[i].open)*100.0,point);
      cumulativeDelta+=MathAbs(change);
      sampleCount++;
   }
   return (sampleCount>0 ? cumulativeDelta/sampleCount*2.0 : 0.0);
}

bool SMC_UpdateFVGThreshold(const MqlRates &bars[],const double point,
                            double &threshold)
{
   int copied=ArraySize(bars);
   if(copied<3)
      return false;
   threshold=SMC_CalculateFVGThreshold(bars,point);
   return true;
}

bool SMC_AnalyzeHistoricalFVG(const MqlRates &bars[],const bool autoThreshold,
                              const int extend,const int periodSeconds,
                              const double point,
                              double &currentThreshold,
                              FairValueGapState &gaps[])
{
   int copied=ArraySize(bars);
   if(copied<3)
      return false;
   double thresholds[];
   if(ArrayResize(thresholds,copied)!=copied)
   {
      PrintFormat("SMC: unable to allocate FVG thresholds (error=%d).",GetLastError());
      return false;
   }
   ArraySetAsSeries(thresholds,true);
   double cumulativeDelta=0.0;
   int sampleCount=0;
   for(int i=copied-3;i>=0;i--)
   {
      double change=(bars[i+1].close-bars[i+1].open)/
                    MathMax(MathAbs(bars[i+1].open)*100.0,point);
      cumulativeDelta+=MathAbs(change);
      sampleCount++;
      thresholds[i]=cumulativeDelta/sampleCount*2.0;
   }
   currentThreshold=thresholds[0];
   if(ArrayResize(gaps,0)!=0)
   {
      PrintFormat("SMC: unable to reset FVG state (error=%d).",GetLastError());
      return false;
   }

   int drawn=0;
   for(int i=0;i<copied-2 && drawn<100;i++)
   {
      double signedChange=(bars[i+1].close-bars[i+1].open)/
                          MathMax(MathAbs(bars[i+1].open)*100.0,point);
      datetime right=bars[i].time+extend*periodSeconds;
      bool bullish=(bars[i].low>bars[i+2].high &&
                    bars[i+1].close>bars[i+2].high &&
                    (!autoThreshold || signedChange>thresholds[i]));
      bool bearish=(bars[i].high<bars[i+2].low &&
                    bars[i+1].close<bars[i+2].low &&
                    (!autoThreshold || -signedChange>thresholds[i]));
      if(i==0)
      {
         bullish=false;
         bearish=false;
      }
      for(int newer=i-1;newer>=0 && (bullish || bearish);--newer)
      {
         if(bullish && bars[newer].low<bars[i+2].high) bullish=false;
         if(bearish && bars[newer].high>bars[i+2].low) bearish=false;
      }
      if(bullish)
      {
         double middle=(bars[i].low+bars[i+2].high)*0.5;
         if(!SMC_AddFairValueGap(bars[i+1].time,1,bars[i+2].high,bars[i].low,
                                 bars[i+1].time,right,bars[i].low,middle,middle,
                                 bars[i+2].high,gaps))
            return false;
         drawn++;
      }
      if(bearish && drawn<100)
      {
         double middle=(bars[i].high+bars[i+2].low)*0.5;
         if(!SMC_AddFairValueGap(bars[i+1].time,-1,bars[i+2].low,bars[i].high,
                                 bars[i+1].time,right,bars[i].high,middle,middle,
                                 bars[i+2].low,gaps))
            return false;
         drawn++;
      }
   }
   return true;
}

bool SMC_UpdateFairValueGaps(const MqlRates &bars[],const datetime chartBarTime,
                             const int chartPeriodSeconds,const int extend,
                             const double threshold,const bool autoThreshold,
                             const double point,
                             FairValueGapState &gaps[],
                             FairValueGapState &removed[],int &removedCount,
                             FairValueGapState &added[],int &addedCount)
{
   removedCount=0;
   addedCount=0;
   if(ArraySize(bars)<4)
      return false;
   int maxRemoved=ArraySize(gaps);
   if(ArrayResize(removed,maxRemoved)!=maxRemoved ||
      ArrayResize(added,2)!=2)
   {
      PrintFormat("SMC: unable to allocate FVG update results (error=%d).",
                  GetLastError());
      return false;
   }

   for(int i=ArraySize(gaps)-1;i>=0;i--)
   {
      bool mitigated=(gaps[i].bias>0 && bars[0].low<gaps[i].bottom) ||
                     (gaps[i].bias<0 && bars[0].high>gaps[i].top);
      if(!mitigated)
         continue;
      removed[removedCount]=gaps[i];
      removedCount++;
      for(int j=i;j<ArraySize(gaps)-1;j++)
         gaps[j]=gaps[j+1];
      int newSize=ArraySize(gaps)-1;
      if(ArrayResize(gaps,newSize)!=newSize)
      {
         PrintFormat("SMC: unable to remove mitigated FVG (error=%d).",GetLastError());
         return false;
      }
   }
   int safeChartPeriodSeconds=(chartPeriodSeconds>0 ? chartPeriodSeconds : 60);
   if(bars[0].time<chartBarTime ||
      bars[0].time>=chartBarTime+safeChartPeriodSeconds)
      return true;
   double signedChange=(bars[2].close-bars[2].open)/
                       MathMax(MathAbs(bars[2].open)*100.0,point);
   bool bullish=(bars[1].low>bars[3].high &&
                 bars[2].close>bars[3].high &&
                 (!autoThreshold || signedChange>threshold));
   bool bearish=(bars[1].high<bars[3].low &&
                 bars[2].close<bars[3].low &&
                 (!autoThreshold || -signedChange>threshold));
   int periodSeconds=(chartPeriodSeconds>0 ? chartPeriodSeconds : 60);
   datetime right=bars[1].time+extend*periodSeconds;
   if(bullish && !SMC_HasFairValueGap(bars[2].time,1,gaps))
   {
      double middle=(bars[1].low+bars[3].high)*0.5;
      if(SMC_AddFairValueGap(bars[2].time,1,bars[3].high,bars[1].low,
                             bars[2].time,right,bars[1].low,middle,middle,
                             bars[3].high,gaps))
      {
         added[addedCount]=gaps[ArraySize(gaps)-1];
         addedCount++;
      }
      else
      {
         Print("SMC: unable to add bullish fair value gap.");
         return false;
      }
   }
   if(bearish && !SMC_HasFairValueGap(bars[2].time,-1,gaps))
   {
      double middle=(bars[1].high+bars[3].low)*0.5;
      if(SMC_AddFairValueGap(bars[2].time,-1,bars[3].low,bars[1].high,
                             bars[2].time,right,bars[1].high,middle,middle,
                             bars[3].low,gaps))
      {
         added[addedCount]=gaps[ArraySize(gaps)-1];
         addedCount++;
      }
      else
      {
         Print("SMC: unable to add bearish fair value gap.");
         return false;
      }
   }
   return true;
}

#endif // SMC_ENGINE_MQH
