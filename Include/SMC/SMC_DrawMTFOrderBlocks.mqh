// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWMTFORDERBLOCKS_MQH
#define SMC_DRAWMTFORDERBLOCKS_MQH

#include <SMC/SMC_DrawOrderBlocks.mqh>
#include <SMC/SMC_TimeframeSlots.mqh>

void SMC_DrawMTFOrderBlocks(
                           const SMC_DrawConfig &config,
                           const SMC_TimeframeBiasState &timeframeStates[],
                           const bool showOrderBlocks)
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
            SMC_DeleteObjectsWithPrefix(timeframePrefix+"OB_");
         continue;
      }

      if(!SMC_IsFirstEnabledTimeframeSlot(timeframeStates,i))
         continue;

      string orderBlockPrefix=timeframePrefix+"OB_";
      if(!showOrderBlocks || !timeframeStates[i].valid ||
         timeframeStates[i].timeframe==config.chartTimeframe)
      {
         SMC_DeleteObjectsWithPrefix(orderBlockPrefix);
         continue;
      }
      int periodSeconds=PeriodSeconds(timeframeStates[i].timeframe);
      datetime currentBarTime=
         iTime(config.symbol,timeframeStates[i].timeframe,0);
      if(periodSeconds<=0 || currentBarTime<=0)
      {
         PrintFormat("SMC: unable to render %s MTF order blocks (period=%d, current bar=%s).",
                     timeframeLabel,periodSeconds,
                     TimeToString(currentBarTime));
         SMC_DeleteObjectsWithPrefix(orderBlockPrefix);
         continue;
      }
      SMC_DrawConfig timeframeConfig=config;
      timeframeConfig.objectPrefix=timeframePrefix;
      timeframeConfig.chartTimeframe=timeframeStates[i].timeframe;
      SMC_DrawOrderBlockObjects(timeframeConfig,
                                timeframeStates[i].orderBlocks,
                                currentBarTime,periodSeconds);
   }
}

#endif // SMC_DRAWMTFORDERBLOCKS_MQH
