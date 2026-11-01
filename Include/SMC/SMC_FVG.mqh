// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_FVG_MQH
#define SMC_FVG_MQH

#include <SMC/SMC_Types.mqh>
#include <SMC/SMC_State.mqh>

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
                            SMC_State &state)
{
   int copied=ArraySize(bars);
   if(copied<3)
      return false;
   state.CurrentFVGThreshold=SMC_CalculateFVGThreshold(bars,point);
   return true;
}

bool SMC_AnalyzeHistoricalFVG(const MqlRates &bars[],const bool autoThreshold,
                              const int extend,const int periodSeconds,
                              const double point,SMC_State &state)
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
   state.CurrentFVGThreshold=thresholds[0];
   if(ArrayResize(state.FairValueGaps,0)!=0)
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
                                 bars[i+2].high,state.FairValueGaps))
            return false;
         drawn++;
      }
      if(bearish && drawn<100)
      {
         double middle=(bars[i].high+bars[i+2].low)*0.5;
         if(!SMC_AddFairValueGap(bars[i+1].time,-1,bars[i+2].low,bars[i].high,
                                 bars[i+1].time,right,bars[i].high,middle,middle,
                                 bars[i+2].low,state.FairValueGaps))
            return false;
         drawn++;
      }
   }
   return true;
}

bool SMC_UpdateFairValueGaps(const MqlRates &bars[],const datetime chartBarTime,
                             const int chartPeriodSeconds,const int extend,
                             const bool autoThreshold,const double point,
                             SMC_State &state,
                             FairValueGapState &removed[],int &removedCount)
{
   removedCount=0;
   if(ArraySize(bars)<4)
      return false;
   int maxRemoved=ArraySize(state.FairValueGaps);
   if(ArrayResize(removed,maxRemoved)!=maxRemoved)
   {
      PrintFormat("SMC: unable to allocate FVG update results (error=%d).",
                  GetLastError());
      return false;
   }

   for(int i=ArraySize(state.FairValueGaps)-1;i>=0;i--)
   {
      bool mitigated=
         (state.FairValueGaps[i].bias>0 &&
          bars[0].low<state.FairValueGaps[i].bottom) ||
         (state.FairValueGaps[i].bias<0 &&
          bars[0].high>state.FairValueGaps[i].top);
      if(!mitigated)
         continue;
      removed[removedCount]=state.FairValueGaps[i];
      removedCount++;
      for(int j=i;j<ArraySize(state.FairValueGaps)-1;j++)
         state.FairValueGaps[j]=state.FairValueGaps[j+1];
      int newSize=ArraySize(state.FairValueGaps)-1;
      if(ArrayResize(state.FairValueGaps,newSize)!=newSize)
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
                 (!autoThreshold ||
                  signedChange>state.CurrentFVGThreshold));
   bool bearish=(bars[1].high<bars[3].low &&
                 bars[2].close<bars[3].low &&
                 (!autoThreshold ||
                  -signedChange>state.CurrentFVGThreshold));
   int periodSeconds=(chartPeriodSeconds>0 ? chartPeriodSeconds : 60);
   datetime right=bars[1].time+extend*periodSeconds;
   if(bullish &&
      !SMC_HasFairValueGap(bars[2].time,1,state.FairValueGaps))
   {
      double middle=(bars[1].low+bars[3].high)*0.5;
      if(!SMC_AddFairValueGap(bars[2].time,1,bars[3].high,bars[1].low,
                              bars[2].time,right,bars[1].low,middle,middle,
                              bars[3].high,state.FairValueGaps))
      {
         Print("SMC: unable to add bullish fair value gap.");
         return false;
      }
   }
   if(bearish &&
      !SMC_HasFairValueGap(bars[2].time,-1,state.FairValueGaps))
   {
      double middle=(bars[1].high+bars[3].low)*0.5;
      if(!SMC_AddFairValueGap(bars[2].time,-1,bars[3].low,bars[1].high,
                              bars[2].time,right,bars[1].high,middle,middle,
                              bars[3].low,state.FairValueGaps))
      {
         Print("SMC: unable to add bearish fair value gap.");
         return false;
      }
   }
   return true;
}

#endif // SMC_FVG_MQH
