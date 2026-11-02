// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_LIQUIDITY_MQH
#define SMC_LIQUIDITY_MQH

#include <SMC/SMC_Types.mqh>

void SMC_UpdateLiquidityFromEqualLevel(const EqualLevelEvent &event,
                                       const datetime confirmedAt,
                                       SMC_LiquidityState &state)
{
   if(!event.valid)
      return;

   SMC_LiquidityLevel level;
   ZeroMemory(level);
   level.valid=true;
   level.firstTime=event.firstTime;
   level.secondTime=event.secondTime;
   level.confirmedAt=confirmedAt;
   level.firstPrice=event.firstPrice;
   level.secondPrice=event.secondPrice;
   if(event.high)
      state.equalHigh=level;
   else
      state.equalLow=level;
}

double SMC_LiquidityPoolPrice(const SMC_LiquidityLevel &level,
                              const bool high)
{
   return high ? MathMax(level.firstPrice,level.secondPrice) :
                 MathMin(level.firstPrice,level.secondPrice);
}

bool SMC_DetectLiquiditySweepForLevel(SMC_LiquidityLevel &level,
                                      const bool high,
                                      const datetime barTime,
                                      const double barHigh,
                                      const double barLow,
                                      const double barClose,
                                      SMC_LiquiditySweepEvent &event)
{
   ZeroMemory(event);
   if(!level.valid || level.swept || level.invalidated ||
      barTime<=level.confirmedAt)
      return false;

   double poolPrice=SMC_LiquidityPoolPrice(level,high);
   bool swept=(high ? barHigh>poolPrice && barClose<poolPrice :
                      barLow<poolPrice && barClose>poolPrice);
   if(swept)
   {
      event.valid=true;
      event.high=high;
      event.time=barTime;
      event.poolPrice=poolPrice;
      event.wickExtreme=(high ? barHigh : barLow);
      event.close=barClose;
      level.swept=true;
      level.sweepTime=barTime;
      return true;
   }
   if((high && barClose>poolPrice) || (!high && barClose<poolPrice))
      level.invalidated=true;
   return false;
}

void SMC_DetectLiquiditySweeps(const datetime barTime,const double barHigh,
                               const double barLow,const double barClose,
                               SMC_LiquidityState &state,
                               SMC_LiquiditySweepEvent &highEvent,
                               SMC_LiquiditySweepEvent &lowEvent)
{
   SMC_DetectLiquiditySweepForLevel(state.equalHigh,true,barTime,barHigh,
                                    barLow,barClose,highEvent);
   SMC_DetectLiquiditySweepForLevel(state.equalLow,false,barTime,barHigh,
                                    barLow,barClose,lowEvent);
}

#endif // SMC_LIQUIDITY_MQH
