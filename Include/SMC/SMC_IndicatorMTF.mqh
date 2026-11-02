// Indicator adapter for timeframe analysis slots, panel, and overlays.
#ifndef SMC_INDICATORMTF_MQH
#define SMC_INDICATORMTF_MQH

#include <SMC/SMC_TimeframeSlots.mqh>

void SMC_UpdateTimeframeAnalysis(const bool forceSetupRender=false)
{
   bool analyzeTimeframeBias=ShowMarketBias && ShowHigherTimeframeBias;
   bool analyzeTimeframeSetups=ShowMTFOrderBlocks || ShowMTFFairValueGaps;
   bool timeframeAnalysisChanged=false;
   if(analyzeTimeframeBias || ShowMTFStructureEvents ||
      analyzeTimeframeSetups)
   {
      for(int i=0;i<ArraySize(TimeframeBiasStates);i++)
      {
         if(!SMC_IsFirstEnabledTimeframeSlot(TimeframeBiasStates,i))
            continue;
         datetime latestClosedBar=
            iTime(_Symbol,TimeframeBiasStates[i].timeframe,1);
         if(latestClosedBar<=0)
         {
            if(TimeframeBiasStates[i].valid)
               timeframeAnalysisChanged=true;
            TimeframeBiasStates[i].valid=false;
            continue;
         }
         bool newClosedBar=
            latestClosedBar!=TimeframeBiasStates[i].lastClosedBar;
         if(newClosedBar && TimeframeBiasStates[i].valid)
         {
            TimeframeBiasStates[i].valid=false;
            timeframeAnalysisChanged=true;
         }
         if(newClosedBar &&
            (TimeframeBiasStates[i].lastAttemptClosedBar!=latestClosedBar ||
             TimeframeBiasStates[i].lastAttemptChartBar!=
                State.LastProcessedBar))
         {
            TimeframeBiasStates[i].lastAttemptClosedBar=latestClosedBar;
            TimeframeBiasStates[i].lastAttemptChartBar=State.LastProcessedBar;
            SMC_ComputeClosedTimeframeAnalysis(
               _Symbol,TimeframeBiasStates[i].timeframe,MaxBarsToProcess,
               SwingLength,InternalConfluenceFilter,SwingLabelSize,
               InternalLabelSize,OrderBlockFilter,OrderBlockMitigation,
               ShowMTFOrderBlocks,ShowMTFFairValueGaps,
               FairValueGapAutoThreshold,FairValueGapExtend,_Point,
               TimeframeBiasStates[i]);
            timeframeAnalysisChanged=true;
            if(TimeframeBiasStates[i].valid)
               TimeframeBiasStates[i].lastClosedBar=latestClosedBar;
         }
      }
   }
   SMC_UpdateMarketBiasLabel(DrawConfig,State.SwingBias,State.InternalBias,
                             ShowHigherTimeframeBias,
                             ShowMTFStructureEvents,TimeframeBiasStates);
   if(timeframeAnalysisChanged || forceSetupRender)
   {
      SMC_DrawMTFOrderBlocks(DrawConfig,TimeframeBiasStates,
                             ShowMTFOrderBlocks);
      SMC_DrawMTFFairValueGaps(DrawConfig,TimeframeBiasStates,
                               ShowMTFFairValueGaps,FairValueGapExtend,
                               MaxFairValueGapsToShow);
   }
}

#endif // SMC_INDICATORMTF_MQH
