// Canonical calculation layer for Smart Money Concepts.
#ifndef SMC_CALCULATION_MQH
#define SMC_CALCULATION_MQH

#include <SMC/SMC_State.mqh>

void SMC_ShiftPivotIndex(PivotState &pivot)
{
   if(pivot.initialized)
      pivot.index++;
}

void SMC_UpdateTrailingLevels(const bool enabled,const datetime currentTime,
                              const double currentHigh,const double currentLow,
                              SMC_State &state)
{
   if(!enabled)
      return;
   if(state.TrailingTop.initialized &&
      currentHigh>=state.TrailingTop.current)
   {
      state.TrailingTop.current=currentHigh;
      state.TrailingTop.time=currentTime;
      state.TrailingTop.index=0;
   }
   if(state.TrailingBottom.initialized &&
      currentLow<=state.TrailingBottom.current)
   {
      state.TrailingBottom.current=currentLow;
      state.TrailingBottom.time=currentTime;
      state.TrailingBottom.index=0;
   }
}

void SMC_ShiftCalculationIndices(SMC_State &state)
{
   SMC_ShiftPivotIndex(state.SwingHigh);
   SMC_ShiftPivotIndex(state.SwingLow);
   SMC_ShiftPivotIndex(state.InternalHigh);
   SMC_ShiftPivotIndex(state.InternalLow);
   SMC_ShiftPivotIndex(state.EqualHigh);
   SMC_ShiftPivotIndex(state.EqualLow);
   SMC_ShiftPivotIndex(state.TrailingTop);
   SMC_ShiftPivotIndex(state.TrailingBottom);
   for(int i=0;i<ArraySize(state.LatestStructures);i++)
      SMC_ShiftPivotIndex(state.LatestStructures[i].pivot);
}

void SMC_UpdateCurrentCalculationValues(const double currentHigh,
                                       const double currentLow,
                                       const double previousClose,
                                       const int ratesTotal,
                                       const ENUM_SMC_FILTER filter,
                                       SMC_State &state)
{
   int count=ArraySize(state.ParsedHighs);
   if(count<2 || ratesTotal<2)
      return;
   double trueRange=MathMax(currentHigh-currentLow,
                     MathMax(MathAbs(currentHigh-previousClose),
                             MathAbs(currentLow-previousClose)));
   state.TrueRangeCache[0]=trueRange;
   state.MeanRangeCache[0]=(state.CumulativeRangeClosedSum+trueRange)/
                           (ratesTotal-1);
   if(state.AtrCache[1]==DBL_MAX)
   {
      double seedSum=0.0;
      for(int i=1;i<count;i++)
         seedSum+=state.TrueRangeCache[i];
      state.AtrCache[0]=(seedSum+trueRange)/count;
   }
   else
      state.AtrCache[0]=(state.AtrCache[1]*199.0+trueRange)/200.0;

   double volatilityMeasure=(filter==SMC_ATR ? state.AtrCache[0] :
                                                state.MeanRangeCache[0]);
   bool volatileBar=(currentHigh-currentLow)>=2.0*volatilityMeasure;
   state.ParsedHighs[0]=(volatileBar ? currentLow : currentHigh);
   state.ParsedLows[0]=(volatileBar ? currentHigh : currentLow);
}

bool SMC_InitializeCalculationCaches(const int ratesTotal,const int count,
                                     const double &high[],const double &low[],
                                     const double &close[],
                                     const ENUM_SMC_FILTER filter,
                                     SMC_State &state)
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
      state.TrueRangeCache[i]=trueRange;
      cumulativeRange+=trueRange;
      int barIndex=ratesTotal-1-i;
      state.MeanRangeCache[i]=(barIndex>0 ? cumulativeRange/barIndex : DBL_MAX);
      state.AtrCache[i]=DBL_MAX;
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
   state.AtrCache[seedIndex]=(seedCount>0 ? seedSum/seedCount :
                                            state.TrueRangeCache[seedIndex]);
   for(int i=seedIndex-1;i>=0;i--)
      state.AtrCache[i]=(state.AtrCache[i+1]*199.0+
                         state.TrueRangeCache[i])/200.0;
   for(int i=oldest;i>=0;i--)
   {
      double volatilityMeasure=(filter==SMC_ATR ? state.AtrCache[i] :
                                                   state.MeanRangeCache[i]);
      bool volatileBar=(high[i]-low[i])>=2.0*volatilityMeasure;
      state.ParsedHighs[i]=(volatileBar ? low[i] : high[i]);
      state.ParsedLows[i]=(volatileBar ? high[i] : low[i]);
   }
   state.CumulativeRangeClosedSum=cumulativeRange-state.TrueRangeCache[0];
   return true;
}

