// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_LIQUIDITY_MQH
#define SMC_LIQUIDITY_MQH

#include <SMC/SMC_Types.mqh>

void SMC_UpdateLiquidityFromEqualLevel(const EqualLevelEvent &event,
                                       SMC_LiquidityState &state)
{
   if(!event.valid)
      return;

   SMC_LiquidityLevel level;
   level.valid=true;
   level.firstTime=event.firstTime;
   level.secondTime=event.secondTime;
   level.firstPrice=event.firstPrice;
   level.secondPrice=event.secondPrice;
   if(event.high)
      state.equalHigh=level;
   else
      state.equalLow=level;
}

#endif // SMC_LIQUIDITY_MQH
