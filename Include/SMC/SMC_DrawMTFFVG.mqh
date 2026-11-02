// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWMTFFVG_MQH
#define SMC_DRAWMTFFVG_MQH

#include <SMC/SMC_DrawFVG.mqh>
#include <SMC/SMC_TimeframeSlots.mqh>

void SMC_DrawMTFFairValueGaps(
                           const SMC_DrawConfig &config,
                           const SMC_TimeframeBiasState &timeframeStates[],
                           const bool showFairValueGaps,
                           const int fairValueGapExtend,
                           const int maxFairValueGapsToShow)
{
   for(int i=0;i<ArraySize(timeframeStates);i++)
   {
      string timeframeLabel=
         SMC_TimeframeLabel(timeframeStates[i].timeframe);
      string timeframePrefix=config.objectPrefix+"MTF_"+
                             timeframeLabel+"_";
      if(!timeframeStates[i].enabled)
      {
         if(!SMC_HasEnabledTimeframe(timeframeStates,
                                     timeframeStates[i].timeframe))
            SMC_DeleteObjectsWithPrefix(timeframePrefix+"FVG_");
         continue;
      }

      if(!SMC_IsFirstEnabledTimeframeSlot(timeframeStates,i))
         continue;

      string fvgPrefix=timeframePrefix+"FVG_";
      SMC_DeleteObjectsWithPrefix(fvgPrefix);
      if(!showFairValueGaps || !timeframeStates[i].valid ||
         timeframeStates[i].timeframe==config.chartTimeframe)
         continue;

      int periodSeconds=PeriodSeconds(timeframeStates[i].timeframe);
      datetime currentBarTime=
         iTime(config.symbol,timeframeStates[i].timeframe,0);
      if(periodSeconds<=0 || currentBarTime<=0)
      {
         PrintFormat("SMC: unable to render %s MTF fair value gaps (period=%d, current bar=%s).",
                     timeframeLabel,periodSeconds,
                     TimeToString(currentBarTime));
         continue;
      }

      int gapCount=ArraySize(timeframeStates[i].fairValueGaps);
      int displayCount=MathMin(maxFairValueGapsToShow,gapCount);
      bool selected[];
      if(ArrayResize(selected,gapCount)!=gapCount)
      {
         PrintFormat("SMC: unable to allocate %s MTF FVG selection (error=%d).",
                     timeframeLabel,GetLastError());
         continue;
      }
      ArrayInitialize(selected,false);
      for(int rank=0;rank<displayCount;rank++)
      {
         int newest=-1;
         for(int gap=0;gap<gapCount;gap++)
         {
            if(selected[gap])
               continue;
            if(newest<0 ||
               timeframeStates[i].fairValueGaps[gap].time>
               timeframeStates[i].fairValueGaps[newest].time)
               newest=gap;
         }
         if(newest>=0)
            selected[newest]=true;
      }
      SMC_DrawConfig timeframeConfig=config;
      timeframeConfig.objectPrefix=timeframePrefix;
      timeframeConfig.chartTimeframe=timeframeStates[i].timeframe;
      for(int rank=0;rank<displayCount;rank++)
      {
         int oldest=-1;
         for(int gap=0;gap<gapCount;gap++)
         {
            if(!selected[gap])
               continue;
            if(oldest<0 ||
               timeframeStates[i].fairValueGaps[gap].time<
               timeframeStates[i].fairValueGaps[oldest].time)
               oldest=gap;
         }
         if(oldest<0)
            break;
         selected[oldest]=false;
         FairValueGapState gap=timeframeStates[i].fairValueGaps[oldest];
         gap.right=currentBarTime+fairValueGapExtend*periodSeconds;
         color gapColor=(gap.bias>0 ? SMC_COLOR_FVG_BULLISH :
                                      SMC_COLOR_FVG_BEARISH);
         SMC_DrawFairValueGap(timeframeConfig,gap,gapColor);
      }
   }
}

#endif // SMC_DRAWMTFFVG_MQH
