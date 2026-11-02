// Indicator adapters for chart-timeframe FVG analysis and rendering.
#ifndef SMC_INDICATORFVG_MQH
#define SMC_INDICATORFVG_MQH

void DrawActiveFairValueGaps(const MqlRates &bars[])
{
   if(!ShowFairValueGaps || ArraySize(bars)==0)
      return;
   int gapCount=ArraySize(State.FairValueGaps);
   bool selected[];
   if(ArrayResize(selected,gapCount)!=gapCount)
   {
      PrintFormat("SMC: unable to allocate FVG display selection (error=%d).",
                  GetLastError());
      return;
   }
   for(int i=0;i<gapCount;i++)
      selected[i]=false;

   int displayCount=MathMin(MaxFairValueGapsToShow,gapCount);
   for(int rank=0;rank<displayCount;rank++)
   {
      int newest=-1;
      for(int i=0;i<gapCount;i++)
      {
         if(selected[i])
            continue;
         if(newest<0 ||
            State.FairValueGaps[i].time>State.FairValueGaps[newest].time)
            newest=i;
      }
      if(newest>=0)
         selected[newest]=true;
   }

   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0)
      periodSeconds=60;
   datetime right=bars[0].time+FairValueGapExtend*periodSeconds;
   SMC_DeleteObjectsWithPrefix(DrawConfig.objectPrefix+"FVG_");
   for(int rank=0;rank<displayCount;rank++)
   {
      int oldest=-1;
      for(int i=0;i<gapCount;i++)
      {
         if(!selected[i])
            continue;
         if(oldest<0 ||
            State.FairValueGaps[i].time<State.FairValueGaps[oldest].time)
            oldest=i;
      }
      if(oldest<0)
         break;
      selected[oldest]=false;
      FairValueGapState gap=State.FairValueGaps[oldest];
      gap.right=right;
      color gapColor=(gap.bias>0 ? SMC_COLOR_FVG_BULLISH :
                                   SMC_COLOR_FVG_BEARISH);
      SMC_DrawFairValueGap(DrawConfig,gap,gapColor);
   }
}

void UpdateFairValueGapsOnTick(const datetime chartBarTime,
                               const double currentHigh,
                               const double currentLow)
{
   if(!ShowFairValueGaps)
      return;
   if(State.FVGUpdateStateInitialized &&
      State.LastFVGUpdateBarTime==chartBarTime &&
      State.LastFVGUpdateHigh==currentHigh &&
      State.LastFVGUpdateLow==currentLow)
      return;
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(_Symbol,_Period,0,4,bars);
   if(copied<4)
   {
      PrintFormat("SMC: unable to update FVG history for chart timeframe %s (bars=%d, error=%d).",
                  EnumToString(_Period),copied,GetLastError());
      return;
   }
   FairValueGapState removed[];
   int removedCount=0;
   if(!SMC_UpdateFairValueGaps(bars,chartBarTime,PeriodSeconds(_Period),
                               FairValueGapExtend,FairValueGapAutoThreshold,
                               _Point,State,removed,removedCount))
   {
      Print("SMC: failed to update fair value gap analysis.");
      return;
   }
   for(int i=0;i<removedCount;i++)
      SMC_DeleteFairValueGap(DrawConfig,removed[i]);
   DrawActiveFairValueGaps(bars);
   State.LastFVGUpdateBarTime=chartBarTime;
   State.LastFVGUpdateHigh=currentHigh;
   State.LastFVGUpdateLow=currentLow;
   State.FVGUpdateStateInitialized=true;
}

bool RefreshCurrentFVGThreshold()
{
   if(!ShowFairValueGaps)
      return true;
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(_Symbol,_Period,0,MaxBarsToProcess,bars);
   if(copied<3)
   {
      PrintFormat("SMC: unable to refresh FVG threshold for chart timeframe %s (bars=%d, error=%d).",
                  EnumToString(_Period),copied,GetLastError());
      return false;
   }
   return SMC_UpdateFVGThreshold(bars,_Point,State);
}

void DrawFVGs()
{
   if(!ShowFairValueGaps)
      return;
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(_Symbol,_Period,0,MaxBarsToProcess,bars);
   if(copied<3)
   {
      PrintFormat("SMC: unable to load FVG history for chart timeframe %s (bars=%d, error=%d).",
                  EnumToString(_Period),copied,GetLastError());
      return;
   }
   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0)
      periodSeconds=60;
   if(!SMC_AnalyzeHistoricalFVG(bars,FairValueGapAutoThreshold,
                                FairValueGapExtend,periodSeconds,_Point,
                                State))
   {
      Print("SMC: failed to analyze historical fair value gaps.");
      return;
   }
   DrawActiveFairValueGaps(bars);
}

#endif // SMC_INDICATORFVG_MQH
