// Shared helpers for configured timeframe slots.
#ifndef SMC_TIMEFRAMESLOTS_MQH
#define SMC_TIMEFRAMESLOTS_MQH

bool SMC_HasEnabledTimeframe(const SMC_TimeframeBiasState &timeframeStates[],
                             const ENUM_TIMEFRAMES timeframe)
{
   for(int i=0;i<ArraySize(timeframeStates);i++)
      if(timeframeStates[i].enabled &&
         timeframeStates[i].timeframe==timeframe)
         return true;
   return false;
}

bool SMC_IsFirstEnabledTimeframeSlot(
                             const SMC_TimeframeBiasState &timeframeStates[],
                             const int slotIndex)
{
   if(slotIndex<0 || slotIndex>=ArraySize(timeframeStates) ||
      !timeframeStates[slotIndex].enabled)
      return false;

   for(int i=0;i<slotIndex;i++)
      if(timeframeStates[i].enabled &&
         timeframeStates[i].timeframe==timeframeStates[slotIndex].timeframe)
         return false;
   return true;
}

#endif // SMC_TIMEFRAMESLOTS_MQH
