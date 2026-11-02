// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_STRUCTURE_MQH
#define SMC_STRUCTURE_MQH

#include <SMC/SMC_State.mqh>

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

void SMC_DetectStructureCore(const bool internal,const int legSize,int &legState,
                         PivotState &pivotHigh,PivotState &pivotLow,
                         int &trendBias,const int i,const int ratesTotal,
                         const datetime &time[],const double &open[],
                         const double &high[],const double &low[],
                         const double &close[],const bool confluenceFilter,
                         const ENUM_SMC_SIZE labelSize,
                         const PivotState &swingHigh,const PivotState &swingLow,
                         PivotState &trailingTop,PivotState &trailingBottom,
                         datetime &trailingAnchorTime,
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
      events[eventCount].labelSize=labelSize;
      eventCount++;
      pivotHigh.crossed=true;
      trendBias=1;
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
      events[eventCount].labelSize=labelSize;
      eventCount++;
      pivotLow.crossed=true;
      trendBias=-1;
   }
}

void SMC_DetectStructure(const bool internal,const int legSize,
                         const int i,const int ratesTotal,
                         const datetime &time[],const double &open[],
                         const double &high[],const double &low[],
                         const double &close[],const bool confluenceFilter,
                         const ENUM_SMC_SIZE labelSize,SMC_State &state,
                         StructureEvent &events[],int &eventCount)
{
   if(internal)
   {
      SMC_DetectStructureCore(true,legSize,state.InternalLeg,
                              state.InternalHigh,state.InternalLow,
                              state.InternalBias,i,ratesTotal,time,open,high,low,
                              close,confluenceFilter,labelSize,state.SwingHigh,
                              state.SwingLow,state.TrailingTop,
                              state.TrailingBottom,state.TrailingAnchorTime,
                              events,eventCount);
      return;
   }

   SMC_DetectStructureCore(false,legSize,state.SwingLeg,state.SwingHigh,
                           state.SwingLow,state.SwingBias,i,ratesTotal,time,
                           open,high,low,close,confluenceFilter,labelSize,
                           state.SwingHigh,state.SwingLow,state.TrailingTop,
                           state.TrailingBottom,state.TrailingAnchorTime,
                           events,eventCount);
}

#endif // SMC_STRUCTURE_MQH