bool SMC_AdvanceCalculationCaches(const int ratesTotal,
                                 const int maxBars,const double &high[],
                                 const double &low[],const double &close[],
                                 const ENUM_SMC_FILTER filter,
                                 SMC_State &state)
{
   int oldCount=ArraySize(state.ParsedHighs);
   int newCount=MathMin(ratesTotal,maxBars);
   if(oldCount<2 || ArraySize(state.ParsedLows)!=oldCount ||
      ArraySize(state.AtrCache)!=oldCount ||
      ArraySize(state.MeanRangeCache)!=oldCount ||
      ArraySize(state.TrueRangeCache)!=oldCount ||
      oldCount!=MathMin(state.LastRatesTotal,maxBars) ||
      ratesTotal<state.LastRatesTotal ||
      ratesTotal>state.LastRatesTotal+1)
      return false;
   if(ArrayResize(state.ParsedHighs,newCount)!=newCount ||
      ArrayResize(state.ParsedLows,newCount)!=newCount ||
      ArrayResize(state.AtrCache,newCount)!=newCount ||
      ArrayResize(state.MeanRangeCache,newCount)!=newCount ||
      ArrayResize(state.TrueRangeCache,newCount)!=newCount)
   {
      PrintFormat("SMC: unable to advance calculation caches (error=%d).",
                  GetLastError());
      return false;
   }

   double closedBarTrueRange=MathMax(high[1]-low[1],
                              MathMax(MathAbs(high[1]-close[2]),
                                      MathAbs(low[1]-close[2])));
   state.CumulativeRangeClosedSum+=closedBarTrueRange;
   for(int i=newCount-1;i>=1;i--)
   {
      int source=i-1;
      if(source<oldCount)
      {
         state.ParsedHighs[i]=state.ParsedHighs[source];
         state.ParsedLows[i]=state.ParsedLows[source];
         state.AtrCache[i]=state.AtrCache[source];
         state.MeanRangeCache[i]=state.MeanRangeCache[source];
         state.TrueRangeCache[i]=state.TrueRangeCache[source];
      }
   }
   ArraySetAsSeries(state.ParsedHighs,true);
   ArraySetAsSeries(state.ParsedLows,true);
   ArraySetAsSeries(state.AtrCache,true);
   ArraySetAsSeries(state.MeanRangeCache,true);
   ArraySetAsSeries(state.TrueRangeCache,true);
   state.TrueRangeCache[1]=closedBarTrueRange;
   state.MeanRangeCache[1]=(ratesTotal>2 ?
                            state.CumulativeRangeClosedSum/(ratesTotal-2) :
                            DBL_MAX);
   if(state.AtrCache[2]==DBL_MAX)
   {
      double seedSum=closedBarTrueRange;
      for(int i=2;i<newCount;i++)
         seedSum+=state.TrueRangeCache[i];
      state.AtrCache[1]=seedSum/newCount;
   }
   else
      state.AtrCache[1]=(state.AtrCache[2]*199.0+
                         closedBarTrueRange)/200.0;
   double closedVolatility=(filter==SMC_ATR ? state.AtrCache[1] :
                                               state.MeanRangeCache[1]);
   bool closedVolatile=(high[1]-low[1])>=2.0*closedVolatility;
   state.ParsedHighs[1]=(closedVolatile ? low[1] : high[1]);
   state.ParsedLows[1]=(closedVolatile ? high[1] : low[1]);
   double previousClose=(ratesTotal>1 ? close[1] : close[0]);
   SMC_UpdateCurrentCalculationValues(high[0],low[0],previousClose,ratesTotal,
                                      filter,state);
   SMC_ShiftCalculationIndices(state);
   return true;
}

#endif // SMC_CALCULATION_MQH
